//
//  ContentLock.m
//  pm25
//
//  Created by Paul De Lange on 28/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "ContentLock.h"

#import <objc/runtime.h>

#import "ReceiptValidator.h"

static const void* kCompletionHandlerAssocationKey = "PurchaseCompletionHandler";

NSString * const kContentUnlockProductIdentifier = @"sexpert_unlock";

@import StoreKit;

@implementation ContentLock

+ (BOOL) unlockWithCompletion: (kContentLockRemovedHandler) completionHandler {
    if( ![SKPaymentQueue canMakePayments] )
        return NO;
    
    NSSet* productIdentifiers = [NSSet setWithObject: kContentUnlockProductIdentifier];
    SKProductsRequest* productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers: productIdentifiers];
    productsRequest.delegate =  (id<SKProductsRequestDelegate>)self;
    [productsRequest start];
    
    objc_setAssociatedObject(self, kCompletionHandlerAssocationKey, completionHandler, OBJC_ASSOCIATION_COPY);
    
    return YES;
}

+ (BOOL) lock {
    return NO;
}

+ (BOOL) tryLock {
#if TARGET_IPHONE_SIMULATOR
    return YES;
#else
    return isUnlockSubscriptionPurchased();
#endif
}

#pragma mark - NSObject
+ (void) initialize {
    [[SKPaymentQueue defaultQueue] addTransactionObserver: (id<SKPaymentTransactionObserver>)self];
}

#pragma mark - SKProductsRequestDelegate
+ (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray* invalid = response.invalidProductIdentifiers;
    
    if( [invalid count] ) {
        NSDictionary* userInfo = @{ @"Invalid Identifiers" : invalid };
        NSError* error = [NSError errorWithDomain: @"In-App"
                                             code: -823
                                         userInfo: userInfo];
        kContentLockRemovedHandler handler = objc_getAssociatedObject(self, kCompletionHandlerAssocationKey);
        objc_setAssociatedObject(self, kCompletionHandlerAssocationKey, nil,  OBJC_ASSOCIATION_COPY);
        
        if( handler )
            handler(error);
        
    }
    else {
        NSParameterAssert([response.products count] == 1);
        SKProduct* product = response.products.lastObject;
        SKPayment* payment = [SKPayment paymentWithProduct: product];
        
        [[SKPaymentQueue defaultQueue] addPayment: payment];
    }
}

+ (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    
    kContentLockRemovedHandler handler = objc_getAssociatedObject(self, kCompletionHandlerAssocationKey);
    objc_setAssociatedObject(self, kCompletionHandlerAssocationKey, nil,  OBJC_ASSOCIATION_COPY);
    
    if( handler )
        handler(error);
    
    //DLogError(error);
}

#pragma mark - SKPaymentTransactionObserver
+ (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for(SKPaymentTransaction* transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStateFailed:
            {
                kContentLockRemovedHandler handler = objc_getAssociatedObject(self, kCompletionHandlerAssocationKey);
                objc_setAssociatedObject(self, kCompletionHandlerAssocationKey, nil,  OBJC_ASSOCIATION_COPY);
                
                if( handler )
                    handler(transaction.error);
                
                [queue finishTransaction: transaction];
                break;
            }
            case SKPaymentTransactionStateRestored:
            case SKPaymentTransactionStatePurchased:
            {
                kContentLockRemovedHandler handler = objc_getAssociatedObject(self, kCompletionHandlerAssocationKey);
                objc_setAssociatedObject(self, kCompletionHandlerAssocationKey, nil,  OBJC_ASSOCIATION_COPY);
                
                NSURL* appReceiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
                if( isValidReceipt(appReceiptURL) ) {
                    NSParameterAssert(isUnlockSubscriptionPurchased());
                    
                    if( handler )
                        handler(nil);
                }
                else {
                    NSError* error = [NSError errorWithDomain: @"In-App"
                                                         code: -666     //You are the devil
                                                     userInfo: nil];
                    if( handler )
                        handler(error);
                    
                    //DLogError(error);
                }
                
                [queue finishTransaction: transaction];
                break;
            }
            case SKPaymentTransactionStatePurchasing:
                break;
            default:
                break;
        }
    }
}

@end
