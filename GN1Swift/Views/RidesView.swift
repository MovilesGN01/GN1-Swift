//
//  RidesView.swift
//  GN1Swift
//
//  Created by Cami Sánchez on 6/03/26.
//

import SwiftUI

struct RidesView: View {
    @Binding var selectedTab: Int

    @State private var selectedDeparture = "Now"
    @State private var activeFilter = "High Reliability"
    @State private var showReserveAlert = false
    @State private var reservedDriverName = ""

    private let departureOptions = ["Now", "7:00 AM", "7:30 AM", "8:00 AM", "8:30 AM"]
    private let filters = ["High Reliability", "Female Driver", "4.5+ Rating"]

    private let rides: [RideItem] = [
        RideItem(
            name: "Maria G.",
            initial: "M",
            rating: 4.8,
            from: "Chapinero",
            to: "Campus",
            time: "7:20 AM",
            eta: "18 min",
            price: "$12.000",
            seats: 2,
            badge: "HIGH RELIABILITY"
        ),
        RideItem(
            name: "Andres R.",
            initial: "A",
            rating: 4.6,
            from: "Teusaquillo",
            to: "Campus",
            time: "7:35 AM",
            eta: "25 min",
            price: "$10.000",
            seats: 1,
            badge: nil
        ),
        RideItem(
            name: "Camila P.",
            initial: "C",
            rating: 4.9,
            from: "Salitre",
            to: "Campus",
            time: "7:50 AM",
            eta: "30 min",
            price: "$14.000",
            seats: 3,
            badge: "FEMALE DRIVER"
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            ridesAppBar

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    searchSummaryCard
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    filterChipsRow
                        .padding(.top, 12)

                    Text("RECOMMENDED RIDES")
                        .font(.custom("Poppins-SemiBold", size: 11))
                        .tracking(0.8)
                        .foregroundColor(.placeholderMuted)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 6)

                    VStack(spacing: 8) {
                        ForEach(rides) { ride in
                            rideCard(ride: ride)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
            }
            .background(Color.backgroundApp)
        }
        .background(Color.backgroundApp)
        .alert("Ride Reserved", isPresented: $showReserveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Ride reserved with \(reservedDriverName)!")
        }
    }

    private var ridesAppBar: some View {
        HStack(spacing: 12) {
            Button {
                selectedTab = 0
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Available Rides")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.textPrimary)

                Text("Chapinero -> Campus")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            Button {
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    private var searchSummaryCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                fromToBlock(label: "FROM", value: "Chapinero", icon: nil)

                Rectangle()
                    .fill(Color.borderLine)
                    .frame(width: 1)

                fromToBlock(label: "TO", value: "Campus", icon: "location.fill")
            }
            .frame(height: 52)

            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.placeholderMuted)
                    .font(.system(size: 14))

                Text("Departure:")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)

                Menu {
                    ForEach(departureOptions, id: \.self) { option in
                        Button(option) {
                            selectedDeparture = option
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedDeparture)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.textPrimary)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.placeholderMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                } label: {
                    Text("Search")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.white)
                        .frame(width: 80, height: 36)
                        .background(Color.primaryBrand)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(Color.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderLine, lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func fromToBlock(label: String, value: String, icon: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.custom("Poppins-Regular", size: 10))
                .foregroundColor(.placeholderMuted)

            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(.primaryBrand)
                } else {
                    Circle()
                        .fill(Color.primaryBrand)
                        .frame(width: 8, height: 8)
                }

                Text(value)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var filterChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { label in
                    Button {
                        activeFilter = label
                    } label: {
                        Text(label)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(label == activeFilter ? .white : .textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(label == activeFilter ? Color.primaryBrand : Color.backgroundApp)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(label == activeFilter ? Color.clear : Color.borderLine, lineWidth: 1)
                            )
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
        .frame(height: 44)
    }

    private func rideCard(ride: RideItem) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.primaryBrand)
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(ride.initial)
                            .font(.custom("Poppins-Bold", size: 16))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(ride.name)
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)

                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(RidesPalette.warningAmber)

                        Text(String(format: "%.1f", ride.rating))
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                if let badge = ride.badge {
                    driverBadge(text: badge)
                }
            }

            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.primaryBrand)
                            .frame(width: 8, height: 8)

                        Text(ride.from)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.textSecondary)
                    }

                    Rectangle()
                        .fill(Color.borderLine)
                        .frame(width: 1, height: 14)
                        .padding(.leading, 3)
                        .padding(.vertical, 2)

                    HStack(spacing: 8) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.placeholderMuted)

                        Text(ride.to)
                            .font(.custom("Poppins-Regular", size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 0) {
                    Text(ride.time)
                        .font(.custom("Poppins-Bold", size: 16))
                        .foregroundColor(.primaryBrand)

                    Text("ETA \(ride.eta)")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.placeholderMuted)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ride.price)
                        .font(.custom("Poppins-Bold", size: 18))
                        .foregroundColor(.textPrimary)

                    if ride.seats == 1 {
                        Text("Only 1 seat left!")
                            .font(.custom("Poppins-SemiBold", size: 12))
                            .foregroundColor(RidesPalette.urgent)
                    } else {
                        Text("\(ride.seats) seats left")
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.placeholderMuted)
                    }
                }

                Spacer()

                Button {
                    reservedDriverName = ride.name
                    showReserveAlert = true
                } label: {
                    Text("Reserve")
                        .font(.custom("Poppins-SemiBold", size: 14))
                        .foregroundColor(.white)
                        .frame(width: 100, height: 40)
                        .background(Color.primaryBrand)
                        .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(Color.backgroundApp)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.borderLine, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .cornerRadius(16)
    }

    private func driverBadge(text: String) -> some View {
        let isReliability = text == "HIGH RELIABILITY"
        return Text(text)
            .font(.custom("Poppins-SemiBold", size: 10))
            .foregroundColor(isReliability ? RidesPalette.successText : RidesPalette.purpleText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isReliability ? RidesPalette.successLight : RidesPalette.purpleLight)
            .cornerRadius(20)
    }
}

private enum RidesPalette {
    static let urgent = Color(hex: "#FF3B30")
    static let successLight = Color(hex: "#E8F5E9")
    static let successText = Color(hex: "#2E7D32")
    static let purpleLight = Color(hex: "#F3E8FF")
    static let purpleText = Color(hex: "#6D28D9")
    static let warningAmber = Color(hex: "#F59E0B")
}

private struct RideItem: Identifiable {
    let id = UUID()
    let name: String
    let initial: String
    let rating: Double
    let from: String
    let to: String
    let time: String
    let eta: String
    let price: String
    let seats: Int
    let badge: String?
}

#Preview {
    RidesView(selectedTab: .constant(1))
    }

