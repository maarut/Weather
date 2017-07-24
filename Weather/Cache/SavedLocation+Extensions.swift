//
//  SavedLocation+Extensions.swift
//  Weather
//
//  Created by Maarut Chandegra on 19/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import CoreData

extension SavedLocation
{
    convenience init(user: User, id: NSNumber?, name: String, latitude: Double, longitude: Double,
        context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entity(forEntityName: "SavedLocation", in: context)!,
            insertInto: context)
        self.user = user
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.dateAdded = NSDate()
    }
}
