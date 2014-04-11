//
//  FaceObject.h
//  iSpy
//
//  Created by Paul de Lange on 11/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <opencv2/opencv.hpp>

@interface FaceObject : NSObject

@property (assign) NSInteger foundationID;
@property (assign) CGRect bounds;

@property (assign) BOOL isFacingCamera;

@property (copy) NSSet* eyes;

@end
