import SwiftUI

struct PortRowView: View {
    let portInfo: PortInfo
    let isExpanded: Bool
    let onToggle: () -> Void
    let onKill: () -> Void

    @State private var isRowHovered = false
    @State private var isKillHovered = false
    @State private var showConfirm = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 메인 행
            HStack(spacing: 10) {
                // 포트 번호 뱃지
                Text("\(portInfo.port)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(portColor.gradient, in: RoundedRectangle(cornerRadius: 5))

                // 프로세스 정보
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(portInfo.processName)
                            .font(.system(size: 13, weight: .semibold))

                        Text("PID \(portInfo.pid)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 3))
                    }

                    // 실행 경로 (cwd)
                    if !portInfo.workingDirectory.isEmpty {
                        HStack(spacing: 3) {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.secondary)
                            Text(portInfo.displayCwd)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                Spacer()

                // Kill 버튼 or 확인 버튼들
                if showConfirm {
                    confirmButtons
                } else {
                    Button {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            showConfirm = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(isKillHovered ? .red : Color(.tertiaryLabelColor))
                    }
                    .buttonStyle(.plain)
                    .onHover { isKillHovered = $0 }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .onTapGesture {
                if !showConfirm {
                    onToggle()
                }
            }

            // 확장 영역 - 상세 정보
            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if !portInfo.executablePath.isEmpty {
                        detailRow(icon: "app.fill", label: "실행 파일", value: portInfo.displayPath)
                    }
                    if !portInfo.command.isEmpty {
                        detailRow(icon: "terminal.fill", label: "커맨드", value: portInfo.command)
                    }
                    if !portInfo.workingDirectory.isEmpty {
                        detailRow(icon: "folder.fill", label: "작업 디렉토리", value: portInfo.displayCwd)
                    }
                    detailRow(icon: "person.fill", label: "사용자", value: portInfo.user)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
                .padding(.leading, 52)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(isRowHovered ? Color(.unemphasizedSelectedContentBackgroundColor).opacity(0.5) : .clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onHover { isRowHovered = $0 }
    }

    // MARK: - 인라인 확인 UI

    private var confirmButtons: some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    showConfirm = false
                }
            } label: {
                Text("취소")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)

            Button {
                showConfirm = false
                onKill()
            } label: {
                Text("종료")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.red.gradient, in: RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
                .frame(width: 12)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.tertiary)
                .frame(width: 60, alignment: .leading)
            Text(value)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }

    private var portColor: Color {
        switch portInfo.port {
        case 0..<1024: return .red
        case 1024..<10000: return .blue
        case 10000..<30000: return .purple
        case 30000..<50000: return .orange
        default: return .gray
        }
    }
}
