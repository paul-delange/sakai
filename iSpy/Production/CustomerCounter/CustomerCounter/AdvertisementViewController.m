//
//  AdvertisementViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "AdvertisementViewController.h"
#import "SettingsViewController.h"

#import "CustomerDetector.h"

@import AssetsLibrary;

@interface AdvertisementViewController () <CustomerDetectorDelegate> {
    NSInteger   _itemCount;
    NSInteger   _currentItemIndex;
    
    dispatch_source_t   _slideshowTimer;
    
    CustomerDetector*   _detector;
}

@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property (strong) ALAssetsLibrary* library;
@property (copy, nonatomic) NSArray* groups;

@end

@implementation AdvertisementViewController

- (void) setGroups:(NSArray *)groups {
    _groups = [groups subarrayWithRange: NSMakeRange(0, MIN(groups.count, 1))];
    
    for(ALAssetsGroup* group in groups) {
        _itemCount = [group numberOfAssets];
        _currentItemIndex = 0;
        
        if( _itemCount <= 0 ) {
            NSString* format = NSLocalizedString(@"No Playlist. Please open the device Photos app and add photos to the album named '%@'.", @"");
            self.messageLabel.text = [NSString stringWithFormat: format, APP_ALBUM_NAME];
        }
        else {
            self.messageLabel.hidden = YES;
            
            [self startSlideshow];
        }
    }
    
    [self.activityIndicator stopAnimating];
}

- (void) startSlideshow {
    NSTimeInterval interval = [[NSUserDefaults standardUserDefaults] doubleForKey: NSUserDefaultsSlideShowIntervalKey];
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, 0), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
    dispatch_source_set_event_handler(timer, ^{
        ALAssetsGroup* group = self.groups.lastObject;
        NSIndexSet* indexSet = [NSIndexSet indexSetWithIndex: _currentItemIndex];
        [group enumerateAssetsAtIndexes: indexSet
                                options: 0
                             usingBlock: ^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                 
                                 if( index != NSNotFound ) {
                                     [self transitionToAsset: result
                                                    duration: 1.0
                                                     options: UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve];
                                     
                                     _currentItemIndex++;
                                     
                                     if( _currentItemIndex >= _itemCount )
                                         _currentItemIndex = 0;
                                 }
                             }];
    });
    dispatch_resume(timer);
    _slideshowTimer = timer;
}

- (void) stopSlideshow {
    if( _slideshowTimer ) {
        dispatch_source_cancel(_slideshowTimer);
        _slideshowTimer = nil;
    }
}

- (void) transitionToAsset: (ALAsset*) asset duration: (NSTimeInterval) interval options: (UIViewAnimationOptions) options {
    ALAssetRepresentation* representation = [asset defaultRepresentation];
    CGImageRef imageRef = [representation fullResolutionImage];
    UIImage* image = [UIImage imageWithCGImage: imageRef];
    
    BOOL alreadyHasImage = self.imageView.image == nil ? NO : YES;
    
    self.imageView.image = image;
    
    if( alreadyHasImage ) {
        CATransition *transition = [CATransition animation];
        transition.duration = interval;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionFade;
        
        [self.imageView.layer addAnimation:transition forKey:nil];
    }
}

#pragma mark - NSObject
- (instancetype) initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        _library = [[ALAssetsLibrary alloc] init];
        _groups = [NSArray array];
        
        _detector = [CustomerDetector new];
        _detector.delegate = self;
    }
    
    return self;
}

- (void) dealloc {
    [self stopSlideshow];
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    NSString* format = NSLocalizedString(@"Search Photos app for an album named '%@'. If nothing is found please try creating this album first...", @"");
    self.messageLabel.text = [NSString stringWithFormat: format, APP_ALBUM_NAME];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];
    
    ALAssetsGroupType types = ALAssetsGroupAlbum;// | ALAssetsGroupSavedPhotos | ALAssetsGroupPhotoStream;
    [self.library enumerateGroupsWithTypes: types usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        NSParameterAssert([NSThread isMainThread]);
        
        NSString* name = [group valueForProperty: ALAssetsGroupPropertyName];
        if( name && [name caseInsensitiveCompare: APP_ALBUM_NAME] == NSOrderedSame ) {
            
            NSMutableArray* mutable = [NSMutableArray arrayWithArray: self.groups];
            [mutable addObject: group];
            self.groups = mutable;
            
            *stop = YES;
        }
        
    } failureBlock:^(NSError *error) {
        NSParameterAssert([NSThread isMainThread]);
        [self.activityIndicator stopAnimating];
        
        if( [error.domain isEqualToString: ALAssetsLibraryErrorDomain] ) {
            
            switch (error.code) {
                case ALAssetsLibraryAccessUserDeniedError:
                {
                    NSString* format = NSLocalizedString(@"%@ is not authorized to display photos. Please enable this in the device Settings app with the Privacy>Photos option", @"");
                    NSString* msg = [NSString stringWithFormat: format, kAppName()];
                    self.messageLabel.text = msg;
                    return;
                }
                case ALAssetsLibraryAccessGloballyDeniedError:
                {
                    self.messageLabel.text = NSLocalizedString(@"You are not authorized to access photos on this device. Please see you device administrator to remove the restriction.", @"");
                    return;
                }
                case ALAssetsLibraryDataUnavailableError:
                {
                    NSString* format = NSLocalizedString(@"Images could not be read from the Photos app. This is a serious error, please restart %@ and try again.", @"");
                    self.messageLabel.text = [NSString stringWithFormat: format, kAppName()];
                    return;
                }
                case ALAssetsLibraryUnknownError:
                {
                    self.messageLabel.text = NSLocalizedString(@"An unknown system error has occured. Try restarting your device.", @"");
                    return;
                }
                default:
                    break;
            }
        }
        
        NSString* description = error.localizedDescription;
        NSString* format = NSLocalizedString(@"An unknown error '%@' has occured. Please restart your device and try again.", @"");
        self.messageLabel.text = [NSString stringWithFormat: format, description];
    }];
    
    [_detector start];
}

- (void) viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear: animated];
    
    [_detector stop];
}

#pragma mark - CustomerDetectorDelegate
- (void) customerDetector:(CustomerDetector *)detector detectedCustomers:(NSSet *)customers {
    NSLog(@"Detected: %@", customers);
}

- (void) customerDetector:(CustomerDetector *)detector encounteredError:(NSError *)error {
    switch (error.code) {
        case kCustomerCounterErrorCanNotAddMetadataOutput:
        {
            NSString* title = NSLocalizedString(@"Initialization Error", @"");
            NSString* format = NSLocalizedString(@"Customers are not being counted because %@ could not connect to the device sensors. Please restart the app and try again.", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: [NSString stringWithFormat: format, kAppName()]
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            break;
        }
        case kCustomerCounterErrorNoFaceRecognition:
        {
            NSString* title = NSLocalizedString(@"Incompatible device", @"");
            NSString* format = NSLocalizedString(@"Customers are not being counted because %@ is not supported on this device! Please try using an iPad 2 or later device.", @"");
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                            message: [NSString stringWithFormat: format, kAppName()]
                                                           delegate: nil
                                                  cancelButtonTitle: NSLocalizedString(@"OK", @"")
                                                  otherButtonTitles: nil];
            [alert show];
            break;
        }
        default:
            break;
    }
}

@end
