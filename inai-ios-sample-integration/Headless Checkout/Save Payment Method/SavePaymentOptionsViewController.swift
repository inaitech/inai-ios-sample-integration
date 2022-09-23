//
//  SavePaymentOptionsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class SavePaymentOptionsViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        
    private var selectedPaymentOption: SavePayment_PaymentMethodOption?
    private var paymentOptions: [SavePayment_PaymentMethodOption] = []
    private var orderId = ""
    
    var base_url: String! {
        return PlistConstants.shared.baseURL
    }
    
    var inai_prepare_order_url: String! {
        return "\(base_url!)/orders"
    }
    
    var inai_get_payment_options_url: String! {
        return "\(base_url!)/payment-method-options"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareOrder()
    }
    
    private func prepareOrder() {
        //  Initiate a new order
        self.activityIndicator.startAnimating()
        
        //  Prep postdata
        let Customer_ID_Key = "customerId-\(PlistConstants.shared.token)"
        var savedCustomerId: String? = UserDefaults.standard.string(forKey: Customer_ID_Key) ?? nil

        var body: [String: AnyHashable] = [
            "amount": DemoConstants.amount,
            "currency": DemoConstants.currency,
            "description": "Acme Shirt",
            "metadata": ["test_order_id": "5735"]
        ]
        
        if let savedCustomerId = savedCustomerId {
            //  Lets reuse the existing customer
            body["customer"] =  [ "id": savedCustomerId]
        } else {
            //  Create a new customer
            body["customer"] = ["email": "testdev@test.com",
                                 "first_name": "Dev",
                                 "last_name": "Smith",
                                 "contact_number": "01010101010"]
        }

        body["capture_method"] = "MANUAL"

        self.request(url: URL(string: self.inai_prepare_order_url)!,
                     method: "POST",
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
                    
                    if savedCustomerId == nil {
                        if let customerId = data["customer_id"] as? String {
                            //  Save customer id to defaults so we can reuse it
                            savedCustomerId = customerId
                            UserDefaults.standard.set(customerId, forKey: Customer_ID_Key)
                        }
                    }
                }
            }
             
            self.activityIndicator.stopAnimating()
            if let orderId = orderId {
                self.orderId = orderId
                self.processPaymentOptions()
            }
        }
    }
    
    private func request(url: URL, method: String,
                         postData: [String: Any]?,
                         completion: @escaping ([String: Any]?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        //  Set headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //  Attach postdata if applicable
        if let postData = postData {
            request.httpBody = try? JSONSerialization.data(withJSONObject: postData, options: .fragmentsAllowed)
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
    
    private func processPaymentOptions() {
        self.activityIndicator.startAnimating()
        
        self.getPaymentOptions(
            orderId: self.orderId) { response, error in
                self.activityIndicator.stopAnimating()
                guard let respo = response else {
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                
                //  Lets render all options to save except Apply Pay
                let paymentOptions = SavePayment_PaymentMethodOption.paymentOptionsFromJSON(respo)
                                    .filter { self.sanitizeRailCode($0.railCode) != "Apple Pay" }
                
                self.paymentOptions = paymentOptions
                self.tbl_payment_options.reloadData()
            }
    }
    
    func getPaymentOptions(orderId: String,
                           completion: @escaping ([String: Any]?, Error?) -> Void) {
        var params: [String: String] = [:]
        params["order_id"] = orderId
        params["country"] = DemoConstants.country
        
        self.request(url: URL(string: inai_get_payment_options_url + buildQueryString(fromDictionary: params))!,
                     method: "GET",
                     postData: nil,
                     completion: completion)
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSavePaymentFieldsView" {
            if let vc = segue.destination as? SavePayment_PaymentFieldsViewController {
                vc.orderId = self.orderId
                vc.selectedPaymentOption = sender as? SavePayment_PaymentMethodOption
            }
        }
    }
}

extension SavePaymentOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let po = self.paymentOptions[indexPath.row]
        cell.textLabel?.text = sanitizeRailCode(po.railCode)
        return cell
    }
    
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowSavePaymentFieldsView", sender: self.paymentOptions[indexPath.row])
    }
    
    func showAlert(_ message: String, title: String = "Alert", completion: ((UIAlertAction) -> Void)? = nil ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: completion))
        self.present(alert, animated: true, completion: nil)
    }
    
    func convertDictToStr(_ dict: [String:Any]) -> String {
        var jsonStr = "";
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
            jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch {}
        
        return jsonStr
    }
    
    func convertStrToDict(_ text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
