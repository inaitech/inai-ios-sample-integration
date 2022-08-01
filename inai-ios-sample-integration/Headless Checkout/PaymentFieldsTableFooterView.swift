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
    override func awakeFromNib() { }
    
    func updateCheckoutButtonUI(enable: Bool) {
        btn_checkout.isEnabled = enable
        btn_checkout.backgroundColor = enable ? greenColor : UIColor.lightGray
    }
}
