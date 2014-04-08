//
//  WorldViewController.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "WorldViewController.h"

#import "SearchScene.h"
#import "SearchResult.h"

@import SpriteKit;

@interface WorldViewController ()

@property (weak, nonatomic) SKView* worldView;
@property (weak) SearchScene* searchScene;

@end

@implementation WorldViewController

- (SKView*) worldView {
    return (SKView*)self.view;
}

- (void) searchForTerm: (NSString*) term {
    
    NSString* searchPath = [NSString stringWithFormat: @"https://itunes.apple.com/search?media=software&term=%@&limit=200", term];
    NSURL* searchURL = [NSURL URLWithString: searchPath];
    NSURLRequest* request = [NSURLRequest requestWithURL: searchURL];
    [NSURLConnection sendAsynchronousRequest: request
                                       queue: [NSOperationQueue currentQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSDictionary* root = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
                               
                               NSArray* results = root[@"results"];
                               
                               for(NSDictionary* dict in results) {
                                   NSString* artworkPath = dict[@"artworkUrl100"];
                                   NSNumber* averageRating = dict[@"averageUserRating"];
                                   
                                   SearchResult* result = [SearchResult new];
                                   result.thumbnailPath = artworkPath;
                                   result.averageRating = [averageRating floatValue];
                                   
                                   
                                   NSInteger index = [results indexOfObject: dict];
                                   CGPoint location = CGPointMake(index / 200. * CGRectGetWidth(self.view.frame), 100);
                                   
                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * index * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                       [self.searchScene addResult: result AtPosition: location];
                                   });
                                   
                               }
                           }];
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
    SearchScene * scene = [SearchScene sceneWithSize: self.worldView.bounds.size];
    scene.scaleMode = SKSceneScaleModeAspectFill;
    self.searchScene = scene;
    
    // Present the scene.
    [self.worldView presentScene:scene];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    [self searchForTerm: @"birds"];
}

@end
