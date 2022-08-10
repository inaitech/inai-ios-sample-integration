//
//  ProductViewController.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 29/07/22.
//

import UIKit
import inai_ios_sdk

class ProductController: UIViewController {

    var payWithSavedMethods: Bool = false
    
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
        if (payWithSavedMethods) {
            performSegue(withIdentifier: "ShowSavedPaymentOptionsView", sender: self)
        } else {
            performSegue(withIdentifier: "ShowPaymentOptionsView", sender: self)
        }
    }
}
