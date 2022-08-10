//
//  SavePaymentOptionsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class SavePaymentOptionsViewController: UIViewController {
    
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
        APIMethods.shared.prepareOrder(savePaymentMethod: true) { orderId, customerId in
            self.activityIndicator.stopAnimating()
            if let orderId = orderId {
                self.orderId = orderId
                self.processPaymentOptions()
            }
        }
    }
    
    private func processPaymentOptions() {
        self.activityIndicator.startAnimating()
        
        APIMethods.shared.getPaymentOptions(
            orderId: self.orderId,
            saved_payment_method: false) { response, error in
                self.activityIndicator.stopAnimating()
                guard let respo = response else {
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                
                //  Lets not render all options to save except  Apply Pay
                let paymentOptions = PaymentMethodOption.paymentOptionsFromJSON(respo)
                                    .filter { self.sanitizeRailCode($0.railCode) != "Apple Pay" }
                
                self.paymentOptions = paymentOptions
                self.tbl_payment_options.reloadData()
            }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowSavePaymentFieldsView" {
            if let vc = segue.destination as? SavePaymentFieldsViewController {
                vc.orderId = self.orderId
                vc.selectedPaymentOption = sender as? PaymentMethodOption
            }
        }
    }
}

extension SavePaymentOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let po = self.paymentOptions[indexPath.row]
        cell.textLabel?.text = sanitizeRailCode(po.railCode)
        return cell
    }
    
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "ShowSavePaymentFieldsView", sender: self.paymentOptions[indexPath.row])
    }
}
