//
//  HourlyForecastDetails.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

// MARK: - HourlyForecastDetailsError Enum
enum HourlyForecastDetailsError: Int
{
    case keyNotFound
}

// MARK: - HourlyForecastDetails Implementation
struct HourlyForecastDetails
{
    static let averageTemperatureKey = "temp"
    static let minTemperature = "temp_min"
    static let maxTemperature = "temp_max"
    static let pressureKey = "pressure"
    static let humidityKey = "humidity"
    
    let averageTemperature: Double
    let minTemperature: Double
    let maxTemperature: Double
    let pressure: Double
    let humidity: Int
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: HourlyForecastDetailsError) -> NSError
        {
            return NSError(domain: "HourlyForecastDetails.ini", code: code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let averageTemperature = json[HourlyForecastDetails.averageTemperatureKey] as? Double else {
            throw makeError("Key \(HourlyForecastDetails.averageTemperatureKey) not found.", code: .keyNotFound)
        }
        guard let minTemperature = json[HourlyForecastDetails.minTemperature] as? Double else {
            throw makeError("Key \(HourlyForecastDetails.minTemperature) not found.", code: .keyNotFound)
        }
        guard let maxTemperature = json[HourlyForecastDetails.maxTemperature] as? Double else {
            throw makeError("Key \(HourlyForecastDetails.maxTemperature) not found.", code: .keyNotFound)
        }
        guard let pressure = json[HourlyForecastDetails.pressureKey] as? Double else {
            throw makeError("Key \(HourlyForecastDetails.pressureKey) not found.", code: .keyNotFound)
        }
        guard let humidity = json[HourlyForecastDetails.humidityKey] as? Int else {
            throw makeError("Key \(HourlyForecastDetails.humidityKey) not found.", code: .keyNotFound)
        }
        
        self.averageTemperature = averageTemperature
        self.minTemperature = minTemperature
        self.maxTemperature = maxTemperature
        self.pressure = pressure
        self.humidity = humidity
    }
}
