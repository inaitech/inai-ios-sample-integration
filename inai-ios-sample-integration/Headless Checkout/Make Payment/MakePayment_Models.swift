//
//  MakePayment_Models.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/3/22.
//

import Foundation
enum MakePayment_FormFieldType:String{
    case textField = "textfield"
    case checkbox = "checkbox"
    case button = "button"
    case select = "select"
}
class MakePayment_FormField {
    var fieldType: MakePayment_FormFieldType!
    var label: String!
    var placeHolder: String!
    var name: String!
    var required: Bool
    var value: String = ""
    var validations: MakePayment_Validation?
    var validated: Bool = false
    var data:MakePayment_Data?
    
    init(_ json: [String: Any]) {
        self.fieldType = MakePayment_FormFieldType(rawValue: json["field_type"] as? String ?? "") ?? .textField
        self.label = json["label"] as? String ?? ""
        self.placeHolder = json["placeholder"] as? String ?? ""
        self.name = json["name"] as? String ?? ""
        self.required = json["required"] as? Bool ?? false
        if let validationsJSON = json["validations"] as? [String: Any] {
            self.validations = MakePayment_Validation.validationFromJSON(validationsJSON)
        }
        if let dataJSON = json["data"] as? [String:Any]{
            self.data = MakePayment_Data(dataJSON)
        }
    }
}

struct MakePayment_Validation {
    var pattern: String?
    var min_length: Int?
    var max_length: Int?
    var required: Bool?
    var input_regex_mask: String?
    
    static func validationFromJSON(_ json: [String: Any]) -> MakePayment_Validation {
        let validation = MakePayment_Validation(pattern: json["pattern"] as? String,
                                                min_length: json["min_length"] as? Int,
                                                max_length: json["max_length"] as? Int,
                                                required: json["required"] as? Bool,
                                                input_regex_mask: json["input_regex_mask"] as? String)
        return validation
    }
    
}

struct MakePayment_PaymentMethodOption {
    var category: String?
    var railCode: String?
    var paymentMethodId: String?
    var modes: [MakePayment_Mode]
    var formFields: [MakePayment_FormField]
    var dict: [String: Any]
    
    static func paymentOptionsFromJSON(_ json: [String: Any]) -> [MakePayment_PaymentMethodOption] {
        var retVal: [MakePayment_PaymentMethodOption] = []
        if let options = json["payment_method_options"] as? [[String: Any]] {
            for opt in options {
                if let rCode = opt["rail_code"] as? String,
                   let fFields = opt["form_fields"] as? [[String: Any]], let category = opt["category"] as? String {
                    
                    var formFields: [MakePayment_FormField] = []
                    for f in fFields {
                        let formField = MakePayment_FormField(f)
                        formFields.append(formField)
                    }
                    var paymentModesList:[MakePayment_Mode] = []
                    if let paymentModesDict = opt["modes"] as? [[String:Any]]{
                        for paymentModeDict in paymentModesDict{
                            let paymentOption = MakePayment_Mode(paymentModeDict)
                            if paymentOption.supportedCurrentPlatform{
                                paymentModesList.append(paymentOption)
                            }
                        }
                    }
                    let paymentOption = MakePayment_PaymentMethodOption(category: category,railCode: rCode, modes: paymentModesList, formFields: formFields, dict: json)
                    retVal.append(paymentOption)
                }
            }
        }
        return retVal
    }
}

struct MakePayment_Mode{
    var label:String
    var code:String
    var supportedCurrentPlatform:Bool
    var form_fields:[MakePayment_FormField] = []
    
    init(_ dictionary:[String: Any]) {
        self.label = dictionary["label"] as? String ?? ""
        self.code = dictionary["code"] as? String ?? ""
        self.supportedCurrentPlatform = (dictionary["supported_platforms"] as? [String] ?? []).contains("MOBILE")
        if let fFields = dictionary["form_fields"] as? [[String: Any]] {
            var formFields: [MakePayment_FormField] = []
            for f in fFields {
                let formField = MakePayment_FormField(f)
                formFields.append(formField)
            }
            self.form_fields = formFields
        }
    }
}

struct MakePayment_Value{
    let label:String
    let value:String
    let symbolUrl:String
    
    init(label:String,value:String,symbolUrl:String){
        self.label = label
        self.value = value
        self.symbolUrl = symbolUrl
    }
    init(_ dictionary: [String:Any]) {
        self.label = dictionary["label"] as? String ?? ""
        self.value = dictionary["value"] as? String ?? ""
        self.symbolUrl = dictionary["symbol_url"] as? String ?? ""
    }
}
struct MakePayment_Data{
    var values:[MakePayment_Value] = []
    
    init (_ dictionary: [String:Any]) {
        var valueList:[MakePayment_Value] = []
        if let valuesDictArray = dictionary["values"] as? [[String:Any]]{
            for valuesDict in valuesDictArray{
                valueList.append(MakePayment_Value(valuesDict))
            }
            self.values = valueList
        }
    }
}




struct MakePayment_PaymentMethodOptionIndia {
    var category: String?
    var paymentOptions:[MakePayment_PaymentMethodOption] = []
    static func paymentOptionsFromJSON(_ json: [String: Any]) -> [MakePayment_PaymentMethodOptionIndia] {
        var categoryVal = [MakePayment_PaymentMethodOptionIndia]()
        var retVal: [MakePayment_PaymentMethodOption] = []
        if let options = json["payment_method_options"] as? [[String: Any]] {
            for opt in options {
                if let rCode = opt["rail_code"] as? String,
                   let fFields = opt["form_fields"] as? [[String: Any]], let category = opt["category"] as? String {
                    
                    var formFields: [MakePayment_FormField] = []
                    for f in fFields {
                        let formField = MakePayment_FormField(f)
                        formFields.append(formField)
                    }
                    var paymentModesList:[MakePayment_Mode] = []
                    if let paymentModesDict = opt["modes"] as? [[String:Any]]{
                        for paymentModeDict in paymentModesDict{
                            let paymentOption = MakePayment_Mode(paymentModeDict)
                            if paymentOption.supportedCurrentPlatform{
                                paymentModesList.append(paymentOption)
                            }
                        }
                    }
                    let paymentOption = MakePayment_PaymentMethodOption(category: category,railCode: rCode, modes: paymentModesList, formFields: formFields, dict: json)
                    if categoryVal.isEmpty{
                        categoryVal.append(MakePayment_PaymentMethodOptionIndia(category: category,paymentOptions: [paymentOption]))
                    }else{
                        if categoryVal.filter({$0.category == category}).isEmpty {
                            categoryVal.append(MakePayment_PaymentMethodOptionIndia(category: category,paymentOptions: [paymentOption]))
                        } else {
                            for (indx,categorVal) in categoryVal.enumerated(){
                                if categorVal.category == category{
                                    categoryVal[indx].paymentOptions.append(paymentOption)
                                }
                            }
                        }
                    }
                }
            }
        }
        return categoryVal
    }
}
