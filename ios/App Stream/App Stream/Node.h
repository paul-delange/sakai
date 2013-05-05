//
//  Node.h
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>

@protocol Renderable <NSObject>
@required
- (void) render;

- (GLKMatrix4) modelViewMatrix;
- (void) setModelViewMatrix: (GLKMatrix4) modelViewMatrix;

- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix;

- (CGRect) projectionInScreenRect: (CGRect) viewport;

#if DEBUG   
@optional
- (void) debugRender;
#endif

@end

@interface Node : NSObject <Renderable>

@end

extern GLKVector3 GLKMatrix4GetScale(GLKMatrix4 matrix);
extern GLKVector3 GLKMatrix4GetTranslation(GLKMatrix4 matrix);