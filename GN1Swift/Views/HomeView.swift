import SwiftUI

struct HomeView: View {
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    HeaderView()
                    
                    Text("Plan Your Commute")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.textPrimary)
                    
                    CommuteCard()
                    
                    Text("Explore Alternatives")
                        .font(.custom("Poppins-Bold", size: 22))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 16) {
                        AlternativeCard(
                            icon: "car.fill",
                            title: "Carpool",
                            subtitle: "Shared rides with peers"
                        )
                        
                        AlternativeCard(
                            icon: "bus.fill",
                            title: "University Bus",
                            subtitle: "Scheduled campus routes"
                        )
                    }
                    
                    HStack {
                        Text("Recurring Rides")
                            .font(.custom("Poppins-Bold", size: 22))
                        
                        Spacer()
                        
                        Text("View All")
                            .foregroundColor(.primaryBrand)
                            .font(.custom("Poppins-Medium", size: 14))
                    }
                    
                    RecurringRideCard(
                        icon: "house",
                        title: "Home to Engineering Lab",
                        subtitle: "Mon, Wed, Fri • 08:30 AM"
                    )
                    
                    RecurringRideCard(
                        icon: "graduationcap",
                        title: "Campus to Chapinero",
                        subtitle: "Daily • 05:45 PM"
                    )
                    
                }
                .padding()
            }
            .background(Color.backgroundApp)
        }
    }
}
