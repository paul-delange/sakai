// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.m instead.

#import "_Participant.h"

const struct ParticipantAttributes ParticipantAttributes = {
	.entryTime = @"entryTime",
	.exitTime = @"exitTime",
	.name = @"name",
	.primaryKey = @"primaryKey",
};

const struct ParticipantRelationships ParticipantRelationships = {
};

const struct ParticipantFetchedProperties ParticipantFetchedProperties = {
};

@implementation ParticipantID
@end

@implementation _Participant

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Participant" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Participant";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Participant" inManagedObjectContext:moc_];
}

- (ParticipantID*)objectID {
	return (ParticipantID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"primaryKeyValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"primaryKey"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic entryTime;






@dynamic exitTime;






@dynamic name;






@dynamic primaryKey;



- (int16_t)primaryKeyValue {
	NSNumber *result = [self primaryKey];
	return [result shortValue];
}

- (void)setPrimaryKeyValue:(int16_t)value_ {
	[self setPrimaryKey:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitivePrimaryKeyValue {
	NSNumber *result = [self primitivePrimaryKey];
	return [result shortValue];
}

- (void)setPrimitivePrimaryKeyValue:(int16_t)value_ {
	[self setPrimitivePrimaryKey:[NSNumber numberWithShort:value_]];
}










@end
