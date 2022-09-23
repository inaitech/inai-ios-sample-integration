//
//  ValidateFieldsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/3/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class ValidateFields_PaymentFieldsViewController: UIViewController, InaiValidateFieldsDelegate {
    
    @IBOutlet weak var tbl_inputs: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var savePaymentMethod: Bool = false
    var selectedPaymentOption: ValidateFields_PaymentMethodOption!
    var orderId: String!
    var tbl_footerView: ValidateFields_PaymentMethodOption!
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardEvents(scrollView: self.tbl_inputs, view: self.view)
        tbl_inputs.separatorStyle = .none
    }
    
    func setupKeyboardEvents(scrollView: UIScrollView,
                             view: UIView) {
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
        self.validateFields()
    }
    
    private func generatePaymentDetails(selectedPaymentOption: ValidateFields_PaymentMethodOption!) -> [String: Any] {
        var paymentDetails = [String:Any]()
        var fieldsArray: [[String: Any]] = []
        for f in selectedPaymentOption.formFields {
            fieldsArray.append(["name":f.name!, "value": f.value as Any])
        }
        paymentDetails["fields"] = fieldsArray
        if let paymentMethodId = selectedPaymentOption.paymentMethodId {
            paymentDetails["paymentMethodId"] = paymentMethodId
        }
        return paymentDetails
    }
    
    private func validateFields() {
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                countryCode: DemoConstants.country
        )
                
        let paymentDetails = generatePaymentDetails(selectedPaymentOption: selectedPaymentOption)
        if let inaiCheckout = InaiCheckout(config: config) {
            self.activityIndicator.startAnimating()
            inaiCheckout.validateFields(
                paymentMethodOption: selectedPaymentOption.railCode!,
                paymentDetails: paymentDetails,
                viewController: self,
                delegate: self )
        } else {
            showResult("Invalid Config")
        }
    }
    
    func fieldsValidationFinished(with result: Inai_ValidateFieldsResult) {
        self.activityIndicator.stopAnimating()
        switch result.status {
        case Inai_ValidateFieldsStatus.success:
            //  Fields validated proceed with payment..
            self.showResult("\(convertDictToStr(result.data))")
            break
            
        case Inai_ValidateFieldsStatus.failed :
            self.showResult("Fields Validation Failed!: \(convertDictToStr(result.data))")
            break
        @unknown default:
            break
        }
    }
    
    func showResult(_ message: String) {
        let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
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

extension ValidateFields_PaymentFieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedPaymentOption.formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formField = self.selectedPaymentOption.formFields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! ValidateFields_PaymentFieldsTableViewCell
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
        btn_checkout.setTitle("Validate", for: .normal)
        btn_checkout.setTitleColor(UIColor.white, for: .normal)
        btn_checkout.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn_checkout.backgroundColor = UIColor(red: 0.46, green: 0.45, blue: 0.87, alpha: 1.00)
        btn_checkout.addTarget(self, action: #selector(checkoutButtonTapped(_:)), for: .touchUpInside)
        
        customView.addSubview(btn_checkout)
        
        return customView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
}
