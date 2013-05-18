//
//  SceneGraph.h
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "Sprite.h"
#import "Background.h"

@interface SceneGraph : NSObject <GLKViewControllerDelegate>

@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) CGFloat zoom;

- (void) addNode: (Node*) node;
- (void) addSprite: (Sprite*) sprite;

- (void) setBackground: (Background*) background;

- (void) setCenter: (CGPoint) center animated: (BOOL) animated;

- (NSSet*) nodesIntersectingRect: (CGRect) rect;

@end
