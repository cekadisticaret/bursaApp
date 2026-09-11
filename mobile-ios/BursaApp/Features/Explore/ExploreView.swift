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

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in center = loc.coordinate }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

struct ExploreView: View {
    @EnvironmentObject private var auth: AuthStore
    @StateObject private var location = ExploreLocation()
    @State private var places: [PlaceItem] = []
    @State private var filter = ""
    @State private var loading = true
    @State private var path = NavigationPath()
    @State private var selectedPlace: PlaceItem?
    @State private var routePoints: [CLLocationCoordinate2D] = []
    @State private var routeLoading = false
    @State private var routeInfo: String?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 40.1885, longitude: 29.0610),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )

    private let filters: [(String, String)] = [
        ("", "Tümü"), ("food", "Restoran"), ("visit", "Gezilecek"), ("hotel", "Otel"), ("vet", "Veteriner"),
    ]

    var body: some View {
        NavigationStack(path: $path) {
            AppPage(title: "Harita") {
                VStack(spacing: 0) {
                    ExploreMapView(
                        region: $region,
                        places: filtered,
                        routePoints: routePoints,
                        selectedId: selectedPlace?.id,
                        onSelect: { place in
                            selectedPlace = place
                            Task { await drawRoute(to: place) }
                        }
                    )
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadii.md))

                    HStack {
                        if let routeInfo, !routeInfo.isEmpty {
                            Text("Rota · \(routeInfo)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(AppColors.accentDeep)
                        }
                        Spacer()
                        Button("Konumum") { location.request() }
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(AppColors.accentDeep)
                    }
                    .padding(.top, 10)

                    FilterChips(items: filters, selected: filter) { filter = $0 }
                        .padding(.vertical, 10)

                    if loading {
                        ProgressView().padding()
                    } else if filtered.isEmpty {
                        Text("Yakında mekan yok").foregroundStyle(AppColors.muted).padding()
                    } else {
                        ScrollView {
                            PlaceListSection(places: filtered)
                                .padding(.bottom, 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .refreshable {
                    location.request()
                    await load()
                }
            }
            .task {
                location.request()
                await load()
            }
            .onChange(of: location.center.latitude) { _ in
                region = MKCoordinateRegion(
                    center: location.center,
                    span: MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
                )
                Task { await load() }
            }
            .navigationDestination(for: String.self) { slug in PlaceDetailView(slug: slug) }
            .sheet(item: $selectedPlace) { place in
                exploreSheet(place)
            }
        }
    }

    private func exploreSheet(_ place: PlaceItem) -> some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text(place.title).font(.title3.bold())
                if !place.ilce.isEmpty { Text(place.ilce).foregroundStyle(AppColors.accentDeep) }
                if !place.blurb.isEmpty { Text(place.blurb).font(.subheadline).foregroundStyle(AppColors.muted) }
                HStack {
                    Button(routeLoading ? "Rota…" : "Rota çiz") {
                        Task { await drawRoute(to: place) }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.nav)
                    .disabled(routeLoading)
                    Button("Detay") { path.append(place.detailSlug); selectedPlace = nil }
                        .buttonStyle(.bordered)
                }
                Spacer()
            }
            .padding(16)
            .presentationDetents([.medium])
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Kapat") { selectedPlace = nil } } }
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

    @MainActor
    private func drawRoute(to place: PlaceItem) async {
        guard let lat = place.lat, let lng = place.lng else { return }
        routeLoading = true
        defer { routeLoading = false }
        do {
            let route = try await auth.apiClient().mapRoute(
                fromLat: location.center.latitude,
                fromLng: location.center.longitude,
                toLat: lat,
                toLng: lng
            )
            routePoints = route.points
            if let d = route.distanceM, let s = route.durationS {
                routeInfo = "\(formatDist(d)) · \(formatDur(s))"
            } else {
                routeInfo = "Haritada"
            }
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(
                    latitude: (location.center.latitude + lat) / 2,
                    longitude: (location.center.longitude + lng) / 2
                ),
                span: MKCoordinateSpan(latitudeDelta: 0.04, longitudeDelta: 0.04)
            )
        } catch {
            routePoints = [location.center, CLLocationCoordinate2D(latitude: lat, longitude: lng)]
            routeInfo = "Kuş uçuşu"
        }
    }

    private func formatDist(_ m: Double) -> String {
        m >= 1000 ? String(format: "%.1f km", m / 1000) : "\(Int(m)) m"
    }

    private func formatDur(_ s: Double) -> String {
        let mins = Int(s / 60)
        return mins >= 60 ? "\(mins / 60) sa \(mins % 60) dk" : "\(mins) dk"
    }
}

// iOS 16 uyumlu harita (MapKit UIViewRepresentable)
private struct ExploreMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let places: [PlaceItem]
    let routePoints: [CLLocationCoordinate2D]
    let selectedId: String?
    let onSelect: (PlaceItem) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSelect: onSelect)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        return map
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.onSelect = onSelect
        if !mapView.region.center.isApproximatelyEqual(to: region.center) {
            mapView.setRegion(region, animated: false)
        }

        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.removeOverlays(mapView.overlays)

        for place in places {
            guard let lat = place.lat, let lng = place.lng else { continue }
            let ann = PlaceMapAnnotation(
                place: place,
                coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lng)
            )
            mapView.addAnnotation(ann)
        }

        if routePoints.count >= 2 {
            var coords = routePoints
            let poly = MKPolyline(coordinates: &coords, count: coords.count)
            mapView.addOverlay(poly)
        }
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var onSelect: (PlaceItem) -> Void

        init(onSelect: @escaping (PlaceItem) -> Void) {
            self.onSelect = onSelect
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard annotation is PlaceMapAnnotation else { return nil }
            let id = "placePin"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.annotation = annotation
            view.markerTintColor = UIColor(red: 1, green: 0.42, blue: 0.42, alpha: 1)
            view.canShowCallout = false
            return view
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let ann = view.annotation as? PlaceMapAnnotation else { return }
            onSelect(ann.place)
            mapView.deselectAnnotation(ann, animated: false)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let poly = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }
            let renderer = MKPolylineRenderer(polyline: poly)
            renderer.strokeColor = UIColor(red: 0.42, green: 0.561, blue: 0.443, alpha: 1)
            renderer.lineWidth = 4
            return renderer
        }
    }
}

private final class PlaceMapAnnotation: NSObject, MKAnnotation {
    let place: PlaceItem
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { place.title }

    init(place: PlaceItem, coordinate: CLLocationCoordinate2D) {
        self.place = place
        self.coordinate = coordinate
    }
}

private extension CLLocationCoordinate2D {
    func isApproximatelyEqual(to other: CLLocationCoordinate2D, epsilon: Double = 0.0001) -> Bool {
        abs(latitude - other.latitude) < epsilon && abs(longitude - other.longitude) < epsilon
    }
}
