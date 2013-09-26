// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.h instead.

#import <CoreData/CoreData.h>


extern const struct EventAttributes {
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





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* primaryKey;



@property int16_t primaryKeyValue;
- (int16_t)primaryKeyValue;
- (void)setPrimaryKeyValue:(int16_t)value_;

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


- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitivePrimaryKey;
- (void)setPrimitivePrimaryKey:(NSNumber*)value;

- (int16_t)primitivePrimaryKeyValue;
- (void)setPrimitivePrimaryKeyValue:(int16_t)value_;





- (NSMutableSet*)primitiveParticipants;
- (void)setPrimitiveParticipants:(NSMutableSet*)value;


@end
