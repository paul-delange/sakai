// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.m instead.

#import "_Participant.h"

const struct ParticipantAttributes ParticipantAttributes = {
	.atama_moji = @"atama_moji",
	.by_proxy = @"by_proxy",
	.company = @"company",
	.department = @"department",
	.entryTime = @"entryTime",
	.exitTime = @"exitTime",
	.name = @"name",
	.on_the_day = @"on_the_day",
	.position = @"position",
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
	
	if ([key isEqualToString:@"by_proxyValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"by_proxy"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}
	if ([key isEqualToString:@"on_the_dayValue"]) {
		NSSet *affectingKey = [NSSet setWithObject:@"on_the_day"];
		keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKey];
		return keyPaths;
	}

	return keyPaths;
}




@dynamic atama_moji;






@dynamic by_proxy;



- (BOOL)by_proxyValue {
	NSNumber *result = [self by_proxy];
	return [result boolValue];
}

- (void)setBy_proxyValue:(BOOL)value_ {
	[self setBy_proxy:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveBy_proxyValue {
	NSNumber *result = [self primitiveBy_proxy];
	return [result boolValue];
}

- (void)setPrimitiveBy_proxyValue:(BOOL)value_ {
	[self setPrimitiveBy_proxy:[NSNumber numberWithBool:value_]];
}





@dynamic company;






@dynamic department;






@dynamic entryTime;






@dynamic exitTime;






@dynamic name;






@dynamic on_the_day;



- (BOOL)on_the_dayValue {
	NSNumber *result = [self on_the_day];
	return [result boolValue];
}

- (void)setOn_the_dayValue:(BOOL)value_ {
	[self setOn_the_day:[NSNumber numberWithBool:value_]];
}

- (BOOL)primitiveOn_the_dayValue {
	NSNumber *result = [self primitiveOn_the_day];
	return [result boolValue];
}

- (void)setPrimitiveOn_the_dayValue:(BOOL)value_ {
	[self setPrimitiveOn_the_day:[NSNumber numberWithBool:value_]];
}





@dynamic position;






@dynamic primaryKey;






@dynamic qrcode;






@dynamic updatedAt;






@dynamic event;

	






@end
