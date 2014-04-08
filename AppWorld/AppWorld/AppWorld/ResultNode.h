//
//  ResultNode.h
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

extern NSString * const ResultNodeName;

@interface ResultNode : SKNode

- (instancetype) initWithImage: (UIImage*) image;

-(void)dragForDuration:(NSTimeInterval) frameDuration;

@property (assign) BOOL repulsive;

@end
