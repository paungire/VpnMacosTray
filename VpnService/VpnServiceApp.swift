//
//  VpnServiceApp.swift
//  VpnService
//
//  Created by Григорий Алексеев on 02.12.2024.
//

import SwiftUI

@main
struct VpnServiceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // WindowGroup {
        //    ContentView().hidden() // Скрыть основное окно приложения, если оно не нужно
        // }
        Settings {
            EmptyView() // Если настройки нужны в будущем
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var statusMenu: NSMenu?
    var vpnStatus = VPNStatusChecker()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Создаем статус-бар элемент
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // Проверяем, что статус-бар элемент создан
        guard let button = statusItem?.button else { return }

        // Устанавливаем кастомное представление через SwiftUI
        let hostingView = NSHostingView(rootView: StatusBarView(vpnStatus: vpnStatus))
        hostingView.frame = NSRect(x: 0, y: 0, width: 36, height: 22)

        button.addSubview(hostingView)
        button.frame = hostingView.frame

        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        button.action = #selector(handleClick(sender:))

        statusMenu = NSMenu()
        statusMenu?.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    @objc func handleClick(sender: NSStatusBarButton) {
        let currentEvent = NSApp.currentEvent!
        Task {
            if currentEvent.type == .rightMouseUp {
                if let menu = statusMenu {
                    statusItem?.menu = menu
                    await statusItem?.button?.performClick(nil)
                    statusItem?.menu = nil
                }
            } else if currentEvent.type == .leftMouseUp {
                print("<clicked>")
                vpnStatus.toggleVPN() // Переключаем иконку после изменения состояния VPN
            }
        }
    }
}

struct StatusBarView: View {
    @ObservedObject var vpnStatus: VPNStatusChecker

    var body: some View {
        ZStack {
            if vpnStatus.mode {
                Color.pink
            }
            Image(.trayIcon)
        }
        .frame(width: 36, height: 22)
        .cornerRadius(4)
        .onAppear {
            vpnStatus.startTimer()
        }
    }
}
