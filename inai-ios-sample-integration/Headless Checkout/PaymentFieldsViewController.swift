//
//  PaymentFieldsViewController.swift
//  inai-checkout
//
//  Created by Parag Dulam on 5/3/22.
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

class PaymentFieldsViewController: UIViewController {
    
    var selectedPaymentOption: PaymentMethodOption!
    var orderId: String!
    var paymentController: PKPaymentAuthorizationController!
    var keyboardHandler: KeyboardHandler!
    
    private var applePayCompletion: ((PKPaymentAuthorizationResult) -> Void)?
    
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
        let isApplePay = selectedPaymentOption.railCode == "apple_pay"
        if let footerView = Bundle.main.loadNibNamed("PaymentFieldsTableFooterView",
                                                  owner: nil,
                                                     options: nil)?.first as? PaymentFieldsTableFooterView {
            tbl_footerView = footerView
            tbl_footerView.updateUI(isApplePay: isApplePay)
            tbl_footerView.btn_apple_pay.addTarget(self, action: #selector(applePay), for: .touchUpInside)
            tbl_footerView.btn_checkout.addTarget(self, action: #selector(checkoutButtonTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc func applePay() {
        let payemtnData = InaiCheckout.getApplePayRequestData(paymentMethodOptionsData: selectedPaymentOption.dict)
        let request = InaiCheckout.getApplePaymentRequest(paymentRequestData: payemtnData!)
        paymentController = PKPaymentAuthorizationController(paymentRequest: request)
        paymentController?.delegate = self
        paymentController?.present(completion: { (presented: Bool) in
            if presented {
                debugPrint("Presented payment controller")
            } else {
                debugPrint("Failed to present payment controller")
            }
        })
    }
    
    @objc func checkoutButtonTapped(_ btn: UIButton) {
        self.view.endEditing(true)
        let requiredFieldsFilled = checkAllFieldsValidated()
        if (!requiredFieldsFilled) {
            showAlert("Please fill all required fields with valid Input")
            return
        }
        
        self.validateFields()
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


extension PaymentFieldsViewController: PKPaymentAuthorizationControllerDelegate {
    
    func paymentAuthorizationController(_ controller: PKPaymentAuthorizationController,
                                        didAuthorizePayment payment: PKPayment,
                                        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void) {
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                countryCode: PlistConstants.shared.country)
        
        if let inaiCheckout = InaiCheckout(config: config) {
            
            let paymentDetails = InaiCheckout.convertPaymentTokenToDict(payment: payment)
            self.applePayCompletion = completion
            
            inaiCheckout.makePayment( paymentMethodOption: "apple_pay",
                                      paymentDetails: paymentDetails,
                                      viewController: self,
                                      delegate: self)
        }
    }
  
    func paymentAuthorizationControllerDidFinish(_ controller: PKPaymentAuthorizationController) {
        controller.dismiss {}
    }
    
    private func checkAllFieldsValidated() -> Bool {
        var retVal: Bool = true
        for fo in selectedPaymentOption.formFields {
            if fo.validated == false {
                retVal = false
                break
            }
        }
        return retVal
    }
}

extension PaymentFieldsViewController: HandlesKeyboardEvent {}
extension PaymentFieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
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

extension PaymentFieldsViewController: InaiValidateFieldsDelegate {
    func fieldsValidationFinished(with result: Inai_ValidateFieldsResult) {
        switch result.status {
        case Inai_ValidateFieldsStatus.success:
            //  Fields validated proceed with payment..
            self.processCheckout()
            break
            
        case Inai_ValidateFieldsStatus.failed :
            self.showResult("Fields Validation Failed!: \(convertDictToStr(result.data))")
            break
        @unknown default:
            break
        }
    }
}

extension PaymentFieldsViewController: InaiCheckoutDelegate {

    private func goToHomeScreen(action: UIAlertAction) -> Void {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func paymentFinished(with result: Inai_PaymentResult) {
        switch result.status {
        case Inai_PaymentStatus.success:
            let resultStr = convertDictToStr(result.data)
            self.applePayCompletion?(PKPaymentAuthorizationResult(status: .success, errors: nil))
            self.showAlert("Payment Success! \(resultStr)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.failed:
            let strError = convertDictToStr(result.data)
            let error = ApplePayStringError(strError);
            self.applePayCompletion?(PKPaymentAuthorizationResult( status: .failure, errors: [error]))
            self.showAlert("Payment Failed with data: \(strError)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.canceled:
            let error = ApplePayStringError("Payment Canceled");
            self.applePayCompletion?(PKPaymentAuthorizationResult( status: .failure, errors: [error]))
            let message = result.data["message"] ?? "Payment Canceled!"
            self.showAlert(message as! String, title: "Result", completion: goToHomeScreen)
            break
        @unknown default:
            break;
        }
    }
}
