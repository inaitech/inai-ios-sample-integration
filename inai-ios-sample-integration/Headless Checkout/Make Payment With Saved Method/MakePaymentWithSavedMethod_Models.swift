//
//  MakePaymentWithSavedMethod_Models.swift
//  inai-ios-sample-integration
//
//  Created by Parag Dulam on 5/3/22.
//

import Foundation

class MakePaymentWithSavedMethod_FormField {
    var fieldType: String!
    var label: String!
    var placeHolder: String!
    var name: String!
    var required: Bool
    var value: String = ""
    var validations: MakePaymentWithSavedMethod_Validation?
    var validated: Bool = false
    
    init(_ json: [String: Any]) {
        self.fieldType = json["field_type"] as? String ?? ""
        self.label = json["label"] as? String ?? ""
        self.placeHolder = json["placeholder"] as? String ?? ""
        self.name = json["name"] as? String ?? ""
        self.required = json["required"] as? Bool ?? false
        if let validationsJSON = json["validations"] as? [String: Any] {
            self.validations = MakePaymentWithSavedMethod_Validation.validationFromJSON(validationsJSON)
        }
    }
}

struct MakePaymentWithSavedMethod_Validation {
    var pattern: String?
    var min_length: Int?
    var max_length: Int?
    var required: Bool?
    var input_regex_mask: String?
    
    static func validationFromJSON(_ json: [String: Any]) -> MakePaymentWithSavedMethod_Validation {
        let validation = MakePaymentWithSavedMethod_Validation(pattern: json["pattern"] as? String,
                                                min_length: json["min_length"] as? Int,
                                                max_length: json["max_length"] as? Int,
                                                required: json["required"] as? Bool,
                                                input_regex_mask: json["input_regex_mask"] as? String)
        return validation
    }
    
}

struct MakePaymentWithSavedMethod_PaymentMethodOption {
    var railCode: String?
    var paymentMethodId: String?
    var formFields: [MakePaymentWithSavedMethod_FormField]
    var dict: [String: Any]
    
    static func paymentOptionsFromJSON(_ json: [String: Any]) -> [MakePaymentWithSavedMethod_PaymentMethodOption] {
        var retVal: [MakePaymentWithSavedMethod_PaymentMethodOption] = []
        if let options = json["payment_method_options"] as? [[String: Any]] {
            for opt in options {
                if let rCode = opt["rail_code"] as? String,
                   let fFields = opt["form_fields"] as? [[String: Any]] {
                    var formFields: [MakePaymentWithSavedMethod_FormField] = []
                    for f in fFields {
                        let formField = MakePaymentWithSavedMethod_FormField(f)
                        formFields.append(formField)
                    }
                    let paymentOption = MakePaymentWithSavedMethod_PaymentMethodOption(railCode: rCode,
                                                                        formFields: formFields,
                                                                        dict: json)
                    retVal.append(paymentOption)
                }
            }
        }
        return retVal
    }
}


struct MakePaymentWithSavedMethod_SavedPaymentMethod {
    
    var type: String?
    var id: String?
    var customer_id: String?
    var typeJSON: [String: Any]?
    
    static func paymentMethodsFromJSON(_ json: [String: Any]) -> [MakePaymentWithSavedMethod_SavedPaymentMethod] {
        var retVal: [MakePaymentWithSavedMethod_SavedPaymentMethod] = []
        if let methods = json["payment_methods"] as? [[String: Any]] {
            for method in methods {
                if let id = method["id"] as? String,
                   let type = method["type"] as? String {
                    let paymentMethod = MakePaymentWithSavedMethod_SavedPaymentMethod(type: type, id: id,
                                                           customer_id: method["customer_id"] as? String,
                                                           typeJSON: method[type] as? [String : Any])
                    retVal.append(paymentMethod)
                }
            }
        }
        return retVal
    }
    
}
