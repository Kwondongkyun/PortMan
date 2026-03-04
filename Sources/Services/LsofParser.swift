import Foundation

enum LsofParser {
    static func parse(_ output: String) -> [PortInfo] {
        let lines = output.components(separatedBy: "\n")

        var results: [PortInfo] = []
        var seen = Set<Int>()

        for line in lines.dropFirst() {
            let columns = line.split(separator: " ", omittingEmptySubsequences: true)
            guard columns.count >= 9 else { continue }

            let processName = String(columns[0])
            guard let pid = Int(columns[1]) else { continue }
            let user = String(columns[2])

            let name = String(columns[columns.count - 2])
            guard let colonIndex = name.lastIndex(of: ":"),
                  let port = Int(name[name.index(after: colonIndex)...]) else { continue }

            if pid < 100 || user == "root" { continue }

            guard !seen.contains(port) else { continue }
            seen.insert(port)

            results.append(PortInfo(
                port: port,
                pid: pid,
                processName: processName,
                user: user,
                executablePath: "",
                workingDirectory: "",
                command: ""
            ))
        }

        return results.sorted { $0.port < $1.port }
    }

    static func resolveProcessDetails(pid: Int) async -> (executablePath: String, cwd: String, command: String) {
        async let execTask = resolveExecutablePath(pid: pid)
        async let cwdTask = resolveWorkingDirectory(pid: pid)
        async let cmdTask = resolveCommand(pid: pid)

        return await (execTask, cwdTask, cmdTask)
    }

    private static func resolveExecutablePath(pid: Int) async -> String {
        guard let result = try? await ProcessRunner.run(
            "/bin/ps", arguments: ["-p", String(pid), "-o", "comm="]
        ) else { return "" }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func resolveWorkingDirectory(pid: Int) async -> String {
        guard let result = try? await ProcessRunner.run(
            "/usr/sbin/lsof", arguments: ["-p", String(pid), "-a", "-d", "cwd", "-Fn"]
        ) else { return "" }

        // lsof -Fn 출력에서 "n" 접두사가 붙은 경로를 찾음
        for line in result.stdout.components(separatedBy: "\n") {
            if line.hasPrefix("n") && line.contains("/") {
                return String(line.dropFirst())
            }
        }
        return ""
    }

    private static func resolveCommand(pid: Int) async -> String {
        guard let result = try? await ProcessRunner.run(
            "/bin/ps", arguments: ["-p", String(pid), "-o", "args="]
        ) else { return "" }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
