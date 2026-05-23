import SwiftUI
import MapKit

struct CreateRideView: View {
    @StateObject private var viewModel: CreateRideViewModel
    @StateObject private var originSearch = LocationSearchService()
    @StateObject private var destinationSearch = LocationSearchService()
    @StateObject private var favoritesVM = FavoritesViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToRequests = false
    private enum Field { case origin, destination }
    @FocusState private var focusedField: Field?

    init(facade: AppFacadeType = AppFacade.shared) {
        _viewModel = StateObject(wrappedValue: CreateRideViewModel(facade: facade))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    header
                    favoritesSection
                    formFields
                }
                .padding(.vertical, 24)
            }
            .onAppear { favoritesVM.load() }
            .background(Color.backgroundApp)
            .navigationBarHidden(true)
            .alert("Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Saved Offline", isPresented: $viewModel.rideSavedOffline) {
                Button("OK") { dismiss() }
            } message: {
                Text("You're offline. Your ride has been saved and will sync automatically when connectivity is restored.")
            }
            .navigationDestination(isPresented: $navigateToRequests) {
                if let rideId = viewModel.createdRideId {
                    DriverRequestsView(rideId: rideId)
                }
            }
            .onChange(of: viewModel.createdRideId) { _, rideId in
                if rideId != nil { navigateToRequests = true }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(width: 32, height: 32)
                }
                Spacer()
            }
            .padding(.horizontal, 24)

            VStack(spacing: 4) {
                Text("Create a Ride")
                    .font(.custom("Poppins-Bold", size: 28))
                    .foregroundColor(.textPrimary)
                Text("Share your route with the university community")
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Form

    private var formFields: some View {
        VStack(spacing: 16) {

            // Origin
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "location.fill")
                        .foregroundColor(.primaryBrand)
                    TextField("Origin (e.g. Chapinero)", text: $viewModel.originText)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textPrimary)
                        .focused($focusedField, equals: .origin)
                        .onChange(of: viewModel.originText) { _, query in
                            originSearch.search(query: query)
                        }
                }
                .inputStyle()

                if focusedField == .origin && !originSearch.suggestions.isEmpty {
                    suggestionsList(suggestions: originSearch.suggestions) { suggestion in
                        originSearch.resolveCoordinate(for: suggestion) { coordinate, name in
                            DispatchQueue.main.async {
                                if let coordinate, let name {
                                    viewModel.setOrigin(name: name, coordinate: coordinate)
                                }
                                originSearch.suggestions = []
                                focusedField = nil
                            }
                        }
                    }
                }
            }

            // Destination
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Image(systemName: "flag.fill")
                        .foregroundColor(.green)
                    TextField("Destination (e.g. Campus Norte)", text: $viewModel.destinationText)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textPrimary)
                        .focused($focusedField, equals: .destination)
                        .onChange(of: viewModel.destinationText) { _, query in
                            destinationSearch.search(query: query)
                        }
                }
                .inputStyle()

                if focusedField == .destination && !destinationSearch.suggestions.isEmpty {
                    suggestionsList(suggestions: destinationSearch.suggestions) { suggestion in
                        destinationSearch.resolveCoordinate(for: suggestion) { coordinate, name in
                            DispatchQueue.main.async {
                                if let coordinate, let name {
                                    viewModel.setDestination(name: name, coordinate: coordinate)
                                }
                                destinationSearch.suggestions = []
                                focusedField = nil
                            }
                        }
                    }
                }
            }

            // Zone
            HStack(spacing: 12) {
                Image(systemName: "map")
                    .foregroundColor(.placeholderMuted)
                TextField("Zone (e.g. Norte, Sur, Centro)", text: $viewModel.zone)
                    .font(.custom("Poppins-Regular", size: 14))
                    .foregroundColor(.textPrimary)
                    .onChange(of: viewModel.zone) { _, newValue in
                        if newValue.count > 30 { viewModel.zone = String(newValue.prefix(30)) }
                    }
            }
            .inputStyle()

            // Save as Favorite
            Button {
                favoritesVM.save(origin: viewModel.originText,
                                 destination: viewModel.destinationText,
                                 zone: viewModel.zone)
            } label: {
                Label("Save as Favorite", systemImage: "star")
                    .font(.custom("Poppins-Medium", size: 13))
                    .foregroundColor(viewModel.originText.isEmpty || viewModel.destinationText.isEmpty
                                     ? .placeholderMuted : .primaryBrand)
            }
            .disabled(viewModel.originText.isEmpty || viewModel.destinationText.isEmpty)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, -4)

            // Departure time
            VStack(alignment: .leading, spacing: 6) {
                Text("Departure Time")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)

                DatePicker("",
                           selection: $viewModel.departureTime,
                           in: Date()...,
                           displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 52)
                    .background(Color.surfaceCard)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
                    .cornerRadius(12)
            }

            // Seats
            VStack(alignment: .leading, spacing: 6) {
                Text("Available Seats")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)

                HStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .foregroundColor(.placeholderMuted)
                    Stepper("\(viewModel.seatsAvailable) seats",
                            value: $viewModel.seatsAvailable, in: 1...8)
                        .font(.custom("Poppins-Regular", size: 14))
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
                .cornerRadius(12)
            }

            // Price
            VStack(alignment: .leading, spacing: 6) {
                Text("Price per seat (COP)")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)

                HStack(spacing: 12) {
                    Image(systemName: "dollarsign.circle")
                        .foregroundColor(.placeholderMuted)
                    TextField("e.g. 5000", text: $viewModel.priceText)
                        .font(.custom("Poppins-Regular", size: 14))
                        .foregroundColor(.textPrimary)
                        .keyboardType(.decimalPad)
                }
                .padding(.horizontal, 12)
                .frame(height: 52)
                .background(Color.surfaceCard)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(
                    viewModel.priceText.isEmpty || viewModel.parsedPrice != nil
                        ? Color.borderLine : Color.red,
                    lineWidth: 1))
                .cornerRadius(12)

                if !viewModel.priceText.isEmpty && viewModel.parsedPrice == nil {
                    Text("Enter a valid positive number.")
                        .font(.custom("Poppins-Regular", size: 12))
                        .foregroundColor(.red)
                        .padding(.leading, 4)
                }
            }

            // Create button
            Button { viewModel.createRide() } label: {
                ZStack {
                    if viewModel.isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Text("Create Ride")
                            .font(.custom("Poppins-SemiBold", size: 16))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(viewModel.isValid ? Color.primaryBrand : Color.primaryBrand.opacity(0.4))
                .cornerRadius(12)
            }
            .disabled(!viewModel.isValid || viewModel.isLoading)
            .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Saved Favorites

    @ViewBuilder
    private var favoritesSection: some View {
        if !favoritesVM.favorites.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Saved Routes")
                    .font(.custom("Poppins-SemiBold", size: 13))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(favoritesVM.favorites) { fav in
                            favoriteChip(fav)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
            .padding(.bottom, 16)
        }
    }

    private func favoriteChip(_ fav: FavoriteRoute) -> some View {
        HStack(spacing: 6) {
            Button {
                favoritesVM.apply(fav, to: viewModel)
            } label: {
                VStack(alignment: .leading, spacing: 1) {
                    Text(fav.origin)
                        .font(.custom("Poppins-SemiBold", size: 11))
                        .foregroundColor(.textPrimary)
                        .lineLimit(1)
                    Text("→ \(fav.destination)")
                        .font(.custom("Poppins-Regular", size: 10))
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            Button {
                favoritesVM.delete(id: fav.id)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primaryBrand.opacity(0.3), lineWidth: 1))
        .cornerRadius(10)
    }

    // MARK: - Suggestions List

    private func suggestionsList(
        suggestions: [MKLocalSearchCompletion],
        onSelect: @escaping (MKLocalSearchCompletion) -> Void
    ) -> some View {
        VStack(spacing: 0) {
            ForEach(suggestions, id: \.self) { suggestion in
                Button {
                    onSelect(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(.custom("Poppins-SemiBold", size: 13))
                            .foregroundColor(.textPrimary)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(.custom("Poppins-Regular", size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                if suggestion != suggestions.last {
                    Divider().padding(.leading, 14)
                }
            }
        }
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(12)
        .padding(.top, 4)
    }
}
