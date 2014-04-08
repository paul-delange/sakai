//
//  ResultNode.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "ResultNode.h"

@implementation ResultNode

- (instancetype) init {
    self = [super init];
    if( self ) {
        UIImage* image = [UIImage imageNamed: @"target_inter.tga"];
        SKTexture* texture = [SKTexture textureWithImage: image];
        SKSpriteNode* sprite = [SKSpriteNode spriteNodeWithTexture: texture];
        sprite.size = CGSizeMake(30, 30);
        sprite.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        
        [self addChild: sprite];
        
        SKPhysicsBody* body = [SKPhysicsBody bodyWithCircleOfRadius: 15.];
        self.physicsBody = body;
        
        _repulsive = NO;
    }
    return self;
}

- (CGRect) calculateAccumulatedFrame {
    return CGRectMake(0, 0, 30, 30);
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.physicsBody.dynamic = NO;
}

- (void) touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch* touch = [touches anyObject];
    CGPoint location = [touch locationInNode: self.parent];
    self.position = location;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    //self.physicsBody.dynamic = YES;
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    //self.physicsBody.dynamic = YES;
}

@end
