//
//  PaymentOptionsListTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 05/04/23.
//

import UIKit

class PaymentOptionsListTableViewCell: UITableViewCell {
    
    @IBOutlet var holderView: UIView!
    @IBOutlet var paymentMethodLbl: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
extension PaymentOptionsListTableViewCell{
    func prePopulateData(title:String?){
        self.selectionStyle = .none
        self.paymentMethodLbl.text = title
    }
}
