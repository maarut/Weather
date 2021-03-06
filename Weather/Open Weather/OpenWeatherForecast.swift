//
//  OpenWeatherForecast.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - OpenWeatherForecastResultsProcessor Protocol
protocol OpenWeatherForecastResultsProcessor: class
{
    func process(forecast: Forecast)
    func handle(error: NSError)
}

// MARK: - OpenWeatherForecastErrorCodes Enum
enum OpenWeatherForecastErrorCodes: Int
{
    case jsonParse
    case noData
}

// MARK: - OpenWeatherForecastCriteria Struct
struct OpenWeatherForecastCriteria
{
    let latitude: Double
    let longitude: Double
    let id: Int64?
    let units: OpenWeatherUnit
    let count: Int
    
    init(latitude: Double, longitude: Double, units: OpenWeatherUnit, count: Int)
    {
        self.latitude = latitude
        self.longitude = longitude
        self.count = count
        self.units = units
        self.id = nil
    }
    
    init(id: Int64, units: OpenWeatherUnit, count: Int)
    {
        latitude = Double.infinity
        longitude = Double.infinity
        self.count = count
        self.units = units
        self.id = id
        
    }
}

class OpenWeatherForecast: OpenWeatherOperationRequestor, OpenWeatherOperationProcessor
{
    fileprivate weak var resultsHandler: OpenWeatherForecastResultsProcessor?
    fileprivate let _request: URLRequest
    var request: URLRequest { return _request }
    
    init(searchCriteria: OpenWeatherForecastCriteria, resultsHandler: OpenWeatherForecastResultsProcessor)
    {
        let unit: String
        switch searchCriteria.units {
        case .metric:   unit = "metric"
        case .imperial: unit = "imperial"
        case .kelvin:   unit = ""
        }
        let parameters: [String: Any]
        if let id = searchCriteria.id {
            parameters = ["id": id as NSNumber, "cnt": searchCriteria.count as NSNumber, "units": unit]
        }
        else {
            parameters = [
                "lat": searchCriteria.latitude as NSNumber,
                "lon": searchCriteria.longitude as NSNumber,
                "cnt": searchCriteria.count as NSNumber,
                "units": unit
            ]
        }
        _request = URLRequest(url: OpenWeatherURL(method: "forecast/daily", parameters: parameters).url as URL)
        self.resultsHandler = resultsHandler
    }
    
    func process(data: Data)
    {
        guard let parsedJson = parseJson(data) else { return }
        guard let json = parsedJson as? [String: AnyObject] else {
            let userInfo = [NSLocalizedDescriptionKey: "Returned data could not be formatted in to JSON."]
            let error = NSError(domain: "OpenWeatherForecast.processData",
                code: OpenWeatherForecastErrorCodes.jsonParse.rawValue, userInfo: userInfo)
            handle(error: error)
            return
        }
        if let forecast = parseForecast(json) { resultsHandler?.process(forecast: forecast) }
    }
    
    func handle(error: NSError)
    {
        resultsHandler?.handle(error: error)
    }

}

// MARK: - OpenWeatherForecast Private Methods
private extension OpenWeatherForecast
{
    func parseForecast(_ data: [String: AnyObject]) -> Forecast?
    {
        do { return try Forecast(json: data) }
        catch let error as NSError {
            let userInfo = [NSLocalizedDescriptionKey: "JSON response could not be parsed.",
                NSUnderlyingErrorKey: error] as [String : Any]
            let error = NSError(domain: "OpenWeatherForecast.processData",
                code: OpenWeatherForecastErrorCodes.jsonParse.rawValue, userInfo: userInfo)
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
            let error = NSError(domain: "OpenWeatherForecast.parseJson",
                code: OpenWeatherForecastErrorCodes.noData.rawValue, userInfo: userInfo)
            handle(error: error)
        }
        return nil
    }
}
