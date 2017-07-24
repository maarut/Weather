//
//  SearchViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 19/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import MapKit

class SearchViewController: UIViewController
{
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet var tapGesture: UITapGestureRecognizer!
    var dataController: DataController!
    var user: User!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func cancelTapped(_ sender: UIBarButtonItem)
    {
        searchBar.resignFirstResponder()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func mapviewTapped(_ sender: UITapGestureRecognizer)
    {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        sender.isEnabled = false
    }
    
    @IBAction func longPressRecognised(_ sender: UILongPressGestureRecognizer)
    {
        switch sender.state {
        case .began:
            let point = sender.location(in: map)
            let coord = map.convert(point, toCoordinateFrom: map)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = "Custom location"
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(CLLocation(latitude: coord.latitude, longitude: coord.longitude)) {
                (placemarks, error) in
                guard error == nil else {
                    let e = error! as NSError
                    self.showError(withTitle: "Error Occured", message: e.localizedDescription)
                    NSLog(e.description + "\n" + error!.localizedDescription)
                    return
                }
                if let placemark = placemarks?.first {
                    annotation.title = placemark.name ?? "Custom location"
                }
            }
            map.addAnnotation(annotation)
        default:
            break
        }
    }
}

// MARK: - MKMapViewDelegate Implementation
extension SearchViewController: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation { return nil }
        let view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "StopPoint")
        if #available(iOS 9.0, *) {
            view.pinTintColor = MKPinAnnotationView.redPinColor()
        } else {
            view.pinColor = MKPinAnnotationColor.red
        }
        view.canShowCallout = true
        view.animatesDrop = true
        let addButton =  UIButton(type: UIButtonType.contactAdd)
        view.rightCalloutAccessoryView = addButton
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
        calloutAccessoryControlTapped control: UIControl) {
        if let annotation = view.annotation {
            dataController.mainThreadContext.insert(
                SavedLocation(user: user, id: nil, name: searchBar.text!, latitude: annotation.coordinate.latitude,
                    longitude: annotation.coordinate.longitude, context: dataController.mainThreadContext)
            )
            dataController.save()
            self.dismiss(animated: true, completion: nil)
        }
    }
}

// MARK: - Private Functions
private extension SearchViewController
{
    func showError(withTitle title: String, message: String)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .default , handler: { _ in }))
        present(alertController, animated: true, completion: nil)
    }
    
    func zoomTo(placemark: CLPlacemark)
    {
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.location!.coordinate
        annotation.title = placemark.name ?? searchBar.text!
        map.addAnnotation(annotation)
        map.setRegion(MKCoordinateRegionMakeWithDistance(placemark.location!.coordinate, 1000, 1000), animated: true)
    }
}

// MARK: - UISearchBarDelegate Implementation
extension SearchViewController: UISearchBarDelegate
{
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar)
    {
        tapGesture.isEnabled = true
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar)
    {
        tapGesture.isEnabled = false
        searchBar.resignFirstResponder()
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchBar.text!) { (placemarks, error) in
            guard error == nil else {
                let e = error! as NSError
                self.showError(withTitle: "Error Occured", message: e.localizedDescription)
                NSLog(e.description + "\n" + error!.localizedDescription)
                return
            }
            if let placemark = placemarks?.first { self.zoomTo(placemark: placemark) }
            else { self.showError(withTitle: "Error Occured", message: "No placemarks returned") }
        }
    }
    
}

// MARK: - UINavigationBarDelegate Implementation
extension SearchViewController: UINavigationBarDelegate
{
    func position(for bar: UIBarPositioning) -> UIBarPosition
    {
        return .topAttached
    }
}
