// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.m instead.

#import "_Participant.h"

const struct ParticipantAttributes ParticipantAttributes = {
	.affiliation = @"affiliation",
	.company = @"company",
	.entryTime = @"entryTime",
	.exitTime = @"exitTime",
	.name = @"name",
	.participationType = @"participationType",
	.primaryKey = @"primaryKey",
	.qrcode = @"qrcode",
	.updatedAt = @"updatedAt",
};

const struct ParticipantRelationships ParticipantRelationships = {
	.event = @"event",
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
	
	if ([key isEqualToString:@"participationTypeValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"participationType"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic affiliation;






@dynamic company;






@dynamic entryTime;






@dynamic exitTime;






@dynamic name;






@dynamic participationType;



- (int16_t)participationTypeValue {
	NSNumber *result = [self participationType];
	return [result shortValue];
}

- (void)setParticipationTypeValue:(int16_t)value_ {
	[self setParticipationType:[NSNumber numberWithShort:value_]];
}

- (int16_t)primitiveParticipationTypeValue {
	NSNumber *result = [self primitiveParticipationType];
	return [result shortValue];
}

- (void)setPrimitiveParticipationTypeValue:(int16_t)value_ {
	[self setPrimitiveParticipationType:[NSNumber numberWithShort:value_]];
}





@dynamic primaryKey;






@dynamic qrcode;






@dynamic updatedAt;






@dynamic event;

	






@end
