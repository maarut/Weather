//
//  OpenWeatherClient.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

class OpenWeatherClient
{
    fileprivate let networkOperationQueue = OperationQueue()
    
    static let instance = OpenWeatherClient()
    
    fileprivate init() { }
    
    func retrieveForecast(searchCriteria: OpenWeatherForecastCriteria,
        resultsProcessor: OpenWeatherForecastResultsProcessor)
    {
        let operation = OpenWeatherForecast(searchCriteria: searchCriteria, resultsHandler: resultsProcessor)
        let networkOp = OpenWeatherOperation(processor: operation, requestor: operation)
        networkOperationQueue.addOperation(networkOp)
    }
    
    func downloadIcon(crieria: OpenWeatherIconDownloaderCriteria, resultsProcessor: OpenWeatherIconProcessor)
    {
        let operation = OpenWeatherIconDownloader(criteria: crieria, resultsHandler: resultsProcessor)
        let networkOp = OpenWeatherOperation(processor: operation, requestor: operation)
        networkOperationQueue.addOperation(networkOp)
    }
}
