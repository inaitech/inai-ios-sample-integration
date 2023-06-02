//
//  MakePayment_PaymentFieldOptionsTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 29/05/23.
//

import UIKit

class MakePayment_PaymentFieldOptionsTableViewCell: UITableViewCell {

    @IBOutlet var titleLbl: UILabel!
    @IBOutlet var tableView: AutoSizingTableView!
    var cellInfo:MakePayment_PaymentMethodOption?
    var viewController:UIViewController!
    var orderId:String!
    var updatedSelectedMode:((MakePayment_Mode, MakePayment_FormField)->())?
    var payDelegate:((String)->())?
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
extension MakePayment_PaymentFieldOptionsTableViewCell{
    func prePopulateCell(cellInfo:MakePayment_PaymentMethodOption,viewController:UIViewController,orderId:String){
        self.cellInfo = cellInfo
        self.viewController = viewController
        self.orderId = orderId
        self.titleLbl.text = "UPI"//cellInfo.label
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.register(UINib(nibName: "MakePayment_DataTableViewCell", bundle: nil), forCellReuseIdentifier: "MakePayment_DataTableViewCell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.contentSize = self.tableView.intrinsicContentSize
    }
}
//MARK: - TableViewDataSource
extension MakePayment_PaymentFieldOptionsTableViewCell:UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        self.cellInfo?.modes.count ?? 0
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellInfo?.modes[section].form_fields.count ?? 0
//        return self.cellInfo?.data?.values.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let formFieldInfo = self.cellInfo?.modes[indexPath.section].form_fields[indexPath.row] else
        {return UITableViewCell()}
        if let values = formFieldInfo.data?.values, values.isEmpty == false{
            
//            return UITableViewCell()
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MakePayment_DataTableViewCell", for: indexPath) as? MakePayment_DataTableViewCell else {return UITableViewCell()}
//            if let data = formFieldInfo{
                cell.prePopulateCell(cellInfo: formFieldInfo)
                cell.updatedSelectedValue = { selectedValue in
                    self.cellInfo?.modes[indexPath.section].form_fields[indexPath.row].value = selectedValue.value
                    if let mode = self.cellInfo?.modes[indexPath.section], let value = self.cellInfo?.modes[indexPath.section].form_fields[indexPath.row]{
                        self.updatedSelectedMode?(mode, value)
                    }
                }
            cell.payDelegate = { _ in
                self.payDelegate?("")
            }
//            }
            return cell
        }else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
//            let po = self.paymentOptions[indexPath.section]
            cell.contentView.layer.cornerRadius = 8
            cell.dropShadow(color: .black, opacity: 0.1, offSet: CGSize(width: -1, height: 1), radius: 8, scale: true)
            cell.accessoryType = .disclosureIndicator
            cell.backgroundColor = .white
            cell.selectionStyle = .none
            cell.textLabel?.text = sanitizeRailCode(self.cellInfo?.modes[indexPath.section].code)
            return cell
        
        }

    }
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
}

//MARK: - TableViewDelegate
extension MakePayment_PaymentFieldOptionsTableViewCell:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let mode = self.cellInfo?.modes[indexPath.section], let value = self.cellInfo?.modes[indexPath.section].form_fields[indexPath.row]{
            self.updatedSelectedMode?(mode, value)
        }
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
