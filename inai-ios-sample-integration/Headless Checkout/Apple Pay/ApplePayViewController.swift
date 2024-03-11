//
//  ApplePayViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk
import PassKit

fileprivate struct ApplePayStringError: Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    public var localizedDescription: String {
        return message
    }
}

class ApplePayViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var button_container: UIStackView!
    
    var selectedPaymentOption: ApplePay_PaymentMethodOption!

    private var orderId = ""

    private var applePayRequestData: [String:Any]?
    
    private var supportredPayments: [PKPaymentNetwork] = []
    
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
            orderId: self.orderId,
            saved_payment_method: false) { response, error in
                self.activityIndicator.stopAnimating()
                guard let respo = response else {
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                
                let payOptions = ApplePay_PaymentMethodOption.paymentOptionsFromJSON(respo)
                    .filter { self.sanitizeRailCode($0.railCode) == "Apple Pay" }
                
                if (payOptions.count == 0 ) {
                    //  Apple Pay not available
                    self.showAlert("Apple Pay not available for this account", title: "Error", completion: self.goToHomeScreen)
                    return
                }
                
                self.selectedPaymentOption = payOptions[0]
                self.initApplePayUI()
            }
    }
    
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
    
    private func initApplePayUI() {
        //  Get Apple Pay Order Information from the Inai SDK
        if let paymentMethodOptions = self.selectedPaymentOption.dict["payment_method_options"] as? [[String: Any]] {
           for paymentMethodOption: [String: Any] in paymentMethodOptions {
               if let _ = paymentMethodOption["rail_code"] {
                   let railCode = paymentMethodOption["rail_code"] as! String
                   if (railCode == "apple_pay") {
                       self.setupApplePayButton(paymentMethodOption)
                       break
                   }
               }
           }
       } else {
           // Invalid Apple Pay Request Data
           self.showAlert("Invalid Apple Pay Request Data", title: "Error", completion: self.goToHomeScreen)
       }
    }
    
    func setupApplePayButton (_ applePayRequestData: [String:Any]) {
        self.applePayRequestData = applePayRequestData
        var canMakePayments:Bool = false
        var canSetupCards:Bool = false
        let configs = applePayRequestData["configs"] as? [String:Any] ?? [:]
        let supportedNetworks = configs["supported_networks"] as? [[String:Any]] ?? []
        if #available(iOS 10.0, *) {
            canMakePayments = PKPaymentAuthorizationController.canMakePayments()
            //selected supported cards
            canSetupCards = PKPaymentAuthorizationController.canMakePayments(usingNetworks: getSupportredPayments(supportedNetworks))
        } else {
            // Fallback on earlier versions
            canMakePayments = PKPaymentAuthorizationViewController.canMakePayments()
            //selected supported cards
            canSetupCards = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: getSupportredPayments(supportedNetworks))
        }
        
        var button: UIButton?
        if canMakePayments{
            button = PKPaymentButton(paymentButtonType: .buy, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(self.payPressed), for: .touchUpInside)
        } else if canSetupCards{
            button = PKPaymentButton(paymentButtonType: .setUp, paymentButtonStyle: .black)
            button?.addTarget(self, action: #selector(self.setupPressed), for: .touchUpInside)
        }
        
        if let applePayButton = button {
            applePayButton.layer.cornerRadius = 20
            applePayButton.clipsToBounds = true
            applePayButton.translatesAutoresizingMaskIntoConstraints = false
            button_container.addSubview(applePayButton)
            applePayButton.topAnchor.constraint(equalTo: button_container.topAnchor).isActive = true
            applePayButton.leftAnchor.constraint(equalTo: button_container.leftAnchor).isActive = true
            applePayButton.rightAnchor.constraint(equalTo: button_container.rightAnchor).isActive = true
            applePayButton.bottomAnchor.constraint(equalTo: button_container.bottomAnchor).isActive = true
        }
    }

    @objc func setupPressed(sender: AnyObject) {
        let passLibrary = PKPassLibrary()
        passLibrary.openPaymentSetup()
    }
    
    @objc func payPressed(sender: Any) {
        var request = self.applePayRequestData!


        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                countryCode: DemoConstants.country)

        if let inaiCheckout = InaiCheckout(config: config) {

            inaiCheckout.makePayment( paymentMethodOption: "apple_pay",
                                      paymentDetails: request,
                                      viewController: self,
                                      delegate: self)
        }
    }
    
    private func goToHomeScreen(action: UIAlertAction) -> Void {
        self.navigationController?.popToRootViewController(animated: true)
    }
     
    func getPaymentOptions(orderId: String,
                           saved_payment_method: Bool = false,
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
    
}


extension ApplePayViewController: InaiCheckoutDelegate {
    func getSupportredPayments(_ cardOptions:[[String:Any]]) ->  [PKPaymentNetwork] {
        var supportedPayments = [PKPaymentNetwork]()
        for cardOption in cardOptions {
            if (cardOption["name"] as? String)?.lowercased() == "amex"{
                supportedPayments.append(.amex)
            }else if (cardOption["name"] as? String)?.lowercased() == "cartesbancaires"{
                supportedPayments.append(.cartesBancaires)
            }else if (cardOption["name"] as? String)?.lowercased() == "chinaunionpay"{
                supportedPayments.append(.chinaUnionPay)
            }else if (cardOption["name"] as? String)?.lowercased() == "discover"{
                supportedPayments.append(.discover)
            }else if (cardOption["name"] as? String)?.lowercased() == "eftpos"{
                supportedPayments.append(.eftpos)
            }else if (cardOption["name"] as? String)?.lowercased() == "electron"{
                supportedPayments.append(.electron)
            }else if (cardOption["name"] as? String)?.lowercased() == "elo"{
                supportedPayments.append(.elo)
            }else if (cardOption["name"] as? String)?.lowercased() == "girocard"{
                if #available(iOS 14.0, *) {
                    supportedPayments.append(.girocard)
                }
            }else if (cardOption["name"] as? String)?.lowercased() == "interac"{
                supportedPayments.append(.interac)
            }else if (cardOption["name"] as? String)?.lowercased() == "mada"{
                supportedPayments.append(.mada)
            }else if (cardOption["name"] as? String)?.lowercased() == "maestro"{
                supportedPayments.append(.maestro)
            }else if (cardOption["name"] as? String)?.lowercased() == "mastercard"{
                supportedPayments.append(.masterCard)
            }else if (cardOption["name"] as? String)?.lowercased() == "mir"{
                if #available(iOS 14.5, *) {
                    supportedPayments.append(.mir)
                }
            }else if (cardOption["name"] as? String)?.lowercased() == "privatelabel"{
                supportedPayments.append(.privateLabel)
            }else if (cardOption["name"] as? String)?.lowercased() == "visa"{
                supportedPayments.append(.visa)
            }else if (cardOption["name"] as? String)?.lowercased() == "vpay"{
                supportedPayments.append(.vPay)
            }
        }
        return supportedPayments
    }
    
    func paymentFinished(with result: Inai_PaymentResult) {
        switch result.status {
        case Inai_PaymentStatus.success:
            let resultStr = convertDictToStr(result.data)
            self.showAlert("Payment Success! \(resultStr)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.failed:
            let strError = convertDictToStr(result.data)
            let error = ApplePayStringError(strError);
            self.showAlert("Payment Failed with data: \(strError)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.canceled:
            let error = ApplePayStringError("Payment Canceled");
            let message = result.data["message"] ?? "Payment Canceled!"
            self.showAlert(message as! String, title: "Result", completion: goToHomeScreen)
            break
        @unknown default:
            break;
        }
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
