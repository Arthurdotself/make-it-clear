import AppKit
import SwiftUI

@main
struct MakeItClearApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        MenuBarExtra("Make It Clear", systemImage: "text.badge.checkmark") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu bar only: no Dock icon, no main window.
        NSApp.setActivationPolicy(.accessory)
        installEditMenu()
        if ProcessInfo.processInfo.environment["MAKEITCLEAR_DEBUG_MENU"] == "1" {
            let keys = NSApp.mainMenu?.items.flatMap { $0.submenu?.items ?? [] }.map(\.keyEquivalent) ?? []
            print("edit shortcuts:", ["x", "c", "v", "a", "z"].filter(keys.contains))
            exit(0)
        }
    }

    /// Menu bar apps have no visible menus, so ⌘X/⌘C/⌘V/⌘A/⌘Z only work if an Edit menu exists.
    private func installEditMenu() {
        let mainMenu = NSApp.mainMenu ?? NSMenu()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        let item = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        item.submenu = edit
        mainMenu.addItem(item)
        NSApp.mainMenu = mainMenu
    }
}
