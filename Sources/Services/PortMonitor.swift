import SwiftUI
import Combine

@MainActor
class PortMonitor: ObservableObject {
    @Published var ports: [PortInfo] = []
    @Published var isLoading = false
    @Published var lastUpdated: Date?
    @Published var errorMessage: String?
    @Published var searchText = ""

    private var cancellables = Set<AnyCancellable>()

    var filteredPorts: [PortInfo] {
        guard !searchText.isEmpty else { return ports }
        let query = searchText.lowercased()
        return ports.filter {
            String($0.port).contains(query) ||
            $0.processName.lowercased().contains(query) ||
            $0.workingDirectory.lowercased().contains(query) ||
            $0.command.lowercased().contains(query)
        }
    }

    init() {
        startAutoRefresh()
    }

    private func startAutoRefresh() {
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
            .store(in: &cancellables)
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await ProcessRunner.run(
                "/usr/sbin/lsof",
                arguments: ["-nP", "-iTCP", "-sTCP:LISTEN"]
            )
            var parsed = LsofParser.parse(result.stdout)

            parsed = await withTaskGroup(of: (Int, String, String, String).self) { group in
                for (index, port) in parsed.enumerated() {
                    group.addTask {
                        let details = await LsofParser.resolveProcessDetails(pid: port.pid)
                        return (index, details.executablePath, details.cwd, details.command)
                    }
                }
                var updated = parsed
                for await (index, exec, cwd, cmd) in group {
                    if index < updated.count {
                        updated[index] = PortInfo(
                            port: updated[index].port,
                            pid: updated[index].pid,
                            processName: updated[index].processName,
                            user: updated[index].user,
                            executablePath: exec,
                            workingDirectory: cwd,
                            command: cmd
                        )
                    }
                }
                return updated
            }

            ports = parsed
            lastUpdated = Date()
        } catch {
            errorMessage = "포트 스캔 실패: \(error.localizedDescription)"
        }
    }

    func killPort(_ portInfo: PortInfo, force: Bool = false) async -> Bool {
        do {
            let result = try await ProcessRunner.killProcess(pid: portInfo.pid, force: force)
            if result.exitCode == 0 {
                await refresh()
                return true
            }
            errorMessage = "종료 실패 (exit code: \(result.exitCode))"
            return false
        } catch {
            errorMessage = "종료 실패: \(error.localizedDescription)"
            return false
        }
    }
}
