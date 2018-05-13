//
//  NSObject+WXSafeKVO.m
//  WXSafeKVO
//
//  Created by Shuguang Wang on 2018/5/13.
//  Copyright © 2018年 Shuguang Wang. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+WXSafeKVO.h"

NSString * const WXKVONotificationKeyPathKey = @"WXKVONotificationKeyPathKey";

static void *WXKVOControllerKey = &WXKVOControllerKey;

@interface _WXKVOInfo: NSObject {
    __weak NSObject *_observer;
    NSString *_keyPath;
    NSKeyValueObservingOptions _options;
    WXKVONotificationBlock _block;
    SEL _action;
    void *_context;
}

- (instancetype)initWithObserver: (NSObject*)observer keyPath: (NSString*)keyPath options: (NSKeyValueObservingOptions)options block: (WXKVONotificationBlock)block action: (SEL)action context: (nullable void *)context;

@end

@implementation _WXKVOInfo

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block action:(SEL)action context:(nullable void *)context {
    self = [super init];
    if (self) {
        _observer = observer;
        _keyPath = [keyPath copy];
        _options = options;
        _block = [block copy];
        _action = action;
        _context = context;
    }
    return self;
}

- (NSUInteger)hash {
    return [_observer hash];
}

- (BOOL)isEqual:(id)object {
    if (nil == object) {
        return NO;
    }
    
    if (![object isKindOfClass: [self class]]) {
        return NO;
    }
    
    if (self == object) {
        return YES;
    }
    
    return _observer = ((_WXKVOInfo*)object)->_observer;
}
@end

@interface _WXKVOController: NSObject

@property (nonatomic, unsafe_unretained) NSObject *observed;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<_WXKVOInfo*> *> *observerInfos;

@end

@implementation _WXKVOController

- (void)dealloc {
    
}

- (instancetype)init {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
}

@end

@implementation NSObject (WXSafeKVO)

+ (void)load {
    
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    
}

- (void)addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options action:(SEL)action {
    
}

- (void)addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options action:(SEL)action {
    
}

- (void)addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context {
    
}

#pragma mark - Swizzled
- (void)wx_addObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context {
    
}

- (void)wx_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context {
    
}

- (void)wx_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath {
    
}

#pragma mark - Private
- (_WXKVOController*)kvoController {
    _WXKVOController *controller = objc_getAssociatedObject(self, WXKVOControllerKey);
    if (nil == controller) {
        controller = [[_WXKVOController alloc] init];
        controller.observed = self;
        objc_setAssociatedObject(self, WXKVOControllerKey, controller, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return controller;
}

- (void)addObserver:(NSObject*)observer kvoInfo:(_WXKVOInfo*)info {
    
}

@end
