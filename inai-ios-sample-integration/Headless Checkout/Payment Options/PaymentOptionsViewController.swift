//
//  PaymentOptionsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class PaymentOptionsViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
        
    private var selectedPaymentOption: PaymentMethodOption?
    private var paymentOptions: [PaymentMethodOption] = []
    private var orderId = ""
    
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
                self.processPaymentOptions()
            }
        }
    }
    
    private func processPaymentOptions() {
        self.activityIndicator.startAnimating()
        var payOptions: [PaymentMethodOption] = []
        
        APIMethods.shared.getPaymentOptions(
            orderId: self.orderId,
            saved_payment_method: false) { response, error in
                self.activityIndicator.stopAnimating()
                guard let respo = response else {
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                let paymentOptions = PaymentMethodOption.paymentOptionsFromJSON(respo)
                payOptions.append(contentsOf: paymentOptions)
                self.paymentOptions = payOptions
                self.tbl_payment_options.reloadData()
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let po = self.paymentOptions[indexPath.row]
        cell.textLabel?.text = sanitizeRailCode(po.railCode)
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
        performSegue(withIdentifier: "ShowPaymentFieldsView", sender: self.paymentOptions[indexPath.row])
    }
}
