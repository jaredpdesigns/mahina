import SwiftUI
import MahinaAssets

/// Root view that routes to the appropriate layout based on device
struct ContentView: View {
    @State private var displayedMonth: Date = Date()
    @State private var activeDate: Date = Date()
    @State private var scrollTarget: Date? = nil
    @State private var isInitialLoading: Bool = true
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                iPadView(
                    displayedMonth: $displayedMonth,
                    activeDate: $activeDate,
                    scrollTarget: $scrollTarget
                )
            } else {
                iPhoneView(
                    displayedMonth: $displayedMonth,
                    activeDate: $activeDate,
                    scrollTarget: $scrollTarget,
                    isInitialLoading: $isInitialLoading
                )
            }
        }
        .onOpenURL { url in
            handleWidgetURL(url)
        }
    }
    
    /*
     * Handles URLs from widgets and shortcuts
     * Supports: mahina://today and mahina://date/[ISO8601-date]
     */
    private func handleWidgetURL(_ url: URL) {
        let calendar = Calendar.current
        
        guard url.scheme == "mahina" else { return }
        
        if url.host == "today" {
            let today = calendar.startOfDay(for: Date())
            displayedMonth = today
            activeDate = today
            scrollTarget = today
            HapticManager.success()
        } else if url.host == "date", url.pathComponents.count > 1 {
            let dateString = url.pathComponents[1]
            let formatter = ISO8601DateFormatter()
            
            if let targetDate = formatter.date(from: dateString) {
                let normalized = calendar.startOfDay(for: targetDate)
                displayedMonth = normalized
                activeDate = normalized
                scrollTarget = normalized
                HapticManager.success()
            }
        }
        
        /* Skip loading screen when launching via deep link */
        if isInitialLoading {
            withAnimation(.easeOut(duration: 0.3)) {
                isInitialLoading = false
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let today = Date()
    
    private var currentPhase: MoonPhase {
        MoonCalendarGenerator.phase(for: today).primary
    }
    
    var body: some View {
        VStack(spacing: 16) {
            MoonImage(
                day: currentPhase.day,
                isDetailed: true,
                accessibilityLabel: "Current moon phase",
                accessibilityValue: currentPhase.name
            )
            .frame(width: 64, height: 64)
            .scaleEffect(1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: currentPhase.day
            )
            
            Text(currentPhase.name)
                .font(.largeTitle)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
