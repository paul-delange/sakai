//
//  WorldViewController.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "WorldViewController.h"

#import "SearchScene.h"

@import SpriteKit;

@interface WorldViewController ()

@property (weak, nonatomic) SKView* worldView;

@end

@implementation WorldViewController

- (SKView*) worldView {
    return (SKView*)self.view;
}

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {

    }
    return self;
}

#pragma mark - UIViewController
- (void) viewDidLoad {
    [super viewDidLoad];
    
#if DEBUG
    self.worldView.showsFPS = YES;
    self.worldView.showsNodeCount = YES;
#endif
    
    // Create and configure the scene.
    SKScene * scene = [SearchScene sceneWithSize: self.worldView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    // Present the scene.
    [self.worldView presentScene:scene];
}

@end
