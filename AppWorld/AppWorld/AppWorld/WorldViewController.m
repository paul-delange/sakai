//
//  WorldViewController.m
//  AppWorld
//
//  Created by Paul de Lange on 7/04/2014.
//  Copyright (c) 2014 Tall Developments. All rights reserved.
//

#import "WorldViewController.h"
#import "WorldViewController+Animations.h"

#import "SearchScene.h"
#import "ResultNode.h"

#import "SearchResult.h"

@import SpriteKit;
@import CoreImage;

@interface WorldViewController () <SearchSceneDelegate, SearchSceneDataSource> {
    NSMutableArray* _results;
}

@property (weak, nonatomic) SKView* worldView;
@property (weak) SearchScene* searchScene;

@end

@implementation WorldViewController

- (SKView*) worldView {
    return (SKView*)self.view;
}

- (void) searchForTerm: (NSString*) term {
    
    // http://www.apple.com/itunes/affiliates/resources/documentation/itunes-store-web-service-search-api.html
    
    NSString* searchPath = [NSString stringWithFormat: @"https://itunes.apple.com/search?media=software&term=%@&limit=50", term];
    NSURL* searchURL = [NSURL URLWithString: searchPath];
    NSURLRequest* request = [NSURLRequest requestWithURL: searchURL];
    [NSURLConnection sendAsynchronousRequest: request
                                       queue: [NSOperationQueue currentQueue]
                           completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               NSDictionary* root = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
                               
                               
                               _results = [NSMutableArray new];
                               [self.searchScene reloadData];
                               
                               NSArray* results = root[@"results"];
                               
                               for(NSDictionary* dict in results) {
                                   NSString* artworkPath = dict[@"artworkUrl60"];
                                   NSNumber* averageRating = dict[@"averageUserRating"];
                                   
                                   SearchResult* result = [SearchResult new];
                                   result.thumbnailPath = artworkPath;
                                   result.averageRating = [averageRating floatValue];
                                   
                                   NSInteger index = [results indexOfObject: dict];
                                   
                                   dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * index * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                       NSString* artworkPath = result.thumbnailPath;
                                       NSURL* artworkURL = [NSURL URLWithString: artworkPath];
                                       NSURLRequest* request = [NSURLRequest requestWithURL: artworkURL];
                                       [NSURLConnection sendAsynchronousRequest: request
                                                                          queue: [NSOperationQueue currentQueue]
                                                              completionHandler: ^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                                                  UIImage* image = [UIImage imageWithData: data];
                                                                  if( image ) {
                                                                      result.thumb = image;
                                                                      
                                                                      [self.searchScene beginUpdates];
                                                                      
                                                                      NSUInteger insertIndex = [_results count];
                                                                      [_results addObject: result];
                                                                      
                                                                      [self.searchScene insertObjectAtIndex: insertIndex];
                                                                      
                                                                      [self.searchScene endUpdates];
                                                                      
                                                                  }
                                                              }];
                                   });
                               }
                           }];
}

#pragma mark - Actions

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
    scene.delegate = self;
    scene.dataSource = self;
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    self.searchScene = scene;
    
    // Present the scene.
    [self.worldView presentScene:scene];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    [self searchForTerm: @"birds"];
}

#pragma mark - SearchSceneDelegate
- (void) searchScene:(SearchScene *)scene didSelectObjectIndex:(NSUInteger)index {
    [self showVignette: YES animated: YES];
}

- (void) searchScene:(SearchScene *)searchScene didSelectUserAtIndex:(NSUInteger)index {
    [self showVignette: NO animated: YES];
}

#pragma mark - SearchSceneDataSource
- (NSUInteger) numberOfObjectsInSearchScene:(SearchScene *)scene {
    return [_results count];
}

- (SKNode*) searchScene:(SearchScene *)scene nodeForObjectAtIndex:(NSUInteger)index {
    SearchResult* result = _results[index];
    return [[ResultNode alloc] initWithImage: result.thumb];
}

@end
