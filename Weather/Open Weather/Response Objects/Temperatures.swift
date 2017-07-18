//
//  Temperatures.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

enum TemperaturesError: Int
{
    case keyNotFound
}

struct Temperatures
{
    static let dayKey = "day"
    static let minKey = "min"
    static let maxKey = "max"
    static let nightKey = "night"
    static let eveningKey = "eve"
    static let morningKey = "morn"
    
    let day: Double
    let min: Double
    let max: Double
    let night: Double
    let evening: Double
    let morning: Double
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: TemperaturesError) -> NSError
        {
            return NSError(domain: "Temperatures.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let day = json[Temperatures.dayKey] as? Double else {
            throw makeError("Key \(Temperatures.dayKey) not found.", code: .keyNotFound)
        }
        guard let min = json[Temperatures.minKey] as? Double else {
            throw makeError("Key \(Temperatures.minKey) not found.", code: .keyNotFound)
        }
        guard let max = json[Temperatures.maxKey] as? Double else {
            throw makeError("Key \(Temperatures.maxKey) not found.", code: .keyNotFound)
        }
        guard let night = json[Temperatures.nightKey] as? Double else {
            throw makeError("Key \(Temperatures.nightKey) not found.", code: .keyNotFound)
        }
        guard let evening = json[Temperatures.eveningKey] as? Double else {
            throw makeError("Key \(Temperatures.eveningKey) not found.", code: .keyNotFound)
        }
        guard let morning = json[Temperatures.morningKey] as? Double else {
            throw makeError("Key \(Temperatures.morningKey) not found.", code: .keyNotFound)
        }
        self.day = day
        self.min = min
        self.max = max
        self.night = night
        self.evening = evening
        self.morning = morning
    }
    
}
