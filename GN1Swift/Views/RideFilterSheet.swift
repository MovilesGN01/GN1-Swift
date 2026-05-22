import SwiftUI

struct RideFilterSheet: View {
    @Environment(\.dismiss) private var dismiss

    let zones: [String]
    @Binding var selectedZone: String
    @Binding var minSeats: Int
    @Binding var minRating: Double

    private let ratingOptions: [(label: String, value: Double)] = [
        ("All", 0.0), ("4.0+", 4.0), ("4.5+", 4.5)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    zoneSection
                    seatsSection
                    ratingSection
                }
                .padding(20)
            }
            .background(Color.backgroundApp)
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        selectedZone = "All"
                        minSeats    = 1
                        minRating   = 0.0
                    }
                    .font(.custom("Poppins-Medium", size: 15))
                    .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.primaryBrand)
                }
            }
        }
    }

    // MARK: - Zone

    private var zoneSection: some View {
        filterBlock("Zone") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(zones, id: \.self) { zone in
                        let active = selectedZone == zone
                        Button { selectedZone = zone } label: {
                            HStack(spacing: 5) {
                                if zone != "All" {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 12))
                                }
                                Text(zone)
                                    .font(.custom("Poppins-SemiBold", size: 13))
                            }
                            .foregroundColor(active ? .white : .textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(active ? Color.primaryBrand : Color.surfaceCard)
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(active ? Color.primaryBrand : Color.borderLine, lineWidth: 1))
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    // MARK: - Seats

    private var seatsSection: some View {
        filterBlock("Minimum Seats") {
            HStack {
                Spacer()
                Button {
                    if minSeats > 1 { minSeats -= 1 }
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(minSeats > 1 ? .primaryBrand : .placeholderMuted)
                        .frame(width: 48, height: 48)
                        .background(Color.surfaceCard)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.borderLine, lineWidth: 1))
                        .cornerRadius(14)
                }
                .disabled(minSeats <= 1)

                VStack(spacing: 2) {
                    Text("\(minSeats)")
                        .font(.custom("Poppins-Bold", size: 48))
                        .foregroundColor(.textPrimary)
                    Text("or more")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.placeholderMuted)
                }
                .frame(width: 110)

                Button {
                    if minSeats < 8 { minSeats += 1 }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(minSeats < 8 ? .primaryBrand : .placeholderMuted)
                        .frame(width: 48, height: 48)
                        .background(Color.surfaceCard)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.borderLine, lineWidth: 1))
                        .cornerRadius(14)
                }
                .disabled(minSeats >= 8)
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Rating

    private var ratingSection: some View {
        filterBlock("Minimum Rating") {
            HStack(spacing: 12) {
                ForEach(ratingOptions, id: \.label) { option in
                    let active = minRating == option.value
                    Button { minRating = option.value } label: {
                        VStack(spacing: 6) {
                            if option.value > 0 {
                                HStack(spacing: 3) {
                                    ForEach(0..<Int(option.value), id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 11))
                                            .foregroundColor(active ? .white : .yellow)
                                    }
                                }
                            } else {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 16))
                                    .foregroundColor(active ? .white : .placeholderMuted)
                            }
                            Text(option.label)
                                .font(.custom("Poppins-SemiBold", size: 13))
                                .foregroundColor(active ? .white : .textPrimary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(active ? Color.primaryBrand : Color.surfaceCard)
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .stroke(active ? Color.primaryBrand : Color.borderLine, lineWidth: 1))
                        .cornerRadius(14)
                    }
                }
            }
        }
    }

    // MARK: - Helper

    private func filterBlock<Content: View>(_ title: String,
                                            @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.custom("Poppins-Bold", size: 17))
                .foregroundColor(.textPrimary)
            content()
        }
    }
}
