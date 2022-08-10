//
//  SavedPaymentOptionsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk


class SavedPaymentOptionsViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var selectedPaymentOption: PaymentMethodOption?
    private var paymentMethods: [SavedPaymentMethod] = []
    private var orderId = ""
    private var customerId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareOrder()
    }
    
    private func prepareOrder() {
        //  Initiate a new order
        self.activityIndicator.startAnimating()
        APIMethods.shared.prepareOrder { orderId, customerId in
            self.activityIndicator.stopAnimating()
            if let orderId = orderId {
                self.orderId = orderId
                self.customerId = customerId!
                self.processPaymentOptions()
            }
        }
    }
    
    private func processPaymentOptions() {
        activityIndicator.startAnimating()
        var payMethods: [SavedPaymentMethod] = []
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPaymentFieldsView" {
            if let vc = segue.destination as? PaymentFieldsViewController {
                vc.orderId = self.orderId
                vc.selectedPaymentOption = sender as? PaymentMethodOption
                vc.ctaText = "Pay with Saved Payment Method"
            }
        }
    }
}

extension SavedPaymentOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let po = self.paymentMethods[indexPath.row]
        cell.textLabel?.text = sanitizePaymentMethod(po)
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
    }
}
