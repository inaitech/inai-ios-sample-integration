//
//  PaymentFieldsTableFooterView.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/14/22.
//

import Foundation
import UIKit

class PaymentFieldsTableFooterView: UIView {
    @IBOutlet weak var btn_checkout: UIButton!
    @IBOutlet weak var btn_apple_pay: UIButton!
    
    override func awakeFromNib() {
        btn_apple_pay.setTitle(nil, for: .normal)
    }
    
    func updateUI(isApplePay: Bool) {
        btn_apple_pay.isHidden = !isApplePay
        btn_checkout.isHidden = isApplePay
    }
    
    func updateCheckoutButtonUI(enable: Bool) {
        btn_checkout.isEnabled = enable
        btn_checkout.backgroundColor = enable ? greenColor : UIColor.lightGray
    }
}
