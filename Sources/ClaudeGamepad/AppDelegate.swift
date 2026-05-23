import AppKit
import GameController

/// Menu bar application delegate.
/// Manages the status bar icon, menu, and coordinates all subsystems.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var settingsWindow: SettingsWindow?

    private var accessibilityTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        requestPermissions()
    }

    // MARK: - Status Bar

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "Claude Gamepad")
            button.image?.isTemplate = true
            // Gray when no controller
            button.appearsDisabled = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Claude Gamepad Controller", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())

        let statusMenuItem = NSMenuItem(title: "No controller connected", action: nil, keyEquivalent: "")
        statusMenuItem.tag = 100
        menu.addItem(statusMenuItem)

        // Accessibility warning — tag 101, hidden when AX is granted
        let axItem = NSMenuItem(title: "⚠️ Grant Accessibility to enable buttons", action: #selector(openAccessibilitySettings), keyEquivalent: "")
        axItem.tag = 101
        axItem.isHidden = AXIsProcessTrusted()
        menu.addItem(axItem)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))

        for item in menu.items {
            if item.action != nil {
                item.target = self
            }
        }

        statusItem.menu = menu
    }

    // MARK: - Gamepad

    private func setupGamepad() {
        let manager = GamepadManager.shared

        manager.onControllerConnected = { [weak self] name in
            DispatchQueue.main.async {
                self?.statusItem.button?.appearsDisabled = false
                self?.updateStatusMenuItem("🎮 \(name)")
            }
        }

        manager.onControllerDisconnected = { [weak self] in
            DispatchQueue.main.async {
                self?.statusItem.button?.appearsDisabled = true
                self?.updateStatusMenuItem("No controller connected")
            }
        }

        manager.start()
    }

    private func updateStatusMenuItem(_ text: String) {
        guard let menu = statusItem.menu,
              let item = menu.item(withTag: 100) else { return }
        item.title = text
    }

    // MARK: - Permissions

    private func requestPermissions() {
        // Gamepad detection (GCController) does not require Accessibility —
        // start it immediately so a connected controller is recognised at launch.
        setupGamepad()

        // Accessibility is only needed for key simulation. If not yet granted,
        // prompt macOS to show the permission dialog and poll until AX is trusted.
        if !AXIsProcessTrusted() {
            AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary)
            accessibilityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self?.accessibilityTimer = nil
                    DispatchQueue.main.async { self?.updateAccessibilityMenuItem() }
                }
            }
        }
    }

    private func updateAccessibilityMenuItem() {
        guard let menu = statusItem.menu,
              let item = menu.item(withTag: 101) else { return }
        item.isHidden = AXIsProcessTrusted()
    }

    // MARK: - Menu Actions

    @objc private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }

    @objc private func openSettings() {
        if settingsWindow == nil {
            settingsWindow = SettingsWindow()
        }
        settingsWindow?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }
}
