// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.h instead.

#import <CoreData/CoreData.h>


extern const struct ParticipantAttributes {
	__unsafe_unretained NSString *atama_moji;
	__unsafe_unretained NSString *by_proxy;
	__unsafe_unretained NSString *company;
	__unsafe_unretained NSString *department;
	__unsafe_unretained NSString *entryTime;
	__unsafe_unretained NSString *exitTime;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *on_the_day;
	__unsafe_unretained NSString *position;
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





@property (nonatomic, strong) NSString* atama_moji;



//- (BOOL)validateAtama_moji:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* by_proxy;



@property BOOL by_proxyValue;
- (BOOL)by_proxyValue;
- (void)setBy_proxyValue:(BOOL)value_;

//- (BOOL)validateBy_proxy:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* company;



//- (BOOL)validateCompany:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* department;



//- (BOOL)validateDepartment:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* entryTime;



//- (BOOL)validateEntryTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* exitTime;



//- (BOOL)validateExitTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSNumber* on_the_day;



@property BOOL on_the_dayValue;
- (BOOL)on_the_dayValue;
- (void)setOn_the_dayValue:(BOOL)value_;

//- (BOOL)validateOn_the_day:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* position;



//- (BOOL)validatePosition:(id*)value_ error:(NSError**)error_;





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


- (NSString*)primitiveAtama_moji;
- (void)setPrimitiveAtama_moji:(NSString*)value;




- (NSNumber*)primitiveBy_proxy;
- (void)setPrimitiveBy_proxy:(NSNumber*)value;

- (BOOL)primitiveBy_proxyValue;
- (void)setPrimitiveBy_proxyValue:(BOOL)value_;




- (NSString*)primitiveCompany;
- (void)setPrimitiveCompany:(NSString*)value;




- (NSString*)primitiveDepartment;
- (void)setPrimitiveDepartment:(NSString*)value;




- (NSDate*)primitiveEntryTime;
- (void)setPrimitiveEntryTime:(NSDate*)value;




- (NSDate*)primitiveExitTime;
- (void)setPrimitiveExitTime:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSNumber*)primitiveOn_the_day;
- (void)setPrimitiveOn_the_day:(NSNumber*)value;

- (BOOL)primitiveOn_the_dayValue;
- (void)setPrimitiveOn_the_dayValue:(BOOL)value_;




- (NSString*)primitivePosition;
- (void)setPrimitivePosition:(NSString*)value;




- (NSString*)primitivePrimaryKey;
- (void)setPrimitivePrimaryKey:(NSString*)value;




- (NSString*)primitiveQrcode;
- (void)setPrimitiveQrcode:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;





- (Event*)primitiveEvent;
- (void)setPrimitiveEvent:(Event*)value;


@end
