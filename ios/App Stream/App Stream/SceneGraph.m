//
//  SceneGraph.m
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SceneGraph.h"

@interface SceneGraph () {
    NSMutableSet* _nodes;
    CGRect _viewRect;
}

@end

@implementation SceneGraph
@synthesize offset=_offset, scale=_scale;

- (id) init 
{
    self = [super init];
    if( self ) {
        _nodes = [NSMutableSet new];
        self.scale = 0.f;
        self.offset = CGPointZero;
    }
    return self;
}

- (void) setScale:(CGFloat)scale 
{
    if( scale != _scale ) {
        _scale = scale;
        [_nodes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            //TODO: Does not handle rotation
            GLKMatrix4 existing = GLKMatrix4MakeScale(_scale, _scale, 1.0);
            existing = GLKMatrix4Multiply(existing, GLKMatrix4MakeTranslation(-_offset.x, -_offset.y, 0));
            [obj setModelViewMatrix: existing];
        }];
    }
}

- (void) setOffset:(CGPoint)offset
{
    if( !CGPointEqualToPoint(offset, _offset) ) {
        _offset = offset;
        [_nodes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            GLKMatrix4 existing = [obj modelViewMatrix];
            existing.m30 = -_offset.x;
            existing.m31 = -_offset.y;
            [obj setModelViewMatrix: existing];
        }];
    }
}

#pragma mark - Object Graph
- (void) addNode:(Node *)node 
{
    NSParameterAssert([node isKindOfClass: [Node class]]);
    [_nodes addObject: node];
}

- (NSSet*) nodesIntersectingRect: (CGRect) rect 
{
    NSPredicate* inRectPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CGRect box = [evaluatedObject projectionInScreenRect: rect];
        if( CGRectIntersectsRect(rect, box) ) {
            return YES;
        }
        NSLog(@"Lost");
        return NO;
    }];
    
    return [_nodes filteredSetUsingPredicate: inRectPredicate];
}

#pragma mark - GLKViewControllerDelegate
- (void) glkViewControllerUpdate:(GLKViewController *)controller 
{
    NSParameterAssert([controller isViewLoaded]);
    CGRect viewRect = controller.view.bounds;
    if( !CGRectEqualToRect(viewRect, _viewRect) ) {
        NSLog(@"Changed");
        CGFloat halfWidth = CGRectGetWidth(viewRect) / 2.f;
        CGFloat halfHeight = CGRectGetHeight(viewRect) / 2.f;
        
        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-halfWidth, halfWidth,
                                                          -halfHeight, halfHeight,
                                                          0.1, 100);
        [_nodes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [obj setProjectionMatrix: projectionMatrix]; 
        }];
        
        _viewRect = viewRect;
    }
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause 
{
    
}

@end
