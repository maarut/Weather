//
//  HourlyWeatherItem.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

enum HourlyWeatherItemError: Int
{
    case keyNotFound
    case descriptionParse
    case hourlyForecastDetailsParse
    case windParse
}

struct HourlyWeatherItem
{
    static let dateKey = "dt"
    static let windKey = "wind"
    static let hourlyForecastKey = "main"
    static let descriptionKey = "weather"
    
    let wind: Wind
    let weatherDescription: WeatherDescription
    let forecastDetails: HourlyForecastDetails
    let date: Date
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: HourlyWeatherItemError) -> NSError
        {
            return NSError(domain: "HourlyWeatherItem.init", code: code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        
        guard let date = json[HourlyWeatherItem.dateKey] as? TimeInterval else {
            throw makeError("Key \(WeatherItem.dateKey) not found.", code: .keyNotFound)
        }
        guard let windJson = json[HourlyWeatherItem.windKey] as? [String: AnyObject] else {
            throw makeError("Key \(HourlyWeatherItem.windKey) not found.", code: .keyNotFound)
        }
        guard let weatherDescriptionArray = json[HourlyWeatherItem.descriptionKey] as? [[String: AnyObject]] else {
            throw makeError("Key \(HourlyWeatherItem.descriptionKey) not found.", code: .keyNotFound)
        }
        guard let hourlyForecastDetailsJson = json[HourlyWeatherItem.hourlyForecastKey] as? [String: AnyObject] else {
            throw makeError("Key \(HourlyWeatherItem.hourlyForecastKey) not found.", code: .keyNotFound)
        }
        

        self.date = Date(timeIntervalSince1970: date)
        do { self.wind = try Wind(json: windJson)! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey:
                    "Could not parse JSON dictionary for key \(HourlyWeatherItem.windKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "HourlyWeatherItem.init", code: HourlyWeatherItemError.windParse.rawValue,
                          userInfo: userInfo)
        }
        do { self.weatherDescription = try WeatherDescription(json: weatherDescriptionArray.first ?? [:])! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey:
                    "Could not parse JSON dictionary for key \(HourlyWeatherItem.descriptionKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "HourlyWeatherItem.init", code: HourlyWeatherItemError.descriptionParse.rawValue,
                          userInfo: userInfo)
        }
        do { self.forecastDetails = try HourlyForecastDetails(json: hourlyForecastDetailsJson)! }
        catch let error as NSError {
            let userInfo: [String: AnyObject] =
                [NSLocalizedDescriptionKey:
                    "Could not parse JSON dictionary for key \(HourlyWeatherItem.hourlyForecastKey)." as NSString,
                 NSUnderlyingErrorKey: error]
            throw NSError(domain: "HourlyWeatherItem.init",
                          code: HourlyWeatherItemError.hourlyForecastDetailsParse.rawValue,
                          userInfo: userInfo)
        }
    }
}
