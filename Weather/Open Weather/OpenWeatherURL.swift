//
//  OpenWeatherURL.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

class OpenWeatherURL
{
    let url: URL
    
    init(method: String, parameters: [String: Any])
    {
        let url = NSURLComponents()
        url.scheme = OpenWeatherConstants.API.Scheme
        url.host = OpenWeatherConstants.API.Host
        url.path = "\(OpenWeatherConstants.API.Path)/\(method)"
        
        url.queryItems = parameters.map { URLQueryItem(name: $0, value: "\($1)") }
        url.queryItems!.append(URLQueryItem(name: OpenWeatherConstants.ParameterKeys.appId,
            value: OpenWeatherConstants.API.Key))
        
        self.url = url.url!
    }
}
