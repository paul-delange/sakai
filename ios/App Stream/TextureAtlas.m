//
//  TextureAtlas.m
//  App Stream
//
//  Created by de Lange Paul on 5/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "TextureAtlas.h"
#import "Sprite.h"

#import <GLKit/GLKit.h>

@interface TextureAtlas () {
    GLuint _renderFBO;
    NSArray* _spriteCoords;
    
    NSUInteger _widthFBO;
    NSUInteger _heightFBO;
}

@end

@implementation TextureAtlas
@synthesize texture;

- (id) init {
    self = [super init];
    if( self ) {
        //NSParameterAssert(strstr((const char*)glGetString(GL_EXTENSIONS), "GL_EXT_framebuffer_object"));
        
        //Get max texture size
        int MAX_TEXTURE_SIZE;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &MAX_TEXTURE_SIZE);
        
        //Create render texture
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);
        UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        NSData* data = UIImagePNGRepresentation(blank);
        
        NSDictionary* options = nil;
        NSError* error = nil;
        self.texture = [GLKTextureLoader textureWithContentsOfData: data
                                                           options: options
                                                             error: &error];
        NSAssert(!error, @"Error creating TextureAtlas texture object: %@", error);
        
        //Generate FBO
        glGenFramebuffers(1, &_renderFBO);
        glBindFramebuffer(GL_FRAMEBUFFER, _renderFBO);
        
        //Associate texture with FBO
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, self.texture.name, 0);
        NSParameterAssert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);
        
        _widthFBO = _heightFBO = MAX_TEXTURE_SIZE;
    }
    
    return self;
}

- (void) dealloc 
{
    glDeleteFramebuffers(1, &_renderFBO);
}

- (NSSet*) sprites 
{
    NSMutableSet* mutable = [NSMutableSet new];
    for(NSArray* row in _spriteCoords) {
        for(NSDictionary* column in row) 
            [mutable addObjectsFromArray: column.allKeys];
    }
    
    return mutable;
}

- (BOOL) addSprite: (Sprite*) sprite
{
    NSParameterAssert(sprite);
    
    NSString* filename = sprite.filename;
    NSString* filePath = [[NSBundle mainBundle] pathForResource: filename ofType:nil];
    NSParameterAssert([[NSFileManager defaultManager] fileExistsAtPath: filePath]);
    
    //Load texture
    NSDictionary* options = nil;
    NSError* error = nil;
    GLKTextureInfo* tex = [GLKTextureLoader textureWithContentsOfFile: filePath
                                                                  options: options
                                                                    error: &error];
    NSAssert(!error, @"Could not load texture %@, got error %@", filePath, error);
    
    texture = tex;
    
    /*
    if(tex.width > _widthFBO ) {
        NSLog(@"Sprite %@ is wider than the atlas", sprite);
        return NO;
    }
    
    if(tex.height > _heightFBO ) {
        NSLog(@"Sprite %@ is taller than the atlas", sprite);
        return NO;
    }
    
    CGRect renderRect = CGRectZero;
    CGFloat maxY = 0;
    for(NSMutableArray* row in _spriteCoords) {
        CGFloat maxX = 0;
        CGFloat minY = 0;
        CGFloat maxHeight = _heightFBO;
        for(NSDictionary* column in row) {
            for(NSValue* value in column.allValues) {
                CGRect rect = [value CGRectValue];
                maxX = MAX(maxX, CGRectGetMaxX(rect));
                maxHeight = MAX(maxHeight, CGRectGetHeight(rect));
                minY = CGRectGetMinY(rect);
                maxY = MAX(maxY, CGRectGetMaxY(rect));
            }
        }
        
        if( tex.width < _widthFBO - maxX ) {
            if( tex.height < maxHeight ) {
                //Add this sprite to this row
                renderRect = CGRectMake(maxX, minY, tex.width, tex.height);
                NSValue* value = [NSValue valueWithCGRect: renderRect];
                NSDictionary* entry = [NSDictionary dictionaryWithObject: value
                                                                  forKey: filename];
                [row addObject: entry];
                break;
            }
            else {
                //Try next row
            }
        }
        else {
            //Try next row
        }
    }
   
    if(CGRectEqualToRect(CGRectZero, renderRect)) {
        //Couldn't add this sprite, maybe we can make a new row
        if( tex.height < _heightFBO - maxY ) {
            //Create new row
            renderRect = CGRectMake(0, maxY, tex.width, tex.height);
            NSValue* value = [NSValue valueWithCGRect: renderRect];
            NSDictionary* entry = [NSDictionary dictionaryWithObject: value
                                                              forKey: filename];
            NSMutableArray* row = [NSMutableArray arrayWithObject: entry];
            NSMutableArray* combined = [NSMutableArray arrayWithObject: row];
            [combined addObjectsFromArray: _spriteCoords];
            _spriteCoords = combined;
        }
        else {
            NSLog(@"Strangely enough there was no space for %@", sprite);
            return NO;
        }
    }
    
    NSLog(@"Added %@ in %@", sprite, NSStringFromCGRect(renderRect));
    
    //Actually render the sprite...
    glBindFramebuffer(GL_FRAMEBUFFER, _renderFBO);
    glClear(GL_COLOR_BUFFER_BIT);
    
    const GLfloat squareVertices[] = {
        CGRectGetMinX(renderRect), CGRectGetMaxY(renderRect),
        CGRectGetMaxX(renderRect), CGRectGetMaxY(renderRect),
        CGRectGetMinX(renderRect), CGRectGetMinY(renderRect),
        CGRectGetMaxX(renderRect),  CGRectGetMinX(renderRect),
    };
    
    const GLfloat textureCoords[] = {
        0, 0,
        1, 0,
        0, 1,
        1, 1,
    };
    
    glEnableClientState(GL_VERTEX_ARRAY);
    //glEnableClientState(GL_NORMAL_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glBindTexture(GL_TEXTURE_2D, tex.name);
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    //glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, textureCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    glDisableClientState(GL_VERTEX_ARRAY);
    //glDisableClientState(GL_NORMAL_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    glBindFramebuffer(GL_FRAMEBUFFER, 0); //unbind
    */
    return YES;
     
}

- (BOOL) removeSprite: (Sprite*) sprite 
{
    NSParameterAssert(sprite);
    
    return YES;
}

- (CGRect) textureCoordinatesForSprite: (Sprite*) sprite
{
    //NSValue* value = [_spriteCoords objectForKey: sprite];
    //sreturn [value CGRectValue];
    return CGRectZero;
}

- (void) render 
{
    GLfloat vertices[] = {
        -1.0, 1.0,
        1.0, 1.0,
        -1.0, -1.0,
        1.0, -1.0, }; 
    
    GLfloat normals[] =  {
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 1.0 }; 
    
    GLfloat textureCoords[] = {
        0.0, 0.0,
        1.0, 0.0,
        0.0, 1.0,
        1.0, 1.0 };
    
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrthof(-5.0, 5.0, -7.5, 7.5, -1, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity(); 
    
    glEnable(GL_TEXTURE_2D);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glBindTexture(GL_TEXTURE_2D, texture.name);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glNormalPointer(GL_FLOAT, 0, normals);
    glTexCoordPointer(2, GL_FLOAT, 0, textureCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

@end
