#import "Event.h"

#import "AppDelegate.h"

@interface Event ()

// Private interface goes here.

@end


@implementation Event

// Custom logic goes here.
+ (instancetype) currentEvent {
    AppDelegate* delegate = [[UIApplication sharedApplication] delegate];
    RKObjectManager* manager = [delegate objectManager];
    RKManagedObjectStore* store = [manager managedObjectStore];
    NSManagedObjectContext* context = [store mainQueueManagedObjectContext];
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName: NSStringFromClass([self class])];
    NSArray* events = [context executeFetchRequest: request error: nil];
    NSAssert(events.count <= 1, @"Detected %d events. Why is this?", events.count);
    return events.lastObject;
}

- (NSString*) resourcePathParticipants {
    
#if USING_PARSE_DOT_COM
    RKObjectManager* objectManager = [[self appDelegate] objectManager];
    RKPathMatcher* pathMatcher = [RKPathMatcher pathMatcherWithPattern: kWebServiceIndividualPath];
    return [pathMatcher pathFromObject: participant addingEscapes: YES interpolatedParameters: nil];
#else
    NSParameterAssert(self.primaryKey);
    return [kWebServiceListPath stringByReplacingOccurrencesOfString: @":primaryKey" withString: self.primaryKey];
#endif
}

@end
