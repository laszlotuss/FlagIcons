//
//  FlagIcons.swift
//  LastDay
//
//  Created by Mateusz Malczak on 17/09/16.
//  Copyright © 2016 The Pirate Cat. All rights reserved.
//

import Foundation
import UIKit

/**
 Represents a flags icon sprite sheet
 */
open class FlagIcons {
    
    public struct Country {
        public let name: String;
        public let code: String;
    }
    
    open class func loadDefault() -> SpriteSheet? {
        guard let assetsBundle = assetsBundle() else {
            return nil
        }
        
        if let infoFile = assetsBundle.path(forResource: "flags", ofType: "json") {
            return self.loadSheetFrom(infoFile)
        }
        
        return nil
    }
    
    open class func loadCountries() -> [Country]? {
        guard let assetsBundle = assetsBundle() else {
            return nil
        }
        
        if let dataFile = assetsBundle.path(forResource: "countries", ofType: "json") {
            if let countriesSet: [[String:String]] = loadJSON(file: dataFile) {
                return countriesSet.compactMap({countryInfo in
                    guard case let (name?, code?) = (countryInfo["name"], countryInfo["code"]) else {
                        return nil
                    }
                    return Country(name: name, code: code)
                }).sorted(by: {country1, country2 in country1.name < country2.name})
            }
        }
        
        return nil
    }
    
    open class func loadSheetFrom(_ file: String) -> SpriteSheet? {
        guard let assetsBundle = assetsBundle() else {
            return nil
        }
        
        if let infoObj: [String:Any] = loadJSON(file: file) {
            if let gridSizeObj = infoObj["gridSize"] as? [String:Int],
                let spriteSizeObj = infoObj["spriteSize"] as? [String:Int] {
                let gridSize = (gridSizeObj["cols"]!, gridSizeObj["rows"]!)
                let spriteSize = (spriteSizeObj["width"]!, spriteSizeObj["height"]!)
                
                if let codes = (infoObj["codes"] as? String)?.components(separatedBy: "|") {
                    if let sheetFileName = infoObj["sheetFile"] as? String,
                        let resourceUrl = assetsBundle.resourceURL {
                        let sheetFileUrl = resourceUrl.appendingPathComponent(sheetFileName)
                        if let image = UIImage(contentsOfFile: sheetFileUrl.path) {
                            let info = SpriteSheet.SheetInfo(gridSize: gridSize, spriteSize: spriteSize, codes: codes)
                            return SpriteSheet(sheetImage: image, info:  info)
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    fileprivate class func loadJSON<T>(file: String) -> T? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            return nil
        }
        
        let options = JSONSerialization.ReadingOptions(rawValue: 0)
        return try? JSONSerialization.jsonObject(with: data, options: options) as? T
    }

    fileprivate class func assetsBundle() -> Bundle? {
#if SWIFT_PACKAGE
        return Bundle.module
#else
        let bundle = Bundle(for: self)
        guard let assetsBundlePath = bundle.path(forResource: "assets", ofType: "bundle") else {
            return nil
        }
        return Bundle(path: assetsBundlePath)
#endif
    }
    
}
