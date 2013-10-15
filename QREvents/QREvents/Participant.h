#import "_Participant.h"

typedef enum {
    kParticpationTypeParticipant = 0,
    kParticpationTypeRepresentative,
    kParticpationTypeDayVisitor,
    kParticpationTypeCount
} kParticpationType;

@interface Participant : _Participant {}

@end
