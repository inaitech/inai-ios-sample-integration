//
//  PaymentFormFieldTableViewCell.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 06/04/23.
//

import UIKit

class PaymentFormFieldTableViewCell: UITableViewCell {
    
    @IBOutlet var holderView: UIView!
    @IBOutlet var formTitleLbl: UILabel!
    @IBOutlet var textViewHolder: UIView!
    @IBOutlet var formFieldTxtField: UITextField!
    @IBOutlet var switchHolderView: UIView!
    @IBOutlet var formFieldSwitch: UISwitch!
    
    
    var formField: MakeInstallmentPayment_FormField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
        self.setupTextField()
    }
    func setupTextField() {
        self.formFieldTxtField.clipsToBounds = true
        self.formFieldTxtField.layer.cornerRadius = 5.0
        self.formFieldTxtField.layer.borderWidth = 1.0
        self.formFieldTxtField.layer.borderColor = UIColor(red: 240.0/255.0,
                                              green: 240.0/255.0,
                                              blue: 240.0/255.0,
                                              alpha: 1.0).cgColor
    }
    func updateTextFieldUI(textfield: UITextField) {
        if formField.validated {
            textfield.layer.borderColor = UIColor(red: 24.0/255.0, green: 172.0/255.0, blue: 174.0/255.0, alpha: 1.0).cgColor
        } else {
            textfield.layer.borderColor = UIColor(red: 244.0/255.0, green: 0, blue: 0, alpha: 1.0).cgColor
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func textFieldDidChange(_ tf: UITextField) {
        formField.value = tf.text!
        formField.validated = validateFormField()
        updateTextFieldUI(textfield:tf)
    }
    
    @IBAction func switchValueDidChange(_ swtch: UISwitch) {
        formField.value = swtch.isOn ? "true" : "false"
    }
    
}
extension PaymentFormFieldTableViewCell{
    func prePopulateCell(_ formField:MakeInstallmentPayment_FormField){
        self.formField = formField
        
        self.formTitleLbl.text = formField.label
        self.formFieldTxtField.placeholder = formField.placeHolder
        
        //  Show the appropriate input field as per field type
        if formField.fieldType == "checkbox" {
            self.textViewHolder.isHidden = true
            self.switchHolderView.isHidden = false
            self.formField.validated = true
        } else {
            self.textViewHolder.isHidden = false
            self.switchHolderView.isHidden = true
        }
        
        if ((formField.validations?.required) != nil && formField.validations?.required == true) {
            formTitleLbl.text = formTitleLbl.text! + "*"
        }
        
        //  Init form field validation status
        formField.validated = self.validateFormField()
    }
}

//MARK: - validation
extension PaymentFormFieldTableViewCell{
    func validateFormField() -> Bool {
        var validated = true
        let req = formField.validations?.required as? Bool
        let min = formField.validations?.min_length as? Int
        let max = formField.validations?.max_length as? Int
        let regex = formField.validations?.input_regex_mask as? String
        if req != nil && req == true && formField.value == "" {
            validated = false
        }
        if let min = min, formField.value.count < min {
            validated = false
        }
        if let max = max, formField.value.count > max {
            validated = false
        }
        if let regex = regex, formField.value.range(of: regex,
                                                    options: .regularExpression,
                                                    range: nil,
                                                    locale: nil) == nil {
            validated = false
        }
        return validated
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
        if (self.formField.name == "expiry") {
            //  Only validadate expiry text
            return self.shouldChangeExpiryTextfield(textField, shouldChangeCharactersIn: range, replacementString: string)
        }
        return true
    }
}
