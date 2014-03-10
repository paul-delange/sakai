//
//  ReceiptValidator.c
//  pm25
//
//  Created by Paul De Lange on 12/02/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#include "ReceiptValidator.h"

#import "ContentLock.h"

#include <openssl/pkcs7.h>
#include <openssl/x509.h>

// Most information for this is available here:
//      https://developer.apple.com/library/mac/releasenotes/General/ValidateAppStoreReceipt/Introduction.html
//
// But there is a lot of information missing from the documentation and this project can help:
//      https://github.com/rmaddy/VerifyStoreReceiptiOS
//
// This one is good too, but includes a number of security holes:
//      https://github.com/robotmedia/RMStore/blob/master/RMStore/Optional/RMAppReceipt.m
//
// The certificate can be downloaded here:
//      http://www.apple.com/appleca/AppleIncRootCertificate.cer
//

//  This is the base64 encoded certificate. I feel it is a little bit safer compiled here than sitting in the app resource bundle as a .cer file
static NSString* kAppleRootCertificate = @"MIIEuzCCA6OgAwIBAgIBAjANBgkqhkiG9w0BAQUFADBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwHhcNMDYwNDI1MjE0MDM2WhcNMzUwMjA5MjE0MDM2WjBiMQswCQYDVQQGEwJVUzETMBEGA1UEChMKQXBwbGUgSW5jLjEmMCQGA1UECxMdQXBwbGUgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkxFjAUBgNVBAMTDUFwcGxlIFJvb3QgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDkkakJH5HbHkdQ6wXtXnmELes2oldMVeyLGYne+Uts9QerIjAC6Bg++FAJ039BqJj50cpmnCRrEdCju+QbKsMflZ56DKRHi1vUFjczy8QPTc4UadHJGXL1XQ7Vf1+b8iUDulWPTV0N8WQ1IxVLFVkds5T39pyez1C6wVhQZ48ItCD3y6wsIG9wtj8BMIy3Q88PnT3zK0koGsj+zrW5DtleHNbLPbU6rfQPDgCSC7EhFi501TwN22IWq6NxkkdTVcGvL0Gz+PvjcM3mo0xFfh9Ma1CWQYnEdGILEINBhzOKgbEwWOxaBDKMaLOPHd5lc/9nXmW8Sdh2nzMUZaF3lMktAgMBAAGjggF6MIIBdjAOBgNVHQ8BAf8EBAMCAQYwDwYDVR0TAQH/BAUwAwEB/zAdBgNVHQ4EFgQUK9BpR5R2Cf70a40uQKb3R01/CF4wHwYDVR0jBBgwFoAUK9BpR5R2Cf70a40uQKb3R01/CF4wggERBgNVHSAEggEIMIIBBDCCAQAGCSqGSIb3Y2QFATCB8jAqBggrBgEFBQcCARYeaHR0cHM6Ly93d3cuYXBwbGUuY29tL2FwcGxlY2EvMIHDBggrBgEFBQcCAjCBthqBs1JlbGlhbmNlIG9uIHRoaXMgY2VydGlmaWNhdGUgYnkgYW55IHBhcnR5IGFzc3VtZXMgYWNjZXB0YW5jZSBvZiB0aGUgdGhlbiBhcHBsaWNhYmxlIHN0YW5kYXJkIHRlcm1zIGFuZCBjb25kaXRpb25zIG9mIHVzZSwgY2VydGlmaWNhdGUgcG9saWN5IGFuZCBjZXJ0aWZpY2F0aW9uIHByYWN0aWNlIHN0YXRlbWVudHMuMA0GCSqGSIb3DQEBBQUAA4IBAQBcNplMLXi37Yyb3PN3m/J20ncwT8EfhYOFG5k9RzfyqZtAjizUsZAS2L70c5vu0mQPy3lPNNiiPvl4/2vIB+x9OYOLUyDTOMSxv5pPCmv/K/xZpwUJfBdAVhEedNO3iyM7R6PVbyTi69G3cN8PReEnyvFteO3ntRcXqNx+IjXKJdXZD9Zr1KIkIxH3oayPc4FgxhtbCS+SsvhESPBgOJ4V9T0mZyCKM2r3DYLP3uujL/lTaltkwGMzd/c6ByxW69oPIQ7aunMZT7XZNn/Bh1XZp5m5MkL72NVxnn6hUrcbvZNCJBIqxw8dtk2cXmPIS4AXUKqK1drk/NAJBzewdXUh";


bool isValidReceipt(NSURL* receiptURL) {
    NSData* rootCert = [[NSData alloc] initWithBase64EncodedString: kAppleRootCertificate options: 0];

    NSCParameterAssert(rootCert);
    
    ERR_load_PKCS7_strings();
    ERR_load_X509_strings();
    OpenSSL_add_all_digests();
    
    const char* receiptPath = [receiptURL fileSystemRepresentation];
    FILE* fp = fopen(receiptPath, "rb");
    if( fp == NULL )
        return false;
    
    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
    fclose(fp);
    
    if( p7 == NULL )
        return false;
    
    if(!PKCS7_type_is_signed(p7)) {
        PKCS7_free(p7);
        return false;
    }
    
    if(!PKCS7_type_is_data(p7->d.sign->contents)) {
        PKCS7_free(p7);
        return nil;
    }
    
    int verifyReturnValue = 0;
    
    //Check this receipt was signed by apple
    X509_STORE *store = X509_STORE_new();
    if( store ) {
        const uint8_t * data = (uint8_t*)[rootCert bytes];
        X509* appleCA = d2i_X509(NULL, &data, (long)[rootCert length]);
        if( appleCA ) {
            BIO *payload = BIO_new(BIO_s_mem());
            X509_STORE_add_cert(store, appleCA);
            
            if( payload ) {
                verifyReturnValue = PKCS7_verify(p7, NULL, store, NULL, payload, 0);
                BIO_free(payload);
            }
            
            X509_free(appleCA);
        }
        
        X509_STORE_free(store);
    }
    EVP_cleanup();
    
    if( verifyReturnValue != 1 ) {
        PKCS7_free(p7);
        return false;
    }
    
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
    const uint8_t *p = octets->data;
	const uint8_t *end = p + octets->length;
    
	int type = 0;
	int xclass = 0;
	long length = 0;
    
	ASN1_get_object(&p, &length, &type, &xclass, end - p);
	if (type != V_ASN1_SET) {
		PKCS7_free(p7);
		return false;
	}
    
    NSData* opaqueValue = nil;
    NSData* sha1hash = nil;
    NSData* identifier = nil;
    
    while (p < end) {
		ASN1_get_object(&p, &length, &type, &xclass, end - p);
		if (type != V_ASN1_SEQUENCE) {
			break;
        }
        
		const uint8_t *seq_end = p + length;
        
		int attr_type = 0;
		int attr_version = 0;
        
		// Attribute type
		ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		if (type == V_ASN1_INTEGER && length == 1) {
			attr_type = p[0];
		}
		p += length;
        
#if DEBUG
        NSString* (^stringValue)(int) = ^(int type) {
            switch (type) {
                case 3:
                    return @"App Version";
                case 2:
                    return @"Bundle Identifier";
                case 4:
                    return @"Opaque Value";
                case 5:
                    return @"SHA-1 Hash";
                case 17:
                    return @"In-App Purchase Receipt";
                case 19:
                    return @"Original Application Version";
                case 21:
                    return @"Receipt Expiration Date";
                default:
                    return [NSString stringWithFormat: @"Unknown Attribute (%d)", type];
            }
        };
        
        NSLog(@"Receipt Attribute: %@", stringValue(attr_type));
#endif
        
        if( attr_type == 4 ) {
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER && length == 1) {
                attr_version = p[0];
                attr_version = attr_version;
            }
            p += length;
            
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_OCTET_STRING) {
                opaqueValue = [NSData dataWithBytes:p length:(NSUInteger)length];
            }
            else {
                verifyReturnValue = false;
            }
            p += length;
        }
        else if( attr_type == 5 ) {
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER && length == 1) {
                attr_version = p[0];
                attr_version = attr_version;
            }
            p += length;
            
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_OCTET_STRING) {
                sha1hash = [NSData dataWithBytes: p length: (NSUInteger)length];
            }
            else {
                verifyReturnValue = false;
            }
            p += length;
        }
        else if( attr_type == 2 ) {
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER && length == 1) {
                attr_version = p[0];
                attr_version = attr_version;
            }
            p += length;
            
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_OCTET_STRING) {
                int str_type = 0;
                long str_length = 0;
                const uint8_t *str_p = p;
                ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                if (str_type == V_ASN1_UTF8STRING) {
                    identifier = [NSData dataWithBytes: p length: (NSUInteger)length];
                    
                    NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                length:(NSUInteger)str_length
                                                              encoding:NSUTF8StringEncoding];
                    if( ![string isEqualToString: APPLICATION_BUNDLE_IDENTIFIER] )
                        verifyReturnValue = false;
                }
                else {
                    verifyReturnValue = false;
                }
            }
            else {
                verifyReturnValue = false;
            }
        }
        
        if( verifyReturnValue != 1 ) {
            PKCS7_free(p7);
            return false;
        }
        
        // Skip any remaining fields in this SEQUENCE
        while (p < seq_end) {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            p += length;
        }
    }
    
    PKCS7_free(p7);
    
    if( !opaqueValue || !sha1hash ) {
        return false;
    }
    
    //Check the hash matches
    unsigned char uuidBytes[16];
    NSUUID* vendorUUID = [[UIDevice currentDevice] identifierForVendor];
    [vendorUUID getUUIDBytes: uuidBytes];
    
    NSMutableData* digest = [NSMutableData new];
    [digest appendBytes: uuidBytes length: sizeof(uuidBytes)];
    [digest appendData: opaqueValue];
    [digest appendData: identifier];
    
    NSMutableData* hash = [NSMutableData dataWithLength: SHA_DIGEST_LENGTH];
    SHA1([digest bytes], [digest length], [hash mutableBytes]);
    
    return [hash isEqualToData: sha1hash];
}

NSSet *parseInAppPurchasesProductIdentifiers(NSData *inappData) {
    NSMutableSet* productIdentifiers = [NSMutableSet new];
    
	int type = 0;
	int xclass = 0;
	long length = 0;
    
	NSUInteger dataLenght = [inappData length];
	const uint8_t *p = [inappData bytes];
    
	const uint8_t *end = p + dataLenght;
    
	while (p < end) {
		ASN1_get_object(&p, &length, &type, &xclass, end - p);
        
		const uint8_t *set_end = p + length;
        
		if(type != V_ASN1_SET) {
			break;
		}
        
        
		while (p < set_end) {
			ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
			if (type != V_ASN1_SEQUENCE) {
				break;
            }
            
			const uint8_t *seq_end = p + length;
            
			int attr_type = 0;
			int attr_version = 0;
            
			// Attribute type
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_INTEGER) {
				if(length == 1) {
					attr_type = p[0];
				}
				else if(length == 2) {
					attr_type = p[0] * 0x100 + p[1]
					;
				}
			}
			p += length;
            
			// Attribute version
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_INTEGER && length == 1) {
                // clang analyser hit (wontfix at the moment, since the code might come in handy later)
                // But if someone has a convincing case throwing that out, I might do so, Roddi
				attr_version = p[0];
			}
			p += length;
            
#if DEBUG
            NSString* (^stringValue)(int) = ^(int type) {
                switch (type) {
                    case 1701:
                        return @"Quantity";
                    case 1702:
                        return @"Product Identifier";
                    case 1703:
                        return @"Transaction Identifier";
                    case 1705:
                        return @"Original Transaction Identifier";
                    case 1704:
                        return @"Purchase Date";
                    case 1706:
                        return @"Original Purchase Date";
                    case 1708:
                        return @"Subscription Expiration Date";
                    case 1712:
                        return @"Cancellation Date";
                    case 1711:
                        return @"Web Order Line Item ID";
                    default:
                        return [NSString stringWithFormat: @"Unknown Field (%d)", type];
                }
            };
            
            NSLog(@"In-App Receipt Field: %@", stringValue(attr_type));
#endif
            
			// Only parse attributes we're interested in
			if (attr_type == 1702) {
				ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
				if (type == V_ASN1_OCTET_STRING) {
                    
                    int str_type = 0;
                    long str_length = 0;
                    const uint8_t *str_p = p;
                    ASN1_get_object(&str_p, &str_length, &str_type, &xclass, seq_end - str_p);
                    if (str_type == V_ASN1_UTF8STRING) {
                        NSString *string = [[NSString alloc] initWithBytes:str_p
                                                                    length:(NSUInteger)str_length
                                                                  encoding:NSUTF8StringEncoding];
                        [productIdentifiers addObject: string];
                    }
				}
                
				p += length;
			}
            
			// Skip any remaining fields in this SEQUENCE
			while (p < seq_end) {
				ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
				p += length;
			}
		}
        
		// Skip any remaining fields in this SET
		while (p < set_end) {
			ASN1_get_object(&p, &length, &type, &xclass, set_end - p);
			p += length;
		}
	}
    
	return productIdentifiers;
}

bool isUnlockSubscriptionPurchased(void) {
    //This next line to me is a huge danger. Hackers can change the receipt that is available there...
    NSURL* receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    
    ERR_load_PKCS7_strings();
    OpenSSL_add_all_digests();
    
    const char* receiptPath = [receiptURL fileSystemRepresentation];
    FILE* fp = fopen(receiptPath, "rb");
    if( fp == NULL )
        return nil;
    
    PKCS7 *p7 = d2i_PKCS7_fp(fp, NULL);
    fclose(fp);
    
    if( p7 == NULL )
        return nil;
    
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
    const uint8_t *p = octets->data;
	const uint8_t *end = p + octets->length;
    
	int type = 0;
	int xclass = 0;
	long length = 0;
    
	ASN1_get_object(&p, &length, &type, &xclass, end - p);
	if (type != V_ASN1_SET) {
		PKCS7_free(p7);
		return nil;
	}
    
	while (p < end) {
		ASN1_get_object(&p, &length, &type, &xclass, end - p);
		if (type != V_ASN1_SEQUENCE) {
			break;
        }
        
		const uint8_t *seq_end = p + length;
        
		int attr_type = 0;
		int attr_version = 0;
        
		// Attribute type
		ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
		if (type == V_ASN1_INTEGER && length == 1) {
			attr_type = p[0];
		}
		p += length;
        
        // Only parse in app purchase
        if (attr_type == 17) {
            
            // Attribute version
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            if (type == V_ASN1_INTEGER && length == 1) {
                attr_version = p[0];
                attr_version = attr_version;
            }
            p += length;
            
			ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
			if (type == V_ASN1_OCTET_STRING) {
                NSData *data = [NSData dataWithBytes:p length:(NSUInteger)length];
                
                NSSet *inApp = parseInAppPurchasesProductIdentifiers(data);

                for(NSString* identifier in inApp) {
                    if( [identifier isEqualToString: kContentUnlockProductIdentifier] )
                        return true;
                }
            }
            
            p += length;
            
            continue;
        }
        
        // Skip any remaining fields in this SEQUENCE
        while (p < seq_end) {
            ASN1_get_object(&p, &length, &type, &xclass, seq_end - p);
            p += length;
        }
    }
    
    PKCS7_free(p7);
    
    return false;
}