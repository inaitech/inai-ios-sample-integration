//
//  CommonMethods.swift
//  inai-checkout
//
//  Created by Parag Dulam on 5/13/22.
//

import Foundation
import UIKit


let greenColor = UIColor(red: 24.0/255.0, green: 172.0/255.0, blue: 174.0/255.0, alpha: 1.0)
let redColor = UIColor(red: 244.0/255.0, green: 0, blue: 0, alpha: 1.0)

protocol HandlesKeyboardEvent {
    func setup(keyboardHandler: KeyboardHandler,
               scrollView: UIScrollView,
               view: UIView)
}

extension HandlesKeyboardEvent {
    
    func setup(keyboardHandler: KeyboardHandler,
               scrollView: UIScrollView,
               view: UIView) {
        keyboardHandler.setupKeyboardEvents(scrollView: scrollView,
                                            view: view)
    }
    
    
}


class KeyboardHandler: NSObject {
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

}
