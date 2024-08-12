//
//  DetailedViewController.m
//  CloudKit-demo
//
//  Created by Maksim Usenko on 3/16/15.
//  Copyright (c) 2015 Yalantis. All rights reserved.
//

#import "DetailedViewController.h"
#import "CloudKitManager.h"
#import <CloudKit/CloudKit.h>


static NSString * const kUnwindId = @"unwindToMainId";

@interface DetailedViewController ()

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *cityImageView;
@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *indicatorView;

@end

@implementation DetailedViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [self setupView];
}

#pragma mark - IBActions

- (IBAction)saveButtonDidPress:(id)sender {
    [self.view endEditing:YES];
    self.scrollView.contentOffset = CGPointZero;
    
    [self shouldAnimateIndicator:YES];
    __weak typeof(self) weakSelf = self;
    [CloudKitManager updateRecordTextWithId:self.city.identifier
                                       text:[self.descriptionTextView.text copy]
                          completionHandler:^(NSArray *results, NSError *error) {
                              
                              if (error) {
                                  [weakSelf shouldAnimateIndicator:NO];
                                  [weakSelf presentMessage:error.userInfo[NSLocalizedDescriptionKey]];
                              } else {
                                  [weakSelf presentMessage:NSLocalizedString(@"City has been updated successfully", nil)];
                                  [weakSelf shouldAnimateIndicator:NO];
                              }
    }];
}

- (IBAction)removeButtonDidPress:(id)sender {
    
    [self shouldAnimateIndicator:YES];
    __weak typeof(self) weakSelf = self;
    [CloudKitManager removeRecordWithId:self.city.identifier completionHandler:^(NSArray *results, NSError *error) {
        
        if (error) {
            [weakSelf shouldAnimateIndicator:NO];
            [weakSelf presentMessage:error.userInfo[NSLocalizedDescriptionKey]];
        } else {
            [weakSelf performSegueWithIdentifier:kUnwindId sender:self];
        }
    }];
}
- (IBAction)shareButtonDidPRess:(id)sender {
//    if (true) {
//        [self share:self.city.identifier ];
//        return;
//    }
    [self shouldAnimateIndicator:YES];
    __weak typeof(self) weakSelf = self;
    UICloudSharingController * cscontroller = [[UICloudSharingController alloc] initWithPreparationHandler:^(UICloudSharingController * _Nonnull controller, void (^ _Nonnull preparationCompletionHandler)(CKShare * _Nullable, CKContainer * _Nullable, NSError * _Nullable)) {
        [CloudKitManager shareRecordWithId:self.city.identifier  preparationCompletionHandler:^(CKShare *share, CKContainer *container, NSError *error) {
            
        
             if(error) {
                [weakSelf shouldAnimateIndicator:NO];
                [weakSelf presentMessage:error.userInfo[NSLocalizedDescriptionKey]];
            } else {
                [weakSelf shouldAnimateIndicator:NO];
            }
        }];
       
    }];
    if (cscontroller) {
        [cscontroller setAvailablePermissions:UICloudSharingPermissionAllowReadWrite];
                        [cscontroller setAvailablePermissions:UICloudSharingPermissionAllowPrivate];
                        [cscontroller setModalPresentationStyle:UIModalPresentationFormSheet];
        cscontroller.delegate = weakSelf;
        [self presentViewController:cscontroller animated:true completion:^{
    //                [weakSelf presentMessage:NSLocalizedString(@"Successfully shared it", nil)];
        }];
    }
   
    
    
}

#pragma mark - Private

- (void)setupView {
    self.cityImageView.image = self.city.image;
    self.nameLabel.text = self.city.name;
    self.descriptionTextView.text = self.city.text;
}

- (void)shouldAnimateIndicator:(BOOL)animate {
    if (animate) {
        [self.indicatorView startAnimating];
    } else {
        [self.indicatorView stopAnimating];
    }
    
    self.view.userInteractionEnabled = !animate;
    self.navigationController.navigationBar.userInteractionEnabled = !animate;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    
    NSDictionary *info  = notification.userInfo;
    NSValue *value = info[UIKeyboardFrameEndUserInfoKey];
    
    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];
    
    self.scrollView.contentOffset = CGPointMake(0, keyboardFrame.size.height);
}

- (void)cloudSharingController:(nonnull UICloudSharingController *)csc failedToSaveShareWithError:(nonnull NSError *)error {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                               message:error.description
                               preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action) {}];

    [alert addAction:defaultAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (nullable NSString *)itemTitleForCloudSharingController:(nonnull UICloudSharingController *)csc {
    return  @"Customowy tytuł pod obrazkiem";
}

- (void)encodeWithCoder:(nonnull NSCoder *)coder {
    
}

- (void)didUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context withAnimationCoordinator:(nonnull UIFocusAnimationCoordinator *)coordinator {
    
}

- (void)setNeedsFocusUpdate {
    
}

- (BOOL)shouldUpdateFocusInContext:(nonnull UIFocusUpdateContext *)context {
    return  true;
}

- (void)updateFocusIfNeeded {
        
}

@end
