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
@import CoreImage;

@interface WorldViewController () <SearchSceneDelegate>

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
    scene.scaleMode = SKSceneScaleModeAspectFill;
    
    /*
    CIFilter* filter = [CIFilter filterWithName: @"CIVignetteEffect"];
    scene.filter = filter;
    scene.shouldEnableEffects = NO;
    */
    
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
    NSLog(@"Selected object %d", index);
}

- (void) searchScene:(SearchScene *)searchScene didSelectUserAtIndex:(NSUInteger)index {
    
    CGRect bounds = self.view.bounds;
    
    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CFMutableArrayRef colors = CFArrayCreateMutable(NULL, 2, NULL);
    
    CGColorRef centerColor = [[UIColor clearColor] CGColor];
    CGColorRef outsideColor = [[UIColor blackColor] CGColor];
    
    CFArraySetValueAtIndex(colors, 0, centerColor);
    CFArraySetValueAtIndex(colors, 1, outsideColor);
    
    const CGFloat locations[2] = { 0., 1. };
    
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        colors,
                                                        locations);
    CGContextDrawRadialGradient(ctx,
                                gradient,
                                CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)),
                                0,
                                CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds)),
                                300,
                                kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    
    UIImage *blank = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage: blank];
    imageView.backgroundColor = [UIColor clearColor];

    [self.view addSubview: imageView];
    
    CGRect afterFrame = imageView.frame;
    CGRect beforeFrame = CGRectInset(afterFrame, -500, -500);
    
    imageView.frame = beforeFrame;
    
    [UIView animateWithDuration: 3.0 animations:^{
        imageView.frame = afterFrame;
    }];
    
    /*
    NSArray* filters = [CIFilter filterNamesInCategories: @[kCICategoryVideo]];
    for (NSString* filterName in filters)
    {
        NSLog(@"Filter: %@", filterName);
        //NSLog(@"Parameters: %@", [[CIFilter filterWithName:filterName] attributes]);
    }*/
    //self.searchScene.shouldEnableEffects = !self.searchScene.shouldEnableEffects;
    //self.searchScene.paused = !self.searchScene.paused;
    
}

@end
