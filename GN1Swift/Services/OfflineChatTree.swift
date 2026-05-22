import Foundation

// MARK: - Node kind

enum OfflineNodeKind {
    /// Static response string defined at compile time.
    case staticText(String)
    /// Response generated at runtime from the user's cached data.
    case dynamic(DynamicResponse)
}

enum DynamicResponse {
    case availableRides
    case myRequests
    case myHistory
    case dataSummary
}

// MARK: - Node model

struct OfflineNode: Identifiable {
    let id: String
    let label: String
    let kind: OfflineNodeKind
    let children: [OfflineNode]

    var isLeaf: Bool { children.isEmpty }

    /// Returns the bot response string, injecting real data when needed.
    func response(context: OfflineDataContext?) -> String {
        switch kind {
        case .staticText(let text):
            return text
        case .dynamic(let type):
            guard let ctx = context else {
                return "Loading your local data… please try again in a moment."
            }
            switch type {
            case .availableRides: return ctx.ridesResponse()
            case .myRequests:     return ctx.requestsResponse()
            case .myHistory:      return ctx.historyResponse()
            case .dataSummary:    return ctx.summaryResponse()
            }
        }
    }

    // Convenience init for static nodes
    init(id: String, label: String, response: String, children: [OfflineNode] = []) {
        self.id = id
        self.label = label
        self.kind = .staticText(response)
        self.children = children
    }

    // Convenience init for dynamic nodes (always leaves)
    init(id: String, label: String, dynamic: DynamicResponse) {
        self.id = id
        self.label = label
        self.kind = .dynamic(dynamic)
        self.children = []
    }
}

// MARK: - Tree

enum OfflineChatTree {
    static let root = OfflineNode(
        id: "root",
        label: "root",
        response: "I'm offline. Here are some things I can help you with:",
        children: [myData, rides, driving, account, safety]
    )
}

// MARK: - My Data branch (dynamic — uses CoreData)

private let myData = OfflineNode(
    id: "mydata",
    label: "📋  My Data",
    response: "Here's what I can show you from your local storage:",
    children: [
        OfflineNode(
            id: "mydata.summary",
            label: "Quick summary",
            dynamic: .dataSummary
        ),
        OfflineNode(
            id: "mydata.rides",
            label: "Available rides nearby",
            dynamic: .availableRides
        ),
        OfflineNode(
            id: "mydata.requests",
            label: "My active requests",
            dynamic: .myRequests
        ),
        OfflineNode(
            id: "mydata.history",
            label: "My ride history",
            dynamic: .myHistory
        ),
    ]
)

// MARK: - Rides branch (static help)

private let rides = OfflineNode(
    id: "rides",
    label: "🚗  How Rides Work",
    response: "What would you like to know about rides?",
    children: [
        OfflineNode(
            id: "rides.reserve",
            label: "Reserving a ride",
            response: "What do you need to know about booking?",
            children: [
                OfflineNode(
                    id: "rides.reserve.how",
                    label: "How do I find a ride?",
                    response: "Open the Rides tab and browse the marketplace. " +
                        "Tap a card to see details or press Reserve directly. " +
                        "Filter by zone, rating, or available seats to narrow results."
                ),
                OfflineNode(
                    id: "rides.reserve.norides",
                    label: "No rides showing?",
                    response: "Try removing zone or rating filters. " +
                        "You can also check the sparkles Recommended section — " +
                        "it shows rides matched to your usual route. " +
                        "If you're offline, the app shows the last cached rides."
                ),
                OfflineNode(
                    id: "rides.reserve.cancel",
                    label: "Can I cancel a request?",
                    response: "Cancellations are handled by the driver. " +
                        "Contact the driver directly if you need to cancel. " +
                        "Your request status appears in My Ride Requests at the bottom of the Rides tab."
                ),
            ]
        ),
        OfflineNode(
            id: "rides.status",
            label: "Request status explained",
            response: "Which status do you have a question about?",
            children: [
                OfflineNode(
                    id: "rides.status.pending",
                    label: "What is Pending?",
                    response: "Pending means the driver received your request but hasn't responded yet. " +
                        "The status updates in real time once you're back online."
                ),
                OfflineNode(
                    id: "rides.status.accepted",
                    label: "My request was accepted",
                    response: "The driver confirmed your seat. " +
                        "Be at the pickup point before the departure time shown on the ride card."
                ),
                OfflineNode(
                    id: "rides.status.rejected",
                    label: "My request was rejected",
                    response: "You're free to request another ride immediately. " +
                        "A rejection doesn't block you from reserving again — try a different zone or time."
                ),
            ]
        ),
        OfflineNode(
            id: "rides.pricing",
            label: "Pricing and seats",
            response: "What do you want to know?",
            children: [
                OfflineNode(
                    id: "rides.pricing.set",
                    label: "How is the price set?",
                    response: "Drivers set the price when they create the ride. " +
                        "It usually covers fuel costs split among passengers. " +
                        "You can see the price on every ride card before requesting."
                ),
                OfflineNode(
                    id: "rides.pricing.seats",
                    label: "How many seats can I book?",
                    response: "Each passenger books one seat per request. " +
                        "The card shows how many seats remain. " +
                        "Once the ride is full the Reserve button is disabled."
                ),
            ]
        ),
    ]
)

// MARK: - Driving branch

private let driving = OfflineNode(
    id: "driving",
    label: "🧑‍✈️  Driving",
    response: "What would you like to know about offering rides?",
    children: [
        OfflineNode(
            id: "driving.create",
            label: "Creating a ride",
            response: "What do you need help with?",
            children: [
                OfflineNode(
                    id: "driving.create.how",
                    label: "How do I post a ride?",
                    response: "Switch to Driver mode in the Rides tab, then tap Create New Ride. " +
                        "Fill in origin, destination, zone, departure time, seats, and price. " +
                        "Tap Create and your ride goes live immediately."
                ),
                OfflineNode(
                    id: "driving.create.offline",
                    label: "Can I create a ride offline?",
                    response: "Yes. If you're offline when you tap Create, the ride is saved locally " +
                        "and uploaded automatically once your connection is restored. " +
                        "You'll see it in your list while it waits to sync."
                ),
            ]
        ),
        OfflineNode(
            id: "driving.passengers",
            label: "Managing passengers",
            response: "What do you need help with?",
            children: [
                OfflineNode(
                    id: "driving.passengers.accept",
                    label: "How to accept or reject?",
                    response: "Tap your ride in the Driver section to see pending requests. " +
                        "Each card has Accept and Reject buttons. " +
                        "You can only process one at a time to avoid conflicts."
                ),
                OfflineNode(
                    id: "driving.passengers.full",
                    label: "Ride is full",
                    response: "Once seats reach zero, no new requests come in automatically. " +
                        "You can reject any excess requests without affecting your rating."
                ),
            ]
        ),
        OfflineNode(
            id: "driving.finish",
            label: "Finishing a ride",
            response: "What do you want to know?",
            children: [
                OfflineNode(
                    id: "driving.finish.how",
                    label: "How to mark a ride complete?",
                    response: "From the Ride In Progress screen tap Finish Ride once everyone arrives. " +
                        "This closes the ride, moves it to history, and triggers ratings for passengers."
                ),
                OfflineNode(
                    id: "driving.finish.ratings",
                    label: "How do ratings work?",
                    response: "After completion, passengers rate you. " +
                        "Your rating is the average of all reviews. " +
                        "Higher ratings push your rides to the top of the marketplace."
                ),
            ]
        ),
    ]
)

// MARK: - Account branch

private let account = OfflineNode(
    id: "account",
    label: "👤  Account",
    response: "What would you like to know?",
    children: [
        OfflineNode(
            id: "account.roles",
            label: "Roles explained",
            response: "What are the roles?",
            children: [
                OfflineNode(
                    id: "account.roles.passenger",
                    label: "Passenger",
                    response: "Can browse the marketplace and request rides. " +
                        "Sees recommended rides based on their travel history."
                ),
                OfflineNode(
                    id: "account.roles.driver",
                    label: "Driver",
                    response: "Can create rides, set the price and seats, " +
                        "and accept or reject passenger requests."
                ),
                OfflineNode(
                    id: "account.roles.both",
                    label: "Both",
                    response: "Full access to passenger and driver features from the same account. " +
                        "Switch between modes using the toggle at the top of the Rides tab."
                ),
            ]
        ),
        OfflineNode(
            id: "account.session",
            label: "Login and session",
            response: "What is the issue?",
            children: [
                OfflineNode(
                    id: "account.session.loggedout",
                    label: "Why was I logged out?",
                    response: "This can happen if your session expired or you logged out manually. " +
                        "UniRide keeps you logged in between restarts — " +
                        "if it happened unexpectedly try logging in again."
                ),
                OfflineNode(
                    id: "account.session.stay",
                    label: "Does the app remember me?",
                    response: "Yes. UniRide saves your session locally so you stay logged in " +
                        "even after closing the app, and restores your profile automatically on relaunch."
                ),
            ]
        ),
    ]
)

// MARK: - Safety branch

private let safety = OfflineNode(
    id: "safety",
    label: "🛡️  Safety",
    response: "What safety topic can I help with?",
    children: [
        OfflineNode(
            id: "safety.drivers",
            label: "Driver trust",
            response: "How do we verify drivers?",
            children: [
                OfflineNode(
                    id: "safety.drivers.nfc",
                    label: "NFC verification",
                    response: "UniRide uses NFC tag verification to confirm a driver's identity " +
                        "before a ride starts. Drivers register once; passengers tap to verify at pickup."
                ),
                OfflineNode(
                    id: "safety.drivers.ratings",
                    label: "Community ratings",
                    response: "Every driver has a rating from passenger reviews visible on each ride card. " +
                        "We recommend choosing drivers rated 4.0 or above."
                ),
                OfflineNode(
                    id: "safety.drivers.report",
                    label: "Report an issue",
                    response: "Go to the Community tab to report a concern. " +
                        "For urgent safety issues contact your university's security office directly."
                ),
            ]
        ),
        OfflineNode(
            id: "safety.privacy",
            label: "Privacy and data",
            response: "What would you like to know?",
            children: [
                OfflineNode(
                    id: "safety.privacy.stored",
                    label: "What data is stored?",
                    response: "UniRide stores your name, university email, role, and ride history in Firestore. " +
                        "Location is only used for map features and is not stored permanently. " +
                        "No payment data is stored on our servers."
                ),
                OfflineNode(
                    id: "safety.privacy.local",
                    label: "What's stored on my phone?",
                    response: "The app caches your recent rides, requests, and ride history locally " +
                        "so the app works offline. This data is stored in a private app database " +
                        "and is removed when you uninstall the app."
                ),
            ]
        ),
    ]
)
