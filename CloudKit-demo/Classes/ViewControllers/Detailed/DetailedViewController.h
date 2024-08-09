//
//  DetailedViewController.h
//  CloudKit-demo
//
//  Created by Maksim Usenko on 3/16/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "City.h"

@interface DetailedViewController : BaseViewController <UICloudSharingControllerDelegate>

@property (nonatomic, strong) City *city;

@end
