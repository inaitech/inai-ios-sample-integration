//
//  PaymentFormFieldsViewController.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 06/04/23.
//

import UIKit
import inai_ios_sdk
class PaymentFormFieldsViewController: UIViewController {
    
    @IBOutlet var holderView: UIView!
    @IBOutlet var tableView: UITableView!
    
    var orderId:String!
    var selectedPaymentOption:MakeInstallmentPayment_PaymentMethodOption!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: "PaymentFormFieldTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentFormFieldTableViewCell")
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let keyboardHeight = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardHeight, right: 0)
        }
    }

    @objc func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.2, animations: {
            // For some reason adding inset in keyboardWillShow is animated by itself but removing is not, that's why we have to use animateWithDuration here
            self.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        })
    }

    deinit {
        print("denit")
        NotificationCenter.default.removeObserver(self)
    }

    @objc func checkoutButtonTapped(_ btn: UIButton) {
        self.view.endEditing(true)
        let requiredFieldsFilled = checkAllFieldsValidated()
        if (!requiredFieldsFilled) {
            showAlert("Please fill all required fields with valid Input")
            return
        }
        
        self.processCheckout()
    }
    
    private func checkAllFieldsValidated() -> Bool {
        var retVal: Bool = true
        for fo in selectedPaymentOption.formFields {
            if fo.validated == false {
                retVal = false
                break
            }
        }
        return retVal
    }
    
    private func pay(token: String, paymentDetails: [String: Any],
                     orderId: String, countryCode: String, paymentMethodOption: String) {
        if let getInstallmentPlansVC = UIStoryboard.init(name: "InstallmentPlans", bundle: Bundle.main).instantiateViewController(withIdentifier: "GetInstallmentPlansViewController") as? GetInstallmentPlansViewController{
            DispatchQueue.main.async{
                getInstallmentPlansVC.paymentDetails = paymentDetails
                getInstallmentPlansVC.orderId = orderId
                getInstallmentPlansVC.selectedPaymentMethodOption = paymentMethodOption
                getInstallmentPlansVC.countryCode = countryCode
                self.navigationController?.pushViewController(getInstallmentPlansVC, animated: true)
            }
        }
    }
    
    private func generatePaymentDetails(selectedPaymentOption: MakeInstallmentPayment_PaymentMethodOption!) -> [String: Any] {
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
    
    private func processCheckout() {
        let paymentDetails = generatePaymentDetails(selectedPaymentOption: selectedPaymentOption)
        self.pay(token: PlistConstants.shared.token,
                 paymentDetails: paymentDetails,
                 orderId: self.orderId,
                 countryCode: DemoConstants.country,
                 paymentMethodOption: selectedPaymentOption.railCode!)
    }
}

extension PaymentFormFieldsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedPaymentOption.formFields.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let formField = self.selectedPaymentOption.formFields[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentFormFieldTableViewCell", for: indexPath) as? PaymentFormFieldTableViewCell{
            cell.prePopulateCell(formField)//updateUI(formField: formField, viewController: self, orderId: self.orderId)
            return cell
        }else{
            return UITableViewCell()
        }
        
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let customView = UIView(frame: CGRect(x: 0, y: 0, width: (tableView.frame.width - 40), height: 80))
        //  customView.backgroundColor = UIColor(red: 0.46, green: 0.45, blue: 0.87, alpha: 1.00)
        let btn_checkout = UIButton(type: .system)
        btn_checkout.frame = CGRect(x: 20, y: 20, width: customView.frame.width, height: 40)
        btn_checkout.setTitle("Installment Plans", for: .normal)
        btn_checkout.setTitleColor(UIColor.white, for: .normal)
        btn_checkout.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        btn_checkout.backgroundColor = UIColor(red: 0.46, green: 0.45, blue: 0.87, alpha: 1.00)
        btn_checkout.addTarget(self, action: #selector(checkoutButtonTapped(_:)), for: .touchUpInside)
        
        customView.addSubview(btn_checkout)
        
        return customView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 60
    }
    
    func showResult(_ message: String) {
        let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension PaymentFormFieldsViewController: InaiCheckoutDelegate {
    
    private func goToHomeScreen(action: UIAlertAction) -> Void {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func paymentFinished(with result: Inai_PaymentResult) {
        switch result.status {
        case Inai_PaymentStatus.success:
            let resultStr = convertDictToStr(result.data)
            self.showAlert("Payment Success! \(resultStr)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.failed:
            let strError = convertDictToStr(result.data)
            self.showAlert("Payment Failed with data: \(strError)", title: "Result", completion: goToHomeScreen)
            break
            
        case Inai_PaymentStatus.canceled:
            let message = result.data["message"] ?? "Payment Canceled!"
            self.showAlert(message as! String, title: "Result", completion: goToHomeScreen)
            break
        @unknown default:
            break;
        }
    }
    
    func showAlert(_ message: String, title: String = "Alert", completion: ((UIAlertAction) -> Void)? = nil ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: completion))
        self.present(alert, animated: true, completion: nil)
    }
    
    func convertDictToStr(_ dict: [String:Any]) -> String {
        var jsonStr = "";
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dict, options: .fragmentsAllowed)
            jsonStr = String(data: jsonData, encoding: String.Encoding.utf8) ?? ""
        } catch {}
        
        return jsonStr
    }
    
    func convertStrToDict(_ text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
