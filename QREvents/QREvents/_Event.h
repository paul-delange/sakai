// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

#import <CoreData/CoreData.h>


extern const struct EventAttributes {
	__unsafe_unretained NSString *baseURL;
	__unsafe_unretained NSString *code;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *primaryKey;
} EventAttributes;

extern const struct EventRelationships {
	__unsafe_unretained NSString *participants;
} EventRelationships;

extern const struct EventFetchedProperties {
} EventFetchedProperties;

@class Participant;






@interface EventID : NSManagedObjectID {}
@end

@interface _Event : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (EventID*)objectID;





@property (nonatomic, strong) NSString* baseURL;



//- (BOOL)validateBaseURL:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* code;



//- (BOOL)validateCode:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* primaryKey;



//- (BOOL)validatePrimaryKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSSet *participants;

- (NSMutableSet*)participantsSet;





@end

@interface _Event (CoreDataGeneratedAccessors)

- (void)addParticipants:(NSSet*)value_;
- (void)removeParticipants:(NSSet*)value_;
- (void)addParticipantsObject:(Participant*)value_;
- (void)removeParticipantsObject:(Participant*)value_;

@end

@interface _Event (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveBaseURL;
- (void)setPrimitiveBaseURL:(NSString*)value;




- (NSString*)primitiveCode;
- (void)setPrimitiveCode:(NSString*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePrimaryKey;
- (void)setPrimitivePrimaryKey:(NSString*)value;





- (NSMutableSet*)primitiveParticipants;
- (void)setPrimitiveParticipants:(NSMutableSet*)value;


@end
