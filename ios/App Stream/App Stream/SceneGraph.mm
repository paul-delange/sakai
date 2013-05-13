//
//  SceneGraph.m
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SceneGraph.h"

#import <Box2D/Box2D.h>

#define PTM_RATIO   200

@interface SceneGraph () {
    NSMutableSet* _nodes;
    CGRect _viewRect;
    Background* _background;
    
    dispatch_source_t _animationSource;
    
    b2World* _world;
    b2Body* _body;
}

@property (nonatomic, assign) CGFloat minimumZoom;
@property (nonatomic, assign) CGFloat maximumZoom;

- (void) setOffset:(CGPoint)offset animated: (BOOL) animated;

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
        
        b2Vec2 gravity;
        gravity.y = 4;
        _world = new b2World(gravity);
        
    }
    
    return self;
}

- (void) dealloc {
    delete _world;
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
            existing = GLKMatrix4Multiply(existing, GLKMatrix4MakeTranslation(_offset.x, -_offset.y, 0));
            [obj setModelViewMatrix: existing];
        }];
    }
}

- (void) setOffset: (CGPoint)offset
{
    [self setOffset: offset animated: NO];
}

- (CGRect) visibleRect {
    CGRect rect = _viewRect;
    rect.origin.x -= _offset.x;// + CGRectGetWidth(_viewRect)/2.f;
    rect.origin.y -= _offset.y;// + CGRectGetWidth(_viewRect)/2.f;    
    return rect;
}

#pragma mark - Animations
- (BOOL) isAnimating {
    return _animationSource != nil;
}

- (void) cancelAnimation {
    if( _animationSource ) {
        dispatch_source_cancel(_animationSource);
        _animationSource = nil;
    }
}
   
- (void) setCenter: (CGPoint) center animated: (BOOL) animated {
    NSParameterAssert(_background);
    
    [self cancelAnimation];
    
    center.x -= CGRectGetWidth(_viewRect)/2.f;
    center.y -= CGRectGetHeight(_viewRect)/2.f;
    
    center.x -= self.offset.x;
    center.y -= self.offset.y;
    
    [self setOffset: CGPointMake(-center.x, -center.y) animated: animated];
}

- (void) setOffset: (CGPoint)offset animated: (BOOL) animated {
    [self cancelAnimation];
    
    GLKVector2 bgSize = _background.size;
    CGFloat maxZoom = 1./self.minimumZoom;
    
    CGFloat rangeX = bgSize.x / maxZoom;
    CGFloat rangeY = bgSize.y / maxZoom;
    
    CGFloat maxXOffset = (rangeX-CGRectGetWidth(_viewRect))/2.f;
    CGFloat maxYOffset = (rangeY-CGRectGetHeight(_viewRect))/2.f;
    
    NSParameterAssert(maxXOffset > 0);
    NSParameterAssert(maxYOffset > 0);
    
    if( offset.x < -maxXOffset ) {
        offset.x = -maxXOffset;
    }
    else if( offset.x > maxXOffset ) {
        offset.x = maxXOffset;
    }
    else if(offset.y < -maxYOffset ) {
        offset.y = -maxYOffset;
    }
    else if(offset.y > maxYOffset ) {
        offset.y = maxYOffset;
    }
    
    __block CGFloat progress = 0.f;
    __block CGPoint initial = _offset;
    
    void (^animation)(void) = ^{
        
        if( _animationSource ) {
            unsigned long timesFired = dispatch_source_get_data(_animationSource);
            progress += .1 * timesFired;
        }
        else {
            progress = 1.f;
        }
        
        CGFloat x = (offset.x - initial.x) * progress + initial.x;
        CGFloat y = (offset.y - initial.y) * progress + initial.y;
        
        CGPoint offset = CGPointMake(x, y);
        
        if( !CGPointEqualToPoint(offset, _offset) ) {
            _offset = offset;
        }
        
        if( progress >= 1.f )
            [self cancelAnimation];
    };
    
    if( animated ) {
        _animationSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(_animationSource, DISPATCH_TIME_NOW, 1 / 30.f * NSEC_PER_SEC, 1 / 300. * NSEC_PER_SEC);
        dispatch_source_set_event_handler(_animationSource, animation);
        dispatch_resume(_animationSource);
    }
    else {
        animation();
    }
}

#pragma mark - Object Graph
- (void) addNode:(Node *)node
{
    NSParameterAssert([node isKindOfClass: [Node class]]);
    [_nodes addObject: node];
    
    // Create ball body and shape
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.userData = (__bridge void*)node;
    _body = _world->CreateBody(&ballBodyDef);
    
    b2CircleShape circle;
    circle.m_radius = 100.0/PTM_RATIO;
    
    b2FixtureDef ballShapeDef;
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 1.0f;
    ballShapeDef.friction = 0.2f;
    ballShapeDef.restitution = 0.8f;
    _body->CreateFixture(&ballShapeDef);
}

- (void) setBackground: (Background*) background 
{
#if DEBUG
    CGRect screen = [UIScreen mainScreen].bounds;
    screen.size.width /= self.minimumZoom;
    screen.size.height /= self.minimumZoom;
    GLKVector2 size = background.size;
    
    NSAssert4(size.x >= screen.size.width, @"Background is %dx%d and the minimum is %dx%d", 
             (int)size.x, (int)size.y, 
             (int)screen.size.width, (int)screen.size.height);
    NSAssert4(size.y >= screen.size.height, @"Background is %dx%d and the minimum is %dx%d", 
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
    CGRect visible = [self visibleRect];
    NSPredicate* inRectPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CGRect box = [evaluatedObject projectionInScreenRect: rect];
        if( evaluatedObject != _background )
        NSLog(@"Visible: %@, Box: %@", NSStringFromCGRect(visible), NSStringFromCGRect(box));
        return CGRectIntersectsRect(visible, box);
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
    /*
    _world->Step(controller.timeSinceLastUpdate, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {    
        if (b->GetUserData() != NULL) {
            Node *ballData = (__bridge Node *)b->GetUserData();
            GLKMatrix4 mvm = [ballData modelViewMatrix];
            mvm.m30 = b->GetPosition().x + self.offset.x;
            mvm.m31 = b->GetPosition().y - self.offset.y;
            [ballData setModelViewMatrix: mvm];
        }        
    }*/
    
    GLKMatrix4 world = _background.modelViewMatrix;
    world.m30 = self.offset.x;
    world.m31 = -self.offset.y;
    [_background setModelViewMatrix: world];
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause
{
    
}

@end
