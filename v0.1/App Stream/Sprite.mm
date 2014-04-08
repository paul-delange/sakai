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

#define Z_DEPTH -0.25

static inline const char * GetGLErrorString(GLenum error)
{
    const char *str;
    switch( error )
    {
        case GL_NO_ERROR:
            str = "GL_NO_ERROR";
            break;
        case GL_INVALID_ENUM:
            str = "GL_INVALID_ENUM";
            break;
        case GL_INVALID_VALUE:
            str = "GL_INVALID_VALUE";
            break;
        case GL_INVALID_OPERATION:
            str = "GL_INVALID_OPERATION";
            break;      
#if defined __gl_h_ || defined __gl3_h_
        case GL_OUT_OF_MEMORY:
            str = "GL_OUT_OF_MEMORY";
            break;
        case GL_INVALID_FRAMEBUFFER_OPERATION:
            str = "GL_INVALID_FRAMEBUFFER_OPERATION";
            break;
#endif
#if defined __gl_h_
        case GL_STACK_OVERFLOW:
            str = "GL_STACK_OVERFLOW";
            break;
        case GL_STACK_UNDERFLOW:
            str = "GL_STACK_UNDERFLOW";
            break;
        case GL_TABLE_TOO_LARGE:
            str = "GL_TABLE_TOO_LARGE";
            break;
#endif
        default:
            str = "(ERROR: Unknown Error Enum)";
            break;
    }
    return str;
};

#define GetGLError()                                    \
{                                                       \
GLenum err = glGetError();                          \
while (err != GL_NO_ERROR) {                        \
NSLog(@"GLError %s set in File:%s Line:%d\n",   \
GetGLErrorString(err),                  \
__FILE__,                               \
__LINE__);                              \
err = glGetError();                             \
}                                                   \
}

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
            NSAssert1(!error, @"Error loading background texture: %@", error);
            NSParameterAssert(_texture.width == _texture.height);   //Should be square for good aspect ratio
            
            NSParameterAssert(_texture);
            
            CGFloat halfWidth = _texture.width / 2.f;
            CGFloat halfHeight = _texture.height / 2.f;
            
            //x, y, texU, texV
            const CGFloat gCubeVertexData[] = {
                -halfWidth, -halfHeight,      0.0, 0.0,
                halfWidth, -halfHeight,       1.0, 0.0,
                -halfWidth, halfHeight,       0.0, 1.0,
                halfWidth, halfHeight,       1.0, 1.0
            };
            
            glGenVertexArraysOES(1, &_vertexArray);
            glBindVertexArrayOES(_vertexArray);
            
            glGenBuffers(1, &_vertexBuffer);
            glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
            glBufferData(GL_ARRAY_BUFFER, sizeof(gCubeVertexData), gCubeVertexData, GL_STATIC_DRAW);
            
            glEnableVertexAttribArray(GLKVertexAttribPosition);
            glVertexAttribPointer(GLKVertexAttribPosition, 2, GL_FLOAT, GL_FALSE, 16, BUFFER_OFFSET(0));
            glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
            glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 16, BUFFER_OFFSET(8));
            
            NSParameterAssert(glGetError() == GL_NO_ERROR);
            
            _effect = [[GLKBaseEffect alloc] init];
            _effect.texture2d0.name = _texture.name;
            _effect.texture2d0.envMode = GLKTextureEnvModeModulate;
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

- (CGSize) size
{
    return CGSizeMake(_texture.width, _texture.height);
}

#pragma mark - Renderable
- (void) render
{    
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindVertexArrayOES(_vertexArray);
    
    [_effect prepareToDraw];
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisable(GL_BLEND);
}

- (CGRect) projectionInScreenRect: (CGRect) viewport {
    CGFloat halfWidth = _texture.width / 2.f;
    CGFloat halfHeight = _texture.height / 2.f;
    
    GLKVector3 upperLeft = GLKVector3Make(-halfWidth, halfHeight, Z_DEPTH);
    GLKVector3 lowerRight = GLKVector3Make(halfWidth, -halfHeight, Z_DEPTH);
    
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
    
    return CGRectMake(ulViewport.x, CGRectGetHeight(viewport)-ulViewport.y, 
                      lrViewport.x-ulViewport.x, ulViewport.y-lrViewport.y);
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
    
    //NSLog(@"Proj: %@", NSStringFromGLKMatrix4(projectionMatrix));
    
    _effect.transform.projectionMatrix = projectionMatrix;
}

#pragma mark - Node


@end
