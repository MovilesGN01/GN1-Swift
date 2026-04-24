import SwiftUI

struct BadgeImageView: View {
    let badgeIcon: String
    let color: String
    let isUnlocked: Bool
    let size: CGFloat = 80
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isUnlocked ? getColor(color).opacity(0.2) : Color.gray.opacity(0.1))
                .frame(width: size, height: size)
            
            if isUnlocked {
                Circle()
                    .stroke(getColor(color), lineWidth: 2)
                    .frame(width: size, height: size)
                
                Image(systemName: badgeIcon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(getColor(color))
            } else {
                Image(systemName: badgeIcon)
                    .font(.system(size: size * 0.4))
                    .foregroundColor(.gray.opacity(0.5))
            }
        }
    }
    
    private func getColor(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .primaryBrand
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "yellow": return .yellow
        case "purple": return .purple
        default: return .primaryBrand
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        BadgeImageView(
            badgeIcon: "star.fill",
            color: "blue",
            isUnlocked: true
        )
        
        BadgeImageView(
            badgeIcon: "flame.fill",
            color: "orange",
            isUnlocked: false
        )
    }
}
