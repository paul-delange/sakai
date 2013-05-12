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

- (instancetype) initWithFilename: (NSString*) filename;

@end
