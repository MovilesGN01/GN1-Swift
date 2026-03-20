import SwiftUI

struct RideDetailView: View {

    let ride: RideItem

    var body: some View {
        VStack {

            ScrollView {
                VStack(spacing: 16) {

                    // 🔹 DRIVER CARD
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Circle()
                                .fill(Color.primaryBrand.opacity(0.2))
                                .frame(width: 56, height: 56)
                                .overlay(
                                    Text(ride.initial)
                                        .font(.custom("Poppins-Bold", size: 20))
                                        .foregroundColor(.primaryBrand)
                                )

                            VStack(alignment: .leading) {
                                Text(ride.name)
                                    .font(.custom("Poppins-Bold", size: 18))

                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)

                                    Text("\(ride.rating)")
                                }
                            }

                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color.surfaceCard)
                    .cornerRadius(20)

                    // 🔹 TRIP SUMMARY
                    section(title: "Trip summary") {
                        detail(icon: "location", label: "From", value: ride.from)
                        Divider()
                        detail(icon: "flag", label: "To", value: ride.to)
                        Divider()
                        detail(icon: "clock", label: "Departure", value: "\(ride.time) • ETA \(ride.eta)")
                        Divider()
                        detail(icon: "dollarsign.circle", label: "Price", value: ride.price)
                    }
                    
                    section(title: "Meeting points") {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            detail(icon: "mappin.and.ellipse", label: "Pickup", value: "Calle 67 #7-35")
                            Divider()
                            detail(icon: "mappin", label: "Drop-off", value: "Uniandes Main Gate")
                            
                        }
                    }

                    // 🔹 VEHICLE
                    section(title: "Vehicle") {
                        detail(icon: "person.3", label: "Seats", value: "\(ride.seats)")
                    }


                    section(title: "About this ride") {
                        Text("This is a regular commute within the Uniandes community. The driver follows a consistent schedule and prioritizes punctuality and comfort for all passengers.")
                            .font(.custom("Poppins-Regular", size: 14))
                            .foregroundColor(.textSecondary)
                    }
                    // 🔹 SAFETY
                    section(title: "Safety signals") {
                        VStack(alignment: .leading, spacing: 12) {
                            
                            safetyRow(text: "Verified university profile")
                            Divider()
                            safetyRow(text: "High rating driver")
                            Divider()
                            safetyRow(text: "Trusted community ride")
                            
                        }
                    }
                }
                .padding()
            }

            // 🔹 BOTONES ABAJO
            HStack {
                Button {
                    print("Chat")
                } label: {
                    Text("Chat")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryBrand)
                        )
                }

                Button {
                    print("Reserve")
                } label: {
                    Text("Reserve")
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.primaryBrand)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(Color.backgroundApp)
        .navigationTitle("Ride Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // 🔧 COMPONENTES

    func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 16))

            content()
        }
        .padding()
        .background(Color.surfaceCard)
        .cornerRadius(16)
    }

    func detail(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.primaryBrand)

            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                Text(value)
                    .font(.custom("Poppins-SemiBold", size: 14))
            }

            Spacer()
        }
    }
    func safetyRow(text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)

            Text(text)
                .font(.custom("Poppins-Medium", size: 14))
                .foregroundColor(.textPrimary)

            Spacer()
        }
    }
}
