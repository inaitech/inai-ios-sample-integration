//
//  MakePayment_UPIIntentTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 31/05/23.
//

import UIKit

class MakePayment_UPIIntentTableViewCell: UITableViewCell {

    @IBOutlet var intentHolderView: UIView!
    @IBOutlet var selectedStateImg: UIImageView!
    @IBOutlet var paymentModeNameLbl: UILabel!
    @IBOutlet var payHolderView: UIView!
    @IBOutlet var payBtn: UIButton!
    
    public var updateSelected:((String)->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func payBtnAction(_ sender: Any) {
        self.updateSelected?("")
    }
    
}
extension MakePayment_UPIIntentTableViewCell{
    func prePopulateCell(cellInfo:MakePayment_Value, selectedRow:Bool){
        self.paymentModeNameLbl.text = cellInfo.label
        if selectedRow {
            self.payHolderView.isHidden = false
            self.selectedStateImg.image =  UIImage(named: "RadioButtonSelected")
        }else{
            self.payHolderView.isHidden = true
            self.selectedStateImg.image = UIImage(named: "RadioButton")
        }
    }
}
