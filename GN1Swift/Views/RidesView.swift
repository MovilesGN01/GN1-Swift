import SwiftUI

// MARK: - Mode

private enum RideMode: String, CaseIterable {
    case passenger = "Passenger"
    case driver = "Driver"
}

// MARK: - View

struct RidesView: View {
    @Binding var selectedTab: Int

    // Mode state — only meaningful when role == "both"
    @State private var mode: RideMode = .passenger

    // Sheets / navigation
    @State private var showCreateRide = false
    @State private var showRecommendations = false
    @State private var rideInProgress: Ride?
    @State private var navigateToRideInProgress = false
    @State private var selectedRide: Ride?
    @State private var navigateToRequests = false
    @State private var showReserveAlert = false
    @State private var showDuplicateAlert = false
    @State private var reservedDriverName = ""

    // ViewModels
    @StateObject private var passengerVM = PassengerRidesViewModel()
    @StateObject private var myRequestsVM = MyRequestsViewModel()
    @StateObject private var driverVM = DriverRidesViewModel()

    // Rating filter options for passenger mode
    private let ratingFilters: [(label: String, value: Double)] = [
        ("All Ratings", 0.0), ("4.0+", 4.0), ("4.5+", 4.5)
    ]

    private var role: String { UserSession.shared.role ?? "passenger" }

    /// Resolves the active mode taking user role into account.
    private var effectiveMode: RideMode {
        switch role {
        case "driver":    return .driver
        case "passenger": return .passenger
        default:          return mode  // "both" → respect the picker
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ridesAppBar

                // Show segmented control only for users that can act as both roles.
                if role == "both" {
                    modePicker
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if effectiveMode == .passenger {
                            passengerContent
                        } else {
                            driverContent
                        }
                    }
                }
                .background(Color.backgroundApp)
            }
            .background(Color.backgroundApp)
            // Reserve quick-action alert (passenger ride cards)
            .alert("Ride Reserved", isPresented: $showReserveAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Request sent to \(reservedDriverName)!")
            }
            .alert("Already Requested", isPresented: $showDuplicateAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You already requested this ride.")
            }
            // Sheets
            .sheet(isPresented: $showCreateRide) { CreateRideView() }
            .sheet(isPresented: $showRecommendations) { RecommendationsView() }
            // Navigation destinations
            .navigationDestination(isPresented: $navigateToRideInProgress) {
                if let ride = rideInProgress {
                    RideInProgressView(ride: ride) { selectedTab = 0 }
                }
            }
            .navigationDestination(isPresented: $navigateToRequests) {
                if let ride = selectedRide { DriverRequestsView(rideId: ride.id) }
            }
            .onAppear { loadForRole() }
        }
    }

    // MARK: - App Bar

    private var ridesAppBar: some View {
        HStack(spacing: 12) {
            Button { selectedTab = 0 } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .frame(width: 32, height: 32)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(effectiveMode == .passenger ? "Available Rides" : "My Rides")
                    .font(.custom("Poppins-SemiBold", size: 18))
                    .foregroundColor(.textPrimary)
                Text(effectiveMode == .passenger
                     ? "Zone: \(passengerVM.selectedZone)"
                     : "Driver dashboard")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
            }

            Spacer()

            // Recommendations shortcut — passenger only
            if effectiveMode == .passenger {
                Button { showRecommendations = true } label: {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryBrand)
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 10)
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("Mode", selection: $mode) {
            ForEach(RideMode.allCases, id: \.self) { m in
                Text(m.rawValue).tag(m)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: - Passenger Content

    @ViewBuilder
    private var passengerContent: some View {
        // --- Filter card ---
        filterCard
            .padding(.horizontal, 16)
            .padding(.top, 8)

        ratingChipsRow
            .padding(.top, 12)

        // --- Available Rides ---
        sectionLabel("ALL AVAILABLE RIDES", color: .placeholderMuted)

        VStack(spacing: 8) {
            if passengerVM.isLoading {
                ProgressView("Loading rides…").padding()
            } else if passengerVM.filteredRides.isEmpty {
                Text("No rides match your filters")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.placeholderMuted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
            }
            ForEach(passengerVM.filteredRides) { ride in
                NavigationLink(destination: RideDetailView(ride: ride)) {
                    rideCard(ride: ride)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)

        // --- Recommended ---
        if !passengerVM.recommendedRides.isEmpty {
            sectionLabel("RECOMMENDED FOR YOU", color: .primaryBrand)

            VStack(spacing: 8) {
                ForEach(passengerVM.recommendedRides) { ride in
                    NavigationLink(destination: RideDetailView(ride: ride)) {
                        rideCard(ride: ride, highlighted: true)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }

        // --- My Requests ---
        MyRequestsSectionView(viewModel: myRequestsVM)
    }

    // MARK: - Driver Content

    @ViewBuilder
    private var driverContent: some View {
        // --- Create Ride CTA ---
        Button { showCreateRide = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Create New Ride")
                    .font(.custom("Poppins-SemiBold", size: 15))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.primaryBrand)
            .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 4)

        // --- My Created Rides ---
        DriverRidesSectionView(
            rides: driverVM.myRides,
            isLoading: driverVM.isLoadingRides,
            onTap: { ride in
                selectedRide = ride
                navigateToRequests = true
            },
            onStartRide: { ride in
                rideInProgress = ride
                navigateToRideInProgress = true
            }
        )

        // --- Passenger Requests ---
        DriverRequestsSectionView(viewModel: driverVM)
    }

    // MARK: - Filter Card (Passenger)

    private var filterCard: some View {
        VStack(spacing: 12) {
            Menu {
                ForEach(passengerVM.zones, id: \.self) { zone in
                    Button(zone) { passengerVM.selectedZone = zone }
                }
            } label: {
                HStack {
                    Text("Zone:")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.placeholderMuted)
                    Text(passengerVM.selectedZone)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.placeholderMuted)
                }
                .padding()
                .background(Color.surfaceCard)
                .cornerRadius(10)
            }

            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2")
                        .foregroundColor(.placeholderMuted)
                        .font(.system(size: 13))
                    Text("Min seats:")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.placeholderMuted)
                    Text("\(passengerVM.minSeats)")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                        .frame(minWidth: 16)
                    Stepper("", value: $passengerVM.minSeats, in: 1...8)
                        .labelsHidden()
                }
                Spacer()
                Button { passengerVM.applyFilters() } label: {
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
        .cornerRadius(12)
    }

    // MARK: - Rating Chips

    private var ratingChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ratingFilters, id: \.label) { filter in
                    let isActive = passengerVM.minRating == filter.value
                    Button { passengerVM.minRating = filter.value } label: {
                        Text(filter.label)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(isActive ? .white : .textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isActive ? Color.primaryBrand : Color.backgroundApp)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(isActive ? Color.primaryBrand : Color.borderLine, lineWidth: 1)
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

    // MARK: - Ride Card (Passenger marketplace)

    private func rideCard(ride: Ride, highlighted: Bool = false) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(ride.origin) → \(ride.destination)")
                        .font(.custom("Poppins-SemiBold", size: 15))
                        .foregroundColor(.textPrimary)
                    Text("Driver: \(ride.driverName)")
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow).font(.system(size: 11))
                        Text(String(format: "%.1f", ride.driverRating))
                            .font(.custom("Poppins-Regular", size: 12))
                            .foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(ride.seatsAvailable) seats")
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                    Text(ride.zone)
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.placeholderMuted)
                }
            }

            // Quick-reserve button (alternative to opening RideDetailView)
            let alreadyRequested = myRequestsVM.hasRequested(rideId: ride.id)
            Button {
                CloudFunctionsService.shared.requestRide(rideId: ride.id) { result in
                    switch result {
                    case .success:
                        reservedDriverName = ride.driverName
                        showReserveAlert = true
                    case .alreadyRequested:
                        showDuplicateAlert = true
                    case .failure:
                        break
                    }
                }
            } label: {
                Text(alreadyRequested ? "Request already sent" : "Reserve")
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(alreadyRequested ? Color.placeholderMuted : Color.primaryBrand)
                    .cornerRadius(10)
            }
            .disabled(alreadyRequested)
        }
        .padding(16)
        .background(highlighted ? Color.primaryBrand.opacity(0.04) : Color.backgroundApp)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(highlighted ? Color.primaryBrand.opacity(0.2) : Color.borderLine, lineWidth: 1)
        )
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.custom("Poppins-SemiBold", size: 11))
            .tracking(0.8)
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 6)
    }

    /// Start only the listeners relevant to the signed-in user's role.
    private func loadForRole() {
        if role != "driver" {           // passenger or both
            passengerVM.loadRides()
            myRequestsVM.startListening()
        }
        if role != "passenger" {        // driver or both
            driverVM.startListening()
        }
    }
}
