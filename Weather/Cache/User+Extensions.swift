//
//  User+Extensions.swift
//  Weather
//
//  Created by Maarut Chandegra on 23/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

import Foundation
import CoreData

extension User
{
    convenience init(userName: String, password: String, context: NSManagedObjectContext)
    {
        self.init(entity: NSEntityDescription.entity(forEntityName: "User", in: context)!,
            insertInto: context)
        self.name = userName
        self.password = password
    }
}
