//
//  NNCocoaTouchCollectionReloader.m
//  ArrayDiff
//
//  Created by Nick Tymchenko on 27/04/14.
//  Copyright (c) 2014 Nick Tymchenko. All rights reserved.
//

#import "NNCocoaTouchCollectionReloader.h"
#import "NNSectionsDiffTracker.h"

@implementation NNCocoaTouchCollectionReloader

#pragma mark - Public

+ (void)reloadCocoaTouchCollection:(id<NNCocoaTouchCollection>)collection
                          withDiff:(NNSectionsDiff *)diff
                           options:(NNDiffReloadOptions)options
                    cellSetupBlock:(void (^)(id cell, NSIndexPath *indexPath))cellSetupBlock
{
    options = [self ensureDefaultOptions:options];
    
    NSAssert(!((options & NNDiffReloadUpdatedWithSetup) && cellSetupBlock == nil), @"NNDiffReloadUpdatedWithSetup requires a non-nil cellSetupBlock.");
    NSAssert(!((options & NNDiffReloadMovedWithMove) && cellSetupBlock == nil), @"NNDiffReloadMovedWithMove requires a non-nil cellSetupBlock.");
    
    
    if ([diff isEqual:[[NNSectionsDiff alloc] init]]) return;
    
    diff = [self sanitizeDiff:diff];
    
    __block NNSectionsDiffTracker *tracker = nil;
    
    
    NSMutableArray *indexPathsToSetup = [NSMutableArray array];
    
    [collection performUpdates:^{
        [collection deleteSections:diff.deletedSections];
        [collection insertSections:diff.insertedSections];
        
        [collection deleteItemsAtIndexPaths:diff.deleted];
        [collection insertItemsAtIndexPaths:diff.inserted];
        
        for (NNSectionsDiffChange *change in diff.changed) {
            if (change.type == NNDiffChangeUpdate) {
                if (options & NNDiffReloadUpdatedWithReload) {
                    if (options & NNDiffReloadMovedWithMove) {
                        // Have to use delete+insert for reloading purpose to co-exist with moves (thanks UIKit!)
                        [collection deleteItemsAtIndexPaths:@[ change.before ]];
                        [collection insertItemsAtIndexPaths:@[ change.after ]];
                    } else {
                        [collection reloadItemsAtIndexPaths:@[ change.before ]];
                    }
                } else {
                    [indexPathsToSetup addObject:change.after];
                }
            } else {
                BOOL shouldMove = (options & NNDiffReloadMovedWithMove);
                
                if (shouldMove) {
                    if (!tracker) {
                        tracker = [[NNSectionsDiffTracker alloc] initWithSectionsDiff:diff];
                    }
                    
                    // Move animations between different sections will crash if the destination section index doesn't match its initial one (thanks UIKit!)
                    NSUInteger sourceSectionIndex = [change.before indexAtPosition:0];
                    NSUInteger destinationSectionIndex = [change.after indexAtPosition:0];
                    NSUInteger previousDestinationSectionIndex = [tracker previousIndexForSection:destinationSectionIndex];
                    
                    if (sourceSectionIndex != previousDestinationSectionIndex &&
                        destinationSectionIndex != previousDestinationSectionIndex) {
                        shouldMove = NO;
                    }
                }
                
                if (shouldMove) {
                    [collection moveItemAtIndexPath:change.before toIndexPath:change.after];
                    if (change.type & NNDiffChangeUpdate) {
                        [indexPathsToSetup addObject:change.after];
                    }
                } else {
                    [collection deleteItemsAtIndexPaths:@[ change.before ]];
                    [collection insertItemsAtIndexPaths:@[ change.after ]];
                }
            }
        }
    }];
    
    for (NSIndexPath *indexPath in indexPathsToSetup) {
        id cell = [collection cellForItemAtIndexPath:indexPath];
        if (cell) {
            cellSetupBlock(cell, indexPath);
        }
    }
}

#pragma mark - Private

+ (NNDiffReloadOptions)ensureDefaultOptions:(NNDiffReloadOptions)options {
    if (!(options & (NNDiffReloadUpdatedWithReload | NNDiffReloadUpdatedWithSetup))) {
        options |= NNDiffReloadUpdatedWithReload;
    }
    if (!(options & (NNDiffReloadMovedWithDeleteAndInsert | NNDiffReloadMovedWithMove))) {
        options |= NNDiffReloadMovedWithDeleteAndInsert;
    }
    return options;
}

+ (NNSectionsDiff *)sanitizeDiff:(NNSectionsDiff *)diff {
    // UIKit would get upset if we attempted to move an item from a section being deleted / into a section being inserted.
    // Therefore, we should break such moves into deletions+insertions.
    
    NSMutableArray *additionalDeleted = [NSMutableArray array];
    NSMutableArray *additionalInserted = [NSMutableArray array];
    
    NSArray *changed = [diff.changed objectsAtIndexes:[diff.changed indexesOfObjectsPassingTest:^BOOL(NNSectionsDiffChange *obj, NSUInteger idx, BOOL *stop) {
        if (!(obj.type & NNDiffChangeMove)) return YES;
        
        if ([diff.deletedSections containsIndex:[obj.before indexAtPosition:0]]) {
            if (![diff.insertedSections containsIndex:[obj.after indexAtPosition:0]]) {
                [additionalInserted addObject:obj.after];
            }
            return NO;
        }
        
        if ([diff.insertedSections containsIndex:[obj.after indexAtPosition:0]]) {
            if (![diff.deletedSections containsIndex:[obj.before indexAtPosition:0]]) {
                [additionalDeleted addObject:obj.before];
            }
            return NO;
        }
        
        return YES;
	}]];
    
    NSArray *deleted = diff.deleted;
    if ([additionalDeleted count] > 0) {
        deleted = [deleted arrayByAddingObjectsFromArray:additionalDeleted];
    }
    
    NSArray *inserted = diff.inserted;
    if ([additionalInserted count] > 0) {
        inserted = [inserted arrayByAddingObjectsFromArray:additionalInserted];
    }
    
    return [[NNSectionsDiff alloc] initWithDeletedSections:diff.deletedSections
                                          insertedSections:diff.insertedSections
                                                   deleted:deleted
                                                  inserted:inserted
                                                   changed:changed];
}

@end
