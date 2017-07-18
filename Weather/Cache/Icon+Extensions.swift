//
//  Icon+Extensions.swift
//  Weather
//
//  Created by Maarut Chandegra on 18/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreData

extension Icon
{
    convenience init(id: String, data: Data, context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Icon", in: context)!,
            insertInto: context)
        self.id = id
        self.data = data as NSData
    }
}
