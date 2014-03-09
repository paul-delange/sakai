//
//  CurrentLocationViewController.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "CurrentLocationViewController.h"

#define kUserDefaultsLastLocationUpdateTimeKey      @"LastLocationUpdateTime"

@import CoreLocation;

NSString * const kCurrentLocationChangedNotification = @"CurrentLocationChanged";
NSString * const kCurrentLocationUserInfoKey = @"CurrentLocationKey";

@interface CurrentLocationViewController () <CLLocationManagerDelegate> {
    CLLocationManager*      _locationManager;
}

@end

@implementation CurrentLocationViewController

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
    
    self.areaLabel.text = NSLocalizedString(@"Unknown area", @"");
    self.locationNameLabel.text = NSLocalizedString(@"Unknown location", @"");
    self.distanceAwayLabel.text = @"";
    self.pmLabel.text = NSLocalizedString(@"PM2.5:", @"");
    self.pmValueLabel.text = NSLocalizedString(@"Unknown", @"");
    self.recentRecordingsLabel.text = NSLocalizedString(@"PM2.5 Movement", @"");
    
    NSString* format = NSLocalizedString(@"Updated: %@", @"");
    NSDate* updateDate = [[NSUserDefaults standardUserDefaults] objectForKey: kUserDefaultsLastLocationUpdateTimeKey];
    self.lastUpdatedLabel.text = [NSString stringWithFormat: format, [NSDateFormatter localizedStringFromDate: updateDate
                                                                                                    dateStyle: NSDateFormatterMediumStyle
                                                                                                    timeStyle: NSDateFormatterShortStyle]];
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
    
#pragma mark - CLLocationManagerDelegate
    - (void)locationManager:(CLLocationManager *)manager
        didUpdateToLocation:(CLLocation *)newLocation
               fromLocation:(CLLocation *)oldLocation {
        
        
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
    
@end
