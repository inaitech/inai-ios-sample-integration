//
//  SavePayment_PaymentFieldsTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/1/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class SavePayment_PaymentFieldsTableViewCell: UITableViewCell,
                                 UITextFieldDelegate {
    
    var SavePayment_FormField: SavePayment_FormField!
    var viewController: UIViewController!
    var orderId: String!
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var switch_check: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupTextField()
    }
    
    func setupTextField() {
        textField.clipsToBounds = true
        textField.layer.cornerRadius = 5.0
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor(red: 240.0/255.0,
                                              green: 240.0/255.0,
                                              blue: 240.0/255.0,
                                              alpha: 1.0).cgColor
    }
    
    func validateSavePayment_FormField() -> Bool {
        var validated = true
        let req = SavePayment_FormField.validations?.required as? Bool
        let min = SavePayment_FormField.validations?.min_length as? Int
        let max = SavePayment_FormField.validations?.max_length as? Int
        let regex = SavePayment_FormField.validations?.input_regex_mask as? String
        if req != nil && req == true && SavePayment_FormField.value == "" {
            validated = false
        }
        if let min = min, SavePayment_FormField.value.count < min {
            validated = false
        }
        if let max = max, SavePayment_FormField.value.count > max {
            validated = false
        }
        if let regex = regex, SavePayment_FormField.value.range(of: regex,
                                                    options: .regularExpression,
                                                    range: nil,
                                                    locale: nil) == nil {
            validated = false
        }
        return validated
    }
    
    func updateTextFieldUI(textfield: UITextField) {
        if SavePayment_FormField.validated {
            textfield.layer.borderColor = UIColor(red: 24.0/255.0, green: 172.0/255.0, blue: 174.0/255.0, alpha: 1.0).cgColor
        } else {
            textfield.layer.borderColor = UIColor(red: 244.0/255.0, green: 0, blue: 0, alpha: 1.0).cgColor
        }
    }
    
    @IBAction func textFieldDidChange(_ tf: UITextField) {
        SavePayment_FormField.value = tf.text!
        SavePayment_FormField.validated = validateSavePayment_FormField()
        updateTextFieldUI(textfield:tf)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func switchValueDidChange(_ swtch: UISwitch) {
        SavePayment_FormField.value = swtch.isOn ? "true" : "false"
    }
    
    func updateUI(formField: SavePayment_FormField, viewController: UIViewController, orderId: String) {
        self.SavePayment_FormField = formField
        self.viewController = viewController
        self.orderId = orderId
        
        label.text = SavePayment_FormField.label
        textField.placeholder = SavePayment_FormField.placeHolder
        
        //  Show the appropriate input field as per field type
        if SavePayment_FormField.fieldType == "checkbox" {
            self.textField.isHidden = true
            self.SavePayment_FormField.validated = true
        } else {
            self.switch_check.isHidden = true
        }
        
        if ((SavePayment_FormField.validations?.required) != nil && SavePayment_FormField.validations?.required == true) {
            label.text = label.text! + "*"
        }
        
        //  Init form field validation status
        SavePayment_FormField.validated = self.validateSavePayment_FormField()
    }
    
    private func shouldChangeExpiryTextfield(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        guard let oldText = textField.text, let r = Range(range, in: oldText) else {
            //  No text change
            return true
        }
        
        let updatedText = oldText.replacingCharacters(in: r, with: string)
        
        //  Dont allow more than 5 chars
        if (updatedText.count > 5) {
            return false
        }
        
        //  Only allow numbers and forward slash for mm/yy expiry format
        let allowedCharacters = CharacterSet(charactersIn: "0123456789/")
        if updatedText.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
            //  Invalid characters on the expiry text value. Reject
            return false
        }
        
        //  We've ensured the string cannot contain any non allowed characters..
        //  Validate and format the value ot be mm/yy format
        
        let deletingText = updatedText.count < oldText.count
        
        
        var formattedText: String? = nil
        var shouldChange = true
        
        let parts = updatedText.components(separatedBy: "/")
        if (parts.count > 2) {
            shouldChange = false
        } else {
            var mmStr: String = parts.count > 0 ? parts[0] : ""
            let yyStr: String =  parts.count > 1 ? parts[1] : ""
            
            let mmInt: Int = Int(mmStr) ?? 0
            
            if (mmInt > 12 ||
                (mmInt == 0 && mmStr.count == 2) ||
                mmStr.count > 2 || yyStr.count > 2
            ) {
                //  Dont allow any invalid month/year entries
                return false
            }
            
            if (mmInt >= 0 && mmInt <= 12) {
                shouldChange = false
                //  Format the String as per rules
                if (mmStr.count == 1) {
                    formattedText = "\(mmInt)"
                    if (mmInt >= 1 && string == "/") {
                        //  Hitting slash after a single digit month evalue
                        //  Lets pad zero and add a slash
                        mmStr = "\(self.padZero(mmInt))/"
                    }
                } else if (mmStr.count == 2) {
                    if (!deletingText && mmInt > 0 && yyStr.count == 0) {
                        //  we've entered a two digit month, make sure we've padded zero and add a slash
                        mmStr = "\(self.padZero(mmInt))/"
                    }
                }
                
                if (yyStr.count > 0) {
                    //  Format the mm/yy string
                    formattedText = "\(mmStr)/\(yyStr)"
                } else {
                    //  We just have a month string
                    formattedText = mmStr
                }
            }
        }
        
        //  Update the text if applicable to formatted text
        if let _ = formattedText {
            textField.text = formattedText!
        }

        if (!shouldChange) {
            //  if shouldChange is set to false, the didChange event wont fire,
            //  Lets manually update the validation status for this case
            self.textFieldDidChange(textField)
        }
        
        return shouldChange
    }
    
    private func padZero(_ num: Int) -> String {
        return num > 9 ? "\(num)" : "0\(num)"
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if (self.SavePayment_FormField.name == "expiry") {
            //  Only validadate expiry text
            return self.shouldChangeExpiryTextfield(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        
        return true
    }
}

