import MapKit
import Combine

class LocationSearchService: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }

    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            return
        }
        completer.queryFragment = query
    }

    func resolveCoordinate(for completion: MKLocalSearchCompletion,
                           result: @escaping (CLLocationCoordinate2D?, String?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, _ in
            let item = response?.mapItems.first
            let displayName = [completion.title, completion.subtitle]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
            result(item?.placemark.coordinate, displayName)
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async { self.suggestions = Array(completer.results.prefix(5)) }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestions = []
    }
}
