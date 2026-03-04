import Foundation

struct PortInfo: Identifiable, Hashable {
    var id: Int { port }
    let port: Int
    let pid: Int
    let processName: String
    let user: String
    let executablePath: String
    let workingDirectory: String
    let command: String

    var displayPath: String {
        shortenHome(executablePath)
    }

    var displayCwd: String {
        shortenHome(workingDirectory)
    }

    private func shortenHome(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }
}
