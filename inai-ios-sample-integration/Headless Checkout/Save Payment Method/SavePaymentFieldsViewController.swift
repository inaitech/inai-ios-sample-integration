//
//  SavePaymentFieldsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/3/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class SavePaymentFieldsViewController: UIViewController {
    
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
        
        if (selectedPaymentOption.railCode == "card") {
            //  Lets not render the save card field as it will always be passed
            self.selectedPaymentOption.formFields = self.selectedPaymentOption.formFields
                                                    .filter { $0.name != "save_card" }
        }
        setupTableFooterView()
    }
    
    func setupTableFooterView() {
        let isApplePay = selectedPaymentOption.railCode == "apple_pay"
        if let footerView = Bundle.main.loadNibNamed("PaymentFieldsTableFooterView",
                                                  owner: nil,
                                                     options: nil)?.first as? PaymentFieldsTableFooterView {
            tbl_footerView = footerView
            tbl_footerView.updateUI(isApplePay: isApplePay)
            tbl_footerView.btn_checkout.addTarget(self, action: #selector(checkoutButtonTapped(_:)), for: .touchUpInside)
            tbl_footerView.btn_checkout.setTitle("Save Payment Method", for: .normal)
        }
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
                                countryCode: PlistConstants.shared.country
        )
        
        if let inaiCheckout = InaiCheckout(config: config) {
            inaiCheckout.makePayment(paymentMethodOption: paymentMethodOption,
                                     paymentDetails: paymentDetails,
                                     viewController: viewController,
                                     delegate: viewController)
        }
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
    
    private func processCheckout() {
        let paymentDetails = generatePaymentDetails(selectedPaymentOption: selectedPaymentOption)
        self.pay(token: PlistConstants.shared.token,
                 paymentDetails: paymentDetails,
                 orderId: self.orderId,
                 countryCode: PlistConstants.shared.country,
                 paymentMethodOption: selectedPaymentOption.railCode!,
                 viewController: self)
    }
}

extension SavePaymentFieldsViewController: HandlesKeyboardEvent {}
extension SavePaymentFieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
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
    
    func showResult(_ message: String) {
        let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension SavePaymentFieldsViewController: InaiCheckoutDelegate {

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
}
