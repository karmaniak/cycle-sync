import SwiftUI
import CycleCore

struct SharerTabView: View {
    @EnvironmentObject private var sharer: SharerStore

    var body: some View {
        TabView {
            SharerTodayView()
                .tabItem { Label(Copy.Tabs.today, systemImage: "sun.max") }
            SharingView()
                .tabItem { Label(Copy.Tabs.sharing, systemImage: "heart.circle") }
            LearnView(currentPhase: sharer.estimate?.phase)
                .tabItem { Label(Copy.Tabs.learn, systemImage: "book") }
            SharerSettingsView()
                .tabItem { Label(Copy.Tabs.settings, systemImage: "gearshape") }
        }
        .tint(Color(ColorScale.color(at: 0.6)))
    }
}
