import SwiftUI

struct PortListView: View {
    @StateObject private var monitor = PortMonitor()
    @State private var expandedPortId: Int?

    var body: some View {
        VStack(spacing: 0) {
            header
            searchBar
            Divider()

            if monitor.isLoading && monitor.ports.isEmpty {
                loadingState
            } else if monitor.filteredPorts.isEmpty {
                emptyState
            } else {
                portList
            }

            Divider()
            footer
        }
        .frame(width: 520, height: 480)
        .task {
            await monitor.refresh()
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "network")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue.gradient)

            Text("PortMan")
                .font(.system(size: 15, weight: .bold))

            Spacer()

            if monitor.isLoading {
                ProgressView()
                    .controlSize(.small)
            }

            Text("\(monitor.ports.count)개 포트")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: Capsule())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            TextField("포트, 프로세스, 경로 검색...", text: $monitor.searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 12))

            if !monitor.searchText.isEmpty {
                Button {
                    monitor.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 14)
        .padding(.bottom, 8)
    }

    // MARK: - Port List

    private var portList: some View {
        ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(monitor.filteredPorts) { port in
                    PortRowView(
                        portInfo: port,
                        isExpanded: expandedPortId == port.id,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                expandedPortId = expandedPortId == port.id ? nil : port.id
                            }
                        },
                        onKill: {
                            Task { await monitor.killPort(port) }
                        }
                    )
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
        }
    }

    // MARK: - States

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text("포트 스캔 중...")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: monitor.searchText.isEmpty ? "checkmark.circle.fill" : "magnifyingglass")
                .font(.system(size: 36))
                .foregroundStyle(monitor.searchText.isEmpty ? Color.green : Color.secondary)

            Text(monitor.searchText.isEmpty ? "열려있는 포트가 없습니다" : "검색 결과가 없습니다")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)

            if !monitor.searchText.isEmpty {
                Text("다른 키워드로 검색해보세요")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 12) {
            if let error = monitor.errorMessage {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .lineLimit(1)
            } else if let date = monitor.lastUpdated {
                Image(systemName: "clock")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Text(date.formatted(date: .omitted, time: .standard))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                Task { await monitor.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .disabled(monitor.isLoading)

            Divider()
                .frame(height: 14)

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Text("종료")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }
}
