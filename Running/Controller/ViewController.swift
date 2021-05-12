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
    
    // MARK: - Properties
    var runningRouteAnnotation: RunningRoute?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkLocationAuthStatus()
        mapView.delegate = self
    }

    //MARK: - IBActions
    @IBAction func PlayPauseButtonPressed(_ sender: Any) {
        if mapView.annotations.count == 1 {
            guard let coordinates = LocationService.instance.currentLocation else { return }
            setupAnnotation(coordinate: coordinates)
        } else {
            //TODO handle moving annotation
        }
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
    
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
            var view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.canShowCallout = true
            view.animatesDrop = true
            view.pinTintColor = .green
            view.calloutOffset = CGPoint(x: -8, y: -3)
            
            return view
        }
        return nil
    }
}

extension ViewController: CustomUserLocDelegate {
    func userLocationUpdated(location: CLLocation) {
        centerMapOnUserLocation(coordinates: location.coordinate)
    }
    
    
}

