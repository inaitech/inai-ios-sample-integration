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
    
    var keyboardHandler: KeyboardHandler!
    var paymentFlow = Payment_Flow.checkout
    var orderId: String = ""
    
    // MARK: - Internal Methods
    // MARK: -
    override func viewDidLoad() {
        super.viewDidLoad()
        self.keyboardHandler = KeyboardHandler()
        setup(keyboardHandler: self.keyboardHandler,
              scrollView: self.scrollView,
              view: self.view)
        
        self.txt_card_number.delegate = self
        self.setupTextField()
        
        APIMethods.shared.prepareOrder { orderId, customerId in
            if let orderId = orderId {
                self.orderId = orderId
            }
        }
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
                                countryCode: PlistConstants.shared.country
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
}

extension GetCardInfoViewController: HandlesKeyboardEvent {}

