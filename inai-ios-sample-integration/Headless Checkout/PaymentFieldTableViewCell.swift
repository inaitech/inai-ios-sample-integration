//
//  TextInputTableViewCell.swift
//  inai-checkout
//
//  Created by Parag Dulam on 5/1/22.
//

import Foundation
import UIKit
import inai_ios_sdk

class PaymentFieldTableViewCell: UITableViewCell,
                                 UITextFieldDelegate {
    
    var formField: FormField!
    var viewController: UIViewController!
    
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
        textField.leftViewMode = .always
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 30))
        textField.layer.borderColor = UIColor(red: 240.0/255.0,
                                              green: 240.0/255.0,
                                              blue: 240.0/255.0,
                                              alpha: 1.0).cgColor
    }
    

    @IBAction func textFieldDidChange(_ tf: UITextField) {
        formField.value = tf.text!
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func switchValueDidChange(_ swtch: UISwitch) {
        formField.value = swtch.isOn ? "true" : "false"
    }
    
    func updateUI(formField: FormField, viewController: UIViewController) {
        self.formField = formField
        self.viewController = viewController
        
        label.text = formField.label
        textField.placeholder = formField.placeHolder
        
        //  Show the appropriate input field as per field type
        if formField.fieldType == "checkbox" {
            self.textField.isHidden = true
        } else {
            self.switch_check.isHidden = true
        }
    }
}

