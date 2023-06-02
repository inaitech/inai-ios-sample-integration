//
//  MakePayment_WalletViewController.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 01/06/23.
//

import UIKit
import inai_ios_sdk

class MakePayment_WalletViewController: UIViewController {

    let mainHolderView = UIView()
    let tableView = UITableView()
    
    var paymentOptions:[MakePayment_PaymentMethodOption] = []
    var orderId:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.initialization()
    }
    
}
extension MakePayment_WalletViewController{
    func initialization(){
        self.setConstraints()
        self.setUI()
        self.setData()
        self.setTableView()
    }
    func setConstraints(){
        self.view.addSubview(self.mainHolderView)
        self.mainHolderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.mainHolderView.topAnchor.constraint(equalTo: self.view.topAnchor),
            self.mainHolderView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            self.mainHolderView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
            self.mainHolderView.rightAnchor.constraint(equalTo: self.view.rightAnchor)
        ])
        
        self.mainHolderView.addSubview(self.tableView)
        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.tableView.topAnchor.constraint(equalTo: self.mainHolderView.topAnchor,constant: 12),
            self.tableView.bottomAnchor.constraint(equalTo: self.mainHolderView.bottomAnchor,constant: -12),
            self.tableView.leftAnchor.constraint(equalTo: self.mainHolderView.leftAnchor,constant: 12),
            self.tableView.rightAnchor.constraint(equalTo: self.mainHolderView.rightAnchor,constant: -12)
        ])
    }
    func setUI(){
        self.view.backgroundColor = .white
    }
    func setData(){
        
    }
    func setTableView(){
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        self.tableView.separatorStyle = .none
        self.tableView.dataSource = self
        self.tableView.delegate = self
        DispatchQueue.main.async{
            self.tableView.reloadData()
        }
    }
}

extension MakePayment_WalletViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.paymentOptions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        let po = self.paymentOptions[indexPath.row]
        cell.backgroundColor = .white
        cell.selectionStyle = .none
        cell.layer.cornerRadius = 8
        cell.dropShadow(color: .black, opacity: 0.1, offSet: CGSize(width: -1, height: 1), radius: 8, scale: true)
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = sanitizeRailCode(po.railCode)
        return cell
    }
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
}
extension MakePayment_WalletViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        processCheckout(selectedPaymentOption:self.paymentOptions[indexPath.row])
    }
    private func processCheckout(selectedPaymentOption:MakePayment_PaymentMethodOption) {
        var paymentDetails = [String:Any]()
        self.pay(token: PlistConstants.shared.token,
                 paymentDetails: paymentDetails,
                 orderId: self.orderId,
                 countryCode: DemoConstants.country,
                 paymentMethodOption: selectedPaymentOption.railCode!,
                 viewController: self)
    }
    private func pay(token: String, paymentDetails: [String: Any],
                     orderId: String, countryCode: String, paymentMethodOption: String,
                     viewController: UIViewController & InaiCheckoutDelegate) {
        let styles = InaiConfig_Styles(
            container: InaiConfig_Styles_Container(backgroundColor: "#fff"),
            cta: InaiConfig_Styles_Cta(backgroundColor: "#123456"),
            errorText: InaiConfig_Styles_ErrorText(color: "#000000")
        )
        
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                styles: styles,
                                countryCode: DemoConstants.country
        )
        
        if let inaiCheckout = InaiCheckout(config: config) {
            print(paymentDetails)
            inaiCheckout.makePayment(paymentMethodOption: paymentMethodOption,
                                     paymentDetails: paymentDetails,
                                     viewController: viewController,
                                     delegate: viewController)
        }
    }
}
extension MakePayment_WalletViewController:InaiCheckoutDelegate{
    func paymentFinished(with result: inai_ios_sdk.Inai_PaymentResult) {
        switch result.status {
        case .success:
            break
        case .failed:
            break
        case .canceled:
            break
        @unknown default:
            break
        }
    }
}
