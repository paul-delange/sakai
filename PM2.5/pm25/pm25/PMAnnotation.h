//
//  PMAnnotation.h
//  pm25
//
//  Created by Paul De Lange on 13/03/14.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface PMAnnotation : MKPointAnnotation

@property (assign) NSUInteger pmValue;

@end