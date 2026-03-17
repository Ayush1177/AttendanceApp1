import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    var location: CLLocation?

    @State private var cameraPosition = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.5332, longitude: -0.4785),
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        )
    )

    var body: some View {
        Map(position: $cameraPosition) {
            if let loc = location {
                Marker("📍 You", coordinate: loc.coordinate)
            }
            // Add classroom marker if needed
            Marker("🏫 Classroom", coordinate: CLLocationCoordinate2D(latitude: 51.5332, longitude: -0.4785))
        }
        .frame(height: 120)
        .cornerRadius(12)
        .padding(.horizontal)
        .onAppear {
            if let loc = location {
                cameraPosition = .region(
                    MKCoordinateRegion(
                        center: loc.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                )
            }
        }
    }
}
