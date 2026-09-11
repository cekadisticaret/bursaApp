import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class ExploreLocation: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var center = CLLocationCoordinate2D(latitude: 40.1885, longitude: 29.0610)
    private let manager = CLLocationManager()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func request() {
        manager.requestWhenInUseAuthorization()
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        center = loc.coordinate
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

struct ExploreView: View {
    @EnvironmentObject private var auth: AuthStore
    @StateObject private var location = ExploreLocation()
    @State private var places: [PlaceItem] = []
    @State private var filter = ""
    @State private var loading = true
    @State private var path = NavigationPath()
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.1885, longitude: 29.0610),
            span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        )
    )

    private let filters: [(String, String)] = [
        ("", "Tümü"), ("food", "Restoran"), ("visit", "Gezilecek"), ("hotel", "Otel"), ("vet", "Veteriner"),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                Map(position: $camera) {
                    ForEach(filtered) { place in
                        if let lat = place.lat, let lng = place.lng {
                            Annotation(place.title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)) {
                                Button {
                                    path.append(place.detailSlug)
                                } label: {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(AppColors.coral)
                                }
                            }
                        }
                    }
                }
                .frame(height: 280)
                .clipShape(RoundedRectangle(cornerRadius: AppRadii.md))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filters, id: \.0) { key, label in
                            Button(label) { filter = key }
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(filter == key ? AppColors.nav : AppColors.card)
                                .foregroundStyle(filter == key ? AppColors.lime : AppColors.ink)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 10)
                }

                if loading {
                    ProgressView().padding()
                } else {
                    ScrollView {
                        PlaceListSection(places: filtered)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .task {
                location.request()
                await load()
            }
            .onChange(of: location.center.latitude) { _ in
                camera = .region(MKCoordinateRegion(center: location.center, span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)))
                Task { await load() }
            }
            .navigationDestination(for: String.self) { slug in PlaceDetailView(slug: slug) }
        }
    }

    private var filtered: [PlaceItem] {
        guard !filter.isEmpty else { return places }
        return places.filter { $0.category == filter }
    }

    @MainActor
    private func load() async {
        loading = true
        defer { loading = false }
        do {
            places = try await auth.apiClient().nearby(
                lat: location.center.latitude,
                lng: location.center.longitude
            )
        } catch {
            places = []
        }
    }
}
