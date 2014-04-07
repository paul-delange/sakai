//
//  SearchScene.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "SearchScene.h"

#import "UserNode.h"
#import "ResultNode.h"

@interface SearchScene ()

@property (weak) UserNode* userNode;

@end

@implementation SearchScene

- (void) addResultNodeAtPosition: (CGPoint) location {
    ResultNode* node = [ResultNode new];
    node.position = location;
    
    [self addChild: node];
    
    CGPoint center = self.userNode.position;
    
    CGFloat x = location.x - center.x;
    CGFloat y = location.y - center.y;
    
    CGFloat length = sqrtf( x*x + y*y );
    
    length /= 2.;
    
    [node.physicsBody applyImpulse: CGVectorMake(-y/length, x/length)];
}

#pragma mark - SKScene
- (instancetype) initWithSize:(CGSize)size {
    self = [super initWithSize: size];
    if( self) {
        self.backgroundColor = [SKColor blackColor];
        
        UserNode* userNode = [[UserNode alloc] initWithSize: CGSizeMake(50, 50)];
        userNode.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild: userNode];
        self.userNode = userNode;
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
    }
    
    return self;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];

        SKNode* touched = [self nodeAtPoint: location];
        
        if( [touched isKindOfClass: [SKSpriteNode class]] ) {
            [touched.parent touchesBegan: touches withEvent: event];
        }
        else {
            [self addResultNodeAtPosition: location];
        }
    }
}

-(void)update:(CFTimeInterval)currentTime {
    
    NSPredicate* resultPredicate =[NSPredicate predicateWithFormat: @"SELF isKindOfClass: %@", [ResultNode class]];
    NSArray* resultNodes = [self.children filteredArrayUsingPredicate: resultPredicate];
    
    //Remove old ones
    NSMutableSet* visibleBodies = [NSMutableSet new];
    [self.physicsWorld enumerateBodiesInRect: self.frame usingBlock: ^(SKPhysicsBody *body, BOOL *stop) {
        [visibleBodies addObject: body];
    }];
    
    for(ResultNode* node in resultNodes ) {
        if( ![visibleBodies containsObject: node.physicsBody] && node.repulsive ) {
            [node removeFromParent];
        }
        else {
            CGPoint location = node.position;
            CGPoint center = self.userNode.position;
            
            CGFloat x = location.x - center.x;
            CGFloat y = location.y - center.y;
            
            CGFloat length = sqrtf( x*x + y*y );
            
            if( length <= 55 ) {
                node.repulsive = YES;
            }
            
            if( node.repulsive ) {
                length *= 5;
                [node.physicsBody applyForce: CGVectorMake(x/length, y/length)];
            }
            else
                [node.physicsBody applyForce: CGVectorMake(-x/length, -y/length)];
        }
    }
}

@end
