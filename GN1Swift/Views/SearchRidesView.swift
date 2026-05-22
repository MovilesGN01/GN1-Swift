import SwiftUI

struct SearchRidesView: View {
    let rides: [Ride]
    @StateObject private var vm: SearchRidesViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    init(rides: [Ride]) {
        self.rides = rides
        _vm = StateObject(wrappedValue: SearchRidesViewModel(rides: rides))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundApp.ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar

                    if vm.isFiltering {
                        Spacer()
                        ProgressView("Searching…")
                            .font(.custom("Poppins-Regular", size: 14))
                        Spacer()
                    } else if vm.results.isEmpty {
                        emptyState
                    } else {
                        resultsList
                    }
                }
            }
            .safeAreaInset(edge: .bottom) { searchBar }
            .onAppear { isSearchFocused = true }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Text("Search Rides")
                .font(.custom("Poppins-Bold", size: 22))
                .foregroundColor(.textPrimary)
            Spacer()
            Button("Cancel") { dismiss() }
                .font(.custom("Poppins-Medium", size: 15))
                .foregroundColor(.primaryBrand)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Results list

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                Text("\(vm.results.count) ride\(vm.results.count == 1 ? "" : "s") found")
                    .font(.custom("Poppins-Regular", size: 12))
                    .foregroundColor(.placeholderMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)

                ForEach(vm.results) { ride in
                    NavigationLink(destination: RideDetailView(ride: ride)) {
                        searchResultCard(ride: ride)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Result card

    private func searchResultCard(ride: Ride) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 6) {
                Circle()
                    .fill(Color.primaryBrand)
                    .frame(width: 8, height: 8)
                    .padding(.top, 4)
                Rectangle()
                    .fill(Color.borderLine)
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .padding(.bottom, 4)
            }
            .frame(width: 8)

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ride.origin)
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.textPrimary)
                    Text(ride.destination)
                        .font(.custom("Poppins-Regular", size: 13))
                        .foregroundColor(.textSecondary)
                }

                HStack(spacing: 10) {
                    Label(ride.driverName, systemImage: "person.fill")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                    Label(ride.zone, systemImage: "mappin")
                        .font(.custom("Poppins-Regular", size: 11))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text(String(format: "$%.0f", ride.price))
                        .font(.custom("Poppins-SemiBold", size: 13))
                        .foregroundColor(.primaryBrand)
                }
            }
        }
        .padding(14)
        .background(Color.surfaceCard)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
        .cornerRadius(12)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundColor(.placeholderMuted)
            Text(vm.query.isEmpty ? "Start typing to search" : "No rides match "\(vm.query)"")
                .font(.custom("Poppins-SemiBold", size: 15))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)
            if !vm.query.isEmpty {
                Text("Try searching by origin, destination, zone or driver name.")
                    .font(.custom("Poppins-Regular", size: 13))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Search bar (pinned to bottom)

    private var searchBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.placeholderMuted)
                    .font(.system(size: 15))
                TextField("Origin, destination, zone or driver…", text: $vm.query)
                    .font(.custom("Poppins-Regular", size: 15))
                    .foregroundColor(.textPrimary)
                    .focused($isSearchFocused)
                    .autocorrectionDisabled()
                if !vm.query.isEmpty {
                    Button { vm.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.placeholderMuted)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surfaceCard)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.borderLine, lineWidth: 1))
            .cornerRadius(12)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color.backgroundApp)
    }
}
