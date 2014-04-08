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

#import "SearchResult.h"

@interface SearchScene ()

@property (copy) NSSet* userNodes;
//@property (weak) UserNode* userNode;

@end

@implementation SearchScene

- (void) addResult: (SearchResult*) result AtPosition: (CGPoint) location {
    
    NSString* artworkPath = result.thumbnailPath;
    NSURL* artworkURL = [NSURL URLWithString: artworkPath];
    NSURLRequest* request = [NSURLRequest requestWithURL: artworkURL];
    [NSURLConnection sendAsynchronousRequest: request
                                       queue: [NSOperationQueue currentQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               UIImage* image = [UIImage imageWithData: data];
                               if( image ) {
                                   ResultNode* node = [[ResultNode alloc] initWithImage: image];
                                   node.position = location;
                                   node.xScale = (result.averageRating / 5) * 2;
                                   node.yScale = node.xScale;
                                   
                                   [self addChild: node];
                                   
                                   CGPoint center = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
                                   
                                   CGFloat x = location.x - center.x;
                                   CGFloat y = location.y - center.y;
                                   
                                   CGFloat length = sqrtf( x*x + y*y );
                                   
                                   length /= 5.;
                                   
                                   [node.physicsBody applyImpulse: CGVectorMake(-y/length, x/length)];
                               }
                           }];
}

#pragma mark - SKScene
- (instancetype) initWithSize:(CGSize)size {
    self = [super initWithSize: size];
    if( self) {
        self.backgroundColor = [SKColor blackColor];
        
        UserNode* userNode1 = [[UserNode alloc] initWithSize: CGSizeMake(50, 50)];
        userNode1.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        [self addChild: userNode1];
        
        /*
        UserNode* userNode2 = [[UserNode alloc] initWithSize: CGSizeMake(50, 50)];
        userNode2.position = CGPointMake(10, 300);
        [self addChild: userNode2];
        
        UserNode* userNode3 = [[UserNode alloc] initWithSize: CGSizeMake(50, 50)];
        userNode3.position = CGPointMake(300, 400);
        [self addChild: userNode3];
        */
        self.userNodes = [NSSet setWithObjects: userNode1, /*userNode2, userNode3,*/ nil];
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
    }
    
    return self;
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
            NSUInteger i = 1;
            for(UserNode* userNode in self.userNodes) {
            CGPoint center = userNode.position;
            
            CGFloat x = location.x - center.x;
            CGFloat y = location.y - center.y;
            
            CGFloat length = sqrtf( x*x + y*y );
            
                if( length <= 55 ) {
                    node.repulsive = YES;
                }
                
            length /= 2 + (1./i);
            
            if( node.repulsive ) {
                length /= 5;
                [node.physicsBody applyForce: CGVectorMake(x/length, y/length)];
            }
            else
                [node.physicsBody applyForce: CGVectorMake(-x/length, -y/length)];
            }
            
            i++;
        }
    }
}

#pragma mark - UIResponder
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        NSArray* nodes = [self nodesAtPoint: location];
        NSLog(@"Touched %d nodes", [nodes count]);
        
        //[self addResultNodeAtPosition: location];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        //[self addResultNodeAtPosition: location];
    }
}

@end
