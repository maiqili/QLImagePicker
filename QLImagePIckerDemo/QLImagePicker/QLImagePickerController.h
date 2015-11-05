//
//  QLImagePickerController.h
//  QLImagePIcker
//
//  Created by maiqili on 15/10/30.
//  Copyright © 2015年 maiqili. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@class QLImagePickerController;
@protocol QLImagePickerControllerDelegate <NSObject>

-(void)qLImagePickerController:(QLImagePickerController *)qLImagePickerController didFinishPickImageWithArray:(NSArray *)imageArray;

-(void)qlImagePickerControllerDidCancel:(QLImagePickerController *)imagePickerController;

@end

typedef enum {
    QLImagePickerFilterTypeAllAssets,
    QLImagePickerFilterTypeAllPhotos,//暂时只用到这个
    QLImagePickerFilterTypeAllVideos
} QLImagePickerFilterType;

@interface QLImagePickerController : UITableViewController

@property (nonatomic, assign) QLImagePickerFilterType filterType;

@property (nonatomic, strong) NSMutableArray *seclectAssetArray;//Object：ALAsset 用于存储已选择的资源文件

@property (nonatomic, strong) NSMutableArray *seclectDictArray;
/*Object：
 NSDictionary ：key{
 @“UIImagePickerControllerOriginalImage”：图片（UIImage），
 @“UIImagePickerControllerMediaType”：图片类型，
 @“UIImagePickerControllerReferenceURL” ： 图片Url
 }
 */

@property (nonatomic, strong) id<QLImagePickerControllerDelegate> delegate;

@property (nonatomic, strong) ALAssetsLibrary *assetsLibrary;
@end
