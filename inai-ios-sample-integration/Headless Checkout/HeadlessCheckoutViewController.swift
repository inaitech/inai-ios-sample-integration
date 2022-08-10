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
                    if (sender["saved_payment_method"] as? Bool ?? false) {
                        vc.payWithSavedMethods = true
                    }
                }
            }
        }
    }
    
    // MARK: - IBActions
    // MARK: -
    @IBAction func showProductView(_ sender: Any) {
        performSegue(withIdentifier: "ShowProductView", sender: nil)
    }
    
    @IBAction func showProductViewWithSavedPayment(_ sender: Any) {
        performSegue(withIdentifier: "ShowProductView", sender: ["saved_payment_method": true])
    }
}

