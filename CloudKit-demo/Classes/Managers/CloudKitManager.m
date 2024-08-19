//
//  CloudKitManager.m
//  CloudKit-demo
//
//  Created by Maksim Usenko on 3/16/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

#import "CloudKitManager.h"
#import <UIKit/UIKit.h>
#import "City.h"

NSString * const kCitiesRecord = @"Cities";
NSString * const kParentsRecord = @"Parents";

NSString * const myCustomZoneName = @"LubiePlacki";
CKRecordZoneID * ids;
CKRecordZone * custZone;

@implementation CloudKitManager

+ (CKDatabase *)privateCloudDatabase {
    return [[CKContainer defaultContainer] privateCloudDatabase];
}


+(void)createOrFetchZone:( void (^)(CKRecordZone * rzone, NSError * error))handler {
    if (!custZone) {
        NSOperationQueue * queue = [[NSOperationQueue alloc] init];
        [queue setMaxConcurrentOperationCount:1];
        CKRecordZone * zone = [[CKRecordZone alloc] initWithZoneID: [[CKRecordZoneID alloc] initWithZoneName:myCustomZoneName ownerName:CKCurrentUserDefaultName]];
        [[self privateCloudDatabase] saveRecordZone: zone completionHandler:^(CKRecordZone * _Nullable zone, NSError * _Nullable error) {
            CKModifyRecordZonesOperation * oper = [[CKModifyRecordZonesOperation alloc] initWithRecordZonesToSave:@[zone] recordZoneIDsToDelete:nil];
            [oper setModifyRecordZonesCompletionBlock:^(NSArray<CKRecordZone *> * _Nullable savedRecordZones, NSArray<CKRecordZoneID *> * _Nullable deletedRecordZoneIDs, NSError * _Nullable operationError) {
                if(!operationError) {
                    custZone = savedRecordZones[0];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler (zone, error);
                    });
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler (nil, operationError);
                    });
                }
                
            }];
            [oper  setDatabase:[self privateCloudDatabase]];
            [queue addOperation:oper];
            if (!handler) return;
            
            
        }];
        
        return;
    } else {
        handler(custZone, nil);
    }
}


// Retrieve existing records
+ (void)fetchAllCitiesWithCompletionHandler:(CloudKitCompletionHandler)handler {
    [self createOrFetchZone:^(CKRecordZone *rzone, NSError *error) {
        if (error) {
            return;
        }
        NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
        CKQuery *query = [[CKQuery alloc] initWithRecordType:kCitiesRecord predicate:predicate];
        
        [[self privateCloudDatabase] performQuery:query
                                    inZoneWithID:rzone.zoneID
                               completionHandler:^(NSArray *results, NSError *error) {
            
            if (!handler) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                handler ([self mapCities:results], error);
            });
        }];
    }];
    
}

+ (void)fetchAllPArentsWithCompletionHandler:(CloudKitCompletionHandler)handler {
    [self createOrFetchZone:^(CKRecordZone *rzone, NSError *error) {
        if (error) {
            return;
        }
        NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
        CKQuery *query = [[CKQuery alloc] initWithRecordType:kParentsRecord predicate:predicate];
        
        [[self privateCloudDatabase] performQuery:query
                                    inZoneWithID:rzone.zoneID
                               completionHandler:^(NSArray *results, NSError *error) {
            
            if (!handler) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                handler ([self mapParents:results], error);
            });
        }];
    }];
    
}


// add a new record
+ (void)createRecord:(NSDictionary *)recordDic completionHandler:(CloudKitCompletionHandler)handler {
    
    [self createOrFetchZone:^(CKRecordZone *rzone, NSError *error) {
        CKRecord *record = [[CKRecord alloc] initWithRecordType:kCitiesRecord zoneID:custZone.zoneID];
        
        [[recordDic allKeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
            
            if ([key isEqualToString:CloudKitCityFields.picture]) {
                NSString *path = [[NSBundle mainBundle] pathForResource:recordDic[key] ofType:@"png"];
                NSData *data = [NSData dataWithContentsOfFile:path];
                record[key] = data;
            } else {
                record[key] = recordDic[key];
            }
        }];
        
        [[self privateCloudDatabase] saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
            
            if (!handler) return;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                handler (@[record], error);
            });
        }];
        
    }];
    
    
}

// updating the record by recordId
+ (void)updateRecordTextWithId:(NSString *)recordId text:(NSString *)text completionHandler:(CloudKitCompletionHandler)handler {
    [self createOrFetchZone:^(CKRecordZone *rzone, NSError *error) {
        CKRecord *record = [[CKRecord alloc] initWithRecordType:kCitiesRecord zoneID:custZone.zoneID];
        CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId zoneID:rzone.zoneID];
        [[self privateCloudDatabase] fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
            
            if (!handler) return;
            
            if (error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler (nil, error);
                });
                return;
            }
            
            record[CloudKitCityFields.text] = text;
            [[self privateCloudDatabase] saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler (@[record], error);
                });
            }];
        }];
    }];
}

// remove the record
+ (void)removeRecordWithId:(NSString *)recordId completionHandler:(CloudKitCompletionHandler)handler {
    
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId];
    [[self privateCloudDatabase] deleteRecordWithID:recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        
        if (!handler) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler (nil, error);
        });
    }];
}

+ (void)shareRecordWithId:(NSString *)recordId preparationCompletionHandler:( void (^)(CKShare * share, CKContainer * container, NSError * error))prephandler {
    NSOperationQueue * quwuw = [[NSOperationQueue alloc] init];
    [quwuw setMaxConcurrentOperationCount:1];
    
    [self createOrFetchZone:^(CKRecordZone *rzone, NSError *error) {
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId zoneID:custZone.zoneID];
    [[self privateCloudDatabase] fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                prephandler(nil, nil,error);
            });
            return;
        }
        
        CKShare * share = [[CKShare alloc] initWithRootRecord:record];
            
//            share[CKShareTitleKey] = @"example";0
            CKModifyRecordsOperation * op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[share, record] recordIDsToDelete:nil];
            [op setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
                if (operationError == nil) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        prephandler(share, [CKContainer defaultContainer],operationError);
                    });
                    
                }
                else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        prephandler(share, [CKContainer defaultContainer],operationError);
                    });
                }
            }];
            [op  setDatabase:[self privateCloudDatabase]];
            [quwuw addOperation:op];
    }];
    }];
}



+ (NSArray *)mapCities:(NSArray *)cities {
    if (cities.count == 0) return nil;
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [cities enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        City *city = [[City alloc] initWithInputData:obj];
        [temp addObject:city];
    }];
    
    return [NSArray arrayWithArray:temp];
}

+ (NSArray *)mapParents:(NSArray *)parents {
    if (parents.count == 0) return nil;
    
    NSMutableArray *temp = [[NSMutableArray alloc] init];
    [parents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        City *city = [[City alloc] initWithInputData:obj];
        [temp addObject:city];
    }];
    
    return [NSArray arrayWithArray:temp];
}

@end
