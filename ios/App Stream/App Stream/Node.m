//
//  Node.m
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Node.h"

@implementation Node
@synthesize position = _position;
@end


GLKVector3 GLKMatrix4GetScale(GLKMatrix4 matrix) {
    //http://www.opengl.org/discussion_boards/showthread.php/166403-scale-in-matrix
    CGFloat xScale = sqrtf(matrix.m00*matrix.m00 + matrix.m10*matrix.m10 + matrix.m20*matrix.m20);
    CGFloat yScale = sqrtf(matrix.m01*matrix.m01 + matrix.m11*matrix.m11 + matrix.m21*matrix.m21);
    CGFloat zScale = sqrtf(matrix.m02*matrix.m02 + matrix.m12*matrix.m12 + matrix.m22*matrix.m22);
    
    return GLKVector3Make(xScale, yScale, zScale);
}

GLKVector3 GLKMatrix4GetTranslation(GLKMatrix4 matrix) {
    CGFloat xTranslation = matrix.m30;
    CGFloat yTranslation = matrix.m31;
    CGFloat zTranslation = matrix.m32;
    
    return GLKVector3Make(xTranslation, yTranslation, zTranslation);
}