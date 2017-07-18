//
//  WeatherDescription.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

// MARK: - WeatherDescriptionError Enum
enum WeatherDescriptionError: Int
{
    case keyNotFound
}

// MARK: - WeatherDescription
// response - list.weather
struct WeatherDescription
{
    static let idKey = "id"
    static let mainKey = "main"
    static let descriptionKey = "description"
    static let iconKey = "icon"
    
    let id: Int
    let main: String
    let description: String
    let icon: String
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: WeatherDescriptionError) -> NSError
        {
            return NSError(domain: "Weather.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let id = json[WeatherDescription.idKey] as? Int else {
            throw makeError("Key \(WeatherDescription.idKey) not found.", code: .keyNotFound)
        }
        guard let main = json[WeatherDescription.mainKey] as? String else {
            throw makeError("Key \(WeatherDescription.mainKey) not found.", code: .keyNotFound)
        }
        guard let description = json[WeatherDescription.descriptionKey] as? String else {
            throw makeError("Key \(WeatherDescription.descriptionKey) not found.", code: .keyNotFound)
        }
        guard let icon = json[WeatherDescription.iconKey] as? String else {
            throw makeError("Key \(WeatherDescription.iconKey) not found.", code: .keyNotFound)
        }
        
        self.id = id
        self.main = main
        self.description = description
        self.icon = icon
    }
}
