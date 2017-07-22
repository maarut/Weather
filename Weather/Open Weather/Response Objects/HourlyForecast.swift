//
//  HourlyForecast.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

enum HourlyForecastError: Int
{
    case keyNotFound
    case hourlyWeatherListParse
    case locationParse
    case validation
}

struct HourlyForecast
{
    static let countKey = "cnt"
    static let weatherListKey = "list"
    static let locationKey = "city"
    
    let weatherList: [HourlyWeatherItem]
    let location: Location
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: HourlyForecastError) -> NSError
        {
            return NSError(domain: "HourlyForecast.init", code: code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let weatherListCount = json[HourlyForecast.countKey] as? Int else {
            throw makeError("Key \(HourlyForecast.countKey) not found.", code: .keyNotFound)
        }
        guard let weatherList = json[HourlyForecast.weatherListKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(HourlyForecast.weatherListKey) not found.", code: .keyNotFound)
        }
        guard let location = json[HourlyForecast.locationKey] as? [String: AnyObject] else {
            throw makeError("Key \(HourlyForecast.locationKey) not found.", code: .keyNotFound)
        }
        
        self.weatherList = try weatherList.flatMap {
            do { return try HourlyWeatherItem(json: $0) }
            catch let error as NSError {
                let userInfo: [String: AnyObject] =
                    [NSLocalizedDescriptionKey:
                        "Could not parse JSON dictionary for key \(HourlyForecast.weatherListKey)." as NSString,
                     NSUnderlyingErrorKey: error]
                throw NSError(domain: "HourlyForecast.init", code: HourlyForecastError.hourlyWeatherListParse.rawValue,
                              userInfo: userInfo)
            }
        }
        do { self.location = try Location(json: location)! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey: "Could not parse JSON dictionary for key \(HourlyForecast.locationKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "Forecast.init", code: HourlyForecastError.locationParse.rawValue,
                          userInfo: userInfo)
        }
        
        if self.weatherList.count != weatherListCount {
            throw makeError("Forecast.init - Malformed response received. Expected \(weatherListCount) WeatherItems." +
                "Received \(self.weatherList.count)",
                code: .validation)
        }
    }
}
