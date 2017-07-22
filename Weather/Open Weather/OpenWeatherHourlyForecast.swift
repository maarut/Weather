//
//  OpenWeatherHourlyForecast.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

// MARK: - OpenWeatherHourlyForecastResultsProcessor Protocol
protocol OpenWeatherHourlyForecastResultsProcessor: class
{
    func process(hourlyForecast: HourlyForecast)
    func handle(error: NSError)
}

// MARK: - OpenWeatherHourlyForecastErrorCodes Enum
enum OpenWeatherHourlyForecastErrorCodes: Int
{
    case jsonParse
    case noData
}

// MARK: - OpenWeatherHourlyForecastCriteria
struct OpenWeatherHourlyForecastCriteria
{
    let id: String
    let units: OpenWeatherUnit
    
    init(id: String, units: OpenWeatherUnit)
    {
        self.units = units
        self.id = id
        
    }
}

// MARK: - OpenWeatherHourlyForecast
class OpenWeatherHourlyForecast: OpenWeatherOperationProcessor, OpenWeatherOperationRequestor
{
    fileprivate weak var resultsHandler: OpenWeatherHourlyForecastResultsProcessor?
    fileprivate let _request: URLRequest
    var request: URLRequest { return _request }
    
    init(searchCriteria: OpenWeatherHourlyForecastCriteria, resultsHandler: OpenWeatherHourlyForecastResultsProcessor)
    {
        let unit: String
        switch searchCriteria.units {
        case .celcius:      unit = "metric"
        case .fahrenheit:   unit = "imperial"
        case .kelvin:       unit = ""
        }
        let parameters: [String: Any] = ["id": searchCriteria.id,
                                         "units": unit]
        _request = URLRequest(url: OpenWeatherURL(method: "forecast", parameters: parameters).url as URL)
        self.resultsHandler = resultsHandler
    }
    
    func process(data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "OpenWeatherHourlyForecast.processData",
                                code: OpenWeatherHourlyForecastErrorCodes.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
            return
        }
        if let forecast = parseForecast(json) { resultsHandler?.process(hourlyForecast: forecast) }
    }
    
    func handle(error: NSError)
    {
        resultsHandler?.handle(error: error)
    }
}

// MARK: - OpenWeatherHourlyForecast Private Methods
private extension OpenWeatherHourlyForecast
{
    func parseForecast(_ data: [String: AnyObject]) -> HourlyForecast?
    {
        do { return try HourlyForecast(json: data) }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                            NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "OpenWeatherHourlyForecast.processData",
                                code: OpenWeatherHourlyForecastErrorCodes.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
    
    func parseJson(_ data: Data) -> Any?
    {
        do { return try JSONSerialization.jsonObject(with: data, options: .allowFragments) }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "Unable to parse JSON object",
                            NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "OpenWeatherHourlyForecast.parseJson",
                                code: OpenWeatherHourlyForecastErrorCodes.noData.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
}

