//
//  MapViewController.m
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "MapViewController.h"
#import "PMAnnotationView.h"
#import "PMAnnotation.h"

#import "MKMapView+ZoomLevel.h"

@import MapKit;

@interface MapViewController () <MKMapViewDelegate> {
    NSURLSessionDataTask*   _dataTask;
}

@property (copy, nonatomic) NSArray* data;

@end

@implementation MapViewController

- (void) fetchPointsForRegion: (MKMapRect) mapRect {
    MKMapPoint neMapPoint = MKMapPointMake(MKMapRectGetMaxX(mapRect), mapRect.origin.y);
    MKMapPoint swMapPoint = MKMapPointMake(mapRect.origin.x, MKMapRectGetMaxY(mapRect));
    
    CLLocationCoordinate2D neCoord = MKCoordinateForMapPoint(neMapPoint);
    CLLocationCoordinate2D swCoord = MKCoordinateForMapPoint(swMapPoint);
    
    [_dataTask cancel];
    
    NSString* dataPath = [NSString stringWithFormat: @"http://api.airtrack.info/data/map?n=%f&e=%f&s=%f&w=%f&max=100",
                          neCoord.latitude, neCoord.longitude, swCoord.latitude, swCoord.longitude];
    NSURL* dataURL = [NSURL URLWithString: dataPath];
    
    _dataTask = [[NSURLSession sharedSession] dataTaskWithURL: dataURL
                                            completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if( !error ) {
#if DEBUG
                                                    NSLog(@"Response: %@", [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding]);
#endif
                                                    id object = [NSJSONSerialization JSONObjectWithData: data options: 0 error: nil];
                                                    if( [object isKindOfClass: [NSArray class]] ) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            self.data = object;
                                                        });
                                                    }
                                                }
                                            }];
    
    [_dataTask resume];
}

- (void) setData:(NSArray *)data {
    [self.mapView removeAnnotations: self.mapView.annotations];
    
    NSMutableArray* annotations = [NSMutableArray new];
    for(NSDictionary* obj in data) {
        id value = obj[@"pm"];
        CLLocationDegrees lat = [obj[@"lat"] doubleValue];
        CLLocationDegrees lon = [obj[@"lon"] doubleValue];
        
        if( [value isKindOfClass: [NSString class]] ) {
            NSString* title = value;
            
            if( [title length] && [title integerValue] > 0) {
                PMAnnotation* ann = [PMAnnotation new];
                ann.title = value;
                ann.pmValue = [value integerValue];
                ann.coordinate = CLLocationCoordinate2DMake(lat, lon);
                [annotations addObject: ann];
            }
        }
    }
    
    [self.mapView addAnnotations: annotations];
    
    _data = data;
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    
    [self.mapView setCenterCoordinate: self.mapView.centerCoordinate zoomLevel: 8 animated: NO];
}

#pragma mark - MKMapViewDelegate
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    if( [annotation isKindOfClass: [MKUserLocation class]] ) {
        return nil;
    }
    else {
        PMAnnotationView* view = (PMAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier: @"PMAnnotation"];
        if( !view ) {
            view = [[PMAnnotationView alloc] initWithAnnotation: annotation reuseIdentifier: @"PMAnnotation"];
        }
        
        return view;
    }
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    
    if( mapView.zoomLevel < 3 ) {
        [mapView setCenterCoordinate: mapView.centerCoordinate zoomLevel: 3 animated: NO];
    }
    
    MKMapRect mapRect = mapView.visibleMapRect;
    
    [self fetchPointsForRegion: mapRect];
}

@end
