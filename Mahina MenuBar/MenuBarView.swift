import SwiftUI
import Foundation
import AppKit

struct MenuBarView: View {
    @ObservedObject var moonController: MoonController
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Computed Properties
    
    private var navigationTitleString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = "EEEE, LLLL d, yyyy"
        return formatter.string(from: Date())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let phase = moonController.currentPhase {
                HStack() {
                    Text(navigationTitleString)
                        .font(.title3)
                        .fontWeight(.semibold)
                    Spacer()
                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }.buttonStyle(.borderless)
                }.padding()
                Divider()
                VStack() {
                    DayDetail(
                        date: Date(),
                        phase: phase,
                        displayMode: .full
                    )
                }.padding()
            }
        }
        .frame(width: 360)
    }
}
