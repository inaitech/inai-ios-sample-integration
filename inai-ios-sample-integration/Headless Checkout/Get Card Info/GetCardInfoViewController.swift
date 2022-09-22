//
//  GetCardInfoViewController.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 02/08/22.
//

import UIKit
import inai_ios_sdk

enum Payment_Flow: Int {
    case checkout
    case add_payment_method
    case pay_with_payment_method
    case get_card_info
    case pay_headless
    case validate_fields
    case headless_checkout
    case payouts_add_method
    case payouts_validate_fields
    case crypto_get_estimate
}

class GetCardInfoViewController: UIViewController, UITextFieldDelegate,
                                 InaiCardInfoDelegate {
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var txt_card_number: UITextField!
    @IBOutlet var btn_get_card_info: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Internal vars
    // MARK: -
    private var gettingCardInfo = false
    private var pendingCardNumber:String? = nil
    private var showCardInfoResult = false
    
    var paymentFlow = Payment_Flow.checkout
    var orderId: String = ""
    
    var base_url: String! {
        return PlistConstants.shared.baseURL
    }
    
    var inai_prepare_order_url: String! {
        return "\(base_url!)/orders"
    }
    
    // MARK: - Internal Methods
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardEvents( scrollView: self.scrollView, view: self.view)
        
        self.txt_card_number.delegate = self
        self.setupTextField()
        
        self.prepareOrder()
    }
    
    private var scrollViewBottomConstraint: NSLayoutConstraint!
    func setupKeyboardEvents(scrollView: UIScrollView,
                             view: UIView) {
        self.scrollViewBottomConstraint = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0)
        self.scrollViewBottomConstraint?.priority = .defaultHigh
        self.scrollViewBottomConstraint?.isActive = true
       
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.notifyKeyboardWillChange),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: .none)
       
       NotificationCenter.default.addObserver(self,
                                              selector: #selector(self.notifyKeyboardWillHide),
                                              name: UIResponder.keyboardWillHideNotification,
                                              object: nil)
   }
   
   @objc func notifyKeyboardWillChange(_ notification: NSNotification){
       
       let userInfo:NSDictionary = notification.userInfo! as NSDictionary
       let keyboardFrame:NSValue = userInfo.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue
       let keyboardRectangle = keyboardFrame.cgRectValue
       let keyboardHeight = keyboardRectangle.height
       //  Offset scrollview accordingly..
       self.scrollViewBottomConstraint?.constant = -keyboardHeight
   }
   
   @objc func notifyKeyboardWillHide(_ notification: NSNotification){
       self.scrollViewBottomConstraint?.constant = 0
   }

    
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
            }
        }
    }
    
    private func request(url: URL, method: String,
                         postData: [String: Any]?,
                         completion: @escaping ([String: Any]?, Error?) -> Void) {
        
        let authStr = "\(PlistConstants.shared.token)"
        let encodedAuthStr = "BASIC \(Data(authStr.utf8).base64EncodedString())"
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        //  Set headers
        request.setValue(encodedAuthStr, forHTTPHeaderField: "Authorization")
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
                completion(result, error)
            }
        }
        //  Fire away
        task.resume()
    }
    
    func setupTextField() {
        self.txt_card_number.clipsToBounds = true
        self.txt_card_number.layer.cornerRadius = 5.0
        self.txt_card_number.rightViewMode = .always
        self.txt_card_number.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 30))
    }
    
    // MARK: - Delegate Methods
    // MARK: -
    func cardInfoFetched(with result: Inai_CardInfoResult) {
        self.gettingCardInfo = false
        self.btn_get_card_info.isEnabled = true
        
        self.activityIndicator.stopAnimating()
        switch result.status {
        case Inai_CardInfoStatus.success:
            if let card = result.data["card"] as? [String: Any], let brand = card["brand"] as? String {
                self.setCreditCardImage(brand)
            }
            
            if (self.showCardInfoResult) {
                let resultStr = convertDictToStr(result.data)
                self.showAlert("Get Card Info Success! \(resultStr)", title: "Result")
            }
            break
            
        case Inai_CardInfoStatus.failed :
            if (self.showCardInfoResult) {
                let resultStr = convertDictToStr(result.data)
                self.showAlert("Get Card Info Failed! \(resultStr)", title: "Result")
            }
            break
        @unknown default:
            break
        }
        
        //  Do we have a pending request?
        if let pendingCardNumber = pendingCardNumber {
            self.getCardInfo(pendingCardNumber)
        }
        
        self.showCardInfoResult = false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func textFieldDidChange(_ tf: UITextField) {
        self.updateCardImageIntextField()
    }
    
    // MARK: - Button Actions
    // MARK: -
    @IBAction func clickedGetCardInfo(_ sender: Any) {
        self.hideKeyboard()
        let cardNumber = self.txt_card_number.text!
        if (cardNumber.count < 6) {
            self.showResult("Please fill at least 6 digits of the Card Number")
            return
        }
        self.showCardInfoResult = true
        self.getCardInfo(cardNumber)
    }
    
    func hideKeyboard() {
        //  Hide keyboard
        self.view.endEditing(true)
    }
    
    
    func showResult(_ message: String) {
        let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func setCreditCardImage(_ brand: String) {
        let cardImage = UIImage(named: brand.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) ?? UIImage(named: "unknown_card")
        let iconContainer = UIView(frame: CGRect(x: 0, y: 0, width: 60, height: 30))
        let cardView = UIImageView(frame: iconContainer.frame)
        cardView.image = cardImage
        cardView.contentMode = .scaleAspectFit
        iconContainer.addSubview(cardView)
        self.txt_card_number.rightViewMode = .always
        self.txt_card_number.rightView = iconContainer
    }
    
    private func getCardInfo(_ cardNumber: String) {
        pendingCardNumber = nil
        if (gettingCardInfo) {
            //  We're already in the middle of a fetch call
            //  Lets queue this request
            pendingCardNumber = cardNumber
            return
        }
        
        self.btn_get_card_info.isEnabled = false
        self.activityIndicator.startAnimating()
        
        let config = InaiConfig(token: PlistConstants.shared.token,
                                orderId : self.orderId,
                                countryCode: DemoConstants.country
        )
        
        if let inaiCheckout = InaiCheckout(config: config) {
            self.gettingCardInfo = true
            inaiCheckout.getCardInfo(cardNumber: cardNumber,
                                     viewController: self, delegate: self)
        }
    }
    
    func updateCardImageIntextField() {
        if (self.txt_card_number.text?.count ?? 0 > 5) {
            //  This is a card number field, lets fetch card info and set the card image if we have it
            //  Min len of 6 required for getCardInfo
            let cardNumber = self.txt_card_number.text!
            self.getCardInfo(cardNumber)
        } else {
            //  Add hodler view to Maintain padding
            self.txt_card_number.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 30))
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

