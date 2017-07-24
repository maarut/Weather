//
//  OpenWeatherUnit.swift
//  Weather
//
//  Created by Maarut Chandegra on 22/07/2017.
//  Copyright © 2017 Maarut Chandegra. All rights reserved.
//

// MARK: - OpenWeatherUnit Enum
enum OpenWeatherUnit
{
    init(number: Int)
    {
        switch number {
        case 0:     self = .celcius
        case 1:     self = .fahrenheit
        default:    self = .kelvin
        }
    }
    
    case kelvin
    case celcius
    case fahrenheit
}
