//
//  MainViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreLocation

class MainViewController: UIViewController
{
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var location: CLLocationCoordinate2D!
    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentForecast: Forecast!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        checkLocationServices()
        locationManager.startUpdatingLocation()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

// MARK: - CLLocationManagerDelegate Implementation
extension MainViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location = locations.last {
            let searchCriteria = OpenWeatherForecastCriteria(latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude, units: .celcius, count: 10)
            OpenWeatherClient.instance.retrieveForecast(searchCriteria: searchCriteria, resultsProcessor: self)
            locationManager.stopUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
//        resetToolbar()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        switch (error as NSError).code {
        case CLError.Code.denied.rawValue:
            NSLog("Location services denied")
            locationManager.stopUpdatingLocation()
            break
        case CLError.Code.locationUnknown.rawValue:
            NSLog("Unable to determine location. Will try again later.")
            break
        default:
            break
        }
        NSLog("\(error.localizedDescription)\n\(error)")
    }
}

// MARK: - UICollectionViewDataSource Implementation
extension MainViewController: UICollectionViewDataSource
{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return currentForecast?.weatherList.count ?? 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let view = collectionView.dequeueReusableCell(withReuseIdentifier: "daily", for: indexPath)
        if let dateLabel = view.viewWithTag(2) as? UILabel {
            dateLabel.text = "\(indexPath)"
        }
        view.layer.borderColor = UIColor.blue.cgColor
        view.layer.borderWidth = 1.0
//        if let imageView = view.viewWithTag(1) as? UIImageView,
//            let imageData = allFlashCards.fetchedObjects?[indexPath.row].image {
//            imageView.image = UIImage(data: imageData as Data)
//        }
//        view.layer.borderColor = UIColor.green.cgColor
//        view.contentView.isHidden = indexPath == selectedCell
//        if isEditing { view.startWobbling() }
        return view
    }
}

// MARK: - UICollectionViewDelegate Implementation
extension MainViewController: UICollectionViewDelegate
{
}

// MARK: - 
extension MainViewController: OpenWeatherForecastResultsProcessor
{
    func process(forecast: Forecast)
    {
        DispatchQueue.main.async {
            self.currentForecast = forecast
            self.locationLabel.text = forecast.location.name
            self.collectionView.reloadData()
        }
    }
    
    func handle(error: NSError)
    {
        NSLog("\(error)\n\(error.localizedDescription)")
    }
}

// MARK: - Private Functions
private extension MainViewController
{
    func authoriseLocationServices()
    {
        switch CLLocationManager.authorizationStatus()
        {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .denied:
            promptForLocationServicesDenied()
            break
        case .restricted:
            let alertVC = UIAlertController(title: "Location Services Restricted",
                message: "Please speak to your device manager to enable location services to automatically retrieve " +
                "a forecast for your current location.",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel,
                handler: { _ in self.dismiss(animated: true, completion: nil) } ))
            present(alertVC, animated: true, completion: nil)
            break
        default:
            break
        }
    }
    
    func promptForLocationServicesDenied()
    {
        let alertVC = UIAlertController(title: "Location Services Denied",
            message: "Please enable location services to automatically retrieve the weather forecast near you.",
            preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel,
            handler: { _ in self.dismiss(animated: true, completion: nil) } ))
        alertVC.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        }))
        present(alertVC, animated: true, completion: nil)
    }
    
    func checkLocationServices()
    {
        if !CLLocationManager.locationServicesEnabled() {
            let alertVC = UIAlertController(title: "Location Services Disabled",
                message: "Please enable location services to automatically retrieve the weather forecast near you.",
                preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel,
                                            handler: { _ in self.dismiss(animated: true, completion: nil) } ))
            alertVC.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
                UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
            }))
            present(alertVC, animated: true, completion: nil)
        }
        else {
            authoriseLocationServices()
        }
    }
}

