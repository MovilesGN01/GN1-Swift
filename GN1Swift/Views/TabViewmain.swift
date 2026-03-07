import SwiftUI

struct TabViewmain: View {

    var body: some View {

        ZStack {

            TabView {

                HomeView()
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }

                RidesView()
                    .tabItem {
                        Image(systemName: "car.fill")
                        Text("Rides")
                    }

                CommunityView()
                    .tabItem {
                        Image(systemName: "person.3.fill")
                        Text("Community")
                    }

                ProfileView()
                    .tabItem {
                        Image(systemName: "person.fill")
                        Text("Profile")
                    }
            }
            .tint(.primaryBrand)

            ChatBotButton()
                .padding(.trailing, 20)
                .padding(.bottom, 80)
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: .bottomTrailing)
        }
        .ignoresSafeArea(.keyboard)
    }
}
