//
//  ProductViewController.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 29/07/22.
//

import UIKit
import inai_ios_sdk

class ProductController: UIViewController {

    var payment_method: String = "normal"
    
    // MARK: - IBOutlets
    // MARK: -
    @IBOutlet var buyNowButton: UIButton!
    
    // MARK: - Internal Methods
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - IBActions
    // MARK: -
    @IBAction func clickedBuyNow(_ sender: Any) {
        if (payment_method == "saved") {
            performSegue(withIdentifier: "ShowSavedPaymentOptionsView", sender: self)
        } else if (payment_method == "apple_pay") {
            performSegue(withIdentifier: "ShowApplePayView", sender: self)
        } else if (payment_method == "installment_plans"){
            performSegue(withIdentifier: "ShowInstallmentPlansView", sender: self)
        }else {
            performSegue(withIdentifier: "ShowPaymentOptionsView", sender: self)
        }
    }
}
