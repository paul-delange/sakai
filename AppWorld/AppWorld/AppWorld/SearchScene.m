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

@interface SearchScene () <UIGestureRecognizerDelegate> {
    CFTimeInterval      _lastUpdateTime;
}

@property (copy) NSArray* userNodes;

@property (weak) UITapGestureRecognizer* tapGestureRecognizer;
@property (weak) UILongPressGestureRecognizer* pressGestureRecognizer;

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

#pragma mark - Actions
- (IBAction) resultTapped: (UITapGestureRecognizer*)sender {
    
    if( sender.state == UIGestureRecognizerStateRecognized ) {
        CGPoint touch_location = [sender locationInView: self.view];
        CGPoint location = [self.scene convertPointFromView: touch_location];
        
        NSArray* nodes = [self.scene nodesAtPoint: location];
        
        for( SKNode* node in nodes ) {
            if( [node.name isEqualToString: ResultNodeName] ) {
                
                if( [self.delegate respondsToSelector: @selector(searchScene:didSelectObjectIndex:)] )
                    [self.delegate searchScene: self didSelectObjectIndex: 0];
                
                break;
            }
        }
        
    }
}

- (IBAction) userNodeLongPressed: (UILongPressGestureRecognizer*)sender {
    
    if( sender.state == UIGestureRecognizerStateBegan ) {
        CGPoint touch_location = [sender locationInView: self.view];
        CGPoint location = [self.scene convertPointFromView: touch_location];
        
        NSArray* nodes = [self.scene nodesAtPoint: location];
        
        for( SKNode* node in nodes ) {
            NSUInteger userIndex = [self.userNodes indexOfObject: node];
            if( userIndex != NSNotFound ) {
                if( [self.delegate respondsToSelector: @selector(searchScene:didSelectUserAtIndex:)] ) {
                    [self.delegate searchScene: self didSelectUserAtIndex: userIndex];
                }
            }
        }
    }
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
        self.userNodes = [NSArray arrayWithObjects: userNode1, /*userNode2, userNode3,*/ nil];
        
        self.physicsWorld.gravity = CGVectorMake(0, 0);
    }
    
    return self;
}

-(void)update:(CFTimeInterval)currentTime {
    
    CFTimeInterval interval = _lastUpdateTime - currentTime;
    
    //Remove old ones
    NSMutableSet* visibleBodies = [NSMutableSet new];
    [self.physicsWorld enumerateBodiesInRect: self.frame usingBlock: ^(SKPhysicsBody *body, BOOL *stop) {
        [visibleBodies addObject: body];
    }];
    
    [self enumerateChildNodesWithName: ResultNodeName usingBlock: ^(SKNode *n, BOOL *stop) {
        ResultNode* node = (ResultNode*)n;
        
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
        
        [node dragForDuration: interval];
    }];
    
    _lastUpdateTime = currentTime;
}

- (void)didMoveToView:(SKView *)view {
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget: self
                                                                                 action: @selector(resultTapped:)];
    tapGesture.delegate = self;
    [view addGestureRecognizer: tapGesture];
    self.tapGestureRecognizer = tapGesture;
    
    UILongPressGestureRecognizer* pressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget: self
                                                                                               action: @selector(userNodeLongPressed:)];
    pressGesture.delegate = self;
    [view addGestureRecognizer: pressGesture];
    
    self.pressGestureRecognizer = pressGesture;
}

- (void)willMoveFromView:(SKView *)view {
    [view removeGestureRecognizer: self.tapGestureRecognizer];
    [view removeGestureRecognizer: self.pressGestureRecognizer];
}

#pragma mark - UIResponder
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        CGPoint location = [touch locationInNode:self];
        
        NSArray* nodes = [self.scene nodesAtPoint: location];
        for(SKNode* node in nodes) {
            if( [node respondsToSelector: @selector(touchesBegan:withEvent:)])
                [node touchesBegan: touches withEvent: event];
            
            break;
        }
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self enumerateChildNodesWithName: ResultNodeName usingBlock: ^(SKNode *node, BOOL *stop) {
        if( [node respondsToSelector: @selector(touchesCancelled:withEvent:)])
            [node touchesCancelled: touches withEvent: event];
    }];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self enumerateChildNodesWithName: ResultNodeName usingBlock: ^(SKNode *node, BOOL *stop) {
        if( [node respondsToSelector: @selector(touchesEnded:withEvent:)])
            [node touchesEnded: touches withEvent: event];
    }];
}

#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if( gestureRecognizer == self.tapGestureRecognizer ) {
        CGPoint touch_location = [gestureRecognizer locationInView: self.view];
        CGPoint location = [self.scene convertPointFromView: touch_location];
        NSArray* nodes = [self.scene nodesAtPoint: location];
        
        for(SKNode* node in nodes) {
            if( [node.name isEqualToString: ResultNodeName] )
                return YES;
        }
        
        return NO;
    }
    
    if( gestureRecognizer == self.pressGestureRecognizer ) {
        CGPoint touch_location = [gestureRecognizer locationInView: self.view];
        CGPoint location = [self.scene convertPointFromView: touch_location];
        NSArray* nodes = [self.scene nodesAtPoint: location];
        
        for(SKNode* node in nodes) {
            if( [node.name isEqualToString: UserNodeName] )
                return YES;
        }
        
        return NO;
        
    }
    
    return YES;
}

@end
