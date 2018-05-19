//
//  NSObject+WXSafeKVO.h
//  WXSafeKVO
//
//  Created by Shuguang Wang on 2018/5/13.
//  Copyright © 2018年 Shuguang Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The key for changed key path. When using block or selector to receive callback, the dictionary contains this key to indicate which key path's value changed.
 */
extern NSString * const WXKVONotificationKeyPathKey;

typedef void (^WXKVONotificationBlock)(id observer, id object, NSDictionary<NSKeyValueChangeKey, id> *change);

@interface NSObject (WXSafeKVO)

- (void)addObserver: (NSObject*)observer forKeyPath: (NSString*)keyPath options: (NSKeyValueObservingOptions)options block: (WXKVONotificationBlock)block;

- (void)addObserver: (NSObject*)observer forKeyPaths: (NSArray<NSString*> *)keyPaths options: (NSKeyValueObservingOptions)options block: (WXKVONotificationBlock)block;

- (void)addObserver: (NSObject*)observer forKeyPath: (NSString*)keyPath options: (NSKeyValueObservingOptions)options action: (SEL)action;

- (void)addObserver: (NSObject*)observer forKeyPaths: (NSArray<NSString*> *)keyPaths options: (NSKeyValueObservingOptions)options action: (SEL)action;

- (void)addObserver: (NSObject*)observer forKeyPaths: (NSArray<NSString*> *)keyPaths options: (NSKeyValueObservingOptions)options context: (nullable void *)context;

@end

NS_ASSUME_NONNULL_END
