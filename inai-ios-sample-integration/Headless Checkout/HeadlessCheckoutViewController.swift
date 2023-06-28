//
//  HeadlessCheckoutViewController.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 29/07/22.
//

import UIKit

class HeadlessCheckoutViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowProductView" {
            if let vc = segue.destination as? ProductController {
                if let sender = sender as? [String: Any] {
                    if let payment_method = sender["payment_method"] as? String {
                        vc.payment_method = payment_method
                    }
                }
            }
        }
    }
    
    // MARK: - IBActions
    // MARK: -
    @IBAction func showProductView(_ sender: Any) {
        performSegue(withIdentifier: "ShowProductView", sender: ["payment_method": "normal"])
    }
    
    @IBAction func showProductViewWithSavedPayment(_ sender: Any) {
        performSegue(withIdentifier: "ShowProductView", sender: ["payment_method": "saved"])
    }
    
    @IBAction func showProductViewWithApplePay(_ sender: Any) {
        performSegue(withIdentifier: "ShowProductView", sender: ["payment_method": "apple_pay"])
    }
    @IBAction func showProductViewWithInstallmentPlans(_ sender: Any) {
        performSegue(withIdentifier: "ShowProductView", sender: ["payment_method": "installment_plans"])
    }
    
}

