import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var manager = CLLocationManager()
    @Published var currentLocation: CLLocation?
    @Published var distanceToClassroom: Double = 0.0
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 51.533222, longitude: -0.4785),
        span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
    )

    let classroomLocation = CLLocation(latitude: 51.533222, longitude: -0.4785)
    let allowedDistance: CLLocationDistance = 200

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last else { return }
        currentLocation = latest
        distanceToClassroom = latest.distance(from: classroomLocation)
        region.center = latest.coordinate
        print("📍 Location updated: \(latest.coordinate)")
        print("📏 Distance to classroom: \(distanceToClassroom) meters")
    }

    func isInsideClassroom() -> Bool {
        return distanceToClassroom <= allowedDistance
    }
}
