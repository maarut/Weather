//
//  MainViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreLocation

private let kphToMphFactor = 0.6213711922

class MainViewController: UIViewController
{
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var minTemp: UILabel!
    @IBOutlet weak var maxTemp: UILabel!
    @IBOutlet weak var pressure: UILabel!
    @IBOutlet weak var humidity: UILabel!
    @IBOutlet weak var windSpeed: UILabel!
    @IBOutlet weak var windDirection: UILabel!
    
    var location: CLLocationCoordinate2D!
    var dataController: DataController!
    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentForecast: Forecast!
    fileprivate var dateFormatter: DateFormatter!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
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
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
    {
        switch (error as NSError).code {
        case CLError.Code.denied.rawValue:
            NSLog("Location services denied")
            locationManager.stopUpdatingLocation()
        case CLError.Code.locationUnknown.rawValue:
            NSLog("Unable to determine location. Will try again later.")
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
        return currentForecast?.weatherList.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let view = collectionView.dequeueReusableCell(withReuseIdentifier: "daily", for: indexPath)
        if let iconView = view.viewWithTag(1) as? UIImageView {
            let id = currentForecast.weatherList[indexPath.row].weather.icon
            if let icon = dataController.icon(withId: id),
                let iconData = icon.data {
                iconView.image = UIImage(data: iconData as Data)
            }
            else {
                let criteria = OpenWeatherIconDownloaderCriteria(iconName: id)
                OpenWeatherClient.instance.downloadIcon(crieria: criteria, resultsProcessor: self)
            }
        }
        if let dateLabel = view.viewWithTag(2) as? UILabel {
            dateLabel.text = stringFormat(for: currentForecast.weatherList[indexPath.row].date,
                includeDayOfMonth: indexPath.row > 6)
        }
        return view
    }
}

// MARK: - UICollectionViewDelegate Implementation
extension MainViewController: UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        let weatherInfo = currentForecast.weatherList[indexPath.row]
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        let speed = weatherInfo.windSpeed * 3600 * kphToMphFactor / 1000
        let minTemp = weatherInfo.temperatures.min
        let maxTemp = weatherInfo.temperatures.max
        let pressure = weatherInfo.pressure
        let humidity = weatherInfo.humidity
        let windDirection = weatherInfo.windDirection
        descriptionLabel.text = weatherInfo.weather.description
        self.minTemp.text = "\(numberFormatter.string(from: minTemp as NSNumber) ?? "\(minTemp)") ℃"
        self.maxTemp.text = "\(numberFormatter.string(from: maxTemp as NSNumber) ?? "\(maxTemp)") ℃"
        self.pressure.text = "\(numberFormatter.string(from: pressure as NSNumber) ?? "\(pressure)") mbar"
        self.humidity.text = "\(numberFormatter.string(from: humidity as NSNumber) ?? "\(humidity)")%"
        self.windSpeed.text = "\(numberFormatter.string(from: speed as NSNumber) ?? "\(speed)") mph"
        self.windDirection.text = "\(numberFormatter.string(from: windDirection as NSNumber) ?? "\(windDirection)") °"
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(panned(_:)))
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        scrollView.panGestureRecognizer.removeTarget(self, action: #selector(panned(_:)))
        resetLabels()
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView)
    {
        resetLabels()
    }
    
    
}

// MARK: - Event Handlers
private extension MainViewController
{
    dynamic func panned(_ gestureRecogniser: UIPanGestureRecognizer)
    {
        if abs(gestureRecogniser.translation(in: collectionView).x) > 75 {
            resetLabels()
        }
    }
    
    @IBAction dynamic func share(_ sender: UIBarButtonItem)
    {
        let screenshot = snapshotVC()
        let description = "Weather forecast for \(currentForecast.location.name). " +
            "Today's weather - \(currentForecast.weatherList[0].weather.description)."
        let activityController = UIActivityViewController(activityItems: [screenshot, description],
            applicationActivities: nil)
        present(activityController, animated: true, completion: nil)
    }
}

// MARK: - OpenWeatherForecastResultsProcessor and OpenWeatherIconProcessor Implementation
extension MainViewController: OpenWeatherForecastResultsProcessor, OpenWeatherIconProcessor
{
    func process(icon: OpenWeatherIcon)
    {
        dataController.mainThreadContext.perform {
            self.dataController.mainThreadContext.insert(
                Icon(id: icon.iconName, data: icon.icon, context: self.dataController.mainThreadContext))
            self.dataController.save()
            self.collectionView.reloadData()
        }
    }
    
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
    func resetLabels()
    {
        descriptionLabel.text = "-"
        minTemp.text = "- ℃"
        maxTemp.text = "- ℃"
        pressure.text = "- mbar"
        humidity.text = "- %"
        windSpeed.text = "- mph"
        windDirection.text = "- °"
    }
    
    func isToday(_ date: Date) -> Bool
    {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return todayComponents.day == dateComponents.day && todayComponents.month == dateComponents.month &&
            todayComponents.year == dateComponents.year
    }
    
    func stringFormat(for date: Date, includeDayOfMonth: Bool = false) -> String
    {
        if isToday(date) {
            return "Today"
        }
        if includeDayOfMonth {
            dateFormatter.dateFormat = "ccc dd"
            let dateString = dateFormatter.string(from: date)
            let dayOfWeek = Calendar.current.component(.day, from: date)
            switch dayOfWeek % 10 {
            case 1:     return dateString + "st"
            case 2:     return dateString + "nd"
            case 3:     return dateString + "rd"
            default:    return dateString + "th"
            }
        }
        else {
            dateFormatter.dateFormat = "ccc"
            return dateFormatter.string(from: date)
        }
    }
    
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
    
    func snapshotVC() -> UIImage
    {
        var drawingFrame = view.bounds
        drawingFrame.size.height *= UIScreen.main.scale
        drawingFrame.size.width *= UIScreen.main.scale
        UIGraphicsBeginImageContext(drawingFrame.size)
        view.drawHierarchy(in: drawingFrame, afterScreenUpdates: true)
        let composedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return composedImage!
    }
}

