//
//  NNCollectionViewCocoaTouchCollection.m
//  ArrayDiff
//
//  Created by Nick Tymchenko on 20/04/14.
//  Copyright (c) 2014 Nick Tymchenko. All rights reserved.
//

#import "NNCollectionViewCocoaTouchCollection.h"

@interface NNCollectionViewCocoaTouchCollection ()

@property (nonatomic, strong) UICollectionView *collectionView;

@end


@implementation NNCollectionViewCocoaTouchCollection

#pragma mark - Init

- (id)initWithCollectionView:(UICollectionView *)collectionView {
    self = [super init];
    if (!self) return nil;
    
    _collectionView = collectionView;
    
    return self;
}

#pragma mark - NNCocoaTouchCollection

- (void)performUpdates:(void (^)())updates {
    [self.collectionView performBatchUpdates:updates completion:nil];
}

- (void)insertSections:(NSIndexSet *)sections {
    [self.collectionView insertSections:sections];
}

- (void)deleteSections:(NSIndexSet *)sections {
    [self.collectionView deleteSections:sections];
}

- (void)insertItemsAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView insertItemsAtIndexPaths:indexPaths];
}

- (void)deleteItemsAtIndexPaths:(NSArray *)indexPaths; {
    [self.collectionView deleteItemsAtIndexPaths:indexPaths];
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPaths {
    [self.collectionView reloadItemsAtIndexPaths:indexPaths];
}

- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath {
    [self.collectionView moveItemAtIndexPath:indexPath toIndexPath:newIndexPath];
}

- (id)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [self.collectionView cellForItemAtIndexPath:indexPath];
}

@end
