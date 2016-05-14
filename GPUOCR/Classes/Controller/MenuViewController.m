//
//  MenuViewController.m
//  GPUOCR
//
//  Created by Chris Hanshew on 5/13/16.
//  Copyright © 2016 Chris Hanshew. All rights reserved.
//

#import "MenuViewController.h"
#import "MenuCell.h"

typedef NS_ENUM(NSUInteger, MenuCellItem){
    MenuCellItemPhoto = 0,
    MenuCellItemAnalysis,
};

@interface MenuViewController ()

@end

@implementation MenuViewController

static NSString * const reuseIdentifier = @"MenuCell";

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDelegateFlowLayout>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(200, 200);
}


#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 2;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MenuCell *cell = (MenuCell *)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    if (cell) {
        switch (indexPath.item) {
            case MenuCellItemPhoto:
            {
                cell.label.text = @"Camera/File OCR";
            }
            case MenuCellItemAnalysis:
            {
                cell.label.text = @"Realtime Analysis";
            }
            default:
            {
                break;
            }
        }
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.item) {
        case MenuCellItemPhoto:
        {
            [self performSegueWithIdentifier:@"ShowPhotoViewController" sender:self];
        }
        case MenuCellItemAnalysis:
        {
            [self performSegueWithIdentifier:@"ShowAnalysisViewController" sender:self];
        }
        default:
        {
            break;
        }
    }
}

@end
