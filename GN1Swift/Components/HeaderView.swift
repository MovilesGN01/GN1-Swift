import SwiftUI

struct HeaderView: View {
    let weather: WeatherSnapshot
    let userName: String   // ← nuevo
    
    var body: some View {
        HStack {
            
            Image("avatar")
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                
                Text("Good morning,")
                    .font(.custom("Poppins-Regular", size: 16))
                    .foregroundColor(.textSecondary)
                
                Text(userName)   // ← dinámico
                    .font(.custom("Poppins-Bold", size: 24))
                
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.primaryBrand)
                    
                    Text("VERIFIED STUDENT")
                        .font(.custom("Poppins-SemiBold", size: 12))
                        .foregroundColor(.primaryBrand)
                }
            }
            
            Spacer()
            
            WeatherBadge(weather: weather)
            
            Image(systemName: "bell")
                .font(.title3)
        }
    }
}
