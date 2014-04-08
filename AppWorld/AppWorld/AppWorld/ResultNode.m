//
//  ResultNode.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "ResultNode.h"

@implementation ResultNode

- (instancetype) initWithImage: (UIImage*) image {
    self = [super init];
    if( self ) {
        
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
        
        [cropNode addChild: sprite];
        
        [self addChild: cropNode];
        
        SKPhysicsBody* body = [SKPhysicsBody bodyWithCircleOfRadius: 15.];
        self.physicsBody = body;
        /*
        SKAction* oneScale = [SKAction scaleTo: 2. duration: 1.0];
        SKAction* reverseScale = [SKAction scaleTo: 1. duration: 1.];
        
        SKAction* pulse = [SKAction sequence: @[oneScale, reverseScale]];
        SKAction* repeat = [SKAction repeatActionForever: pulse];
        [self runAction: repeat];
*/
        _repulsive = NO;
    }
    return self;
}

- (CGRect) calculateAccumulatedFrame {
    return CGRectMake(0, 0, 30, 30);
}

@end
