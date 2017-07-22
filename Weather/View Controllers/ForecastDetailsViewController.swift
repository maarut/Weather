//
//  ForecastDetailsViewController.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import UIKit

// MARK: - ForecastDetailsState
enum ForecastDetailsState
{
    case none
    case hourly([HourlyWeatherItem])
    case overview(WeatherItem)
}

private let kphToMphFactor = 0.6213711922

class ForecastDetailsViewController: UITableViewController
{
    
    fileprivate let dateFormatter = DateFormatter()
    fileprivate let numberFormatter = NumberFormatter()
    var state: ForecastDetailsState = .none {
        didSet {
            let indexPaths: [IndexPath]
            switch oldValue {
            case .none: indexPaths = []
            case .hourly(let data): indexPaths = (0 ..< data.count).map { IndexPath(row: $0, section: 0) }
            case .overview(_): indexPaths = [IndexPath(row: 0, section: 0)]
            }
            tableView.beginUpdates()
            tableView.deleteRows(at: indexPaths, with: .fade)
            setNewRows()
            tableView.endUpdates()
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        tableView.isScrollEnabled = false
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "ha"
        numberFormatter.numberStyle = .none
    }
}

// MARK: - UITableViewControllerDelegate Implementation
extension ForecastDetailsViewController
{

}


// MARK: - UITableViewControllerDataSource Implementation
extension ForecastDetailsViewController
{
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        switch state {
        case .overview(let data):
            let cell = tableView.dequeueReusableCell(withIdentifier: "overview")!
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .none
            let speed = data.windSpeed * 3600 * kphToMphFactor / 1000
            let minTemp = data.temperatures.min
            let maxTemp = data.temperatures.max
            let pressure = data.pressure
            let humidity = data.humidity
            let windDirection = data.windDirection
            (cell.viewWithTag(1) as! UILabel).text = "\(data.weather.description)"
            (cell.viewWithTag(2) as! UILabel).text =
                "\(numberFormatter.string(from: minTemp as NSNumber) ?? "\(minTemp)") °C"
            (cell.viewWithTag(3) as! UILabel).text =
                "\(numberFormatter.string(from: maxTemp as NSNumber) ?? "\(maxTemp)") °C"
            (cell.viewWithTag(4) as! UILabel).text =
                "\(numberFormatter.string(from: pressure as NSNumber) ?? "\(pressure)") mbar"
            (cell.viewWithTag(5) as! UILabel).text =
                "\(numberFormatter.string(from: humidity as NSNumber) ?? "\(humidity)")%"
            (cell.viewWithTag(6) as! UILabel).text =
                "\(numberFormatter.string(from: speed as NSNumber) ?? "\(speed)") mph"
            (cell.viewWithTag(7) as! UILabel).text =
                "\(numberFormatter.string(from: windDirection as NSNumber) ?? "\(windDirection)") °"
            return cell
        case .hourly(let data):
            let cell = tableView.dequeueReusableCell(withIdentifier: "hourly")!
            let info = data[indexPath.row]
            (cell.viewWithTag(1) as! UILabel).text = dateFormatter.string(from: info.date)
            (cell.viewWithTag(2) as! UILabel).text = info.weatherDescription.description
            (cell.viewWithTag(3) as! UILabel).text =
                numberFormatter.string(from: info.forecastDetails.minTemperature as NSNumber)! + " °C"
            (cell.viewWithTag(4) as! UILabel).text =
                numberFormatter.string(from: info.forecastDetails.maxTemperature as NSNumber)! + " °C"
            (cell.viewWithTag(5) as! UILabel).text =
                numberFormatter.string(from: info.forecastDetails.humidity as NSNumber)! + "%"
            return cell
        case .none:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        switch state {
        case .none: return 0
        case .hourly(_): return 128
        case .overview(_): return 256
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        switch state {
        case .none:                 return 0
        case .overview(_):          return 1
        case .hourly(let items):    return items.count
        }
    }
}

// MARK: - Private Functions
private extension ForecastDetailsViewController
{
    func setNewRows()
    {
        switch state {
        case .none:
            tableView.isScrollEnabled = false
        case .hourly(let data):
            let indexPaths = (0 ..< data.count).map { IndexPath(row: $0, section: 0) }
            tableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.fade)
            tableView.isScrollEnabled = true
        case .overview(_):
            tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.fade)
            tableView.isScrollEnabled = false
            
        }
    }
}
