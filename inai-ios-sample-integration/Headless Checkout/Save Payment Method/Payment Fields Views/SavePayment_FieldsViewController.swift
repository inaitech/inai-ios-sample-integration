//
//  SavePayment_PaymentFieldsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/3/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class SavePayment_PaymentFieldsViewController: UIViewController {
    
    var savePaymentMethod: Bool = false
    var selectedPaymentOption: SavePayment_PaymentMethodOption!
    var orderId: String!
    
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tbl_inputs: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupKeyboardEvents(scrollView: self.tbl_inputs, view: self.view)
        tbl_inputs.separatorStyle = .none
        
        if (selectedPaymentOption.railCode == "card") {
            //  Lets not render the save card field as it will always be passed
            self.selectedPaymentOption.formFields = self.selectedPaymentOption.formFields
                .filter { $0.name != "save_card" }
        }
    }
    
    func setupKeyboardEvents(scrollView: UIScrollView, view: UIView) {
        self.scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        self.scrollViewBottomConstraint?.priority = .defaultHigh
        self.scrollViewBottomConstraint?.isActive = true
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.notifyKeyboardWillChange),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: .none)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.notifyKeyboardWillHide),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }
    
    @objc func notifyKeyboardWillChange(_ notification: NSNotification){
        
        let userInfo:NSDictionary = notification.userInfo! as NSDictionary
        let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
        let keyboardRectangle = keyboardFrame.cgRectValue
        let keyboardHeight = keyboardRectangle.height
        //  Offset scrollview accordingly..
        self.scrollViewBottomConstraint?.constant = -keyboardHeight
    }
    
    @objc func notifyKeyboardWillHide(_ notification: NSNotification){
        self.scrollViewBottomConstraint?.constant = 0
    }
    
    @objc func checkoutButtonTapped(_ btn: UIButton) {
        self.view.endEditing(true)
        self.processCheckout()
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
            inaiCheckout.makePayment(paymentMethodOption: paymentMethodOption,
                                     paymentDetails: paymentDetails,
                                     viewController: viewController,
                                     delegate: viewController)
        }
    }
    
    private func generatePaymentDetails(selectedPaymentOption: SavePayment_PaymentMethodOption!) -> [String: Any] {
        var paymentDetails = [String:Any]()
        var fieldsArray: [[String: Any]] = []
        for f in selectedPaymentOption.formFields {
            fieldsArray.append(["name":f.name!, "value": f.value as Any])
        }
        fieldsArray.append(["name":"save_card", "value": true])
        paymentDetails["fields"] = fieldsArray
        if let paymentMethodId = selectedPaymentOption.paymentMethodId {
            paymentDetails["paymentMethodId"] = paymentMethodId
        }
        return paymentDetails
    }
    
    private func processCheckout() {
        let paymentDetails = generatePaymentDetails(selectedPaymentOption: selectedPaymentOption)
        self.pay(token: PlistConstants.shared.token,
                 paymentDetails: paymentDetails,
                 orderId: self.orderId,
                 countryCode: DemoConstants.country,
                 paymentMethodOption: selectedPaymentOption.railCode!,
                 viewController: self)
    }
}

extension SavePayment_PaymentFieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedPaymentOption.formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formField = self.selectedPaymentOption.formFields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! SavePayment_PaymentFieldsTableViewCell
        cell.updateUI(formField: formField, viewController: self, orderId: self.orderId)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: (tableView.frame.width - 40), height: 80))
        //  customView.backgroundColor = UIColor(red: 0.46, green: 0.45, blue: 0.87, alpha: 1.00)
        let btn_checkout = UIButton(type: .system)
        btn_checkout.frame = CGRect(x: 20, y: 20, width: customView.frame.width, height: 40)
        btn_checkout.setTitle("Save Payment Method", for: .normal)
        btn_checkout.setTitleColor(UIColor.white, for: .normal)
        btn_checkout.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn_checkout.backgroundColor = UIColor(red: 0.46, green: 0.45, blue: 0.87, alpha: 1.00)
        
        //  btn_checkout.addTarget(self, action: #selector(applePay), for: .touchUpInside)
        btn_checkout.addTarget(self, action: #selector(checkoutButtonTapped(_:)), for: .touchUpInside)
        
        customView.addSubview(btn_checkout)
        
        return customView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
    
    func showResult(_ message: String) {
        let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SavePayment_PaymentFieldsViewController: InaiCheckoutDelegate {
    
    private func goToHomeScreen(action: UIAlertAction) -> Void {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func paymentFinished(with result: Inai_PaymentResult) {
        switch result.status {
        case Inai_PaymentStatus.success:
            let resultStr = convertDictToStr(result.data)
            self.showAlert("Payment Method Save Success! \(resultStr)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.failed:
            let strError = convertDictToStr(result.data)
            self.showAlert("Payment Method Save Failed with data: \(strError)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.canceled:
            let message = result.data["message"] ?? "Payment Method Save Canceled!"
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
