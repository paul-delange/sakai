//
//  UserNode.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "UserNode.h"

@implementation UserNode

- (instancetype) initWithSize:(CGSize)size {
    NSAssert(size.width == size.height, @"The UserNode should be square not %fx%f", size.width, size.height);
    
    self = [super init];
    if( self ) {
        
        UIImage* image = [UIImage imageNamed: @"player357.tga"];
        SKTexture* texture = [SKTexture textureWithImage: image];
        SKSpriteNode* spriteNode = [SKSpriteNode spriteNodeWithTexture: texture];
        spriteNode.size = size;
        [self addChild: spriteNode];
        
        SKPhysicsBody* body = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2.];
        body.dynamic = NO;
        self.physicsBody = body;
        
        SKAction *oneRevolution = [SKAction rotateByAngle:-M_PI*2 duration: 5.0];
        SKAction *repeat = [SKAction repeatActionForever:oneRevolution];
        //[self runAction:repeat];
        
        SKAction* oneScale = [SKAction scaleTo: 1.25 duration: 1.0];
        SKAction* reverseScale = [SKAction scaleTo: 1. duration: 1.];
        
        SKAction* pulse = [SKAction sequence: @[oneScale, reverseScale]];
        repeat = [SKAction repeatActionForever: pulse];
        [self runAction: repeat];
    }
    
    return self;
}

@end
