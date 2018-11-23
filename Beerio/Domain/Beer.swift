//
//  Beer.swift
//  Beerio
//
//  Created by Casper Verswijvelt on 21/11/2018.
//  Copyright © 2018 Casper Verswijvelt. All rights reserved.
//

import Foundation

class Beer : Codable{
    var id: String
    var name: String
    var description: String?
    var foodPairings: String?
    var originalGravity: String?
    var alcoholByVolume: String? //abv
    var internationalBitteringUnit: String? //ibu
    var isRetired: String?
    var glass: Glass?
    var isOrganic: String?
    var labels : Labels?
    var servingTemperature : String? //servingTemperatureDisplay
    var status : String?
    var year: Int?
    
    
    func getValues() -> [BeerSectionInfo] {
        var sections : [BeerSectionInfo] = []
        
        //Section with basic info (name and description)
        var basicInfo = BeerSectionInfo(header: "Basic info", cells: [])
        basicInfo.cells.append(BeerCellInfo(key: "Name", value: name, cellType: .SIMPLE,url:nil))
        basicInfo.cells.appendCellIfValueIsPresent(key: "Description", value: description, cellType : .LARGE,url:nil)
        
        //Section with numbers and stuff
        var numbers = BeerSectionInfo(header: "Numbers and stuff", cells: [])
        numbers.cells.appendCellIfValueIsPresent(key: "Original Gravity", value: originalGravity, cellType: .SIMPLE,url:nil)
        numbers.cells.appendCellIfValueIsPresent(key: "Alcohol By Volume", value: alcoholByVolume, cellType: .SIMPLE,url:nil)
        numbers.cells.appendCellIfValueIsPresent(key: "International Bittering Unit", value: internationalBitteringUnit, cellType: .SIMPLE, url:nil)
        numbers.cells.appendCellIfValueIsPresent(key: "Serving Temperature", value: servingTemperature, cellType: .SIMPLE,url:nil)
        
        //Section about other random stuff
        var random = BeerSectionInfo(header: "Other", cells: [])
        random.cells.appendCellIfValueIsPresent(key: "Food Pairings", value: foodPairings, cellType: CellType.LARGE,url:nil)
        random.cells.appendCellIfValueIsPresent(key: "Is still made", value: isRetired, cellType: CellType.SIMPLE,url:nil)
        random.cells.appendCellIfValueIsPresent(key: "Is organic", value: isOrganic, cellType: CellType.SIMPLE,url:nil)
        random.cells.appendCellIfValueIsPresent(key: "Year", value: year, cellType: CellType.SIMPLE,url:nil)
        random.cells.appendCellIfValueIsPresent(key: "Bottle Label", value: "Show image", cellType: CellType.IMAGE, url: labels?.large)
        
        
        
        
        sections.appendSectionIfHasCells(basicInfo)
        sections.appendSectionIfHasCells(numbers)
        sections.appendSectionIfHasCells(random)
        
        
        return sections
    }
    
    
    private enum CodingKeys : String, CodingKey {
        case id
        case name
        case description
        case foodPairings
        case originalGravity
        case alcoholByVolume = "abv"
        case internationalBitteringUnit = "ibu"
        case isRetired
        case glass
        case isOrganic
        case labels
        case servingTemperature = "servingTemperatureDisplay"
        case status
        case year
    }
    
    
    
    
}

class Beers : Codable {
    var beers : [Beer]?
    
    private enum CodingKeys : String, CodingKey {
        case beers = "data"
    }
}

extension Array where Iterator.Element == BeerSectionInfo  {
    mutating func appendSectionIfHasCells(_ section : BeerSectionInfo) {
        if(section.cells.count != 0) {
            self.append(section)
        }
    }
}

extension Array where Iterator.Element == BeerCellInfo  {
    mutating func appendCellIfValueIsPresent(key: String, value: Any?, cellType: CellType, url: URL?) {
        if let value = value {
            var beerCellInfo = BeerCellInfo(key: key, value: nil, cellType: cellType, url: url)
            if let value = value as? String {
                beerCellInfo.value = value
            }
            if let value = value as? Int {
                beerCellInfo.value = String(value)
            }
            if !(cellType == .IMAGE && url == nil) {
                self.append(beerCellInfo)
            }
        }
    }
}
