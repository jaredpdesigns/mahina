import SwiftUI
import Combine

@main
struct ContentView: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var moonController = MoonController()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(moonController: moonController)
        } label: {
            if let phase = moonController.currentPhase {
                if let nsImage = renderedMoonImage(for: phase.day) {
                    Image(nsImage: nsImage)
                        .accessibilityLabel("Current moon phase: \(phase.name)")
                        .accessibilityValue("Lunar day \(phase.day)")
                } else {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .accessibilityLabel("Current moon phase: \(phase.name)")
                }
            } else {
                Image(systemName: "moon.fill")
                    .font(.system(size: 14))
                    .accessibilityLabel("Loading moon phase")
            }
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Image Rendering

    private func renderedMoonImage(for day: Int) -> NSImage? {
        let moonView = MoonImage(
            day: day,
            isDetailed: false,
            isAccentedRendering: true
        )
        .frame(width: 16, height: 16)

        let renderer = ImageRenderer(content: moonView)
        renderer.scale = 2.0 // For crisp rendering on Retina displays

        guard let nsImage = renderer.nsImage else { return nil }

        // Make it a template image so it adapts to system appearance
        nsImage.isTemplate = true

        return nsImage
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)
    }
}

// MARK: - Moon Controller

class MoonController: ObservableObject {
    @Published var currentPhase: MoonPhase?
    private var midnightTimer: Timer?

    init() {
        updateCurrentPhase()
        scheduleMidnightUpdate()
    }

    deinit {
        midnightTimer?.invalidate()
    }

    private func updateCurrentPhase() {
        currentPhase = MoonCalendarGenerator.phase(for: Date())
    }

    /*
     * Updates the displayed phase for a specific date
     */
    func updatePhase(for date: Date) {
        currentPhase = MoonCalendarGenerator.phase(for: date)
    }

    private func scheduleMidnightUpdate() {
        // Calculate seconds until next midnight
        let calendar = Calendar.current
        let now = Date()

        guard let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else {
            return
        }

        let secondsUntilMidnight = midnight.timeIntervalSince(now)

        // Schedule timer to fire at midnight
        midnightTimer?.invalidate()
        midnightTimer = Timer.scheduledTimer(withTimeInterval: secondsUntilMidnight, repeats: false) { [weak self] _ in
            self?.updateCurrentPhase()
            self?.scheduleDailyUpdates()
        }
    }

    private func scheduleDailyUpdates() {
        // Schedule daily updates every 24 hours after the first midnight
        midnightTimer?.invalidate()
        midnightTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.updateCurrentPhase()
        }
    }

    func refreshPhase() {
        updateCurrentPhase()
    }
}
