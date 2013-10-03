// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.h instead.

#import <CoreData/CoreData.h>


extern const struct ParticipantAttributes {
	__unsafe_unretained NSString *entryTime;
	__unsafe_unretained NSString *exitTime;
	__unsafe_unretained NSString *name;
	__unsafe_unretained NSString *primaryKey;
	__unsafe_unretained NSString *qrcode;
	__unsafe_unretained NSString *updatedAt;
} ParticipantAttributes;

extern const struct ParticipantRelationships {
} ParticipantRelationships;

extern const struct ParticipantFetchedProperties {
} ParticipantFetchedProperties;









@interface ParticipantID : NSManagedObjectID {}
@end

@interface _Participant : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (ParticipantID*)objectID;





@property (nonatomic, strong) NSDate* entryTime;



//- (BOOL)validateEntryTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* exitTime;



//- (BOOL)validateExitTime:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* name;



//- (BOOL)validateName:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* primaryKey;



//- (BOOL)validatePrimaryKey:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* qrcode;



//- (BOOL)validateQrcode:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSDate* updatedAt;



//- (BOOL)validateUpdatedAt:(id*)value_ error:(NSError**)error_;






@end

@interface _Participant (CoreDataGeneratedAccessors)

@end

@interface _Participant (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveEntryTime;
- (void)setPrimitiveEntryTime:(NSDate*)value;




- (NSDate*)primitiveExitTime;
- (void)setPrimitiveExitTime:(NSDate*)value;




- (NSString*)primitiveName;
- (void)setPrimitiveName:(NSString*)value;




- (NSString*)primitivePrimaryKey;
- (void)setPrimitivePrimaryKey:(NSString*)value;




- (NSString*)primitiveQrcode;
- (void)setPrimitiveQrcode:(NSString*)value;




- (NSDate*)primitiveUpdatedAt;
- (void)setPrimitiveUpdatedAt:(NSDate*)value;




@end
