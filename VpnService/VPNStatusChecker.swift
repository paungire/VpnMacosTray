import Foundation

class VPNStatusChecker: ObservableObject {
    @Published var mode: Bool = false

    private var isRunning = false

    func startTimer() {
        // Убедитесь, что не запускаем несколько процессов одновременно
        guard !isRunning else { return }

        isRunning = true
        checkVPNStatus()
    }

    func stopTimer() {
        isRunning = false
    }

    private func checkVPNStatus() {
        // Проводим асинхронный запрос на проверку статуса VPN
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "scutil --nc status FoXray"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
        } catch {
            print("Ошибка запуска команды: \(error)")
            return
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            print("Ошибка чтения вывода команды")
            return
        }

        let isConnected = !output.components(separatedBy: "\n")[0].contains("Disconnected")

        DispatchQueue.main.async {
            self.mode = isConnected
        }

        // Проверяем статус каждую миллисекунду (например, через 100 миллисекунд)
        if isRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.checkVPNStatus()
            }
        }
    }

    func toggleVPN() {
        print(mode ?
            "Connecting..." :
            "Disconnecting...")
        runShellCommandAsync(command: mode ?
            "networksetup -disconnectpppoeservice FoXray" :
            "networksetup -connectpppoeservice FoXray")
    }

    private func runShellCommandAsync(command: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.launch()
    }
}
