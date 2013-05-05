//
//  TextureAtlas.h
//  App Stream
//
//  Created by de Lange Paul on 5/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GLKTextureInfo;
@class Sprite;

@interface TextureAtlas : NSObject

@property (strong, nonatomic) GLKTextureInfo* texture;
@property (readonly, nonatomic) NSSet* sprites;

- (BOOL) addSprite: (Sprite*) sprite;       //False if there is no room
- (BOOL) removeSprite: (Sprite*) sprite;    //False if this sprite isn't managed here

- (CGRect) textureCoordinatesForSprite: (Sprite*) sprite;

- (void) render;

@end
