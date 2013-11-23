//
//  EventSummaryView.m
//  QREvents
//
//  Created by Paul De Lange on 15/10/13.
//  Copyright (c) 2013 Toshimoto Sakai. All rights reserved.
//

#import "EventSummaryView.h"

#import "Event.h"
#import "Participant.h"

#import "AppDelegate.h"

@interface EventSummaryView () <NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) UILabel* nameLabel;
@property (weak, nonatomic) UILabel* subtitleLabel;
@end

@implementation EventSummaryView

#pragma mark - NSObject
- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

#pragma mark - UIView
- (instancetype) initWithFrame:(CGRect)frame {
    self = [super initWithFrame: frame];
    if( self ) {
        UILabel* nl = [UILabel new];
        nl.backgroundColor = [UIColor clearColor];
        nl.translatesAutoresizingMaskIntoConstraints = NO;
        nl.font = [UIFont boldSystemFontOfSize: 15.f];
        nl.textAlignment = NSTextAlignmentCenter;
        [self addSubview: nl];
        
        UILabel* stl = [UILabel new];
        stl.backgroundColor = [UIColor clearColor];
        stl.translatesAutoresizingMaskIntoConstraints = NO;
        stl.font = [UIFont systemFontOfSize: 10.f];
        stl.textAlignment = NSTextAlignmentCenter;
        [self addSubview: stl];
        
        self.nameLabel = nl;
        self.subtitleLabel = stl;
        self.backgroundColor = [UIColor clearColor];
        
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[nl(stl)][stl]|" options: 0 metrics: nil views: NSDictionaryOfVariableBindings(nl, stl)]];
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[nl]|" options: 0 metrics: nil views: NSDictionaryOfVariableBindings(nl)]];
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[stl]|" options: 0 metrics: nil views: NSDictionaryOfVariableBindings(stl)]];
    }
    
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    NSLog(@"Self: %@", NSStringFromCGRect(self.bounds));
    NSLog(@"Title: %@", NSStringFromCGRect(self.nameLabel.frame));
    NSLog(@"Sub: %@", NSStringFromCGRect(self.subtitleLabel.frame));
}

- (void) setEvent:(Event *)event {
    
    if( _event ) {
        [[NSNotificationCenter defaultCenter] removeObserver: self name: NSManagedObjectContextDidSaveNotification object: nil];
    }
    
    
    _event = event;
    
    if( event ) {
        self.nameLabel.text = event.name;
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(databaseSaved:)
                                                     name: NSManagedObjectContextDidSaveNotification
                                                   object: nil];
        NSManagedObjectContext* context = event.managedObjectContext;
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([Participant class])];
        NSUInteger totalCount = [context countForFetchRequest: request error: nil];
        [request setPredicate: [NSPredicate predicateWithFormat: @"entryTime > %@ AND exitTime < %@", [NSDate date], [NSDate date]]];
        NSUInteger activeCount = [context countForFetchRequest: request error: nil];
        
        [self setActive: activeCount withTotal: totalCount];
    }
    else {
        self.nameLabel.text = @"";
        [self setActive: 0 withTotal: 0];
    }
}

- (void) setActive: (NSUInteger) active withTotal: (NSUInteger) total {
    if( total > 0 )
        self.subtitleLabel.text = [NSString stringWithFormat: NSLocalizedString(@"%d / %d participants in meeting", @""), active, total];
    else
        self.subtitleLabel.text = NSLocalizedString(@"No participants found", @"");
    
    NSLog(@"Set %d/%d", active, total);
}

- (void) databaseSaved: (NSNotification*) notification {
    if( [NSThread isMainThread] ) {
        AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
        RKObjectManager* manager = [delegate objectManager];
        RKManagedObjectStore* store = [manager managedObjectStore];
        NSManagedObjectContext* context = [store mainQueueManagedObjectContext];
        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([Participant class])];
        
        NSUInteger totalCount = [context countForFetchRequest: request error: nil];
        
        [request setPredicate: [NSPredicate predicateWithFormat: @"entryTime > %@ AND exitTime < %@", [NSDate date], [NSDate date]]];
        
        NSUInteger activeCount = [context countForFetchRequest: request error: nil];
        
        [self setActive: activeCount withTotal: totalCount];
        [self setNeedsLayout];
    }
}

@end
