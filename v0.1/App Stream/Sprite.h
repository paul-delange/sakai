//
//  Sprite.h
//  App Stream
//
//  Created by de Lange Paul on 5/1/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "Node.h"

@interface Sprite : Node

@property (readonly, nonatomic) NSString* filename;
@property (assign, nonatomic) CGFloat zDepth;
@property (assign, nonatomic) BOOL dynamic;

- (instancetype) initWithFilename: (NSString*) filename;
- (CGSize) size;

@end
