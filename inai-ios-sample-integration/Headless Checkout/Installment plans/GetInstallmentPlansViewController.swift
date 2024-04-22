//
//  GetInstallmentPlansViewController.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 05/04/23.
//

import UIKit
import inai_ios_sdk

class GetInstallmentPlansViewController: UIViewController {

    @IBOutlet var itemsPriceView: UIView!
    @IBOutlet var itemsPriceLbl: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private var selectedEmiPlan:IndexPath = IndexPath(row: -1, section: 0)
    var orderId:String!
    var paymentDetails:[String:Any]!
    var selectedPaymentMethodOption:String!
    var countryCode:String!
    
    var installmentPlansList:InstallmentPlansOptions?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.initialization()
    }
    
}
//MARK: - Initialization
extension GetInstallmentPlansViewController{
    func initialization(){
        self.setUI()
        self.setData()
        self.setTableView()
    }
    func setUI(){
        self.title = "Installment Plans"
        self.itemsPriceLbl.text = "Items(s) price: \(DemoConstants.amount)"
    }
    func setData(){
        self.fetchInstallMentPlans()
    }
    func setTableView(){
        self.tableView.register(UINib(nibName: "InstallmentPlanDetailTableViewCell", bundle: nil), forCellReuseIdentifier: "InstallmentPlanDetailTableViewCell")
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
}
//MARK: - UITableViewDataSource
extension GetInstallmentPlansViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.installmentPlansList?.installmentPlans.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let data = self.installmentPlansList?.installmentPlans[indexPath.row]{
            guard let installmentPlanDetailTVC = tableView.dequeueReusableCell(withIdentifier: "InstallmentPlanDetailTableViewCell") as? InstallmentPlanDetailTableViewCell else {
                return UITableViewCell()
            }
            installmentPlanDetailTVC.installmentPlanSelected = { _ in
                if let planDetails = data.planDetails{
                    self.makePayment(planDetails)
                }
            }
            installmentPlanDetailTVC.prePopulateCell(data, self.selectedEmiPlan == indexPath)
            return installmentPlanDetailTVC
        }else{
            return UITableViewCell()
        }
    }
}
//MARK: - UITableViewDelegate
extension GetInstallmentPlansViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //handle navigation here
        self.selectedEmiPlan = indexPath
        self.tableView.reloadData()
    }
}
//MARK: - Installmentplans
extension GetInstallmentPlansViewController:InaiInstallmentPlansDelegate{
    private func generatePaymentDetails(_ selectedPaymentOption: MakeInstallmentPayment_PaymentMethodOption!) -> [String: Any] {
        var paymentDetails = [String:Any]()
        var fieldsArray: [[String: Any]] = []
        for f in selectedPaymentOption.formFields {
            fieldsArray.append(["name":f.name!, "value": f.value as Any])
        }
        paymentDetails["fields"] = fieldsArray
        if let paymentMethodId = selectedPaymentOption.paymentMethodId {
            paymentDetails["paymentMethodId"] = paymentMethodId
        }
        return paymentDetails
    }
    func fetchInstallMentPlans(){
        
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                countryCode: DemoConstants.country
        )
        if let inaiCheckout = InaiCheckout(config: config) {
            inaiCheckout.getInstallmentPlans(
                    paymentMethodOption: self.selectedPaymentMethodOption,
                    paymentDetails: paymentDetails,
                    viewController: self,
                    delegate: self)
        } else {
            print("Please check configuration details")
        }
    }
    func installmentPlansFetched(with result: inai_ios_sdk.Inai_InstallmentPlansResult) {
        if result.status == .success{
            do {
                let jsonData = try JSONSerialization.data(withJSONObject:result.data)
                print(jsonData)
                self.installmentPlansList = try JSONDecoder().decode(InstallmentPlansOptions.self, from: jsonData)
                print(try JSONSerialization.jsonObject(with: jsonData, options: []))
    
            } catch {
                print(error, result.data)
                self.navigationController?.popViewController(animated: true)
            }
        }else if result.status == .failed{
            print(result.data)
        }
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = true
            self.tableView.reloadData()
        }
    }
}
//MARK: - Navigation
extension GetInstallmentPlansViewController:InaiCheckoutDelegate{
    func paymentFinished(with result: inai_ios_sdk.Inai_PaymentResult) {
        var shalldismiss = false
        let alert = UIAlertController(title: "PaymentStatus", message: "\(result.data)", preferredStyle: .alert)
        if result.status == .success{
            shalldismiss = true
        }
        alert.addAction(UIAlertAction(title: "OK", style: .cancel){ _ in
            if shalldismiss {
                self.navigationController?.popToRootViewController(animated: true)
            }
        })
        self.present(alert, animated: true)
    }
    
    func makePayment(_ data:PlanDetails){
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
        if let _ = self.paymentDetails{
            var installmentPaymentDetail = self.paymentDetails!
            let jsonEncoder =  JSONEncoder()
            if let jsonData = try? jsonEncoder.encode(data){
                if let installmentPlanJson = try? JSONSerialization.jsonObject(with: jsonData,  options: []){
                    installmentPaymentDetail["installment_plan"] = installmentPlanJson
                    if let inaiCheckout = InaiCheckout(config: config) {
                        inaiCheckout.makePayment(paymentMethodOption: selectedPaymentMethodOption,
                                                 paymentDetails: installmentPaymentDetail,
                                                 viewController: self,
                                                 delegate: self)
                    }
                }
            }
        }
    }
}
