import SwiftUI

struct TabViewmain: View {

    @Binding var isLoggedIn: Bool
    @State private var showChat = false
    @State private var selectedTab = 0

    var body: some View {

        ZStack {

            TabView(selection: $selectedTab) {

                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                    .tag(0)

                RidesView(selectedTab: $selectedTab)
                    .tabItem {
                        Image(systemName: "car.fill")
                        Text("Rides")
                    }
                    .tag(1)

                CommunityView()
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Community")
                    }
                    .tag(2)

                ProfileView(isLoggedIn: $isLoggedIn)
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
                    .tag(3)
            }
            .tint(.primaryBrand)

            ChatBotButton {
                showChat = true
            }
            .padding(.trailing, 20)
            .padding(.bottom, 80)
            .frame(maxWidth: .infinity,
                   maxHeight: .infinity,
                   alignment: .bottomTrailing)
        }
        .sheet(isPresented: $showChat) {
            ChatView()
        }
        .ignoresSafeArea(.keyboard)
    }
}
