//
//  MapViewController.h
//  pm25
//
//  Created by Paul de Lange on 9/03/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MKMapView;

@interface MapViewController : UIViewController

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
