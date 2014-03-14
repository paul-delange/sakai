//
//  CurrentLocationViewController.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CurrentLocationViewController.h"

#import "ParticleCollectionViewCell.h"
#import "HistoryGraphView.h"

@import CoreLocation;

NSString * const kCurrentLocationChangedNotification = @"CurrentLocationChanged";
NSString * const kCurrentLocationUserInfoKey = @"CurrentLocationKey";

typedef NS_ENUM(NSUInteger, kParticleType) {
    kParticleTypeNitrogenOxide = 0,
    kParticleTypeNitrogenDioxide,
    kParticleTypeSulfurDioxide,
    kParticleTypeNitricOxide,
    kParticleTypeSuspendedPariculateMatter,
    kParticleTypeCount
};

@interface CurrentLocationViewController () <CLLocationManagerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate> {
    CLLocationManager*      _locationManager;
    NSURLSessionDataTask*   _dataTask;
}

@property (weak, nonatomic) IBOutlet UICollectionView *particleCollectionView;
@property (weak, nonatomic) IBOutlet HistoryGraphView *graphView;
@property (weak, nonatomic) IBOutlet UILabel *explanationLabel;
@property (weak) IBOutlet UIRefreshControl* refreshControl;

@end

@implementation CurrentLocationViewController

- (void) fetchInformationForLocation: (CLLocation*) location {
    
    [_dataTask cancel];
    
    NSString* dataPath = [NSString stringWithFormat: @"http://api.airtrack.info/data/position?lat=%f&lon=%f", location.coordinate.latitude, location.coordinate.longitude];
    NSURL* dataURL = [NSURL URLWithString: dataPath];
    _dataTask = [[NSURLSession sharedSession] dataTaskWithURL: dataURL
                                            completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                                //NSLog(@"End: %@", [NSDate date]);
                                                
                                                if( error ) {
                                                    NSLog(@"Error: %@", error);
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self setLocationDictionary: nil];
                                                    });
                                                }
                                                else {
#if DEBUG
                                                    NSLog(@"Response: %@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
#endif
                                                    id object = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
                                                    if( [object objectForKey: @"area"] ) {  //Hope we are ok!
                                                        [[NSUserDefaults standardUserDefaults] setObject: object forKey: kUserDefaultsLastUpdateKey];
                                                        [[NSUserDefaults standardUserDefaults] setObject: [NSDate date] forKey: kUserDefaultsLastLocationUpdateTimeKey];
                                                        [[NSUserDefaults standardUserDefaults] synchronize];
                                                    }
                                                    
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        [self setLocationDictionary: object];
                                                    });
                                                }
                                                
                                                [self.refreshControl endRefreshing];
                                            }];
    [_dataTask resume];
}

- (void) setLocationDictionary: (NSDictionary*) locationInfo {
    NSParameterAssert([NSThread isMainThread]);
    
    if( [locationInfo isKindOfClass: [NSDictionary class]] ) {
        self.areaLabel.text = locationInfo[@"area"];
        self.locationNameLabel.text = locationInfo[@"position_name"];
        self.pmValueLabel.text = locationInfo[@"pm25"];
        NSString* format = NSLocalizedString(@"Distance away: %0.2fkm", @"");
        self.distanceAwayLabel.text = [NSString stringWithFormat:format, [locationInfo[@"distance"] floatValue]];
        self.graphView.points = locationInfo[@"history"];
        
        id value = locationInfo[@"pm25"];
        
        if( [value integerValue] > 35 ) {
            self.pmValueLabel.textColor = [UIColor redColor];
        }
        else {
            self.pmValueLabel.textColor = [UIColor whiteColor];
        }
    }
    else {
        self.pmValueLabel.textColor = [UIColor whiteColor];
        self.graphView.points = nil;
        self.areaLabel.text = NSLocalizedString(@"Unknown area", @"");
        self.locationNameLabel.text = NSLocalizedString(@"Unknown location", @"");
        self.distanceAwayLabel.text = @"";
        self.pmValueLabel.text = NSLocalizedString(@"Unknown", @"");
    }
    
    [self.particleCollectionView performBatchUpdates: ^{
        [self.particleCollectionView reloadData];
    } completion: NULL];
    
    NSString* format = NSLocalizedString(@"Updated: %@", @"");
    NSDate* updateDate = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultsLastLocationUpdateTimeKey];
    self.lastUpdatedLabel.text = [NSString stringWithFormat: format, [NSDateFormatter localizedStringFromDate: updateDate
                                                                                                    dateStyle: NSDateFormatterMediumStyle
                                                                                                    timeStyle: NSDateFormatterShortStyle]];
}

#pragma mark - Actions
- (IBAction) refreshPushed:(UIRefreshControl*)sender {
    CLLocation* lastKnownLocation = _locationManager.location;      //nil on simulator
    if( lastKnownLocation ) {
        [self fetchInformationForLocation: lastKnownLocation];
    }
    else {
        [sender endRefreshing];
    }
}

#pragma mark - NSObject
+ (void) initialize {
    NSDictionary* defaults = @{ kUserDefaultsLastLocationUpdateTimeKey : [NSDate date] };
    [[NSUserDefaults standardUserDefaults] registerDefaults: defaults];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIViewController
- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder: aDecoder];
    if( self ) {
        
        CLLocationManager* manager = [CLLocationManager new];
        manager.delegate = self;
        manager.distanceFilter = kCLDistanceFilterNone;
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _locationManager = manager;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    NSDictionary* lastUpdate = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultsLastUpdateKey];
    [self setLocationDictionary: lastUpdate];
    
    NSDictionary* pmLabelAttributes = @{
                                        NSForegroundColorAttributeName :  [UIColor whiteColor],
                                        //NSUnderlineStyleAttributeName : @YES
                                        };
    
    self.pmLabel.attributedText = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"PM2.5", @"") attributes: pmLabelAttributes];
    self.recentRecordingsLabel.text = NSLocalizedString(@"PM2.5 Movement", @"");
    self.explanationLabel.text = NSLocalizedString(@"Normal: Less than 35uG/m3 per day", @"");
    
    UIRefreshControl* refreshControl = [UIRefreshControl new];
    refreshControl.tintColor = [UIColor whiteColor];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"Refreshing...", @"")
                                                                     attributes: @{
                                                                                   NSForegroundColorAttributeName : [UIColor whiteColor]
                                                                                   }];
    
    [refreshControl addTarget: self action: @selector(refreshPushed:) forControlEvents: UIControlEventValueChanged];
    [self.scrollView addSubview: refreshControl];
    self.refreshControl = refreshControl;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear: animated];
    
    if( [CLLocationManager significantLocationChangeMonitoringAvailable] ) {
        [_locationManager startMonitoringSignificantLocationChanges];
    }
    else {
        [_locationManager startUpdatingLocation];
    }
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear: animated];
    
    if( [CLLocationManager significantLocationChangeMonitoringAvailable] ) {
        [_locationManager stopMonitoringSignificantLocationChanges];
    }
    else {
        [_locationManager stopUpdatingLocation];
    }
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self.particleCollectionView performBatchUpdates: ^{
        [self.particleCollectionView reloadData];
    } completion: NULL];
    
    CGSize scrollSize = self.view.bounds.size;
    scrollSize.height += 44.;
    
    self.scrollView.contentSize = scrollSize;
    
    //NSLog(@"Size: %@", NSStringFromCGSize(self.scrollView.contentSize));
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    //NSLog(@"Location: %@", manager.location);
    
    [self fetchInformationForLocation: newLocation];
    
    NSDictionary* userInfo = @{ kCurrentLocationUserInfoKey : newLocation };
    [[NSNotificationCenter defaultCenter] postNotificationName: kCurrentLocationChangedNotification
                                                        object: manager
                                                      userInfo: userInfo];
}

- (void)locationManager:(CLLocationManager *)manager
       didFailWithError:(NSError *)error {
    
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return kParticleTypeCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ParticleCollectionViewCell* cell = [collectionView dequeueReusableCellWithReuseIdentifier: @"ParticleTypeCell" forIndexPath: indexPath];
    
    NSDictionary* cachedResponse = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultsLastUpdateKey];
    
    NSString* key = @"no";
    
    switch (indexPath.row) {
        case kParticleTypeNitricOxide:
            cell.particleNameLabel.text = NSLocalizedString(@"NOX[ppm]", @"");
            cell.borderMask = kParticleBorderMaskBottom | kParticleBorderMaskLeft | kParticleBorderMaskRight;
            key = @"nox";
            break;
        case kParticleTypeNitrogenDioxide:
            cell.particleNameLabel.text = NSLocalizedString(@"NO2[ppm]", @"");
            cell.borderMask = kParticleBorderMaskTop | kParticleBorderMaskRight | kParticleBorderMaskBottom;
            key = @"no2";
            break;
        case kParticleTypeNitrogenOxide:
            cell.particleNameLabel.text = NSLocalizedString(@"NO[ppm]", @"");
            cell.borderMask = kParticleBorderMaskTop | kParticleBorderMaskRight | kParticleBorderMaskLeft | kParticleBorderMaskBottom;
            key = @"no";
            break;
        case kParticleTypeSulfurDioxide:
            cell.particleNameLabel.text = NSLocalizedString(@"SO2[ppm]", @"");
            cell.borderMask = kParticleBorderMaskTop | kParticleBorderMaskRight | kParticleBorderMaskBottom;
            key = @"so2";
            break;
        case kParticleTypeSuspendedPariculateMatter:
            cell.particleNameLabel.text = NSLocalizedString(@"SPM[mg/m3]", @"");
            cell.borderMask = kParticleBorderMaskBottom | kParticleBorderMaskRight;
            key = @"spm";
            break;
        default:
            break;
    }
    
    id value = cachedResponse[key];
    cell.particleValueLabel.text = [value length] ? value : NSLocalizedString(@"N/A", @"");
    
    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(CGRectGetWidth(collectionView.bounds)/3., (CGRectGetHeight(collectionView.bounds)-10.)/2.);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    return 0.;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    return 0.;
}

#pragma mark - UIScrollViewDelegate
- (void) scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat minoffset = MIN(0, scrollView.contentOffset.y);
    scrollView.contentOffset = CGPointMake(0, minoffset);
    
    //NSLog(@"Offset: %f", minoffset);
}

@end
