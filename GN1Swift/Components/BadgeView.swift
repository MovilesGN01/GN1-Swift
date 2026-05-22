import SwiftUI

struct BadgeView: View, Equatable {
    let badge: Badge
    let size: CGFloat = 80
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? Color.primaryBrand.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: size, height: size)
                
                if badge.isUnlocked {
                    Circle()
                        .stroke(Color.primaryBrand, lineWidth: 2)
                        .frame(width: size, height: size)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.primaryBrand)
                } else {
                    Image(systemName: badge.icon)
                        .font(.system(size: size * 0.4))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    if let progress = badge.progress {
                        ZStack(alignment: .bottom) {
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                                .frame(width: size, height: size)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(progress) / 100.0)
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                                .frame(width: size, height: size)
                                .rotationEffect(.degrees(-90))
                        }
                    }
                }
            }
            .drawingGroup()

            Text(badge.name)
                .font(.custom("Poppins-SemiBold", size: 12))
                .foregroundColor(.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: size + 12)
    }
}

#Preview {
    VStack(spacing: 20) {
        BadgeView(badge: Badge(
            id: "first_ride",
            name: "First Ride",
            description: "Complete your first ride",
            icon: "figure.walk",
            color: "blue",
            unlockedAt: Date(),
            progress: nil
        ))
        
        BadgeView(badge: Badge(
            id: "streak_5",
            name: "5-Day Streak",
            description: "5 consecutive rides",
            icon: "flame.fill",
            color: "orange",
            unlockedAt: nil,
            progress: 60
        ))
    }
}
