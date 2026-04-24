import SwiftUI

struct AchievementNotificationView: View {
    let badge: Badge?
    let pointsEarned: Int
    let isPresented: Bool
    
    var body: some View {
        if isPresented, let badge = badge {
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: badge.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.yellow)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Badge Unlocked!")
                            .font(.custom("Poppins-Bold", size: 14))
                            .foregroundColor(.white)
                        
                        Text(badge.name)
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("+\(pointsEarned)")
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.yellow)
                        
                        Text("points")
                            .font(.custom("Poppins-Regular", size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(12)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.primaryBrand, Color.primaryBrand.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(16)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

#Preview {
    AchievementNotificationView(
        badge: Badge(
            id: "first_ride",
            name: "First Ride",
            description: "Complete your first ride",
            icon: "figure.walk",
            color: "blue",
            unlockedAt: Date(),
            progress: nil
        ),
        pointsEarned: 50,
        isPresented: true
    )
}
