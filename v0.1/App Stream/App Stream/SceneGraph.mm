//
//  SceneGraph.m
//  App Stream
//
//  Created by de Lange Paul on 5/5/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "SceneGraph.h"

#import "Sprite.h"

#import <Box2D/Box2D.h>

#define PTM_RATIO   20

@interface SceneGraph () {
    NSMutableSet* _nodes;
    CGRect _viewRect;
    GLKMatrix4 _projectionViewMatrix;
    
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
        
        b2Vec2 gravity = b2Vec2_zero;
        _world = new b2World(gravity);
        _world->SetContinuousPhysics(true);
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
            existing = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(_offset.x, -_offset.y, 0), existing);
            [obj setModelViewMatrix: existing];
        }];
    }
}

- (void) setOffset: (CGPoint)offset
{
    [self setOffset: offset animated: NO];
}

- (CGRect) visibleRect {
    
    CGFloat height = CGRectGetHeight(_viewRect) / self.zoom;
    CGFloat width = CGRectGetWidth(_viewRect) / self.zoom;
    CGFloat x = 0;//-CGRectGetWidth(_viewRect) / 2.f;
    CGFloat y = 0;//- CGRectGetHeight(_viewRect) / 2.f;
    
    
    CGRect rect = CGRectMake(x, y, width, height);
    
    //NSLog(@"Visible: %@", NSStringFromCGRect(rect));
    
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

    [self setOffset: CGPointMake(-center.x, center.y) animated: animated];
}

- (void) setOffset: (CGPoint)offset animated: (BOOL) animated {
    [self cancelAnimation];
    
    CGSize bgSize = _background.size;
    CGFloat maxZoom = 1./self.minimumZoom;
    
    CGFloat rangeX = bgSize.width / maxZoom;
    CGFloat rangeY = bgSize.height / maxZoom;
    
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
}

- (void) addSprite: (Sprite*) sprite
{
    [self addNode: sprite];
    
    if( sprite.dynamic ) {
        // Create ball body and shape
        b2BodyDef ballBodyDef;
        ballBodyDef.type = b2_dynamicBody;;
        ballBodyDef.userData = (__bridge void*)sprite;
        
        double x = (double)arc4random() / ARC4RANDOM_MAX;
        double y = (double)arc4random() / ARC4RANDOM_MAX;
        
        x -= 0.5;
        y -= 0.5;
        
        b2Vec2 initialForce = b2Vec2(x, y);
        initialForce *= 5;
        
        _body = _world->CreateBody(&ballBodyDef);
        _body->SetTransform(b2Vec2(sprite.position.x / PTM_RATIO, sprite.position.y / PTM_RATIO), 0);
        
        b2Vec2 center = _body->GetWorldCenter();
        _body->ApplyLinearImpulse(initialForce, center);
        
        NSParameterAssert(sprite.size.width == sprite.size.height);
        CGFloat radius = MAX(sprite.size.width, sprite.size.height) / 2.f;
        
        b2CircleShape circle;
        circle.m_radius = radius/PTM_RATIO;
        
        b2FixtureDef ballShapeDef;
        ballShapeDef.shape = &circle;
        ballShapeDef.density = 1.0f;
        ballShapeDef.friction = 0.2f;
        ballShapeDef.restitution = 0.8f;
        
        _body->CreateFixture(&ballShapeDef);
    }
    else {
        b2BodyDef groundBodyDef;
        groundBodyDef.type = b2_staticBody;
        groundBodyDef.userData = (__bridge void*)sprite;
        
        _body = _world->CreateBody(&groundBodyDef);
        _body->SetTransform(b2Vec2(sprite.position.x / PTM_RATIO, sprite.position.y / PTM_RATIO), 0);
        
        NSParameterAssert(sprite.size.width == sprite.size.height);
        CGFloat radius = MAX(sprite.size.width, sprite.size.height) / 2.f;
        
        b2CircleShape circle;
        circle.m_radius = radius/PTM_RATIO;
        
        b2FixtureDef fd;
        fd.shape = &circle;
        
        _body->CreateFixture(&fd);
    }
    
    [sprite setModelViewMatrix: GLKMatrix4MakeScale(_scale, _scale, 1.0)];
}

- (void) setBackground: (Background*) background 
{
    if( background != _background ) {
        if(_background ) {
            NSParameterAssert([_nodes containsObject: _background]);
            [_nodes removeObject: _background];
        }
        
        _background = background;
        
        if( background )
            [_nodes addObject: background];
    }
}

- (Background*) background {
    return _background;
}

- (NSArray*) nodesIntersectingRect: (CGRect) rect 
{
    CGRect visible = [self visibleRect];
    
    if( CGRectEqualToRect(visible, CGRectZero) )
        return [NSSet set];
    
    rect.size.width /= self.zoom;
    rect.size.height /= self.zoom;
    
    NSPredicate* inRectPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        CGRect box = [evaluatedObject projectionInScreenRect: rect];
        if( evaluatedObject == _background )
            return NO;
        
        if( CGRectGetMinX(box) > CGRectGetMaxX(visible) )
            return NO;
        if( CGRectGetMinY(box) > CGRectGetMaxY(visible) )
            return NO;
        if( CGRectGetMaxX(box) < CGRectGetMinX(visible) )
            return NO;
        if( CGRectGetMaxY(box) < CGRectGetMinY(visible) )
            return NO;
        
        return YES;
    }];
    
    NSSet* others = [_nodes filteredSetUsingPredicate: inRectPredicate];
    NSArray* world = [NSArray arrayWithObject: _background];
    return [world arrayByAddingObjectsFromArray: others.allObjects];
}

- (CGPoint) locationInWorld: (CGPoint) point {
    
    //Center around screen center
    point.x -= CGRectGetWidth(_viewRect)/2.f;
    point.y -= CGRectGetHeight(_viewRect)/2.f;
    
    //Flip y coordinate
    point.y = -point.y;
    
    point.x -= self.offset.x;
    point.y += self.offset.y;
    
    return CGPointMake(point.x, point.y);
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
        
        _projectionViewMatrix = GLKMatrix4MakeOrtho(-halfWidth, halfWidth,
                                                    -halfHeight, halfHeight,
                                                    0.1, 100);
        [_background setProjectionMatrix: _projectionViewMatrix];
    }
    
    _world->Step(controller.timeSinceLastUpdate, 10, 10);
    for(b2Body *b = _world->GetBodyList(); b; b=b->GetNext()) {
        
        if (b->GetUserData() != NULL) {
            Node *ballData = (__bridge Node *)b->GetUserData();
            b2Vec2 position = b->GetPosition();
            
            GLKMatrix4 mvm = [ballData modelViewMatrix];
            mvm.m30 = b->GetPosition().x * PTM_RATIO * _scale + self.offset.x;
            mvm.m31 = b->GetPosition().y * PTM_RATIO * _scale - self.offset.y;
            mvm.m32 = -0.25;
            
            [ballData setModelViewMatrix: mvm];    
            [ballData setProjectionMatrix: _projectionViewMatrix];
        }
    }
    
    GLKMatrix4 world = _background.modelViewMatrix;
    world.m30 = self.offset.x;
    world.m31 = -self.offset.y;
    world.m32 = -0.5;
    
    [_background setModelViewMatrix: world];
}

- (void)glkViewController:(GLKViewController *)controller willPause:(BOOL)pause
{
    
}

@end
