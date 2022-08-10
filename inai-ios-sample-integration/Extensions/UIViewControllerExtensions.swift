//
//  UIViewControllerExtensions.swift
//  inai-ios-sample-integration
//
//  Created by Amit Yadav on 29/07/22.
//


import UIKit

extension UIViewController {
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
