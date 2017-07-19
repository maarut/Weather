//
//  MainViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation

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
    
    
    weak var shareButton: UIBarButtonItem!
    var location: SavedLocation?
    var dataController: DataController!
    fileprivate let speechSynthesiser = AVSpeechSynthesizer()
    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentForecast: Forecast!
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var selectedIndexPath: IndexPath?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        if let location = location {
            let searchCriteria: OpenWeatherForecastCriteria
            if let id = location.id {
                searchCriteria = OpenWeatherForecastCriteria(id: id, units: .celcius, count: 10)
            }
            else {
                searchCriteria = OpenWeatherForecastCriteria(latitude: location.latitude, longitude: location.longitude,
                    units: .celcius, count: 10)
            }
            OpenWeatherClient.instance.retrieveForecast(searchCriteria: searchCriteria, resultsProcessor: self)
        }
        else {
            checkLocationServices()
            locationManager.startUpdatingLocation()
        }
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        shareButton.target = self
        shareButton.action = #selector(share(_:))
    }
    
    override func viewWillDisappear(_ animated: Bool)
    {
        super.viewWillDisappear(animated)
        speechSynthesiser.stopSpeaking(at: AVSpeechBoundary.word)
    }
}



// MARK: - CLLocationManagerDelegate Implementation
extension MainViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location = locations.last {
            locationManager.stopUpdatingLocation()
            let searchCriteria = OpenWeatherForecastCriteria(latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude, units: .celcius, count: 10)
            OpenWeatherClient.instance.retrieveForecast(searchCriteria: searchCriteria, resultsProcessor: self)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        NSLog("Authorisation status changed. New status \(status.rawValue)")
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
        selectedIndexPath = indexPath
        setDetailWeatherData()
        speakForecast()
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
        let description: String
        if let selectedIndexPath = self.selectedIndexPath {
            description = "Weather forecast for \(currentForecast.location.name). " +
            "Today's weather - \(currentForecast.weatherList[selectedIndexPath.row].weather.description)."
        }
        else {
            let ip = IndexPath(row: 0, section: 0)
            collectionView.selectItem(at: ip, animated: false, scrollPosition: .centeredHorizontally)
            selectedIndexPath = ip
            setDetailWeatherData()
            
            description = "Weather forecast for \(currentForecast.location.name). " +
            "Today's weather - \(currentForecast.weatherList[0].weather.description)."
        }
        let screenshot = snapshotScreen()
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
            self.location?.managedObjectContext?.perform {
                if self.location?.id == nil {
                    self.location?.id = "\(forecast.location.id)"
                    do {
                        try self.location?.managedObjectContext?.save()
                        self.dataController.save()
                    }
                    catch let error as NSError { NSLog("\(error.localizedDescription)\n\(error)") }
                }
            }
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
        minTemp.text = "- °C"
        maxTemp.text = "- °C"
        pressure.text = "- mbar"
        humidity.text = "- %"
        windSpeed.text = "- mph"
        windDirection.text = "- °"
        selectedIndexPath = nil
    }
    
    func isToday(_ date: Date) -> Bool
    {
        let todayComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return todayComponents.day == dateComponents.day &&
            todayComponents.month == dateComponents.month &&
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
    
    func snapshotScreen() -> UIImage
    {
        guard let window = (UIApplication.shared.delegate as? AppDelegate)?.window else {
            fatalError("AppDelegate's window property not set.")
        }
        var drawingFrame = window.bounds
        drawingFrame.size.height *= window.screen.scale
        drawingFrame.size.width *= window.screen.scale
        UIGraphicsBeginImageContext(drawingFrame.size)
        window.drawHierarchy(in: drawingFrame, afterScreenUpdates: true)
        let composedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return composedImage!
    }
    
    func speakForecast()
    {
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = nil
        let date = dateFormatter.string(from: currentForecast.weatherList[selectedIndexPath!.row].date)
        let utterances = [AVSpeechUtterance(string: "Forecast for \(locationLabel.text!) on \(date)."),
                        AVSpeechUtterance(string: "Expect \(descriptionLabel.text!)."),
                        AVSpeechUtterance(string: "Minimum Temperature is \(minTemp.text!)"),
                        AVSpeechUtterance(string: "Maximum Temperature is \(maxTemp.text!)"),
                        AVSpeechUtterance(string: "Humidity is \(humidity.text!)"),
                        AVSpeechUtterance(string: "Wind speed is \(windSpeed.text!)")
        ]
        for utterance in utterances {
            utterance.postUtteranceDelay = 0.4
            speechSynthesiser.speak(utterance)
        }
    }
    
    func setDetailWeatherData()
    {
        guard let indexPath = selectedIndexPath else { return }
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
        self.minTemp.text = "\(numberFormatter.string(from: minTemp as NSNumber) ?? "\(minTemp)") °C"
        self.maxTemp.text = "\(numberFormatter.string(from: maxTemp as NSNumber) ?? "\(maxTemp)") °C"
        self.pressure.text = "\(numberFormatter.string(from: pressure as NSNumber) ?? "\(pressure)") mbar"
        self.humidity.text = "\(numberFormatter.string(from: humidity as NSNumber) ?? "\(humidity)")%"
        self.windSpeed.text = "\(numberFormatter.string(from: speed as NSNumber) ?? "\(speed)") mph"
        self.windDirection.text = "\(numberFormatter.string(from: windDirection as NSNumber) ?? "\(windDirection)") °"
    }
}

