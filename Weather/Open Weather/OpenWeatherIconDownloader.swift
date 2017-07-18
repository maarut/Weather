//
//  OpenWeatherIconDownloader.swift
//  Weather
//
//  Created by Maarut Chandegra on 18/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - OpenWeatherIconProcessor Protocol
protocol OpenWeatherIconProcessor: class
{
    func process(icon: OpenWeatherIcon)
    func handle(error: NSError)
}

// MARK: - OpenWeatherIconDownloaderErrorCodes Enum
enum OpenWeatherIconDownloaderErrorCodes
{
    case noData
}

// MARK: - OpenWeatherIconDownloaderCriteria Struct
struct OpenWeatherIconDownloaderCriteria
{
    let iconName: String
}

// MARK: - OpenWeatherIcon Struct
struct OpenWeatherIcon
{
    let iconName: String
    let icon: Data
}

// MARK: - OpenWeatherIconDownloader Implementation
class OpenWeatherIconDownloader: OpenWeatherOperationProcessor, OpenWeatherOperationRequestor
{
    fileprivate weak var resultsHandler: OpenWeatherIconProcessor?
    fileprivate let iconName: String
    fileprivate let _request: URLRequest
    var request: URLRequest { return _request }
    
    init(criteria: OpenWeatherIconDownloaderCriteria, resultsHandler: OpenWeatherIconProcessor)
    {
        var urlComponents = URLComponents()
        urlComponents.scheme = OpenWeatherConstants.API.Scheme
        urlComponents.host = "openweathermap.org"
        urlComponents.path = "/img/w/\(criteria.iconName).png"
        _request = URLRequest(url: urlComponents.url!)
        self.resultsHandler = resultsHandler
        self.iconName = criteria.iconName
    }
    
    func process(data: Data)
    {
        resultsHandler?.process(icon: OpenWeatherIcon(iconName: iconName, icon: data))
    }
    
    func handle(error: NSError)
    {
        resultsHandler?.handle(error: error)
    }
}
