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
        SKShapeNode* shapeNode = [SKShapeNode new];
        
        UIBezierPath* bezier = [UIBezierPath bezierPathWithOvalInRect: CGRectMake(-size.width/2., -size.height/2., size.width, size.height)];
        
        shapeNode.path = [bezier CGPath];
        shapeNode.fillColor = [UIColor redColor];
        
        [self addChild: shapeNode];
        
        
        SKPhysicsBody* body = [SKPhysicsBody bodyWithCircleOfRadius: size.width/2.];
        body.dynamic = NO;
        self.physicsBody = body;
    }
    
    return self;
}

@end
