// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Event.m instead.

#import "_Event.h"

const struct EventAttributes EventAttributes = {
	.name = @"name",
	.primaryKey = @"primaryKey",
};

const struct EventRelationships EventRelationships = {
	.participants = @"participants",
};

const struct EventFetchedProperties EventFetchedProperties = {
};

@implementation EventID
@end

@implementation _Event

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Event";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Event" inManagedObjectContext:moc_];
}

- (EventID*)objectID {
	return (EventID*)[super objectID];
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





@dynamic participants;

	
- (NSMutableSet*)participantsSet {
	[self willAccessValueForKey:@"participants"];
  
	NSMutableSet *result = (NSMutableSet*)[self mutableSetValueForKey:@"participants"];
  
	[self didAccessValueForKey:@"participants"];
	return result;
}
	






@end
