//
//  InstallmentPlanDetailTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 06/04/23.
//

import UIKit

class InstallmentPlanDetailTableViewCell: UITableViewCell {

    @IBOutlet var interestTotalAmountView: UIView!
    @IBOutlet var holderView: UIView!
    @IBOutlet var selectEmiPlanBtn: UIButton!
    @IBOutlet var installmentInfoLbl: UILabel!
    @IBOutlet var interestAmountLbl: UILabel!
    @IBOutlet var totalAmountLbl: UILabel!
    @IBOutlet var choosePlanHolderView: UIView!
    @IBOutlet var chooseInstallmentPlanBtn: UIButton!
    public var installmentPlanSelected:((InstallmentPlanDetailTableViewCell)->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func chooseInstallmentPlanBtnAction(_ sender: Any) {
        self.installmentPlanSelected?(self)
    }
}
extension InstallmentPlanDetailTableViewCell{
    func prePopulateCell(_ installmentPlan: InstallmentPlanDetails,_ isSelected:Bool){
        self.selectEmiPlanBtn.setTitle("", for: .normal)
        if isSelected{
            self.selectEmiPlanBtn.setImage(UIImage(named: "SelectedRadioButton"), for: .normal)
            self.backgroundColor = UIColor.white
            self.interestTotalAmountView.isHidden = false
            self.choosePlanHolderView.isHidden = false
        }else{
            self.selectEmiPlanBtn.setImage(UIImage(named: "RadioButton"), for: .normal)
            self.backgroundColor = UIColor.quaternarySystemFill
            self.interestTotalAmountView.isHidden = true
            self.choosePlanHolderView.isHidden = true
        }
        let installmentAmountTerm = "\(installmentPlan.amount) x \(installmentPlan.installments) | "
        let totalAmount = (Double(installmentPlan.amount) ?? 0) * Double(installmentPlan.installments)
        let interestAmount = totalAmount - (Double(DemoConstants.amount) ?? 0)
        
        self.totalAmountLbl.text = String(totalAmount.rounded(toPlaces: 2))
        self.interestAmountLbl.text = String(interestAmount.rounded(toPlaces: 2))
        self.setAttribuitedText(dualLbl: installmentInfoLbl, subString: installmentAmountTerm, secondSubString: installmentPlan.fees, subStringFont: 12, secondSubStringFont: 10, subStringColor: .black, secondSubStringColor: .black)
    }
    func setAttribuitedText(dualLbl:UILabel,subString:String,secondSubString:String,subStringFont:CGFloat,secondSubStringFont:CGFloat,subStringColor:UIColor,secondSubStringColor:UIColor){
        let attrString = NSMutableAttributedString(string: subString,
                                                   attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: subStringFont), NSAttributedString.Key.foregroundColor:subStringColor])
        attrString.append(NSMutableAttributedString(string: secondSubString,
                                                    attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: secondSubStringFont),NSAttributedString.Key.foregroundColor:secondSubStringColor]))
        dualLbl.attributedText = attrString
    }
}


extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
