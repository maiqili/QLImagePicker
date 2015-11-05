//
//  QLImageAssetPickerController.h
//  QLImagePIcker
//
//  Created by maiqili on 15/10/30.
//  Copyright (c) 2015年 maiqili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class QLImageAssetPickerController;
@protocol QLImageAssetPickerDelegate <NSObject>

- (void)qLImageAssetPickerController:(QLImageAssetPickerController *)qLImageAssetPickerController didChangeSeclectAssetArray:(NSMutableArray *)seclectAssetArray;

- (void)qLImageAssetPickerController:(QLImageAssetPickerController *)qLImageAssetPickerController didFinishSeclectAssetArray:(NSMutableArray *)seclectAssetArray;

@end

@interface QLImageAssetPickerController : UIViewController

@property (nonatomic, strong) ALAssetsGroup *assetGroup;

@property (nonatomic, strong) NSMutableArray *seclectAssetArray;

@property (nonatomic, assign) id<QLImageAssetPickerDelegate> delegate;

@end
