#import "Participant.h"
#import "Event.h"

#import <RestKit/RKManagedObjectStore.h>

@interface Participant ()

// Private interface goes here.

@end


@implementation Participant

- (NSString*) resourcePath {
    NSParameterAssert(self.primaryKey);
    
    Event* event = [Event currentEvent];
    NSString* eventPath = [event resourcePathParticipants];
    return [eventPath stringByAppendingPathComponent: self.primaryKey];
}

- (BOOL) participatingValue {
    return self.entryTime != nil;
}

@end
