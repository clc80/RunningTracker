//
//  ViewController.swift
//  Running
//
//  Created by Claudia Maciel on 4/21/21.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    
    //MARK: -  IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var distanceSegmentedControl: UISegmentedControl!
    @IBOutlet weak var startPauseButton: RoundButton!
    
    // MARK: - Properties
    var runningRouteAnnotation: RunningRoute?
    var metersRan: Double = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationAuthStatus()
        mapView.delegate = self
        
        setupLongPress()
    }

    //MARK: - IBActions
    @IBAction func PlayPauseButtonPressed(_ sender: Any) {
        removeOverlays()
        guard let coordinates = LocationService.instance.currentLocation else { return }
        
        if runningRouteAnnotation == nil  {
            setupAnnotation(coordinate: coordinates)
            startPauseButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        } else {
            startPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            
            
            guard let endCoordinate = LocationService.instance.currentLocation,
                  let startCoordinate = runningRouteAnnotation else { return }
            getDistanceOfRun(startCoordinate: startCoordinate.coordinate, endCoordinate: endCoordinate)
            
            runningRouteAnnotation = nil
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
    
    }
    
    @IBAction func distanceUnitChanged(_ sender: Any) {
        calculateDistanceToShow()
    }
    
}

// MARK: - Extensions

extension ViewController:  MKMapViewDelegate {
    func checkLocationAuthStatus() {
        if LocationService.instance.locationManager.authorizationStatus == .authorizedWhenInUse{
            self.mapView.showsUserLocation = true
            LocationService.instance.customUserLocDelgate = self
        } else {
            LocationService.instance.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func centerMapOnUserLocation(coordinates: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        self.mapView.setRegion(region, animated: true)
    }
    
    func setupAnnotation(coordinate: CLLocationCoordinate2D) {
        runningRouteAnnotation = RunningRoute(coordinate: coordinate)
        mapView.addAnnotation(runningRouteAnnotation!)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? RunningRoute {
            let id = "pin"
            let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.pinTintColor = .green
            view.calloutOffset = CGPoint(x: -8, y: -3)
            
            return view
        }
        return nil
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let coordinates = LocationService.instance.currentLocation,
              let runningStartLocation = runningRouteAnnotation else { return }
        getDistanceOfRun(startCoordinate: runningStartLocation.coordinate, endCoordinate: coordinates)
        view.setSelected(false, animated: true)
    }
}

extension ViewController: CustomUserLocDelegate {
    func userLocationUpdated(location: CLLocation) {
        centerMapOnUserLocation(coordinates: location.coordinate)
    }
}

extension ViewController {
    func setupLongPress() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        longPress.minimumPressDuration = 0.75
        self.mapView.addGestureRecognizer(longPress)
    }
    
    @objc func handleLongPress(gesture: UILongPressGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        
        if gesture.state == .ended {
            let point = gesture.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            setupAnnotation(coordinate: coordinate)
            
            startPauseButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        }
    }
}

extension ViewController {
    func getDistanceOfRun(startCoordinate: CLLocationCoordinate2D, endCoordinate: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: endCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: startCoordinate))
        request.transportType = .walking
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let route = response?.routes.first else { return }
            self.mapView.addOverlay(route.polyline)
            
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 200, left: 50, bottom: 50, right: 50), animated: true )
            
            for step in route.steps {
                self.metersRan = step.distance
                self.calculateDistanceToShow()
            }
        }
    }
    
    func calculateDistanceToShow() {
        var distanceRan = 0.0
        if distanceSegmentedControl.selectedSegmentIndex == 0 {
            // Miles
            distanceRan = metersRan * 0.00062137119224
        } else {
            // Kilometers
            distanceRan = metersRan / 1000
        }
        self.distanceLabel.text = String(format: "%.2f", distanceRan)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let directionsRenderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        
        directionsRenderer.strokeColor = .systemGreen
        directionsRenderer.lineWidth = 5
        directionsRenderer.alpha = 0.85
        
        return directionsRenderer
    }
    
    func removeOverlays() {
        self.mapView.overlays.forEach({ self.mapView.removeOverlay($0) })
        self.mapView.removeAnnotations(mapView.annotations)
    }
}
