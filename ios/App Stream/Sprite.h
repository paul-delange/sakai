//
//  Sprite.h
//  App Stream
//
//  Created by de Lange Paul on 5/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TextureAtlas;

@interface Sprite : NSObject

@property (readonly, nonatomic) NSString* filename;

- (instancetype) initWithFilename: (NSString*) filename;
- (instancetype) initWithFilename: (NSString*) filename andTextureAtlas: (TextureAtlas*) atlas;

- (void) render;

@end
