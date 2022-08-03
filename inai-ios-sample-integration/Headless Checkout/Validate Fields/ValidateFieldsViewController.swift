//
//  ValidateFieldsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/3/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class ValidateFieldsViewController: UIViewController, InaiValidateFieldsDelegate {
    
    var savePaymentMethod: Bool = false
    var selectedPaymentOption: PaymentMethodOption!
    var orderId: String!
    var keyboardHandler: KeyboardHandler!
        
    @IBOutlet weak var tbl_inputs: UITableView!
    var tbl_footerView: PaymentFieldsTableFooterView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.keyboardHandler = KeyboardHandler()
        setup(keyboardHandler: self.keyboardHandler,
              scrollView: self.tbl_inputs,
              view: self.view)
        tbl_inputs.separatorStyle = .none
        setupTableFooterView()
    }
    
    func setupTableFooterView() {
        if let footerView = Bundle.main.loadNibNamed("PaymentFieldsTableFooterView",
                                                  owner: nil,
                                                     options: nil)?.first as? PaymentFieldsTableFooterView {
            tbl_footerView = footerView
            tbl_footerView.updateUI(isApplePay: false)
            tbl_footerView.btn_checkout.addTarget(self, action: #selector(checkoutButtonTapped(_:)), for: .touchUpInside)
            tbl_footerView.btn_checkout.setTitle("Validate Fields", for: .normal)
        }
    }
    
    @objc func checkoutButtonTapped(_ btn: UIButton) {
        self.view.endEditing(true)
        self.validateFields()
    }
    
    private func generatePaymentDetails(selectedPaymentOption: PaymentMethodOption!) -> [String: Any] {
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
    
    private func validateFields() {
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                countryCode: PlistConstants.shared.country
        )
                
        let paymentDetails = generatePaymentDetails(selectedPaymentOption: selectedPaymentOption)
        if let inaiCheckout = InaiCheckout(config: config) {
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
        switch result.status {
        case Inai_ValidateFieldsStatus.success:
            //  Fields validated proceed with payment..
            self.showResult("Fields Validation Success!: \(convertDictToStr(result.data))")
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
}



extension ValidateFieldsViewController: HandlesKeyboardEvent {}
extension ValidateFieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedPaymentOption.formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formField = self.selectedPaymentOption.formFields[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextInputTableViewCell", for: indexPath) as! PaymentFieldTableViewCell
        cell.updateUI(formField: formField, viewController: self, orderId: self.orderId)
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tbl_footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
}
