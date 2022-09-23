//
//  MakePaymentWithSavedMethodOptionsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk


class MakePaymentWithSavedMethodOptionsViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var paymentMethods: [MakePaymentWithSavedMethod_SavedPaymentMethod] = []
    private var orderId = ""
    private var customerId = ""
    
    var base_url: String! {
        return PlistConstants.shared.baseURL
    }
    
    var inai_prepare_order_url: String! {
        return "\(base_url!)/orders"
    }
    
    var inai_get_customer_url: String! {
        return "\(base_url!)/customers"
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
                self.customerId = savedCustomerId!
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
    
    func getCustomerPayments(customerId: String, completion: @escaping ([String: Any]?, Error?) -> Void) {
        self.request(url: URL(string: inai_get_customer_url + "/\(customerId)/payment-methods")!,
                     method: "GET",
                     postData: nil,
                     completion: completion)
    }
    
    private func processPaymentOptions() {
        activityIndicator.startAnimating()
        var payMethods: [MakePaymentWithSavedMethod_SavedPaymentMethod] = []
        self.getCustomerPayments(customerId: customerId) { (customerPayments, error) in
            guard let customerPayments = customerPayments else {
                self.activityIndicator.stopAnimating()
                self.showAlert(error?.localizedDescription ?? "")
                return
            }
            let paymentMethods = MakePaymentWithSavedMethod_SavedPaymentMethod.paymentMethodsFromJSON(customerPayments)
            payMethods.append(contentsOf: paymentMethods)
            self.paymentMethods = payMethods
            self.tbl_payment_options.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPaymentFieldsView" {
            if let vc = segue.destination as? MakePaymentWithSavedMethod_PaymentFieldsViewController {
                vc.orderId = self.orderId
                vc.selectedPaymentOption = sender as? MakePaymentWithSavedMethod_PaymentMethodOption
            }
        }
    }
}

extension MakePaymentWithSavedMethodOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let po = self.paymentMethods[indexPath.row]
        cell.textLabel?.text = sanitizePaymentMethod(po)
        return cell
    }
    
    private func sanitizePaymentMethod(_ paymentMethod: MakePaymentWithSavedMethod_SavedPaymentMethod) -> String? {
        var retVal: String? = nil
        if paymentMethod.type == "card" {
            if let cardDetails = paymentMethod.typeJSON,
               let cardName = cardDetails["brand"] as? String,
               let last4 = cardDetails["last_4"] as? String {
                retVal = "\(cardName) - \(last4)"
            }
        } else {
            retVal = sanitizeRailCode(paymentMethod.type)
        }
        return retVal
    }
    
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        activityIndicator.startAnimating()
        self.getPaymentOptions(
            orderId: self.orderId) { paymentOptions, error in
                guard let paymentOptions = paymentOptions else {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                let payOptions = MakePaymentWithSavedMethod_PaymentMethodOption.paymentOptionsFromJSON(paymentOptions)
                let payMethod = self.paymentMethods[indexPath.row]
                if var finalPayOption = payOptions.filter({ option in
                    return self.sanitizeRailCode(option.railCode) == self.sanitizeRailCode(payMethod.type)
                }).first {
                    finalPayOption.paymentMethodId = payMethod.id
                    self.activityIndicator.stopAnimating()
                    self.performSegue(withIdentifier: "ShowPaymentFieldsView", sender: finalPayOption)
                }
            }
    }
    
    func getPaymentOptions(orderId: String,
                           saved_payment_method: Bool = false,
                           completion: @escaping ([String: Any]?, Error?) -> Void) {
        var params: [String: String] = [:]
        params["order_id"] = orderId
        params["country"] = DemoConstants.country
        params["saved_payment_method"] = "true"
     
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
