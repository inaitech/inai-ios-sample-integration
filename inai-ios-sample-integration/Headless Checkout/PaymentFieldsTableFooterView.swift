//
//  PaymentFieldsTableFooterView.swift
//  inai-checkout
//
//  Created by Parag Dulam on 5/14/22.
//

import Foundation
import UIKit

class PaymentFieldsTableFooterView: UIView {
    @IBOutlet weak var btn_checkout: UIButton!
    @IBOutlet weak var btn_apple_pay: UIButton!
    
    @IBOutlet weak var top_btn_apple_pay: NSLayoutConstraint!
    @IBOutlet weak var height_btn_apple_pay: NSLayoutConstraint!
    @IBOutlet weak var top_btn_checkout: NSLayoutConstraint!
    @IBOutlet weak var height_btn_checkout: NSLayoutConstraint!

    override func awakeFromNib() {
        btn_apple_pay.setTitle(nil, for: .normal)
    }
    
    func updateUI(isApplePay: Bool) {
        btn_apple_pay.isHidden = !isApplePay
        btn_checkout.isHidden = isApplePay
        
        top_btn_apple_pay.constant = isApplePay ? 10 : 0
        height_btn_apple_pay.constant = isApplePay ? 40 : 0
        top_btn_checkout.constant = isApplePay ? 0 : 10
        height_btn_checkout.constant = isApplePay ? 0 : 40
    }
    
    func updateCheckoutButtonUI(enable: Bool) {
        btn_checkout.isEnabled = enable
        btn_checkout.backgroundColor = enable ? greenColor : UIColor.lightGray
    }
}
