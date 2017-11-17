//
//  ForecastViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit
import CoreLocation
import AVFoundation

private let kphToMphFactor = 0.6213711922

class ForecastViewController: UIViewController
{
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var shareButton: UIBarButtonItem!
    var location: SavedLocation?
    var user: User!
    var dataController: DataController!
    fileprivate let speechSynthesiser = AVSpeechSynthesizer()
    fileprivate let locationManager = CLLocationManager()
    fileprivate var currentForecast: Forecast!
    fileprivate var detailedForecast: HourlyForecast?
    fileprivate var dateFormatter: DateFormatter!
    fileprivate var selectedIndexPath: IndexPath?
    fileprivate weak var forecastDetailVC: ForecastDetailsViewController!
    fileprivate var unitsText: String!
    override func viewDidLoad()
    {
        super.viewDidLoad()
        dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        shareButton.target = self
        shareButton.action = #selector(share(_:))
        
        switch user.units {
        case 0: unitsText = "°C"
        case 1: unitsText = "°F"
        default: unitsText = ""
        }
        forecastDetailVC.unitsText = unitsText
        forecastDetailVC.tableView.reloadData()
        
        if let location = location {
            let searchCriteria: OpenWeatherForecastCriteria
            if let id = location.id {
                searchCriteria = OpenWeatherForecastCriteria(id: Int64(id),
                    units: .metric, count: Int(user.forecastedCount))
            }
            else {
                searchCriteria = OpenWeatherForecastCriteria(latitude: location.latitude, longitude: location.longitude,
                    units: .metric, count: Int(user.forecastedCount))
            }
            OpenWeatherClient.instance.retrieveForecast(searchCriteria: searchCriteria, resultsProcessor: self)
        }
        else {
            checkLocationServices()
            locationManager.startUpdatingLocation()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        speechSynthesiser.stopSpeaking(at: AVSpeechBoundary.word)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        switch segue.identifier ?? "" {
        case "embed":
            forecastDetailVC = segue.destination as! ForecastDetailsViewController
            forecastDetailVC.unitsText = unitsText
            forecastDetailVC.convertCelciusToFahrenheit = convertCelciusToFahrenheit(temp:)
        default: return
        }
    }
}



// MARK: - CLLocationManagerDelegate Implementation
extension ForecastViewController: CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        if let location = locations.last {
            locationManager.stopUpdatingLocation()
            let searchCriteria = OpenWeatherForecastCriteria(latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                units: .metric, count: Int(user.forecastedCount))
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
extension ForecastViewController: UICollectionViewDataSource
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
extension ForecastViewController: UICollectionViewDelegate
{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath)
    {
        selectedIndexPath = indexPath
        if let detailedForecast = detailedForecast {
            update(detailedForecast: detailedForecast)
        }
        else {
            let criteria = OpenWeatherHourlyForecastCriteria(id: "\(currentForecast.location.id)", units: .metric)
            OpenWeatherClient.instance.retrieveHourlyForecast(searchCriteria: criteria, resultsProcessor: self)
            setDetailWeatherData()
        }
        speakForecast()
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(panned(_:)))
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool)
    {
        scrollView.panGestureRecognizer.removeTarget(self, action: #selector(panned(_:)))
    }
}

// MARK: - Event Handlers
private extension ForecastViewController
{
    dynamic func panned(_ gestureRecogniser: UIPanGestureRecognizer)
    {
        if abs(gestureRecogniser.translation(in: collectionView).x) > 75 {
            resetLabels()
            speechSynthesiser.stopSpeaking(at: .word)
        }
    }
    
    @IBAction dynamic func share(_ sender: UIBarButtonItem)
    {
        let description: String
        if let selectedIndexPath = self.selectedIndexPath {
            let weatherInfo = currentForecast.weatherList[selectedIndexPath.row]
            description = "Weather forecast for \(currentForecast.location.name). " +
                "\(stringFormat(for: weatherInfo.date, includeDayOfMonth: selectedIndexPath.row > 6))'s weather - " +
                weatherInfo.weather.description
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
extension ForecastViewController: OpenWeatherForecastResultsProcessor, OpenWeatherIconProcessor,
    OpenWeatherHourlyForecastResultsProcessor
{
    func process(hourlyForecast: HourlyForecast)
    {
        DispatchQueue.main.async {
            self.detailedForecast = hourlyForecast
            self.update(detailedForecast: hourlyForecast)
        }
    }
    
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
                    self.location?.id = Int64(forecast.location.id) as NSNumber
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
private extension ForecastViewController
{
    func update(detailedForecast: HourlyForecast)
    {
        if let indexPath = selectedIndexPath {
            let date = currentForecast.weatherList[indexPath.row].date
            let details = detailedForecast.weatherList.filter( { isSameDay($0.date, date) } )
            if details.count > 0 { forecastDetailVC.state = .hourly(details) }
            else { forecastDetailVC.state = .overview(currentForecast.weatherList[indexPath.row]) }
        }
    }
    
    func resetLabels()
    {
        selectedIndexPath = nil
        forecastDetailVC.state = .none
    }
    
    func stringFormat(for date: Date, includeDayOfMonth: Bool = false) -> String
    {
        if isToday(date) {
            return "Today"
        }
        if includeDayOfMonth {
            dateFormatter.dateFormat = "ccc d"
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
        guard let indexPath = selectedIndexPath else { return }
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.dateFormat = nil
        let date = dateFormatter.string(from: currentForecast.weatherList[indexPath.row].date)
        let weatherInfo = currentForecast.weatherList[indexPath.row]
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .none
        
        let minTemp = convertCelciusToFahrenheit(temp: weatherInfo.temperatures.min)
        let maxTemp = convertCelciusToFahrenheit(temp: weatherInfo.temperatures.max)
        let humidity = weatherInfo.humidity
        let speed = weatherInfo.windSpeed * 3600 * kphToMphFactor / 1000
        let unitsText = self.unitsText ?? ""
        let utterances = [AVSpeechUtterance(string: "Forecast for \(currentForecast.location.name) on \(date)."),
            AVSpeechUtterance(string: "Expect \(weatherInfo.weather.description)."),
            AVSpeechUtterance(string:
"Minimum Temperature is \(numberFormatter.string(from: minTemp as NSNumber) ?? "\(minTemp)") \(unitsText)"),
            AVSpeechUtterance(string:
"Maximum Temperature is \(numberFormatter.string(from: maxTemp as NSNumber) ?? "\(maxTemp)") \(unitsText)"),
            AVSpeechUtterance(string:
                "Humidity is \(numberFormatter.string(from: humidity as NSNumber) ?? "\(humidity)")%"),
            AVSpeechUtterance(string:
                "Wind speed is \(numberFormatter.string(from: speed as NSNumber) ?? "\(speed)") mph")
        ]
        for utterance in utterances {
            utterance.postUtteranceDelay = 0.4
            speechSynthesiser.speak(utterance)
        }
    }
    
    func setDetailWeatherData()
    {
        guard let indexPath = selectedIndexPath else { return }
        forecastDetailVC.state = .overview(currentForecast.weatherList[indexPath.row])
    }
    
    func convertCelciusToFahrenheit(temp: Double) -> Double
    {
        switch user.units {
        case 0: return temp
        case 1: return temp * 9.0 / 5.0 + 32.0
        default: return temp
        }
    }
}


// MARK: - Private Utility Functions
private func isSameDay(_ date: Date, _ other: Date) -> Bool
{
    let otherComponents = Calendar.current.dateComponents([.year, .month, .day], from: other)
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: date)
    return otherComponents.day == dateComponents.day &&
        otherComponents.month == dateComponents.month &&
        otherComponents.year == dateComponents.year
}


private func isToday(_ date: Date) -> Bool
{
    return isSameDay(date, Date())
}
