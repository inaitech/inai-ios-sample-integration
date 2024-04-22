//
//  Modal.swift
//  inai-ios-sample-integration
//
//  Created by Shanmukh DM on 06/04/23.
//

import Foundation

struct InstallmentPlansOptions:Decodable, Encodable{
    let installmentPlans:[InstallmentPlanDetails]
    enum CodingKeys: String, CodingKey {
        case installmentPlans = "installment_plans"
    }
}

struct InstallmentPlanDetails:Decodable, Encodable{
    let installments: Int
    let amount, frequency, fees: String
    let planDetails: PlanDetails?
    let displayInformation: DisplayInformation?
    
    enum CodingKeys: String, CodingKey {
        case installments, amount, frequency, fees
        case planDetails = "plan_details"
        case displayInformation = "display_information"
    }
}

// MARK: - DisplayInformation
struct DisplayInformation: Codable {
    let header: Header
    let footer: Footer
}

// MARK: - Footer
struct Footer: Codable {
    let termsAndConditions: String
    let disclaimerMessage: String?
    
    enum CodingKeys: String, CodingKey {
        case termsAndConditions = "terms_and_conditions"
        case disclaimerMessage = "disclaimer_message"
    }
}

// MARK: - Header
struct Header: Codable {
    let name: String
    let logo: String
}

// MARK: - PlanDetails
struct PlanDetails: Codable {
    let id, duration: JSONNull?
    let installments: Int
    let issuerCode, planCode: String?
    let amount, frequency: String
    let fees: String
    
    enum CodingKeys: String, CodingKey {
        case id, duration, installments
        case issuerCode = "issuer_code"
        case planCode = "plan_code"
        case amount, frequency, fees
    }
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {
    
    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }
    
    public var hashValue: Int {
        return 0
    }
    
    public init() {}
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}




import Foundation

class MakeInstallmentPayment_FormField {
    var fieldType: String!
    var label: String!
    var placeHolder: String!
    var name: String!
    var required: Bool
    var value: String = ""
    var validations: MakeInstallmentPayment_Validation?
    var validated: Bool = false
    
    init(_ json: [String: Any]) {
        self.fieldType = json["field_type"] as? String ?? ""
        self.label = json["label"] as? String ?? ""
        self.placeHolder = json["placeholder"] as? String ?? ""
        self.name = json["name"] as? String ?? ""
        self.required = json["required"] as? Bool ?? false
        if let validationsJSON = json["validations"] as? [String: Any] {
            self.validations = MakeInstallmentPayment_Validation.validationFromJSON(validationsJSON)
        }
    }
}

struct MakeInstallmentPayment_Validation {
    var pattern: String?
    var min_length: Int?
    var max_length: Int?
    var required: Bool?
    var input_regex_mask: String?
    
    static func validationFromJSON(_ json: [String: Any]) -> MakeInstallmentPayment_Validation {
        let validation = MakeInstallmentPayment_Validation(pattern: json["pattern"] as? String,
                                                min_length: json["min_length"] as? Int,
                                                max_length: json["max_length"] as? Int,
                                                required: json["required"] as? Bool,
                                                input_regex_mask: json["input_regex_mask"] as? String)
        return validation
    }
    
}

struct MakeInstallmentPayment_PaymentMethodOption {
    var railCode: String?
    var installmentPlans:String?
    var paymentMethodId: String?
    var formFields: [MakeInstallmentPayment_FormField]
    var dict: [String: Any]
    
    static func paymentOptionsFromJSON(_ json: [String: Any]) -> [MakeInstallmentPayment_PaymentMethodOption] {
        var retVal: [MakeInstallmentPayment_PaymentMethodOption] = []
        if let options = json["payment_method_options"] as? [[String: Any]] {
            for opt in options {
                if let rCode = opt["rail_code"] as? String,
                   let fFields = opt["form_fields"] as? [[String: Any]] {
                    var formFields: [MakeInstallmentPayment_FormField] = []
                    for f in fFields {
                        let formField = MakeInstallmentPayment_FormField(f)
                        formFields.append(formField)
                    }
                    
                    var paymentOption = MakeInstallmentPayment_PaymentMethodOption(railCode: rCode,
                                                                        formFields: formFields,
                                                                        dict: json)
                    if let installmentPlans = opt["installment_plans"] as? String{
                        paymentOption = MakeInstallmentPayment_PaymentMethodOption(railCode: rCode,
                                                                            installmentPlans: installmentPlans,
                                                                            formFields: formFields,
                                                                            dict: json)
                    }
                    retVal.append(paymentOption)
                }
            }
        }
        return retVal
    }
}
