import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "square.grid.2x2.fill")
                    Text("Home")
                }
                .tag(AppState.Tab.home)
            
            MapScreenView()
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(AppState.Tab.map)
        }
        .tint(AppColors.primaryBlue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
