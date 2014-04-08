//
//  ResultNode.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "ResultNode.h"

NSString * const ResultNodeName = @"ResultNode";

@interface ResultNode () {
    SKShapeNode*            _selectNode;
    
    CGPoint                 _touchOffset;
    __weak UITouch*         _touch;
}

@end

@implementation ResultNode

-(void)dragForDuration:(NSTimeInterval) frameDuration {
    if( _touch ) {
        CGPoint location = [_touch locationInNode: self.scene];
        self.position = CGPointMake(location.x - _touchOffset.x, location.y - _touchOffset.y);
    }
}

- (instancetype) initWithImage: (UIImage*) image {
    self = [super init];
    if( self ) {
        self.name = ResultNodeName;
        
        SKShapeNode* maskNode = [SKShapeNode new];
        maskNode.path = [[UIBezierPath bezierPathWithOvalInRect: CGRectMake(-7.5, -7.5, 15, 15)] CGPath];
        maskNode.fillColor = [SKColor clearColor];
        maskNode.strokeColor = [SKColor whiteColor];
        maskNode.lineWidth = 13;
        
        SKCropNode* cropNode = [SKCropNode new];
        cropNode.maskNode = maskNode;
        
        SKTexture* texture = [SKTexture textureWithImage: image];
        SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture: texture];
        sprite.size = CGSizeMake(30, 30);
        sprite.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        sprite.userInteractionEnabled = NO;
        
        [cropNode addChild: sprite];
        
        [self addChild: cropNode];
        
        SKPhysicsBody* body = [SKPhysicsBody bodyWithCircleOfRadius: 15.];
 
        self.physicsBody = body;
        
        _repulsive = NO;
    }
    
    return self;
}

- (CGRect) calculateAccumulatedFrame {
    CGRect frame = [super calculateAccumulatedFrame];
    return frame;
}

#pragma mark - UIResponder
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if( _touch )
        return;
    
    for(UITouch* touch in touches) {
        
        
        CGPoint location = [touch locationInNode: self.scene];
        NSArray* nodes = [self.scene nodesAtPoint: location];
        
        if( [nodes containsObject: self]  ) {
            _touch = touch;
            _touchOffset = CGPointMake(location.x-self.position.x, location.y-self.position.y);
            
            SKShapeNode* shape = [SKShapeNode node];
            shape.glowWidth = 10.;
            shape.path = [[UIBezierPath bezierPathWithOvalInRect: CGRectMake(-15, -15, 30, 30)] CGPath];
            shape.fillColor = [SKColor whiteColor];
            shape.strokeColor = [SKColor whiteColor];
            shape.zPosition = -1;
            
            [self insertChild: shape atIndex: 0];
            _selectNode = shape;
            
            break;
            
        }
    }
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if( [touches containsObject: _touch] ) {
        _touch = nil;
        [_selectNode removeFromParent];
    }
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded: touches withEvent: event];
}

@end
