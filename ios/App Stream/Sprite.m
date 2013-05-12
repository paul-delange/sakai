//
//  Sprite.m
//  App Stream
//
//  Created by de Lange Paul on 5/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Sprite.h"

#import <GLKit/GLKit.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

@interface Sprite () {
    NSString* _filename;
    
    GLKTextureInfo* _texture;
    GLKBaseEffect* _effect;
    
    GLuint _vertexBuffer;
    GLuint _vertexArray;
}

@end

@implementation Sprite

- (instancetype) initWithFilename: (NSString*) filename 
{
    NSParameterAssert(filename);
    NSParameterAssert([EAGLContext currentContext]);
    
    self = [super init];
    if( self ) {
        if(!_texture) {
            NSError* error;
            NSDictionary* params = [NSDictionary dictionaryWithObject: [NSNumber numberWithBool: YES]
                                                               forKey: GLKTextureLoaderOriginBottomLeft];
            NSString* path = [[NSBundle mainBundle] pathForResource: filename
                                                             ofType: nil];
            NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath: path]);
            _texture = [GLKTextureLoader textureWithContentsOfFile: path
                                                           options: params
                                                             error: &error];
            NSAssert(!error, @"Error loading background texture: %@", error);
            NSParameterAssert(_texture.width == _texture.height);   //Should be square for good aspect ratio
        }
    }
    return self;
}

- (void) dealloc {
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    _effect = nil;
}

- (NSString*) filename 
{
    return _filename;
}
#pragma mark - Renderable
- (void) render
{    
    if( !_effect ) {
        NSParameterAssert(_texture);
        
        CGFloat halfWidth = _texture.width / 2.f;
        CGFloat halfHeight = _texture.height / 2.f;
        
        //x, y, z, normX, normY, normZ, texU, texV
        const CGFloat gCubeVertexData[] = {
            -halfWidth, -halfHeight, -0.2,   0.0, 0.0, -1.0,   0.0, 0.0,
            halfWidth, -halfHeight, -0.2,    0.0, 0.0, -1.0,   1.0, 0.0,
            -halfWidth, halfHeight, -0.2,    0.0, 0.0, -1.0,   0.0, 1.0,
            halfWidth, halfHeight, -0.2,     0.0, 0.0, -1.0,   1.0, 1.0
        };
        
        glGenVertexArraysOES(1, &_vertexArray);
        glBindVertexArrayOES(_vertexArray);
        
        glGenBuffers(1, &_vertexBuffer);
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(0));
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(12));
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 32, BUFFER_OFFSET(24));
        
        _effect = [[GLKBaseEffect alloc] init];
        _effect.texture2d0.name = _texture.name;
        _effect.texture2d0.envMode = GLKTextureEnvModeReplace;
    }
    
    glBindVertexArrayOES(_vertexArray);
    
    [_effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

- (CGRect) projectionInScreenRect: (CGRect) viewport {
    CGFloat halfWidth = _texture.width / 2.f;
    CGFloat halfHeight = _texture.height / 2.f;
    
    GLKVector3 upperLeft = GLKVector3Make(-halfWidth, halfHeight, -0.2);
    GLKVector3 lowerRight = GLKVector3Make(halfWidth, -halfHeight, -0.2);
    
    GLKMatrix4 model = _effect.transform.modelviewMatrix;
    GLKMatrix4 proj = _effect.transform.projectionMatrix;
    
    int vp[4] = {
        0,
        0,
        (int)CGRectGetWidth(viewport),
        (int)CGRectGetHeight(viewport)
    };
    
    GLKVector3 ulViewport = GLKMathProject(upperLeft, model, proj, vp);
    GLKVector3 lrViewport = GLKMathProject(lowerRight, model, proj, vp);
    
    return CGRectMake(ulViewport.x, CGRectGetMaxY(viewport)-ulViewport.y, 
                      lrViewport.x, CGRectGetMaxX(viewport)-lrViewport.y);
}

- (GLKMatrix4) modelViewMatrix {
    return _effect.transform.modelviewMatrix;
}

- (void) setModelViewMatrix: (GLKMatrix4) modelViewMatrix 
{
    NSParameterAssert(_effect);
    _effect.transform.modelviewMatrix = modelViewMatrix;
}

- (GLKMatrix4) projectionMatrix {
    return _effect.transform.projectionMatrix;
}

- (void) setProjectionMatrix: (GLKMatrix4) projectionMatrix
{
    NSParameterAssert(_effect);
    _effect.transform.projectionMatrix = projectionMatrix;
}

@end
