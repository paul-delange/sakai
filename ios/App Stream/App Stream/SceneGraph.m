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
    Background* _background;
}

@property (nonatomic, assign) CGFloat minimumZoom;
@property (nonatomic, assign) CGFloat maximumZoom;

@end

@implementation SceneGraph
@synthesize offset=_offset, zoom=_scale;
@synthesize minimumZoom, maximumZoom;

- (id) init 
{
    self = [super init];
    if( self ) {
        _nodes = [NSMutableSet new];
        _scale = 1.f;
        _offset = CGPointZero;
        
        self.minimumZoom = 0.5;
        self.maximumZoom = 2.0;
    }
    
    return self;
}

- (void) setZoom:(CGFloat) scale
{
    scale = MAX(scale, self.minimumZoom);
    scale = MIN(scale, self.maximumZoom);
    
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

- (void) setOffset: (CGPoint)offset
{
    GLKVector2 bgSize = _background.size;
    CGFloat maxZoom = 1./self.minimumZoom;
    
    CGFloat rangeX = bgSize.x /= maxZoom;
    CGFloat rangeY = bgSize.y /= maxZoom;
    
    CGFloat maxXOffset = (rangeX-CGRectGetWidth(_viewRect))/2.f;
    CGFloat maxYOffset = (rangeY-CGRectGetHeight(_viewRect))/2.f;
    
    NSParameterAssert(maxXOffset > 0);
    NSParameterAssert(maxYOffset > 0);
    
    if( offset.x < -maxXOffset ) {
        //NSLog(@"Moving off left");
        return;
    }
    else if( offset.x > maxXOffset ) {
        //NSLog(@"Moving off right");
        return;
    }
    else if(offset.y < -maxYOffset ) {
        //NSLog(@"Moving off top");
        return;
    }
    else if(offset.y > maxYOffset ) {
        //NSLog(@"Moving off bottom");
        return;
    }
    
    if( !CGPointEqualToPoint(offset, _offset) ) {
        _offset = offset;
        [_nodes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            GLKMatrix4 existing = [obj modelViewMatrix];
            existing.m30 = -_offset.x;
            existing.m31 = _offset.y;
            [obj setModelViewMatrix: existing];
        }];
    }
}

- (void) setCenter: (CGPoint) center animated: (BOOL) animated {
    
}

- (CGRect) visibleRect {
    CGRect rect = _viewRect;
    rect.origin.x -= _offset.x;
    rect.origin.y -= _offset.y;
    
    rect.origin.x /= _scale;
    rect.origin.y /= _scale;
    
    rect.size.width /= _scale;
    rect.size.height /= _scale;
    
    return rect;
}

#pragma mark - Object Graph
- (void) addNode:(Node *)node 
{
    NSParameterAssert([node isKindOfClass: [Node class]]);
    [_nodes addObject: node];
}

- (void) setBackground: (Background*) background 
{
#if DEBUG
    CGRect screen = [UIScreen mainScreen].bounds;
    screen.size.width /= self.minimumZoom;
    screen.size.height /= self.minimumZoom;
    GLKVector2 size = background.size;
    
    NSAssert(size.x >= screen.size.width, @"Background is %dx%d and the minimum is %dx%d", 
             (int)size.x, (int)size.y, 
             (int)screen.size.width, (int)screen.size.height);
    NSAssert(size.y >= screen.size.height, @"Background is %dx%d and the minimum is %dx%d", 
             (int)size.x, (int)size.y, 
             (int)screen.size.width, (int)screen.size.height);
#endif
    
    if( background != _background ) {
        if(_background ) {
            NSParameterAssert([_nodes containsObject: _background]);
            [_nodes removeObject: _background];
        }
        _background = background;
        
        if( _background )
            [_nodes addObject: _background];
    }
}

- (NSSet*) nodesIntersectingRect: (CGRect) rect 
{
    NSPredicate* inRectPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CGRect box = [evaluatedObject projectionInScreenRect: rect];
        return CGRectIntersectsRect([self visibleRect], box);
    }];
    
    return [_nodes filteredSetUsingPredicate: inRectPredicate];
}

#pragma mark - GLKViewControllerDelegate
- (void) glkViewControllerUpdate:(GLKViewController *)controller 
{
    NSParameterAssert([controller isViewLoaded]);
    CGRect viewRect = controller.view.bounds;
    if( !CGRectEqualToRect(viewRect, _viewRect) ) {
        _viewRect = viewRect;
        
        CGFloat halfWidth = CGRectGetWidth(viewRect) / 2.f;
        CGFloat halfHeight = CGRectGetHeight(viewRect) / 2.f;
        
        GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-halfWidth, halfWidth,
                                                          -halfHeight, halfHeight,
                                                          0.1, 100);
        [_nodes enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
            [obj setProjectionMatrix: projectionMatrix]; 
        }];
    }
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause 
{
    
}

@end
