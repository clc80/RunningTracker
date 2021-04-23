//
//  RunningRoute.swift
//  Running
//
//  Created by Claudia Maciel on 4/22/21.
//

import UIKit
import MapKit

class RunningRoute: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}
