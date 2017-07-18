//
//  WeatherItem.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - WeatherItemError Enum
enum WeatherItemError: Int
{
    case keyNotFound
    case weatherParse
    case temperaturesParse
}

// MARK: - WeatherItem Struct
// response list.weather - item
struct WeatherItem
{
    static let temperaturesKey = "temp"
    static let pressureKey = "pressure"
    static let humidityKey = "humidity"
    static let windSpeedKey = "speed"
    static let windDirectionKey = "deg"
    static let weatherKey = "weather"
    static let dateKey = "dt"
    
    let temperatures: Temperatures
    let pressure: Double
    let humidity: Int
    let windSpeed: Double
    let windDirection: Double
    let weather: WeatherDescription
    let date: Date
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: WeatherItemError) -> NSError
        {
            return NSError(domain: "WeatherList.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let pressure = json[WeatherItem.pressureKey] as? Double else {
            throw makeError("Key \(WeatherItem.pressureKey) not found.", code: .keyNotFound)
        }
        guard let humidity = json[WeatherItem.humidityKey] as? Int else {
            throw makeError("Key \(WeatherItem.pressureKey) not found.", code: .keyNotFound)
        }
        guard let windSpeed = json[WeatherItem.windSpeedKey] as? Double else {
            throw makeError("Key \(WeatherItem.windSpeedKey) not found.", code: .keyNotFound)
        }
        guard let windDirection = json[WeatherItem.windDirectionKey] as? Double else {
            throw makeError("Key \(WeatherItem.windDirectionKey) not found.", code: .keyNotFound)
        }
        guard let temperatures = json[WeatherItem.temperaturesKey] as? [String: AnyObject] else {
            throw makeError("Key \(WeatherItem.temperaturesKey) not found.", code: .keyNotFound)
        }
        guard let weather = json[WeatherItem.weatherKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(WeatherItem.weatherKey) not found.", code: .keyNotFound)
        }
        guard let date = json[WeatherItem.dateKey] as? TimeInterval else {
            throw makeError("Key \(WeatherItem.dateKey) not found.", code: .keyNotFound)
        }
        
        self.pressure = pressure
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.windDirection = windDirection
        self.date = Date(timeIntervalSince1970: date)
        do { self.temperatures = try Temperatures(json: temperatures)! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(WeatherItem.temperaturesKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "WeatherItem.init", code: WeatherItemError.temperaturesParse.rawValue,
                userInfo: userInfo)
        }
        do { self.weather = try WeatherDescription(json: weather.first ?? [:])! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(WeatherItem.weatherKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "WeatherItem.init", code: WeatherItemError.weatherParse.rawValue,
                userInfo: userInfo)
        }
    }
}
