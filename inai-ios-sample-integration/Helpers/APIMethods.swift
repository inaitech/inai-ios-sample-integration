//
//  APIMethods.swift
//  inai-checkout
//
//  Created by Parag Dulam on 5/3/22.
//  Refactored by Amit Yadav in 29/07/2022
//

import Foundation
import inai_ios_sdk
import UIKit

class APIMethods {
    
    private let HTTP_GET = "GET"
    private let HTTP_POST = "POST"
    
    // static property to create singleton
    static let shared = APIMethods()
    
    var base_url: String! {
        return PlistConstants.shared.baseURL
    }

    var inai_get_payment_options_url: String! {
        return "\(base_url!)/payment-method-options"
    }
    
    var inai_get_order_details_url: String! {
        return "\(base_url!)/orders"
    }
    
    var inai_get_customer_url: String! {
        return "\(base_url!)/customers"
    }
    
    var inai_prepare_order_url: String! {
        return "\(base_url!)/orders"
    }
    
    func buildQueryString(fromDictionary parameters: [String:String]) -> String {
        var urlVars:[String] = []
        for (k, value) in parameters {
            let value = value as NSString
            if let encodedValue = value.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
                urlVars.append(k + "=" + encodedValue)
            }
        }
        return urlVars.isEmpty ? "" : "?" + urlVars.joined(separator: "&")
    }
    
    func prepareOrder(completion: @escaping (String?) -> Void) {
        //  Prep postdata
        let body: [String: AnyHashable] = [
            "amount": "110",
            "currency": PlistConstants.shared.currency,
            "description": "Acme Shirt",
            "customer": ["email": "testdev@test.com",
                         "first_name": "Dev",
                         "last_name": "Smith",
                         "contact_number": "01010101010"],
            "metadata": ["test_order_id": "5735"]
        ]
        
        self.request(url: URL(string: self.inai_prepare_order_url)!,
                     method: HTTP_POST,
                     postData: body) { (data, error) in
            
            var orderId: String? = nil
            
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                if let data = data {
                    if let responseOrderId = data["id"] as? String {
                        orderId = responseOrderId
                    }
                }
            }
            
            completion(orderId)
        }
    }
    
    func getPaymentOptions(orderId: String,
                           completion: @escaping ([String: Any]?, Error?) -> Void) {
        var params: [String: String] = [:]
        params["order_id"] = orderId
        params["country"] = PlistConstants.shared.country
     
        self.request(url: URL(string: inai_get_payment_options_url + buildQueryString(fromDictionary: params))!,
                     method: HTTP_GET,
                     postData: nil,
                     completion: completion)
    }
    
    func getCustomerPayments(customerId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        self.request(url: URL(string: inai_get_customer_url + "/\(customerId)/payment-methods")!,
                     method: HTTP_GET,
                     postData: nil,
                     completion: completion)
    }
    
    private func request(url: URL, method: String,
                         postData: [String: Any]?,
                         completion: @escaping ([String: Any]?, Error?) -> Void) {
        
        let authStr = "\(PlistConstants.shared.token):\(PlistConstants.shared.password)"
        let encodedAuthStr = "BASIC \(Data(authStr.utf8).base64EncodedString())"
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        //  Set headers
        request.setValue(encodedAuthStr, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //  Attach postdata if applicable
        if let postData = postData {
            if (method == HTTP_POST) {
                request.httpBody = try? JSONSerialization.data(withJSONObject: postData, options: .fragmentsAllowed)
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, urlRequest, error in
            var result: [String: Any]? = nil
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                result = json as? [String : Any]
            }
            
            DispatchQueue.main.async {
                completion(result, error)
            }
        }
        //  Fire away
        task.resume()
    }
}
