//
//  SceneGraph.h
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <GLKit/GLKit.h>

#import "Node.h"

@interface SceneGraph : NSObject <GLKViewControllerDelegate>

@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) CGFloat scale;

- (void) addNode: (Node*) node;
- (NSSet*) nodesIntersectingRect: (CGRect) rect;

@end
