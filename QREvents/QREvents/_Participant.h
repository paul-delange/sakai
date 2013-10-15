// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.h instead.

#import <CoreData/CoreData.h>


extern const struct ParticipantAttributes {
	__unsafe_unretained NSString *affiliation;
	__unsafe_unretained NSString *company;
	__unsafe_unretained NSString *entryTime;
	__unsafe_unretained NSString *exitTime;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *participationType;
	__unsafe_unretained NSString *primaryKey;
	__unsafe_unretained NSString *qrcode;
	__unsafe_unretained NSString *updatedAt;
} ParticipantAttributes;

extern const struct ParticipantRelationships {
	__unsafe_unretained NSString *event;
} ParticipantRelationships;

extern const struct ParticipantFetchedProperties {
} ParticipantFetchedProperties;

@class Event;











@interface ParticipantID : NSManagedObjectID {}
@end

@interface _Participant : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ParticipantID*)objectID;





@property (nonatomic, strong) NSString* affiliation;



//- (BOOL)validateAffiliation:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* company;



//- (BOOL)validateCompany:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* entryTime;



//- (BOOL)validateEntryTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* exitTime;



//- (BOOL)validateExitTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* participationType;



@property int16_t participationTypeValue;
- (int16_t)participationTypeValue;
- (void)setParticipationTypeValue:(int16_t)value_;

//- (BOOL)validateParticipationType:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* primaryKey;



//- (BOOL)validatePrimaryKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* qrcode;



//- (BOOL)validateQrcode:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) Event *event;

//- (BOOL)validateEvent:(id*)value_ error:(NSError**)error_;





@end

@interface _Participant (CoreDataGeneratedAccessors)

@end

@interface _Participant (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveAffiliation;
- (void)setPrimitiveAffiliation:(NSString*)value;




- (NSString*)primitiveCompany;
- (void)setPrimitiveCompany:(NSString*)value;




- (NSDate*)primitiveEntryTime;
- (void)setPrimitiveEntryTime:(NSDate*)value;




- (NSDate*)primitiveExitTime;
- (void)setPrimitiveExitTime:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveParticipationType;
- (void)setPrimitiveParticipationType:(NSNumber*)value;

- (int16_t)primitiveParticipationTypeValue;
- (void)setPrimitiveParticipationTypeValue:(int16_t)value_;




- (NSString*)primitivePrimaryKey;
- (void)setPrimitivePrimaryKey:(NSString*)value;




- (NSString*)primitiveQrcode;
- (void)setPrimitiveQrcode:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;





- (Event*)primitiveEvent;
- (void)setPrimitiveEvent:(Event*)value;


@end
