//
//  HeadlessCheckoutViewController.swift
//  inai-checkout
//
//  Created by Parag Dulam on 4/29/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class PaymentOptionsViewController: UIViewController {
    
    @IBOutlet weak var tbl_payment_options: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedPaymentOption: PaymentMethodOption?
    var paymentOptions: [PaymentMethodOption] = []
    var orderId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.processPaymentOptions()
    }
    
    private func processPaymentOptions() {
        
        activityIndicator.startAnimating()
        var payOptions: [PaymentMethodOption] = []
        
        APIMethods.shared.getPaymentOptions(
                          orderId: self.orderId) { response, error in
            guard let respo = response else {
                self.activityIndicator.stopAnimating()
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Payment Options"
    }
    
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
        performSegue(withIdentifier: "ShowPaymentFieldsView", sender: self.paymentOptions[indexPath.row])
    }
}
