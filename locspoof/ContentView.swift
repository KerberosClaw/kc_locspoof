import SwiftUI
import MapKit
import AppKit

struct ContentView: View {
    @EnvironmentObject var status: StatusModel

    var body: some View {
        VStack(spacing: 0) {
            MapClickView(
                spoofed: status.snapshot.lastLoc,
                onTap: { coord in
                    Task {
                        await status.inject(lat: coord.latitude, lon: coord.longitude)
                    }
                }
            )
            statusBar
        }
    }

    private var statusBar: some View {
        HStack(spacing: 12) {
            Image(systemName: status.iconSystemName)
                .foregroundStyle(status.iconColor)
            Text(status.coordinateText ?? status.headline)
                .font(.system(.body, design: .monospaced))
            Spacer()
            Text("點地圖任意處注入")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("停止注入") {
                Task { await status.stopSpoof() }
            }
            .disabled(!status.isSpoofing)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.regularMaterial)
    }
}

struct MapClickView: NSViewRepresentable {
    let spoofed: Coordinate?
    let onTap: (CLLocationCoordinate2D) -> Void

    func makeNSView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 24.1477, longitude: 120.6736),
            span: MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        )
        let click = NSClickGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleClick(_:))
        )
        click.numberOfClicksRequired = 1
        click.delaysPrimaryMouseButtonEvents = false
        map.addGestureRecognizer(click)
        context.coordinator.map = map
        return map
    }

    func updateNSView(_ map: MKMapView, context: Context) {
        context.coordinator.onTap = onTap
        map.removeAnnotations(map.annotations)
        if let c = spoofed {
            let pin = MKPointAnnotation()
            pin.coordinate = CLLocationCoordinate2D(latitude: c.lat, longitude: c.lon)
            pin.title = "注入位置"
            map.addAnnotation(pin)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onTap: onTap)
    }

    final class Coordinator: NSObject {
        weak var map: MKMapView?
        var onTap: (CLLocationCoordinate2D) -> Void

        init(onTap: @escaping (CLLocationCoordinate2D) -> Void) {
            self.onTap = onTap
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let map = map else { return }
            let point = gesture.location(in: map)
            let coord = map.convert(point, toCoordinateFrom: map)
            onTap(coord)
        }
    }
}
