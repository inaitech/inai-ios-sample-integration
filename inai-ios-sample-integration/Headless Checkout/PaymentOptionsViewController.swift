//
//  HeadlessCheckoutViewController.swift
//  inai-checkout
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk


enum PaymentType: Int {
    case savedPaymentOption = 0
    case paymentOption = 1
}


class PaymentOptionsViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedPaymentOption: PaymentMethodOption?
    var paymentOptions: [PaymentMethodOption] = []
    var paymentMethods: [SavedPaymentMethod] = []
    var orderId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.processPaymentOptions()
    }
    
    private func processPaymentOptions() {
        
        activityIndicator.startAnimating()
        var payOptions: [PaymentMethodOption] = []
        var payMethods: [SavedPaymentMethod] = []
        
        APIMethods.shared.getPaymentOptions(
                          orderId: self.orderId,
                          saved_payment_method: false) { response, error in
            guard let respo = response else {
                self.activityIndicator.stopAnimating()
                self.showAlert(error?.localizedDescription ?? "")
                return
            }
            let paymentOptions = PaymentMethodOption.paymentOptionsFromJSON(respo)
            payOptions.append(contentsOf: paymentOptions)
            self.paymentOptions = payOptions
            self.tbl_payment_options.reloadData()
              APIMethods.shared.getOrderDetails(
                 orderId: self.orderId) { (orderDetails, error) in
                guard let orderDetails = orderDetails else {
                    self.activityIndicator.stopAnimating()
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                if let customer = orderDetails["customer"] as? [String: Any],
                    let customerId = customer["id"] as? String {
                    APIMethods.shared.getCustomerPayments(customerId: customerId) { (customerPayments, error) in
                        guard let customerPayments = customerPayments else {
                            self.activityIndicator.stopAnimating()
                            self.showAlert(error?.localizedDescription ?? "")
                            return
                        }
                        let paymentMethods = SavedPaymentMethod.paymentMethodsFromJSON(customerPayments)
                        payMethods.append(contentsOf: paymentMethods)
                        self.paymentMethods = payMethods
                        self.tbl_payment_options.reloadData()
                        self.activityIndicator.stopAnimating()
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPaymentFieldsView" {
            if let vc = segue.destination as? PaymentFieldsViewController {
                vc.orderId = self.orderId
                vc.selectedPaymentOption = sender as? PaymentMethodOption
            }
        }
    }
}

extension PaymentOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var retVal: String? = nil
        switch section {
            case PaymentType.savedPaymentOption.rawValue:
                if self.paymentMethods.count > 0 {
                    retVal = "Saved"
                }
            case PaymentType.paymentOption.rawValue:
                if self.paymentOptions.count > 0 {
                    retVal = "Payment Options"
                }
            default:
                break
        }
        return retVal
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var retVal: Int = 0
        switch section {
            case PaymentType.savedPaymentOption.rawValue:
                retVal = self.paymentMethods.count
            case PaymentType.paymentOption.rawValue:
                retVal =  self.paymentOptions.count
            default: break
        }
        return retVal
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        switch indexPath.section {
            case PaymentType.savedPaymentOption.rawValue:
                let po = self.paymentMethods[indexPath.row]
                cell.textLabel?.text = sanitizePaymentMethod(po)
            case PaymentType.paymentOption.rawValue:
                let po = self.paymentOptions[indexPath.row]
                cell.textLabel?.text = sanitizeRailCode(po.railCode)
            default:
                break
        }
        return cell
    }
    
    private func sanitizePaymentMethod(_ paymentMethod: SavedPaymentMethod) -> String? {
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
        switch indexPath.section {
            case PaymentType.savedPaymentOption.rawValue:
                activityIndicator.startAnimating()
                APIMethods.shared.getPaymentOptions(
                                  orderId: self.orderId,
                                  saved_payment_method: true) { paymentOptions, error in
                    guard let paymentOptions = paymentOptions else {
                        self.activityIndicator.stopAnimating()
                        self.showAlert(error?.localizedDescription ?? "")
                        return
                    }
                    let payOptions = PaymentMethodOption.paymentOptionsFromJSON(paymentOptions)
                    let payMethod = self.paymentMethods[indexPath.row]
                    if var finalPayOption = payOptions.filter({ option in
                        return self.sanitizeRailCode(option.railCode) == self.sanitizeRailCode(payMethod.type)
                    }).first {
                        finalPayOption.paymentMethodId = payMethod.id
                        self.activityIndicator.stopAnimating()
                        self.performSegue(withIdentifier: "ShowPaymentFieldsView", sender: finalPayOption)
                    }
                }
            case PaymentType.paymentOption.rawValue:
                performSegue(withIdentifier: "ShowPaymentFieldsView", sender:   self.paymentOptions[indexPath.row])
            default: break
        }
    }
}
