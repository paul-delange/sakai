//
//  ResultsViewController.m
//  CustomerCounter
//
//  Created by Paul de Lange on 20/04/2014.
//  Copyright (c) 2014 Chesterford. All rights reserved.
//

#import "ResultsViewController.h"

#import "Customer.h"
#import "CoreDataStack.h"

@import CoreData;

#define kAlertViewTagConfirmReset   89

#define SAMPLE_DICTIONARY_TIME_KEY      @"localized.time"
#define SAMPLE_DICTIONARY_COUNT_KEY     @"count"

NSString * const NSUserDefaultsResultsDisplayPeriod = @"ResultsPeriod";

@interface ResultsViewController () <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate> {
    NSArray* _data;
}

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *resetBarButton;

@end

@implementation ResultsViewController

- (void) reconstructData {
    NSManagedObjectContext* context = NSManagedObjectContextGetMainThreadContext();
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: @"Customer"];
    NSError* error;
    NSArray* allCustomers = [context executeFetchRequest: request error: &error];
    DLogError(error);
    
    NSLog(@"%d customers", [allCustomers count]);
}

#pragma mark - Actions
- (IBAction)resetPushed:(id)sender {
    NSString* title = NSLocalizedString(@"Are you sure?", @"");
    NSString* msg = NSLocalizedString(@"Reset will clear all data and restart counting from zero.", @"");
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: title
                                                    message: msg
                                                   delegate: self
                                          cancelButtonTitle: NSLocalizedString(@"Cancel", @"")
                                          otherButtonTitles: NSLocalizedString(@"Reset'", @""), nil];
    alert.tag = kAlertViewTagConfirmReset;
    [alert show];
}

- (IBAction)periodChanged:(UISegmentedControl*) sender {
    [[NSUserDefaults standardUserDefaults] setInteger: sender.selectedSegmentIndex forKey: NSUserDefaultsResultsDisplayPeriod];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reconstructData];
    [self.tableView reloadData];
}

#pragma mark - NSObject
+ (void) initialize {
    NSDictionary* params = @{ NSUserDefaultsResultsDisplayPeriod : @(0) };
    [[NSUserDefaults standardUserDefaults] registerDefaults: params];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.segmentedControl setTitle: NSLocalizedString(@"By Day", @"") forSegmentAtIndex: 0];
    [self.segmentedControl setTitle: NSLocalizedString(@"By Hour", @"") forSegmentAtIndex: 1];
    [self.resetBarButton setTitle: NSLocalizedString(@"Reset", @"")];
    
    NSInteger segmentToSelect = [[NSUserDefaults standardUserDefaults] integerForKey: NSUserDefaultsResultsDisplayPeriod];
    [self.segmentedControl setSelectedSegmentIndex: segmentToSelect];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"ResultTableViewCell" forIndexPath:indexPath];
    
    NSDictionary* sampleDictionary = _data[indexPath.item];
    
    cell.textLabel.text = sampleDictionary[SAMPLE_DICTIONARY_TIME_KEY];
    
    NSString* format = NSLocalizedString(@"%d people", @"");
    cell.detailTextLabel.text = [NSString stringWithFormat: format, sampleDictionary[SAMPLE_DICTIONARY_COUNT_KEY]];
    
    return cell;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data count];
}

#pragma mark - UITableViewDelegate

#pragma mark - UIAlertViewDelegate
- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case kAlertViewTagConfirmReset:
        {
            if( buttonIndex != alertView.cancelButtonIndex ) {
                NSManagedObjectContext* context = NSManagedObjectContextGetMainThreadContext();
                NSFetchRequest * allCars = [NSFetchRequest fetchRequestWithEntityName: @"Customer"];
                [allCars setIncludesPropertyValues:NO];
                
                NSError * error = nil;
                NSArray * results = [context executeFetchRequest:allCars error:&error];
                DLogError(error);
                
                for (NSManagedObject * car in results) {
                    [context deleteObject:car];
                }
                NSError* saveError;
                [context threadSafeSave: &saveError];
                DLogError(saveError);
            }
            break;
        }
        default:
            break;
    }
}

@end
