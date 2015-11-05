//
//  QLImageAssetPickerController.m
//  QLImagePIcker
//
//  Created by maiqili on 15/10/30.
//  Copyright (c) 2015年 maiqili. All rights reserved.
//

#import "QLImageAssetPickerController.h"
#import "QLAssetPickerCell.h"
#import "QLImagePickerConfig.h"

static NSString *assetCellIdentifier = @"QLAssetPickerCell";

@interface QLImageAssetPickerController ()
<
UICollectionViewDelegate,
UICollectionViewDataSource,
UICollectionViewDelegateFlowLayout
>

@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, strong) UILabel *choicedNumLable;

@property (nonatomic, strong) NSMutableArray *assetArray;

@end

@implementation QLImageAssetPickerController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.assetArray = [NSMutableArray array];
    self.title = [self.assetGroup valueForProperty:ALAssetsGroupPropertyName];
    self.view.backgroundColor = [UIColor whiteColor];
//    self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"确定", nil) style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonItemDidClick:)];
    
    self.choicedNumLable = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.frame) - 30 , CGRectGetWidth(self.view.frame), 30)];
    self.choicedNumLable.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleTopMargin;
    self.choicedNumLable.textAlignment = NSTextAlignmentCenter;
    self.choicedNumLable.textColor = [UIColor blackColor];
    self.choicedNumLable.font = [UIFont systemFontOfSize:20];
    [self updateSelectCountLable];
    [self.view addSubview:self.choicedNumLable];
    
    CGFloat collectionViewY = 0;
    UIInterfaceOrientation orientation =[UIApplication sharedApplication].statusBarOrientation;
    if((orientation == UIInterfaceOrientationLandscapeLeft) || (orientation == UIInterfaceOrientationLandscapeRight)) {
        collectionViewY = 52;//横屏时navagtionBar的高度为52
    }else{
        collectionViewY = 64;
    }
    
    //1.初始化layout
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    
    //2.初始化collectionView
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, collectionViewY, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - collectionViewY - CGRectGetHeight(_choicedNumLable.frame)) collectionViewLayout:layout];
    _collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth|
    UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:_collectionView];
    _collectionView.backgroundColor = [UIColor whiteColor];
    
    //3.注册collectionViewCell
    [_collectionView registerClass:[QLAssetPickerCell class] forCellWithReuseIdentifier:assetCellIdentifier];
    
    //4.设置代理
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    //5.多选
    _collectionView.allowsMultipleSelection = YES;
    
    [self initAssetArrayData];

}

-(BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(qLImageAssetPickerController:didChangeSeclectAssetArray:)]) {
        [self.delegate qLImageAssetPickerController:self didChangeSeclectAssetArray:_seclectAssetArray];
    }
    [super viewDidDisappear:animated];
    
    
}

- (void)initAssetArrayData
{
    [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result) {
            [self.assetArray insertObject:result atIndex:0];
        }
    }];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    CGFloat dis = 0;
    if ((toInterfaceOrientation == UIInterfaceOrientationLandscapeLeft) || (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
        dis = 52;
    }else{
        dis = 64;
    }
     _collectionView.frame = CGRectMake(0, dis, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame) - dis - CGRectGetHeight(_choicedNumLable.frame));
    [self.collectionView reloadData];
}

#pragma mark collectionView代理方法

//返回section个数
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}

//每个section的collectionItem个数
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.assetArray.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    QLAssetPickerCell *cell = (QLAssetPickerCell *)[collectionView dequeueReusableCellWithReuseIdentifier:assetCellIdentifier forIndexPath:indexPath];
    
    ALAsset *asset = (ALAsset *)self.assetArray[indexPath.row];
    if ([asset isKindOfClass:NSClassFromString(@"ALAsset")]) {
        
        BOOL selected = [self hasExistCollectionViewAtIndex:indexPath];
        if (selected) {
            cell.selected = YES;
            [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
        }
        [cell setThumbnailWithUIImage:[UIImage imageWithCGImage:[asset thumbnail]]];
    }
    return cell;
}

//设置每个collectionItem的尺寸
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake(qlAssetPickerCellWidth, qlAssetPickerCellWidth);
}

//设置整个collectionView的UIEdgeInsets
- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    CGFloat spacing = [self calculateCollectionItemHorizontalSpacing];
    return UIEdgeInsetsMake(10, spacing, 0, spacing);
}

//设置每个collectionItem之间的水平间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return [self calculateCollectionItemHorizontalSpacing];
}

//设置每个collectionItem之间的垂直间距
- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return [self calculateCollectionItemHorizontalSpacing];
}

//选择collectionItem
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.seclectAssetArray.count <= qlPickerViewMaxNumber) {
        BOOL hasExist = [self hasExistCollectionViewAtIndex:indexPath];
        if (!hasExist) {
            [self.seclectAssetArray addObject:self.assetArray[indexPath.row]];
            [self updateSelectCountLable];
        }
    }
    NSLog(@"selectItem-------%@",[((ALAsset *)self.assetArray[indexPath.row]) valueForProperty:ALAssetPropertyAssetURL]);
}

//判断collectionItem是否可选择
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.seclectAssetArray.count < qlPickerViewMaxNumber) {
        return YES;
    }
    return NO;
}

//取消选择collectionItem
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self removeObjectFromAssetArrayWithPathIndex:indexPath];
    NSLog(@"unSelectItem-------%@",indexPath);
}

//计算collectionItem之间的间距
- (CGFloat)calculateCollectionItemHorizontalSpacing
{
    NSInteger numOfRow = CGRectGetWidth(self.view.bounds) / qlAssetPickerCellWidth;
    CGFloat spacing = (CGRectGetWidth(self.view.bounds) - qlAssetPickerCellWidth*numOfRow)/(numOfRow + 1);
    return spacing;
}

#pragma mark 私有方法

- (BOOL)hasExistCollectionViewAtIndex:(NSIndexPath *)indexPath
{
    for (ALAsset *selectAsset in self.seclectAssetArray)
    {
        if ([[selectAsset valueForProperty:ALAssetPropertyAssetURL] isEqual:[((ALAsset *)_assetArray[indexPath.row]) valueForProperty:ALAssetPropertyAssetURL]])
        {
            return YES;
        }
    }
    return NO;
}

- (void)removeObjectFromAssetArrayWithPathIndex:(NSIndexPath *)indexPath
{
    for (ALAsset *selectAsset in self.seclectAssetArray)
    {
        if ([[selectAsset valueForProperty:ALAssetPropertyAssetURL] isEqual:[((ALAsset *)_assetArray[indexPath.row]) valueForProperty:ALAssetPropertyAssetURL]])
        {
            [self.seclectAssetArray removeObject:selectAsset];
            [self updateSelectCountLable];
            return;
        }
    }
}

- (void)updateSelectCountLable
{
    self.choicedNumLable.text = [NSString stringWithFormat:@"已选择了%ld张，还可以选择%ld张", self.seclectAssetArray.count,qlPickerViewMaxNumber - self.seclectAssetArray.count];
}

- (void)rightBarButtonItemDidClick:(id)sender
{
    UIBarButtonItem *item = (UIBarButtonItem *)sender;
    [item setEnabled:NO];
    if ([self.delegate respondsToSelector:@selector(qLImageAssetPickerController:didFinishSeclectAssetArray:)]) {
        [self.delegate qLImageAssetPickerController:self didFinishSeclectAssetArray:_seclectAssetArray];
    }
}

@end
