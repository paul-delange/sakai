//
//  AVMetadataFaceObject+GazeTracking.m
//  iSpy
//
//  Created by Paul de Lange on 11/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AVMetadataFaceObject+GazeTracking.h"

@implementation AVMetadataFaceObject (GazeTracking)

- (BOOL) isFacingCamera {
    return YES;
    
    NSParameterAssert([self hasRollAngle]);
    NSParameterAssert([self hasYawAngle]);
    return fabs(self.rollAngle) < 30 && fabs(self.yawAngle) < 30;
}

@end
