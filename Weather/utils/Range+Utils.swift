//
//  Range+Utils.swift
//  Weather
//
//  Created by Maarut Chandegra on 17/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

public func ~=<I : Comparable>(value: I, pattern: Range<I>) -> Bool where I : Comparable
{
    return pattern ~= value
}
