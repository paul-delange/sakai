//
//  SKNode+Dragging.m
//  AppWorld
//
//  Created by Paul de Lange on 8/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "SKNode+Dragging.h"

#import <objc/message.h>
#import <objc/runtime.h>

NSString * const DragNodeName = @"DragNode";

char * const ASSOCIATION_DRAGGABLE_KEY  = "isDraggable";
char * const ASSOCIATION_TOUCH_KEY      = "touch";
char * const ASSOCIATION_OFFSET_KEY     = "offset";

@interface SKNode (DraggingInternal)

@property (weak) UITouch* boundTouch;
@property (assign) CGPoint touchOffset;

@end

@implementation SKNode (DraggingInternal)

- (SKNode*) dragNode {
    return [self childNodeWithName: DragNodeName];
}

-(void)dragForDuration:(NSTimeInterval) frameDuration {
    CGPoint offset = self.touchOffset;

    if( !CGPointEqualToPoint(offset, CGPointZero) ) {
        CGPoint location = [self.boundTouch locationInNode: self.scene];
        SKNode* node = [self dragNode];
        node.position = location;
    }
}

#pragma mark - NSObject
+ (void) load {
    [super load];
    
    @autoreleasepool {
        Class c = [SKNode class];
        
        SEL methodsToSwizzle[] = {
            @selector(touchesBegan:withEvent:),
            @selector(touchesMoved:withEvent:),
            @selector(touchesCancelled:withEvent:),
            @selector(touchesEnded:withEvent:)
        };
        
        size_t swizzleCount = sizeof(methodsToSwizzle) / sizeof(methodsToSwizzle[0]);
        
        for(size_t i=0;i<swizzleCount;i++) {
            SEL originalSelector = methodsToSwizzle[i];
            NSString* originalSelectorAsString = NSStringFromSelector(originalSelector);
            
            NSString* swizzledSelectorAsString = [NSString stringWithFormat: @"swizzled_%@", originalSelectorAsString];
            SEL swizzledSelector = NSSelectorFromString(swizzledSelectorAsString);
            
            IMP implementation = class_getMethodImplementation(c, swizzledSelector);
            class_addMethod(c, swizzledSelector, implementation, "v@:@@");
            
            Method original, swizzled;
            
            original = class_getInstanceMethod(c, originalSelector);
            swizzled = class_getInstanceMethod(c, swizzledSelector);
            
            method_exchangeImplementations(original, swizzled);
        }
    }
}

- (void) setDraggable:(BOOL)draggable {
    objc_setAssociatedObject(self, ASSOCIATION_DRAGGABLE_KEY, @(draggable), OBJC_ASSOCIATION_COPY);
    
    if( draggable ) {
        
    }
    else {
        
    }
}

- (BOOL) isDraggable {
    NSNumber* obj = objc_getAssociatedObject(self, ASSOCIATION_DRAGGABLE_KEY);
    return [obj boolValue];
}

- (void) setBoundTouch: (UITouch*) touch {
    
    if( touch ) {
        CGPoint location = [touch locationInNode: self.scene];
        
        CGPoint offset = CGPointMake(location.x-self.position.x, location.y-self.position.y);
        self.touchOffset = offset;
    }
    else {
        objc_setAssociatedObject(self, ASSOCIATION_OFFSET_KEY, nil, OBJC_ASSOCIATION_RETAIN);
    }
    
    objc_setAssociatedObject(self, ASSOCIATION_TOUCH_KEY, touch, OBJC_ASSOCIATION_ASSIGN);
}

- (UITouch*) boundTouch {
    return objc_getAssociatedObject(self, ASSOCIATION_TOUCH_KEY);
}

- (void) setTouchOffset:(CGPoint)touchOffset {
    objc_setAssociatedObject(self, ASSOCIATION_OFFSET_KEY, [NSValue valueWithCGPoint: touchOffset],  OBJC_ASSOCIATION_RETAIN);
}

- (CGPoint) touchOffset {
    NSValue* value = objc_getAssociatedObject(self, ASSOCIATION_OFFSET_KEY);
    return [value CGPointValue];
}

- (void) willStartDragging {
    
}

- (void) willEndDragging {
    
}

#pragma mark - Swizzling
- (void) swizzled_touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if( [self respondsToSelector: @selector(isDraggable)] ) {
        if( self.isDraggable ) {
            
            UITouch* bound = self.boundTouch;
            
            if( !bound ) {
                [self willStartDragging];
                
                for( UITouch* touch in touches) {
                    CGPoint location = [touch locationInNode: self.scene];
                    NSArray* nodes = [self.scene nodesAtPoint: location];
                    if( [nodes containsObject: self] ) {
                        self.boundTouch = touch;
                        
                        SKScene* scene = self.scene;
                        
                        SKShapeNode* shape = [SKShapeNode node];
                        shape.name = DragNodeName;
                        
                        shape.path = [[UIBezierPath bezierPathWithOvalInRect: CGRectMake(-10, -10, 20, 20)] CGPath];
                        shape.fillColor = [SKColor redColor];
                        shape.position = [touch locationInNode: scene];
                        [scene addChild: shape];
                        
                        SKPhysicsBody* dragBody = [SKPhysicsBody bodyWithCircleOfRadius: 15.];
                        dragBody.dynamic = NO;
                        dragBody.categoryBitMask = 1 << 7;
                        dragBody.collisionBitMask = 1 << 7;
                        shape.physicsBody = dragBody;
                        
                        /*
                        SKPhysicsJointSpring* spring = [SKPhysicsJointSpring jointWithBodyA: self.physicsBody
                                                                                      bodyB: dragBody
                                                                                    anchorA: CGPointMake(0, 0)
                                                                                    anchorB: CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))];
                        
                        [self.scene.physicsWorld addJoint: spring]; */

                        
                        break;
                    }
                }
            }
        }
    }
    
    SEL real = @selector(swizzled_touchesBegan:withEvent:);
    if( [self respondsToSelector: real] )
        objc_msgSend(self, real, touches, event);
}

- (void) swizzled_touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    SEL real = @selector(swizzled_touchesMoved:withEvent:);
    if( [self respondsToSelector: real] )
        objc_msgSend(self, real, touches, event);
}

- (void) swizzled_touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if( [self respondsToSelector: @selector(isDraggable)] ) {
        if( self.isDraggable ) {
            SKNode* node = [self dragNode];
            [node removeFromParent];
            
            self.boundTouch = nil;
        }
    }
    
    SEL real = @selector(swizzled_touchesCancelled:withEvent:);
    if( [self respondsToSelector: real] )
        objc_msgSend(self, real, touches, event);
}

- (void) swizzled_touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    if( [self respondsToSelector: @selector(isDraggable)] ) {
        if( self.isDraggable ) {
            SKNode* node = [self dragNode];
            [node removeFromParent];
            
            self.boundTouch = nil;
        }
    }
    
    SEL real = @selector(swizzled_touchesEnded:withEvent:);
    if( [self respondsToSelector: real] )
        objc_msgSend(self, real, touches, event);
}

@end