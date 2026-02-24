import SwiftUI
import MahinaAssets

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    let moonController = MoonController()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            moonController.handleURL(url)
        }
    }
}

@main
struct ContentView: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra {
            MenuBarView(moonController: appDelegate.moonController)
        } label: {
            if let phaseResult = appDelegate.moonController.currentPhase {
                if let nsImage = renderedMoonImage(for: phaseResult) {
                    Image(nsImage: nsImage)
                        .accessibilityLabel("Current moon phase: \(phaseResult.primary.name)")
                        .accessibilityValue("Lunar day \(phaseResult.primary.day)")
                } else {
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .accessibilityLabel("Current moon phase: \(phaseResult.primary.name)")
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
    
    @ViewBuilder
    private func menuBarMoonView(for phaseResult: PhaseResult) -> some View {
        if phaseResult.isTransitionDay, let secondary = phaseResult.secondary {
            SplitMoonImage(
                primaryDay: phaseResult.primary.day,
                secondaryDay: secondary.day,
                isDetailed: false,
                isAccentedRendering: true
            )
            .frame(width: 18, height: 18)
        } else {
            MoonImage(
                day: phaseResult.primary.day,
                isDetailed: false,
                isAccentedRendering: true
            )
            .frame(width: 16, height: 16)
        }
    }
    
    private func renderedMoonImage(for phaseResult: PhaseResult) -> NSImage? {
        let view = menuBarMoonView(for: phaseResult)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        
        guard let nsImage = renderer.nsImage else { return nil }
        nsImage.isTemplate = true
        
        return nsImage
    }
}

// MARK: - Moon Controller

@Observable
class MoonController {
    var currentPhase: PhaseResult?
    var activeDate: Date
    var displayedMonth: Date
    private var midnightTimer: Timer?
    
    init() {
        let today = Calendar.current.startOfDay(for: Date())
        self.activeDate = today
        self.displayedMonth = today
        updateCurrentPhase()
        scheduleMidnightUpdate()
    }
    
    deinit {
        midnightTimer?.invalidate()
    }
    
    private func updateCurrentPhase() {
        currentPhase = MoonCalendarGenerator.phase(for: activeDate)
    }
    
    func updatePhase(for date: Date) {
        let calendar = Calendar.current
        let normalized = calendar.startOfDay(for: date)
        activeDate = normalized
        currentPhase = MoonCalendarGenerator.phase(for: normalized)
        if !calendar.isDate(normalized, equalTo: displayedMonth, toGranularity: .month) {
            displayedMonth = normalized
        }
    }
    
    func goToToday() {
        let today = Calendar.current.startOfDay(for: Date())
        updatePhase(for: today)
    }
    
    /*
     * Parses a mahina:// deep link URL and navigates to the requested date.
     * Supports: mahina://today, mahina://date/{ISO8601}
     */
    func handleURL(_ url: URL) {
        guard url.scheme == "mahina" else { return }
        
        switch url.host {
        case "today":
            goToToday()
        case "date":
            let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let formatter = ISO8601DateFormatter()
            if let date = formatter.date(from: path) {
                updatePhase(for: date)
            }
        default:
            break
        }
    }
    
    private func scheduleMidnightUpdate() {
        let calendar = Calendar.current
        let now = Date()
        
        guard let midnight = calendar.nextDate(after: now, matching: DateComponents(hour: 0, minute: 0, second: 0), matchingPolicy: .nextTime) else {
            return
        }
        
        let secondsUntilMidnight = midnight.timeIntervalSince(now)
        
        midnightTimer?.invalidate()
        midnightTimer = Timer.scheduledTimer(withTimeInterval: secondsUntilMidnight, repeats: false) { [weak self] _ in
            self?.goToToday()
            self?.scheduleDailyUpdates()
        }
    }
    
    private func scheduleDailyUpdates() {
        midnightTimer?.invalidate()
        midnightTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.goToToday()
        }
    }
}
