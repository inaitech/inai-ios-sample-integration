//
//  MakePaymentViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class MakePaymentViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: AutoSizingTableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var paymentOptions: [MakePayment_PaymentMethodOptionIndia] = []
    private var orderId = ""
    var selectedPaymentMode:MakePayment_Mode!
    var selectedPaymentFormField:MakePayment_FormField!
    
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
        self.tbl_payment_options.register(UINib(nibName: "MakePayment_PaymentFieldOptionsTableViewCell", bundle: nil), forCellReuseIdentifier: "MakePayment_PaymentFieldOptionsTableViewCell")
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
                                "contact_number": "8884609010"]
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
        request.setValue("Basic Y2lfNGVjNUVLeUtyNmhLSG81RXJKTnAyN3pIY0FialBZdnpyRUJyaTlmUEJod2Q6Y3NfNTU3ampOd3NBNFNrU1BtUmV1VHFWWVZhTWVxVXFHR1FvYlZueXRLR1NidDk=", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //  Attach postdata if applicable
        if let postData = postData {
            request.httpBody = try? JSONSerialization.data(withJSONObject: postData, options: .fragmentsAllowed)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, urlRequest, error in
            var result: [String: Any]? = nil
            print(data!)
            print(String(data: data!, encoding: .utf8))
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
                
                //  Lets render all payment options except Apply Pay as its handled separately
                self.paymentOptions = MakePayment_PaymentMethodOptionIndia.paymentOptionsFromJSON(respo)
   
                for (indx,paymentOption) in self.paymentOptions.enumerated(){
                    self.paymentOptions[indx].paymentOptions = paymentOption.paymentOptions.filter({ $0.railCode != "Apple Pay" })
                }
                print(respo)
                print(self.paymentOptions)
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
    
}

extension MakePaymentViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.paymentOptions.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.paymentOptions[section].category?.lowercased() == "wallet"{
            return 1
        }else{
            return self.paymentOptions[section].paymentOptions.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if self.paymentOptions[indexPath.section].category?.lowercased() == "upi"{
            let selectedPaymentOption  = self.paymentOptions[indexPath.section].paymentOptions[indexPath.row]
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MakePayment_PaymentFieldOptionsTableViewCell") as? MakePayment_PaymentFieldOptionsTableViewCell else {return UITableViewCell()}
            cell.prePopulateCell(cellInfo:selectedPaymentOption, viewController: self,orderId: self.orderId )
            cell.payDelegate = { _ in
                self.processCheckout(railCode:selectedPaymentOption.railCode ?? "")
            }
            cell.updatedSelectedMode = { paymentMode,value in
                if paymentMode.code == "upi_intent"{
                    self.selectedPaymentMode = paymentMode
                    self.selectedPaymentFormField = value
                    self.tbl_payment_options.contentSize = self.tbl_payment_options.intrinsicContentSize
                    self.tbl_payment_options.reloadData()
                }else{
                    guard let makePaymentFieldsVC = self.storyboard?.instantiateViewController(identifier: "MakePayment_PaymentFieldsViewController") as? MakePayment_PaymentFieldsViewController else {return }
                    makePaymentFieldsVC.orderId = self.orderId
                    var optionsPayment = self.paymentOptions[indexPath.section].paymentOptions[indexPath.row]
                    optionsPayment.modes = optionsPayment.modes.filter({$0.code == "upi_collect"})
                    makePaymentFieldsVC.selectedPaymentOption = optionsPayment
                    self.navigationController?.pushViewController(makePaymentFieldsVC, animated: false)
                }
                
            }
            return cell
        }else if self.paymentOptions[indexPath.section].category?.lowercased() == "wallet"{
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            let po = self.paymentOptions[indexPath.section]
            cell.contentView.layer.cornerRadius = 8
            cell.contentView.dropShadow(color: .black, opacity: 0.1, offSet: CGSize(width: -1, height: 1), radius: 8, scale: true)
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            cell.textLabel?.text = sanitizeRailCode(po.category)
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            let po = self.paymentOptions[indexPath.section].paymentOptions[indexPath.row]
            cell.contentView.layer.cornerRadius = 8
            cell.contentView.dropShadow(color: .black, opacity: 0.1, offSet: CGSize(width: -1, height: 1), radius: 8, scale: true)
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            cell.textLabel?.text = sanitizeRailCode(po.railCode)
            return cell
        }
    }
    
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.paymentOptions[indexPath.section].category?.lowercased() == "upi" {
            
        }else if self.paymentOptions[indexPath.section].category?.lowercased() == "netbanking" {
            let makePaymentNBVC = MakePayment_NBViewController()
            makePaymentNBVC.orderId = self.orderId
            makePaymentNBVC.paymentOptions = self.paymentOptions[indexPath.section].paymentOptions[indexPath.row]
            self.navigationController?.pushViewController(makePaymentNBVC, animated: false)
        }else if self.paymentOptions[indexPath.section].category?.lowercased() == "wallet" {
            let makePaymentNBVC = MakePayment_WalletViewController()
            makePaymentNBVC.orderId = self.orderId
            makePaymentNBVC.paymentOptions = self.paymentOptions[indexPath.section].paymentOptions
            self.navigationController?.pushViewController(makePaymentNBVC, animated: false)
        }else{
            guard let makePaymentFieldsVC = self.storyboard?.instantiateViewController(identifier: "MakePayment_PaymentFieldsViewController") as? MakePayment_PaymentFieldsViewController else {return }
            makePaymentFieldsVC.orderId = self.orderId
            makePaymentFieldsVC.selectedPaymentOption = self.paymentOptions[indexPath.section].paymentOptions[indexPath.row]
            self.navigationController?.pushViewController(makePaymentFieldsVC, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionHolderView = UIView()
        
        let sectionTitleLbl = UILabel()
        let po = self.paymentOptions[section]
        sectionHolderView.addSubview(sectionTitleLbl)
        
        sectionTitleLbl.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sectionTitleLbl.topAnchor.constraint(equalTo: sectionHolderView.topAnchor,constant: 12),
            sectionTitleLbl.bottomAnchor.constraint(equalTo: sectionHolderView.bottomAnchor,constant: -12),
            sectionTitleLbl.leftAnchor.constraint(equalTo: sectionHolderView.leftAnchor,constant: 12),
            sectionTitleLbl.rightAnchor.constraint(equalTo: sectionHolderView.rightAnchor,constant: -12)
        ])
        
        sectionTitleLbl.text = sanitizeRailCode(po.category)?.uppercased()
        
        sectionTitleLbl.textColor = .black
        
        sectionTitleLbl.font = UIFont.systemFont(ofSize: 14)
        
        return sectionHolderView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
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
    private func processCheckout(railCode:String) {
        var paymentDetails = [String:Any]()
        if let _ = self.selectedPaymentMode, let _ = self.selectedPaymentFormField{
            paymentDetails = generatePaymentDetailsForPaymenMode(selectedMode:self.selectedPaymentMode!, selectedPaymentFormField : self.selectedPaymentFormField!)
        }
        print(paymentDetails)
        self.pay(token: PlistConstants.shared.token,
                 paymentDetails: paymentDetails,
                 orderId: self.orderId,
                 countryCode: DemoConstants.country,
                 paymentMethodOption: railCode,
                 viewController: self)
    }
    private func generatePaymentDetailsForPaymenMode(selectedMode:MakePayment_Mode, selectedPaymentFormField : MakePayment_FormField) -> [String:Any]{
        var paymentDetails = [String:Any]()
        var fieldsArray: [[String: Any]] = []
        fieldsArray.append(["name":selectedPaymentFormField.name!,"value":selectedPaymentFormField.value])
        paymentDetails["fields"] = fieldsArray
        paymentDetails["mode"] = selectedMode.code
        return paymentDetails
    }
    private func pay(token: String, paymentDetails: [String: Any],
                     orderId: String, countryCode: String, paymentMethodOption: String,
                     viewController: UIViewController & InaiCheckoutDelegate) {
        let styles = InaiConfig_Styles(
            container: InaiConfig_Styles_Container(backgroundColor: "#fff"),
            cta: InaiConfig_Styles_Cta(backgroundColor: "#123456"),
            errorText: InaiConfig_Styles_ErrorText(color: "#000000")
        )
        
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                styles: styles,
                                countryCode: DemoConstants.country
        )
        
        if let inaiCheckout = InaiCheckout(config: config) {
            print(paymentDetails)
            inaiCheckout.makePayment(paymentMethodOption: paymentMethodOption,
                                     paymentDetails: paymentDetails,
                                     viewController: viewController,
                                     delegate: viewController)
        }
    }
}


extension MakePaymentViewController: InaiCheckoutDelegate {
    
    private func goToHomeScreen(action: UIAlertAction) -> Void {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func paymentFinished(with result: Inai_PaymentResult) {
        switch result.status {
        case Inai_PaymentStatus.success:
            let resultStr = convertDictToStr(result.data)
            self.showAlert("Payment Success! \(resultStr)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.failed:
            let strError = convertDictToStr(result.data)
            self.showAlert("Payment Failed with data: \(strError)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.canceled:
            let message = result.data["message"] ?? "Payment Canceled!"
            self.showAlert(message as! String, title: "Result", completion: goToHomeScreen)
            break
        @unknown default:
            break;
        }
    }
}

extension UIView {
    
    // OUTPUT 1
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
}
