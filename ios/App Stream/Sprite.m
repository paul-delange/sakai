//
//  Sprite.m
//  App Stream
//
//  Created by de Lange Paul on 5/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Sprite.h"
#import "TextureAtlas.h"

#import <GLKit/GLKit.h>

@interface Sprite () {
    TextureAtlas* _atlas;
    NSString* _filename;
}

@property (strong, nonatomic) TextureAtlas* atlas;

@end

@implementation Sprite
@synthesize atlas=_atlas;

- (instancetype) initWithFilename: (NSString*) filename 
{
    return [self initWithFilename: filename andTextureAtlas: nil];
}

- (instancetype) initWithFilename: (NSString*) filename andTextureAtlas: (TextureAtlas*) atlas
{
    NSParameterAssert(filename);
    
    self = [super init];
    if( self ) {
        _filename = filename;

        if( atlas ) {
            BOOL success = [atlas addSprite: self];
            if( !success ) {
                NSLog(@"Failed to add %@ to texture atlas %@. Defaulting to un-atlased sprite", filename, atlas);
            }
            _atlas = atlas;
        }
        
        if( !_atlas ) {
            NSAssert(atlas, @"//TODO: handle individual sprites");
        }
    }
    
    return self;
}

- (void) dealloc 
{
    [EAGLContext setCurrentContext: nil];
}

- (NSString*) filename 
{
    return _filename;
}

- (TextureAtlas*) atlas 
{
    return _atlas;
}

- (void) render
{
    //Render by getting texture / tex coords from texture atlas
}

@end
