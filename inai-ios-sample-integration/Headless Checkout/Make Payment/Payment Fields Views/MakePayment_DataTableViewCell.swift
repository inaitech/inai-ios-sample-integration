//
//  MakePayment_DataTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 30/05/23.
//

import UIKit

class MakePayment_DataTableViewCell: UITableViewCell {

    @IBOutlet var tableView: AutoSizingTableView!
    var cellInfo:MakePayment_FormField?
    var selectedRow:IndexPath = IndexPath(row: -1, section: 0)
    var viewController:UIViewController!
    var orderId:String!
    var updatedSelectedValue:((MakePayment_Value)->())?
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

extension MakePayment_DataTableViewCell{
    func prePopulateCell(cellInfo:MakePayment_FormField){
        self.cellInfo = cellInfo
        self.tableView.register(UINib(nibName: "MakePayment_UPIIntentTableViewCell", bundle: nil), forCellReuseIdentifier: "MakePayment_UPIIntentTableViewCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.contentSize = self.tableView.intrinsicContentSize
    }
}

extension MakePayment_DataTableViewCell:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cellInfo?.data?.values.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let intentInfo = self.cellInfo?.data?.values[indexPath.row]
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MakePayment_UPIIntentTableViewCell") as? MakePayment_UPIIntentTableViewCell else {return UITableViewCell()}
        if let intentInfo = intentInfo{
            cell.prePopulateCell(cellInfo: intentInfo,selectedRow: selectedRow == indexPath)
        }
        cell.updateSelected = { _ in
            self.payDelegate?("")
        }
        return cell
    }
    
}

extension MakePayment_DataTableViewCell:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedRow = indexPath
        if let intentInfo = self.cellInfo?.data?.values[indexPath.row]{
            self.updatedSelectedValue?(intentInfo)
        }
        self.tableView.reloadData()
        self.tableView.contentSize = self.tableView.intrinsicContentSize
    }
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


final class AutoSizingTableView: UITableView {

    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }

    override func reloadData() {
        super.reloadData()
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        setNeedsLayout()
        layoutIfNeeded()
        return contentSize
    }
}
