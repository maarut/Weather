//
//  OpenWeatherConstants.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

struct OpenWeatherConstants
{
    struct API
    {
        static let Scheme = "http"
        static let Host = "api.openweathermap.org"
        static let Path = "/data/2.5"
        static let Key = kOpenWeatherAPIKey
    }
    
    struct ParameterKeys
    {
        static let appId = "appid"
    }
}
