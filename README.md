# inai Checkout

## Overview
This repository demonstrates how to integrate Inai’s iOS Framework into your project.

## Features
### Headless Checkout
- Make a payment with variety of payment methods
    - File : [PaymentOptionsViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/e4c946d4dd694559d99ec3ffc269969918983b18/inai-ios-sample-integration/Headless%20Checkout/Payment%20Options/PaymentOptionsViewController.swift)
- Save a payment method
    - File : [SavePaymentOptionsViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/e4c946d4dd694559d99ec3ffc269969918983b18/inai-ios-sample-integration/Headless%20Checkout/Save%20Payment%20Method/SavePaymentOptionsViewController.swift)
- Pay with Saved Payment Method
    - File : [SavedPaymentOptionsViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/e4c946d4dd694559d99ec3ffc269969918983b18/inai-ios-sample-integration/Headless%20Checkout/Make%20Payment%20With%20Saved%20Method/SavedPaymentOptionsViewController.swift)
- Pay with Apple Pay (iOS) - [Setup Instructions](https://docs.inai.io/docs/apple-pay-with-inai-headless-checkout-ios)
    - File : [ApplePayViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/ae5b96f9ff4832a14e98f2d2b61864328e5a599b/inai-ios-sample-integration/Headless%20Checkout/Apple%20Pay/ApplePayViewController.swift)
- Validate Fields
    - File : [ValidateFieldsOptionsViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/e4c946d4dd694559d99ec3ffc269969918983b18/inai-ios-sample-integration/Headless%20Checkout/Validate%20Fields/ValidateFieldsViewController.swift)
- Get Card Info
    - File : [GetCardInfoViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/main/inai-ios-sample-integration/Headless%20Checkout/Get%20Card%20Info/GetCardInfoViewController.swift)

### Drop In Checkout
- Make a payment using Inai's Checkout Interface
    - File: [DropInCheckoutViewController.swift](https://github.com/inaitech/inai-ios-sample-integration/blob/f56e0caee501f1ca116c89932401a22b4e24164a/inai-ios-sample-integration/DropIn%20Checkout/DropInCheckoutViewController.swift)

## Prerequisites
- To begin, you will require the client username and client password values. Instructions to get this can be found [here](https://docs.inai.io/docs/getting-started)
- Make sure the following steps are completed in the merchant dashboard,
  - [Adding a Provider](https://docs.inai.io/docs/adding-a-payment-processor)
  - [Adding Payment Methods](https://docs.inai.io/docs/adding-a-payment-method)
  - [Customizing Checkout](https://docs.inai.io/docs/customizing-your-checkout)

### Minimum Requirements
iOS 9, Swift 5.x

## Setup

To start the backend NodeJS server:
1. Navigate to the ./server folder at the root level.
2. Run command `npm install` to install the dependency packages.
3. Update the following environment variables in the `./server/.env` file. This can be accessed from inai's merchant dashboard under `Settings > Credentials`
    - client_username
    - client_password
    
| **variables** | **description**                                               |
|---------------|---------------------------------------------------------------|
| client_username | client username under **Settings > Credentials** in dashboard |
| client_password | client password under **Settings > Credentials** in dashboard     

4. Run command `npm start` to start the nodejs backend server

To setup the inai sample app for iOS, follow the steps below:
1. `git clone https://github.com/inaitech/inai-ios-sample-integration`
2. Navigate to  ./config.plist fileupdate the following values :
   - Client Username
   - Base URL    // backend api server url eg: http://localhost:5009. If you are using a simulator, please replace localhost with the system IP address.
3. Run command `pod install` at the root level of the project to install the CocoaPods dependencies.
4. Open the workspace file `inai-ios-sample-integration.xcworkspace`, build and run the project.
5. In `DemoConstants.swift`, replace `amount`, `currency` & `country` as required.

## FAQs
<TBA>

## Support
Inai ios sdk reference docs available [here](https://docs.inai.io/docs/ios-native-sdk).
If you found a bug or want to suggest a new [feature/use case/sample], please contact **[customer support](mailto:support@inai.io)**.
