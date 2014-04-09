//
//  SKNode+Dragging.h
//  AppWorld
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface SKNode (Dragging)

@property (assign, setter = setDraggable:) BOOL isDraggable;

- (void) willStartDragging;
- (void) willEndDragging;

-(void)dragForDuration:(NSTimeInterval) frameDuration;

@end
