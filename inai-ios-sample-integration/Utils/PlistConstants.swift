//
//  PlistConstants.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 29/07/22.
//


import Foundation

class PlistConstants {
  
    var token: String = ""
    var baseURL: String = ""
    
    // static property to create singleton
    static let shared = PlistConstants()
    
    // create a private initializer
    private init() {
        if let variables = getVariables() {
            self.token = variables["token"] as? String ?? ""
            self.baseURL = variables["base_url"] as? String ?? ""
        }
    }
    
    func getVariables() -> [String: Any]? {
        var propertyListFormat =  PropertyListSerialization.PropertyListFormat.xml
        var plistData: [String: AnyObject] = [:] //Our data
        let plistPath: String? = Bundle.main.path(forResource: "config", ofType: "plist")!
        let plistXML = FileManager.default.contents(atPath: plistPath!)!
        do {
            plistData = try PropertyListSerialization.propertyList(from: plistXML, options: .mutableContainersAndLeaves, format: &propertyListFormat) as! [String:AnyObject]
            return plistData
        } catch {
            print("Error reading plist: \(error), format: \(propertyListFormat)")
        }
        return nil
    }
}

