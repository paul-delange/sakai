//
//  PhotoGrabber.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^kPhotoGrabberCompleted)(UIImage* image, NSError* error);

@interface PhotoGrabber : NSObject

+ (UIImage*) getPhotoForLocation: (CLLocation*) location withCompletionHandler: (kPhotoGrabberCompleted) completion;

+ (void) setPhoto: (UIImage*) image;

@end
