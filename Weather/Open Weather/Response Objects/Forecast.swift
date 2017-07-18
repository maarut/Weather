//
//  Forecast.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - ForecastError Enum
enum ForecastError: Int
{
    case keyNotFound
    case weatherListParse
    case locationParse
    case validation
}

// MARK: - Forecast struct
// response
struct Forecast
{
    static let countKey = "cnt"
    static let weatherListKey = "list"
    static let locationKey = "city"
    
    let weatherList: [WeatherItem]
    let location: Location
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: ForecastError) -> NSError
        {
            return NSError(domain: "Forecast.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let weatherListCount = json[Forecast.countKey] as? Int else {
            throw makeError("Key \(Forecast.countKey) not found.", code: .keyNotFound)
        }
        guard let weatherList = json[Forecast.weatherListKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(Forecast.weatherListKey) not found.", code: .keyNotFound)
        }
        guard let location = json[Forecast.locationKey] as? [String: AnyObject] else {
            throw makeError("Key \(Forecast.locationKey) not found.", code: .keyNotFound)
        }
        
        self.weatherList = try weatherList.flatMap {
            do { return try WeatherItem(json: $0) }
            catch let error as NSError {
                let userInfo: [String: AnyObject] =
                    [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(Forecast.weatherListKey)." as NSString,
                     NSUnderlyingErrorKey: error]
                throw NSError(domain: "Forecast.init", code: ForecastError.weatherListParse.rawValue,
                    userInfo: userInfo)
            }
        }
        do { self.location = try Location(json: location)! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(Forecast.locationKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "Forecast.init", code: ForecastError.locationParse.rawValue,
                userInfo: userInfo)
        }
        
        if self.weatherList.count != weatherListCount {
            throw makeError("Forecast.init - Malformed response received. Expected \(weatherListCount) WeatherItems. Received \(self.weatherList.count)",
                code: .validation)
        }
    }
}
