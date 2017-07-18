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
    func process(iconData: Data)
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

// MARK: - OpenWeatherIconDownloader Implementation
class OpenWeatherIconDownloader: OpenWeatherOperationProcessor, OpenWeatherOperationRequestor
{
    fileprivate weak var resultsHandler: OpenWeatherIconProcessor?
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
    }
    
    func process(data: Data)
    {
        resultsHandler?.process(iconData: data)
    }
    
    func handle(error: NSError)
    {
        resultsHandler?.handle(error: error)
    }
}
