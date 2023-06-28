//
//  PaymentOptionsInstallmentPlansViewController.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 05/04/23.
//

import UIKit

class PaymentOptionsInstallmentPlansViewController: UIViewController {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var tableView: UITableView!
    
    private var paymentOptions: [MakeInstallmentPayment_PaymentMethodOption] = []
    private var orderId = ""
    
    var base_url: String! {
        return PlistConstants.shared.baseURL
    }
    
    var inai_prepare_order_url: String! {
        return "\(base_url!)/orders"
    }
    
    var inai_get_payment_options_url: String! {
        return "\(base_url!)/payment-method-options"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.initialization()
    }
}
extension PaymentOptionsInstallmentPlansViewController{
    func initialization(){
        self.setUI()
        self.setData()
    }
    func setUI(){
        self.setTableView()
    }
    func setData(){
        self.prepareOrder()
    }
    func setTableView(){
        self.tableView.register(UINib(nibName: "PaymentOptionsListTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentOptionsListTableViewCell")
        self.tableView.separatorStyle = .none
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}

//MARK: - UITableViewDataSource
extension PaymentOptionsInstallmentPlansViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let paymentOptionsCount = self.paymentOptions.count
        if paymentOptionsCount == 0 {
            let noDataLabel: UILabel  = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text          = "No payment methods avaliable"
            noDataLabel.textColor     = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView  = noDataLabel
            tableView.separatorStyle  = .none
        }else{
            self.tableView.backgroundView = nil
        }
        return paymentOptionsCount
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let paymentOption = self.paymentOptions[indexPath.row]
        guard let paymentOptionsListTVC = tableView.dequeueReusableCell(withIdentifier: "PaymentOptionsListTableViewCell") as? PaymentOptionsListTableViewCell else { return UITableViewCell()}
        paymentOptionsListTVC.prePopulateData(title: sanitizeRailCode(paymentOption.railCode ?? ""))
        return paymentOptionsListTVC
    }
}

//MARK: - UItableViewDelegate
extension PaymentOptionsInstallmentPlansViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //navigate to payment method
        if let paymentOption = self.paymentOptions[indexPath.row].installmentPlans {
            if let paymentFormFieldsVC = UIStoryboard.init(name: "InstallmentPlans", bundle: Bundle.main).instantiateViewController(withIdentifier: "PaymentFormFieldsViewController") as? PaymentFormFieldsViewController{
                DispatchQueue.main.async{
                    paymentFormFieldsVC.selectedPaymentOption = self.paymentOptions[indexPath.row]
                    paymentFormFieldsVC.orderId = self.orderId
                    self.navigationController?.pushViewController(paymentFormFieldsVC, animated: true)
                }
            }
        }else{
            print("No installment plans for this method")
        }
    }
}

//MARK: - APICall
extension PaymentOptionsInstallmentPlansViewController{
    private func prepareOrder() {
        //  Initiate a new order
        self.activityIndicator.startAnimating()
        
        //  Prep postdata
        let Customer_ID_Key = "customerId-\(PlistConstants.shared.token)"
        var savedCustomerId: String? = UserDefaults.standard.string(forKey: Customer_ID_Key) ?? nil
        
        var body: [String: AnyHashable] = [
            "amount": DemoConstants.amount,
            "currency": DemoConstants.currency,
            "description": "Acme Shirt",
            "metadata": ["test_order_id": "5735"]
        ]
        
        if let savedCustomerId = savedCustomerId {
            //  Lets reuse the existing customer
            body["customer"] =  [ "id": savedCustomerId]
        } else {
            //  Create a new customer
            body["customer"] = ["email": "testdev@test.com",
                                "first_name": "Dev",
                                "last_name": "Smith",
                                "contact_number": "01010101010"]
        }
        
        self.request(url: URL(string: self.inai_prepare_order_url)!,
                     method: "POST",
                     postData: body) { (data, error) in
            
            var orderId: String? = nil
            
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                if let data = data {
                    if let responseOrderId = data["id"] as? String {
                        orderId = responseOrderId
                    }
                    
                    if savedCustomerId == nil {
                        if let customerId = data["customer_id"] as? String {
                            //  Save customer id to defaults so we can reuse it
                            savedCustomerId = customerId
                            UserDefaults.standard.set(customerId, forKey: Customer_ID_Key)
                        }
                    }
                }
            }
            
            self.activityIndicator.stopAnimating()
            if let orderId = orderId {
                self.orderId = orderId
                self.processPaymentOptions()
            }
        }
    }
    private func request(url: URL, method: String,
                         postData: [String: Any]?,
                         completion: @escaping ([String: Any]?, Error?) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        //  Set headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //  Attach postdata if applicable
        if let postData = postData {
            request.httpBody = try? JSONSerialization.data(withJSONObject: postData, options: .fragmentsAllowed)
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, urlRequest, error in
            var result: [String: Any]? = nil
            if let data = data {
                let json = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                result = json as? [String : Any]
            }
            
            DispatchQueue.main.async {
                print("\(result)")
                completion(result, error)
            }
        }
        //  Fire away
        task.resume()
    }
    private func processPaymentOptions() {
        self.activityIndicator.startAnimating()
        
        self.getPaymentOptions(
            orderId: self.orderId) { response, error in
                self.activityIndicator.stopAnimating()
                guard let respo = response else {
                    self.showAlert(error?.localizedDescription ?? "")
                    return
                }
                
                //  Lets render all payment options except Apply Pay as its handled separately
                self.paymentOptions = MakeInstallmentPayment_PaymentMethodOption.paymentOptionsFromJSON(respo)
                    .filter { self.sanitizeRailCode($0.railCode) != "Apple Pay" }
                self.tableView.reloadData()
            }
    }
    func getPaymentOptions(orderId: String,
                           completion: @escaping ([String: Any]?, Error?) -> Void) {
        var params: [String: String] = [:]
        params["order_id"] = orderId
        params["country"] = DemoConstants.country
        
        self.request(url: URL(string: inai_get_payment_options_url + buildQueryString(fromDictionary: params))!,
                     method: "GET",
                     postData: nil,
                     completion: completion)
    }
    func showAlert(_ message: String, title: String = "Alert", completion: ((UIAlertAction) -> Void)? = nil ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: completion))
        self.present(alert, animated: true, completion: nil)
    }
    func buildQueryString(fromDictionary parameters: [String:String]) -> String {
        var urlVars:[String] = []
        for (k, value) in parameters {
            let value = value as NSString
            if let encodedValue = value.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) {
                urlVars.append(k + "=" + encodedValue)
            }
        }
        return urlVars.isEmpty ? "" : "?" + urlVars.joined(separator: "&")
    }
    private func sanitizeRailCode(_ railCode: String?) -> String? {
        let sanitizedString = railCode?.replacingOccurrences(of: "_", with: " ")
        return sanitizedString?.capitalized
    }
}
