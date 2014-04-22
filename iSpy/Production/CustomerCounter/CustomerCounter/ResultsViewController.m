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

#define SAMPLE_DICTIONARY_TIME_KEY      @"time"
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
    
    BOOL isByHour = [[NSUserDefaults standardUserDefaults] boolForKey: NSUserDefaultsResultsDisplayPeriod] == 1;
    
    if( isByHour ) {
        NSCalendar* calendar = [NSCalendar currentCalendar];
        
        NSMutableArray* mutableData = [NSMutableArray array];
        for(Customer* customer in allCustomers) {
            NSDate* date = customer.timestamp;
        
            NSDateComponents* components = [calendar components: NSHourCalendarUnit
                                                       fromDate: date];
            
            NSInteger hour = [components hour];
            NSString* strDate = [NSString stringWithFormat: @"%d:00-%d:00", hour, hour + 1];
            
            NSPredicate* predicate = [NSPredicate predicateWithFormat: @"%K = %@", SAMPLE_DICTIONARY_TIME_KEY, strDate];
            NSMutableDictionary* existingSection = [[mutableData filteredArrayUsingPredicate: predicate] lastObject];
            if( existingSection ) {
                NSNumber* count = existingSection[SAMPLE_DICTIONARY_COUNT_KEY];
                existingSection[SAMPLE_DICTIONARY_COUNT_KEY] = @([count integerValue] + 1);
            }
            else {
                existingSection = [NSMutableDictionary dictionary];
                existingSection[SAMPLE_DICTIONARY_TIME_KEY] = strDate;
                existingSection[SAMPLE_DICTIONARY_COUNT_KEY] = @(1);
                
                [mutableData addObject: existingSection];
            }
        }
        
        [mutableData sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1[SAMPLE_DICTIONARY_TIME_KEY] caseInsensitiveCompare: obj2[SAMPLE_DICTIONARY_TIME_KEY]];
        }];
        
        _data = [mutableData copy];
    }
    else {
        NSDateFormatterStyle dateStyle = NSDateFormatterMediumStyle;
        NSDateFormatterStyle timeStyle = NSDateFormatterNoStyle;
        
        NSMutableArray* mutableData = [NSMutableArray array];
        for(Customer* customer in allCustomers) {
            NSDate* date = customer.timestamp;
            
            NSString* strDate = [NSDateFormatter localizedStringFromDate: date
                                                               dateStyle: dateStyle
                                                               timeStyle: timeStyle];
            
            NSPredicate* predicate = [NSPredicate predicateWithFormat: @"%K = %@", SAMPLE_DICTIONARY_TIME_KEY, strDate];
            NSMutableDictionary* existingSection = [[mutableData filteredArrayUsingPredicate: predicate] lastObject];
            if( existingSection ) {
                NSNumber* count = existingSection[SAMPLE_DICTIONARY_COUNT_KEY];
                existingSection[SAMPLE_DICTIONARY_COUNT_KEY] = @([count integerValue] + 1);
            }
            else {
                existingSection = [NSMutableDictionary dictionary];
                existingSection[SAMPLE_DICTIONARY_TIME_KEY] = strDate;
                existingSection[SAMPLE_DICTIONARY_COUNT_KEY] = @(1);
                
                [mutableData addObject: existingSection];
            }
        }
        
        [mutableData sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            return [obj1[SAMPLE_DICTIONARY_TIME_KEY] caseInsensitiveCompare: obj2[SAMPLE_DICTIONARY_TIME_KEY]];
        }];
        
        _data = [mutableData copy];
    }
    
    //NSLog(@"Data: %@", _data);
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
    
    [self reconstructData];
    [self.tableView reloadData];
}

#pragma mark - UITableViewDataSource
- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier: @"ResultTableViewCell" forIndexPath:indexPath];
    
    NSDictionary* sampleDictionary = _data[indexPath.item];
    
    cell.textLabel.text = sampleDictionary[SAMPLE_DICTIONARY_TIME_KEY];
    
    NSString* format = NSLocalizedString(@"%d people", @"");
    cell.detailTextLabel.text = [NSString stringWithFormat: format, [sampleDictionary[SAMPLE_DICTIONARY_COUNT_KEY] integerValue]];
    
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
                
                [self.navigationController popViewControllerAnimated: YES];
            }
            break;
        }
        default:
            break;
    }
}

@end
