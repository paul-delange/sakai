// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Participant.m instead.

#import "_Participant.h"

const struct ParticipantAttributes ParticipantAttributes = {
	.entryTime = @"entryTime",
	.exitTime = @"exitTime",
	.name = @"name",
	.primaryKey = @"primaryKey",
	.qrcode = @"qrcode",
	.updatedAt = @"updatedAt",
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
	

	return keyPaths;
}




@dynamic entryTime;






@dynamic exitTime;






@dynamic name;






@dynamic primaryKey;






@dynamic qrcode;






@dynamic updatedAt;











@end
