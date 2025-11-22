import SwiftUI
import MapKit

struct GPSMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion
    @State private var routeOverlay: MKPolyline?

    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates

        // Calculate initial region
        if let first = coordinates.first {
            _region = State(initialValue: MKCoordinateRegion(
                center: first,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                Circle()
                    .fill(annotation.isStart ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
            }
        }
        .overlay(
            MapOverlay(coordinates: coordinates)
        )
        .onAppear {
            updateRegionToFitRoute()
        }
        .onChange(of: coordinates) { _, _ in
            updateRegionToFitRoute()
        }
    }

    private var mapAnnotations: [MapAnnotation] {
        var annotations: [MapAnnotation] = []
        if let first = coordinates.first {
            annotations.append(MapAnnotation(coordinate: first, isStart: true))
        }
        if coordinates.count > 1, let last = coordinates.last {
            annotations.append(MapAnnotation(coordinate: last, isStart: false))
        }
        return annotations
    }

    private func updateRegionToFitRoute() {
        guard !coordinates.isEmpty else { return }

        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        guard let minLat = latitudes.min(),
              let maxLat = latitudes.max(),
              let minLon = longitudes.min(),
              let maxLon = longitudes.max() else { return }

        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )

        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.3,
            longitudeDelta: (maxLon - minLon) * 1.3
        )

        region = MKCoordinateRegion(center: center, span: span)
    }
}

struct MapAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let isStart: Bool
}

struct MapOverlay: UIViewRepresentable {
    let coordinates: [CLLocationCoordinate2D]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.isUserInteractionEnabled = false
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)

        if coordinates.count > 1 {
            let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
            mapView.addOverlay(polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemCyan
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// Live tracking map for recording view
struct LiveGPSMapView: View {
    let coordinates: [CLLocationCoordinate2D]
    @State private var region: MKCoordinateRegion

    init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates

        if let last = coordinates.last {
            _region = State(initialValue: MKCoordinateRegion(
                center: last,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
        }
    }

    var body: some View {
        Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: currentLocationAnnotation) { annotation in
            MapAnnotation(coordinate: annotation.coordinate) {
                ZStack {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 20, height: 20)
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .overlay(
            MapOverlay(coordinates: coordinates)
        )
        .onChange(of: coordinates) { _, newCoordinates in
            if let last = newCoordinates.last {
                withAnimation {
                    region.center = last
                }
            }
        }
    }

    private var currentLocationAnnotation: [MapAnnotation] {
        if let last = coordinates.last {
            return [MapAnnotation(coordinate: last, isStart: false)]
        }
        return []
    }
}
