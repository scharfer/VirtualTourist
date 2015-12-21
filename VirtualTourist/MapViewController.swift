//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Evan Scharfer on 12/15/15.
//  Copyright © 2015 Evan Scharfer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var pins = [Pin]()
    var selectedPin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let lpgr = UILongPressGestureRecognizer(target: self, action: "addPin:")
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        lpgr.delegate = self
        view.addGestureRecognizer(lpgr)
        
        mapView.delegate = self
        
        // get the Pins from CoreData
        pins = fetchAllPins()
        
        for pin in pins {
            let annotation = MyImagesAnnotation()
            let point = CLLocationCoordinate2D(latitude: pin.latitude as Double,longitude: pin.longitude as Double)
            annotation.coordinate = point
            annotation.title = "See Images"
            //annotation.annotationId = index
            annotation.pin = pin
            mapView.addAnnotation(annotation)
        }
    }

    func addPin(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.Ended {
            return
        }
        
        let touchPoint = gestureReconizer.locationInView(mapView)
        let point = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
        
        // Here we create the annotation and set its coordiate, title, and subtitle properties
        let annotation = MyImagesAnnotation()
        annotation.coordinate = point
        
        // Now we create a new Pin, using the shared Context
        let newPin = Pin(latitude: point.latitude, longitude: point.longitude,  context: sharedContext)
        //annotation.annotationId = pins.count
        annotation.pin = newPin
        annotation.title = "See Images"
        pins.append(newPin)
        
        
        // Finally we save the shared context, using the convenience method in
        // The CoreDataStackManager
        CoreDataStackManager.sharedInstance().saveContext()
        
        mapView.addAnnotation(annotation)
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Get all the pins
    func fetchAllPins() -> [Pin] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
            
        } catch let error as NSError {
            
            print("Error in fetchAllActors(): \(error)")
            return [Pin]()
            
        }
    }
    
    // Here we create a view with a "right callout accessory view". You might choose to look into other
    // decoration alternatives. Notice the similarity between this method and the cellForRowAtIndexPath
    // method in TableViewDataSource.
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .InfoLight)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }

    // This delegate method is implemented to respond to taps. It opens the system browser
    // to the URL specified in the annotationViews subtitle property.
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.rightCalloutAccessoryView {
            let annotation = view.annotation as! MyImagesAnnotation
            selectedPin = annotation.pin
            if (selectedPin.photos.count == 0 ) {
                FlickrWSClient.sharedInstance().callFlickrForImages(annotation.pin!, callBack: flickImageResults)
            } else {
                // we already have the images just send to collection
                sendToPhotos()
            }
            //print(annotation.pin?.longitude)
        }
    }
    
    func flickImageResults (result: AnyObject?, error: NSError? ) {
        if let error = error {
            // error
            print("There was an error: \(error)")
        } else {
            //print(result)
            let perPage = result!["photos"]??["perpage"] as? Int
            if let perPage = perPage {
                dispatch_async(dispatch_get_main_queue(), {
                    var photos = [Photo]()
                    for photo in result!["photos"]??["photo"] as! [AnyObject] {
                        let photo = Photo(photoUrl: photo["url_m"] as! String, filePath: nil, pin: self.selectedPin, context: self.sharedContext)
                        photos.append(photo)
                    }
                
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    self.sendToPhotos()
                })
            } else {
                // error
                print("There was an error: \(error)")
            }
            
            
        }
        
    }
    
    func sendToPhotos() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("ImageCollectionViewController") as! ImageCollectionViewController
        
        controller.selectedPin = selectedPin
        controller.imageCount = selectedPin.photos.count
        self.navigationController?.pushViewController(controller, animated: true)
    }

}

