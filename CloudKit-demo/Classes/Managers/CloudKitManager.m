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

@implementation CloudKitManager

+ (CKDatabase *)publicCloudDatabase {
    return [[CKContainer defaultContainer] publicCloudDatabase];
}

// Retrieve existing records
+ (void)fetchAllCitiesWithCompletionHandler:(CloudKitCompletionHandler)handler {
    
    NSPredicate *predicate = [NSPredicate predicateWithValue:YES];
    CKQuery *query = [[CKQuery alloc] initWithRecordType:kCitiesRecord predicate:predicate];
    
    [[self publicCloudDatabase] performQuery:query
                                inZoneWithID:nil
                           completionHandler:^(NSArray *results, NSError *error) {
        
                               if (!handler) return;
                               
                               dispatch_async(dispatch_get_main_queue(), ^{
                                   handler ([self mapCities:results], error);
                               });
    }];
}

// add a new record
+ (void)createRecord:(NSDictionary *)recordDic completionHandler:(CloudKitCompletionHandler)handler {
    
    CKRecord *record = [[CKRecord alloc] initWithRecordType:kCitiesRecord];

    [[recordDic allKeys] enumerateObjectsUsingBlock:^(NSString *key, NSUInteger idx, BOOL *stop) {
        
        if ([key isEqualToString:CloudKitCityFields.picture]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:recordDic[key] ofType:@"png"];
            NSData *data = [NSData dataWithContentsOfFile:path];
            record[key] = data;
        } else {
            record[key] = recordDic[key];
        }
    }];
    
    [[self publicCloudDatabase] saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
        
        if (!handler) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler (@[record], error);
        });
    }];
}

// updating the record by recordId
+ (void)updateRecordTextWithId:(NSString *)recordId text:(NSString *)text completionHandler:(CloudKitCompletionHandler)handler {
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId];
    [[self publicCloudDatabase] fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
        if (!handler) return;
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler (nil, error);
            });
            return;
        }
        
        record[CloudKitCityFields.text] = text;
        [[self publicCloudDatabase] saveRecord:record completionHandler:^(CKRecord *record, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler (@[record], error);
            });
        }];
    }];
}

// remove the record
+ (void)removeRecordWithId:(NSString *)recordId completionHandler:(CloudKitCompletionHandler)handler {
    
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId];
    [[self publicCloudDatabase] deleteRecordWithID:recordID completionHandler:^(CKRecordID *recordID, NSError *error) {
        
        if (!handler) return;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            handler (nil, error);
        });
    }];
}

+ (void)shareRecordWithId:(NSString *)recordId preparationCompletionHandler:( void (^)(CKShare * share, CKContainer * container, NSError * error))prephandler {
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId];
    [[self publicCloudDatabase] fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
//        if (!handler) return;
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                prephandler(nil, nil,error);
            });
            return;
        }
        
        CKShare * share = [[CKShare alloc] initWithRootRecord:record];
        share[CKShareTitleKey] = @"Olimpiada  w Jarzynowie";
        [share setPublicPermission:CKShareParticipantPermissionReadWrite];
//            share[CKShare.SystemFieldKey.title] = @"";
        CKModifyRecordsOperation * op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[share, record] recordIDsToDelete:nil];
        [op setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (error == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    prephandler(share, [CKContainer defaultContainer],error);
                        });
                
            }
        }];
//        [op  setDatabase:[self publicCloudDatabase]];
        [[self publicCloudDatabase] addOperation:op];
//        operationQueue. 89addOperation(modifyRecordsOp);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            handler (@[record], error);
//        });
    }];
}

+ (void)shareRecordWithId:(NSString *)recordId completionHandler:(CloudKitCompletionHandler)handler preparationCompletionHandler:( void (^)(CKShare * share, CKContainer * container, NSError * error))prephandler {
    
    CKRecordID *recordID = [[CKRecordID alloc] initWithRecordName:recordId];
    [[self publicCloudDatabase] fetchRecordWithID:recordID completionHandler:^(CKRecord *record, NSError *error) {
        
        if (!handler) return;
        
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler (nil, error);
            });
            return;
        }
        
        CKShare * share = [[CKShare alloc] initWithRootRecord:record];
//            share[CKShare.SystemFieldKey.title] = @"";
        CKModifyRecordsOperation * op = [[CKModifyRecordsOperation alloc] initWithRecordsToSave:@[share, record] recordIDsToDelete:nil];
        [op setModifyRecordsCompletionBlock:^(NSArray<CKRecord *> * _Nullable savedRecords, NSArray<CKRecordID *> * _Nullable deletedRecordIDs, NSError * _Nullable operationError) {
            if (error == nil) {
                prephandler(share, [CKContainer defaultContainer],error);
            }
        }];
//        [op  setDatabase:[self publicCloudDatabase]];
        [[self publicCloudDatabase] addOperation:op];
//        operationQueue.addOperation(modifyRecordsOp);
//        dispatch_async(dispatch_get_main_queue(), ^{
//            handler (@[record], error);
//        });
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

@end
