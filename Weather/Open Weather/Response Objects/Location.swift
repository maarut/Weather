//
//  Location.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation

enum LocationError: Int
{
    case keyNotFound
}

struct Location
{
    static let idKey = "id"
    static let nameKey = "name"
    
    let id: Int
    let name: String
    
    init?(json: [String: AnyObject]) throws
    {
        func makeError(_ errorString: String, code: LocationError) -> NSError
        {
            return NSError(domain: "Location.init", code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: errorString])
        }
        
        guard let id = json[Location.idKey] as? Int else {
            throw makeError("Key \(Location.idKey) not found.", code: .keyNotFound)
        }
        guard let name = json[Location.nameKey] as? String else {
            throw makeError("Key \(Location.nameKey) not found.", code: .keyNotFound)
        }
        
        self.id = id
        self.name = name
    }
}
