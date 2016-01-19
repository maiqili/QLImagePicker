//
//  QLImagePickerController.m
//  QLImagePIcker
//
//  Created by maiqili on 15/10/30.
//  Copyright © 2015年 maiqili. All rights reserved.
//

#import "QLImagePickerController.h"
#import "QLImagePickerCell.h"
#import "QLImageAssetPickerController.h"

static CGRect swapWidthAndHeight(CGRect rect) {
    CGFloat swap = rect.size.width;
    rect.size.width  = rect.size.height;
    rect.size.height = swap;
    return rect;
}

@interface QLImagePickerController () <QLImageAssetPickerDelegate>

@property (nonatomic, strong) NSMutableArray *assetsGroupArray;//本地的相册--小组列表

@end

@implementation QLImagePickerController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"照片", nil);
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"取消", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonDidCilck:)];
    
    //判断相册是否可以访问
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusDenied || status == ALAuthorizationStatusRestricted) {
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    
    if (!self.seclectDictArray) {
        self.seclectDictArray = [NSMutableArray array];
    }
    
    self.seclectAssetArray = [NSMutableArray array];
    
#warning testcode
    self.filterType = QLImagePickerFilterTypeAllPhotos;
    self.assetsGroupArray = [NSMutableArray array];
    self.assetsLibrary = [[ALAssetsLibrary alloc] init];
    [self loadLocalAssetGroup];
}

- (void)loadLocalAssetGroup
{
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [self.assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupAll usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
            
            if (group) {
                switch (self.filterType) {
                    case QLImagePickerFilterTypeAllAssets:
                        [group setAssetsFilter:[ALAssetsFilter allAssets]];
                        break;
                        
                    case QLImagePickerFilterTypeAllPhotos:
                        [group setAssetsFilter:[ALAssetsFilter allPhotos]];
                        break;
                        
                    case QLImagePickerFilterTypeAllVideos:
                        [group setAssetsFilter:[ALAssetsFilter allVideos]];
                        break;
                        
                    default:
                        break;
                }
                [self.assetsGroupArray addObject:group];
            }else{
                dispatch_semaphore_signal(semaphore);
            }
        } failureBlock:^(NSError *error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            dispatch_semaphore_signal(semaphore);
        }];
    });
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        
        //遍历所有图片把已选择的图片加到 seclectAssetArray 里
        for (ALAssetsGroup *group in self.assetsGroupArray) {
            for (NSDictionary *assetDict in self.seclectDictArray) {
                NSURL *assetUrl = [assetDict objectForKey:UIImagePickerControllerReferenceURL];
                [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                    if ([assetUrl isEqual:[result valueForProperty:ALAssetPropertyAssetURL]]) {
                        [self.seclectAssetArray addObject:result];
                    }
                }];
            }
        }
        
        //根据asset的唯一路径去除seclectAssetArray里重复的asset
        NSMutableArray *copyArray = [NSMutableArray array];
        for (ALAsset *asset in self.seclectAssetArray) {
            BOOL isUnique = YES;
            for (ALAsset *selectAsset in copyArray) {
                if ([[asset valueForProperty:ALAssetPropertyAssetURL] isEqual:[selectAsset valueForProperty:ALAssetPropertyAssetURL]]) {
                    isUnique = NO;
                    break;
                }
            }
            if (isUnique) {
                [copyArray addObject:asset];
            }
        }
        self.seclectAssetArray = copyArray;
        
        for (int index = 0; index < [self.assetsGroupArray count]; ++index) {
            ALAssetsGroup *group = (ALAssetsGroup *)[self.assetsGroupArray objectAtIndex:index];
            
            //默认自动进入系统的全部图片相册
            if ([[group valueForProperty:ALAssetsGroupPropertyType] integerValue] == ALAssetsGroupSavedPhotos) {
                [self pushGroupWithIndex:index withAnimation:NO];
                break;
            }
        }
        
    });
    
}

//防止横评时状态栏消失
-(BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - 私有
- (void)pushGroupWithIndex:(NSUInteger)index withAnimation:(BOOL)animation
{
    ALAssetsGroup *assetsGroup = [self.assetsGroupArray objectAtIndex:index];
    
    QLImageAssetPickerController *vc = [[QLImageAssetPickerController alloc] init];
    vc.assetGroup = assetsGroup;
    vc.seclectAssetArray = self.seclectAssetArray;
    vc.delegate = self;
    [self.navigationController pushViewController:vc animated:animation];
}

- (void)cancelButtonDidCilck:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(qlImagePickerControllerDidCancel:)]) {
        [self.delegate qlImagePickerControllerDidCancel:self];
    }
}

//把ALAsset转成dictionary回调出去
- (NSDictionary *)mediaInfoFromAsset:(ALAsset *)asset
{
    NSMutableDictionary *mediaInfo = [NSMutableDictionary dictionary];
    ALAssetRepresentation *assetRepresentation = [asset defaultRepresentation];
    UIImageOrientation imageOrientation = (UIImageOrientation)[assetRepresentation orientation];
    
    UIImage *originalImage = [self fixOrientationTo:imageOrientation image:[UIImage imageWithCGImage:[assetRepresentation fullResolutionImage]]];
    
    if (originalImage) {
        [mediaInfo setObject:originalImage forKey:UIImagePickerControllerOriginalImage];
        [mediaInfo setObject:[asset valueForProperty:ALAssetPropertyType] forKey:UIImagePickerControllerMediaType];
        [mediaInfo setObject:[asset valueForProperty:ALAssetPropertyAssetURL] forKey:UIImagePickerControllerReferenceURL];
    }else {
        [self.seclectAssetArray removeObject:asset];
        return nil;
    }
    return mediaInfo;
}

//修正图片方向，使之正向（竖直）面对用户
- (UIImage *)fixOrientationTo:(UIImageOrientation) orient image:(UIImage *)image
{
    if (UIImageOrientationUp == orient) {
        return image;
    }
    
    CGRect bnds = CGRectZero;
    UIImage *copy = nil;
    CGContextRef ctxt = nil;
    CGImageRef imag = image.CGImage;
    CGRect rect = CGRectZero;
    CGAffineTransform tran = CGAffineTransformIdentity;
    
    rect.size.width = CGImageGetWidth(imag);
    rect.size.height = CGImageGetHeight(imag);
    
    bnds = rect;
    
    switch (orient)
    {
        case UIImageOrientationUp:
            // would get you an exact copy of the original
            return image;
            
        case UIImageOrientationUpMirrored:
            tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            break;
            
        case UIImageOrientationDown:
            tran = CGAffineTransformMakeTranslation(rect.size.width,
                                                    rect.size.height);
            tran = CGAffineTransformRotate(tran, M_PI);
            break;
            
        case UIImageOrientationDownMirrored:
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
            tran = CGAffineTransformScale(tran, 1.0, -1.0);
            break;
            
        case UIImageOrientationLeft:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            //	tran = CGAffineTransformMakeRotation(3.0 * M_PI / 2.0);
            //	tran = CGAffineTransformTranslate(tran, 0.0, rect.size.width);
            break;
            
        case UIImageOrientationLeftMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height,
                                                    rect.size.width);
            tran = CGAffineTransformScale(tran, -1.0, 1.0);
            tran = CGAffineTransformRotate(tran, 3.0 * M_PI / 2.0);
            break;
            
        case UIImageOrientationRight:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        case UIImageOrientationRightMirrored:
            bnds = swapWidthAndHeight(bnds);
            tran = CGAffineTransformMakeScale(-1.0, 1.0);
            tran = CGAffineTransformRotate(tran, M_PI / 2.0);
            break;
            
        default:
            // orientation value supplied is invalid
            assert(false);
            return nil;
    }
    
    UIGraphicsBeginImageContext(bnds.size);
    ctxt = UIGraphicsGetCurrentContext();
    
    switch (orient)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextScaleCTM(ctxt, -1.0, 1.0);
            CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
            break;
            
        default:
            CGContextScaleCTM(ctxt, 1.0, -1.0);
            CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
            break;
    }
    
    CGContextConcatCTM(ctxt, tran);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), rect, imag);
    
    copy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return copy;
}


#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _assetsGroupArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIndentifer = @"QLImagePickerCell";
    QLImagePickerCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIndentifer];
    if (cell == nil) {
        cell = [[QLImagePickerCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIndentifer];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    ALAssetsGroup *assetsGroup = [self.assetsGroupArray objectAtIndex:indexPath.row];
    
    cell.imageView.image = [UIImage imageWithCGImage:assetsGroup.posterImage];
    cell.titleLabel.text = [NSString stringWithFormat:@"%@", [assetsGroup valueForProperty:ALAssetsGroupPropertyName]];
    cell.countLabel.text = [NSString stringWithFormat:@"(%ld)", (long)assetsGroup.numberOfAssets];
    return cell;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 56;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self pushGroupWithIndex:indexPath.row withAnimation:YES];
}

#pragma mark - QLImageAssetPickerDelegate
- (void)qLImageAssetPickerController:(QLImageAssetPickerController *)qLImageAssetPickerController didChangeSeclectAssetArray:(NSMutableArray *)seclectAssetArray
{
    self.seclectAssetArray = seclectAssetArray;
}

- (void)qLImageAssetPickerController:(QLImageAssetPickerController *)qLImageAssetPickerController didFinishSeclectAssetArray:(NSMutableArray *)seclectAssetArray
{
    self.seclectAssetArray = seclectAssetArray;
    if ([self.delegate respondsToSelector:@selector(qLImagePickerController:didFinishPickImageWithArray:)]) {
        
        NSMutableArray *transformArray = [NSMutableArray array];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            
            for (ALAsset *asset in self.seclectAssetArray) {
                @autoreleasepool {//及时释放掉多余的资源
                    //判断本地文件是否已经删除
                    NSDictionary *assetDict = [self mediaInfoFromAsset:asset];
                    if (assetDict) {
                        [transformArray addObject:assetDict];
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                
                //                [MBProgressHUD dismissGlobalHUD];
                [self.delegate qLImagePickerController:self didFinishPickImageWithArray:transformArray];
            });
        });
    }
}

@end
