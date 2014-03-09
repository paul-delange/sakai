//
//  ReceiptValidator.h
//  pm25
//
//  Created by Paul De Lange on 12/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#ifndef e_Anatomy_ReceiptValidator_h
#define e_Anatomy_ReceiptValidator_h

/** This function will verify the validity of a receipt using the method described by Apple. Validation performs the following steps:

 1. Confirm the app receipt was signed by Apple
 2. Verify the app receipt matches the app bundle identifier
 3. Verify the app receipt signature is correct
 
 @warning This function does not explicitly verify the app version is the same as the receipt version! If it does this, the user needs to download a new receipt every time the app updates.
 
 @see https://developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW2
 
 @param receiptURL The url to the receipt to validate
 @return true if valid, false otherwise
 
 */
FOUNDATION_EXPORT bool isValidReceipt(NSURL* receiptURL);


FOUNDATION_EXPORT bool isUnlockSubscriptionPurchased(void);

#endif
