//
//  ProductViewController.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 29/07/22.
//

import UIKit
import inai_ios_sdk

class ProductController: UIViewController {

    // MARK: - Internal vars
    // MARK: -
    var token: String = ""
    var password: String = ""
    
    let inai_backend_orders_url: String = "\(PlistConstants.shared.baseURL)/orders"
    
    //  Tracking variables
    var paymentMethodId = ""
    var orderId = ""
    var customerId = ""
    var countryCode = ""
    var currency = ""
    
    @IBOutlet var buyNowButton: UIButton!
    
    // MARK: - Internal Methods
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPaymentOptionsView" {
            if let vc = segue.destination as? PaymentOptionsViewController {
                vc.selectedPaymentOption = sender as? PaymentMethodOption
                vc.orderId = self.orderId
            }
        }
    }
    
    // MARK: - Payment Functions
    // MARK: -
    func payNow(){
        performSegue(withIdentifier: "ShowPaymentOptionsView", sender: self)
    }
    
    // MARK: - IBActions
    // MARK: -
    @IBAction func clickedBuyNow(_ sender: Any) {
        self.buyNowButton.isEnabled = false
        APIMethods.shared.prepareOrder { orderId in
            self.buyNowButton.isEnabled = true
            if let orderId = orderId {
                self.orderId = orderId
                self.payNow()
            }
        }
    }
}
