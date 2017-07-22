//
//  Wind.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

// MARK: - WindError Enum
enum WindError: Int
{
    case keyNotFound
}

// MARK: - Wind Implementation
// list.wind
struct Wind
{
    static let windSpeedKey = "speed"
    static let windDirectionKey = "deg"
    
    let speed: Double
    let direction: Double
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: WindError) -> NSError
        {
            return NSError(domain: "Wind.init", code: code.rawValue,
                           userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let speed = json[Wind.windSpeedKey] as? Double else {
            throw makeError("Key \(Wind.windSpeedKey) not found.", code: .keyNotFound)
        }
        guard let direction = json[Wind.windDirectionKey] as? Double else {
            throw makeError("Key \(Wind.windDirectionKey) not found.", code: .keyNotFound)
        }
        
        self.speed = speed
        self.direction = direction
    }
}
