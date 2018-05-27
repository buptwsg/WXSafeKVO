//
//  NSObject+WXSafeKVO.m
//  WXSafeKVO
//
//  Created by Shuguang Wang on 2018/5/13.
//  Copyright © 2018年 Shuguang Wang. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+WXSafeKVO.h"
#import "NSObject+WXDeallocBlock.h"

NSString * const WXKVONotificationKeyPathKey = @"WXKVONotificationKeyPathKey";

static void *WXKVOControllerKey = &WXKVOControllerKey;

#pragma mark - _WXKVOInfo

typedef NS_ENUM(uint8_t, _WXKVOInfoState) {
    _WXKVOInfoStateInitial,
    
    /// whether the observer registration in Foundation has completed
    _WXKVOInfoStateObserving,
    
    /// whether `unobserve` was called before observer registration in Foundation has completed
    /// this could happen when `NSKeyValueObservingOptionInitial` is one of the NSKeyValueObservingOptions
    _WXKVOInfoStateNotObserving
};

@interface _WXKVOInfo: NSObject {
    @public
    __weak NSObject *_observer;
    NSString *_keyPath;
    NSKeyValueObservingOptions _options;
    WXKVONotificationBlock _block;
    SEL _action;
    void *_context;
    _WXKVOInfoState _state;
    NSUInteger _hash;
}

- (instancetype)initWithObserver: (NSObject*)observer keyPath: (NSString*)keyPath options: (NSKeyValueObservingOptions)options block: (WXKVONotificationBlock)block action: (SEL)action context: (nullable void *)context NS_DESIGNATED_INITIALIZER;

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block;

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options action:(SEL)action;

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;

- (instancetype)initWithObserver:(NSObject*)observer keyPath:(NSString*)keyPath context:(void*)context;

- (instancetype)initWithObserver:(NSObject*)observer keyPath:(NSString*)keyPath;

- (instancetype)init NS_UNAVAILABLE;

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
        _state = _WXKVOInfoStateInitial;
        _hash = [_observer hash];
    }
    return self;
}

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    return [self initWithObserver: observer keyPath: keyPath options: options block: block action: nil context: NULL];
}

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options action:(SEL)action {
    return [self initWithObserver: observer keyPath: keyPath options: options block: nil action: action context: NULL];
}

- (instancetype)initWithObserver:(NSObject *)observer keyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    return [self initWithObserver: observer keyPath: keyPath options: options block: nil action: nil context: context];
}

- (instancetype)initWithObserver:(NSObject*)observer keyPath:(NSString*)keyPath context:(void*)context {
    return [self initWithObserver: observer keyPath: keyPath options: kNilOptions block: nil action: nil context: context];
}

- (instancetype)initWithObserver:(NSObject*)observer keyPath:(NSString*)keyPath {
    return [self initWithObserver: observer keyPath: keyPath options: kNilOptions block: nil action: nil context: NULL];
}

- (NSUInteger)hash {
    return _hash;
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

- (void)addKVOInfo:(_WXKVOInfo*)info;
- (void)removeKVOInfo:(_WXKVOInfo*)info;

@end

@implementation _WXKVOController

- (void)dealloc {
#if DEBUG
    NSLog(@"when dealloc, observerInfos is :\n %@", self.observerInfos);
#endif
    [self.observerInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableSet<_WXKVOInfo *> * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.count > 0) {
            [self.observed removeObserver: self forKeyPath: key];
        }
    }];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _observerInfos = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)addKVOInfo:(_WXKVOInfo *)info {
    NSMutableSet<_WXKVOInfo*> *registeredInfos = self.observerInfos[info->_keyPath];
    if (nil == registeredInfos) {
        registeredInfos = [NSMutableSet set];
        self.observerInfos[info->_keyPath] = registeredInfos;
    }
    
    _WXKVOInfo *savedInfo = [registeredInfos member: info];
    if (nil == savedInfo) {
        [registeredInfos addObject: info];
        
        __weak _WXKVOInfo *weakInfo = info;
        __weak _WXKVOController *weakSelf = self;
        __weak NSMutableSet *weakRegisteredInfos = registeredInfos;
        [info->_observer wx_addDeallocBlock:^{
            _WXKVOInfo *strongInfo = weakInfo;
            _WXKVOController *strongSelf = weakSelf;
            NSMutableSet *strongRegisteredInfos = weakRegisteredInfos;
            
            if (strongInfo) {
                [strongRegisteredInfos removeObject: strongInfo];
                [strongSelf.observed removeObserver: strongSelf forKeyPath: strongInfo->_keyPath context: (__bridge void*)strongInfo];
            }
        }];
        [self.observed addObserver: self forKeyPath: info->_keyPath options: info->_options context: (__bridge void*)info];
        
        if (info->_state == _WXKVOInfoStateInitial) {
            info->_state = _WXKVOInfoStateObserving;
        }
        else if (info->_state == _WXKVOInfoStateNotObserving) {
            // this could happen when `NSKeyValueObservingOptionInitial` is one of the NSKeyValueObservingOptions,
            // and the observer is unregistered within the callback block.
            // at this time the object has been registered as an observer (in Foundation KVO),
            // so we can safely remove the observer.
            [self.observed removeObserver: self forKeyPath: info->_keyPath context: (__bridge void*)info];
        }
    }
    else {
#if DEBUG
        NSLog(@"the observer has already been added, do nothing");
#endif
    }
}

- (void)removeKVOInfo:(_WXKVOInfo *)info {
    NSMutableSet<_WXKVOInfo*> *registeredInfos = self.observerInfos[info->_keyPath];
    if (nil == registeredInfos) {
        return;
    }
    
    _WXKVOInfo *savedInfo = [registeredInfos member: info];
    if (nil == savedInfo) {
#if DEBUG
        NSLog(@"the observer has not been added, do nothing");
#endif
    }
    else {
        [registeredInfos removeObject: savedInfo];
        
        if (savedInfo->_state == _WXKVOInfoStateObserving) {
            [self.observed removeObserver: self forKeyPath: info->_keyPath context: (__bridge void*)savedInfo];
        }
        savedInfo->_state = _WXKVOInfoStateNotObserving;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    _WXKVOInfo *kvoInfo = (__bridge _WXKVOInfo*)context;
    NSObject *observer = kvoInfo->_observer;
    NSMutableDictionary *changeDic = [change mutableCopy];
    changeDic[WXKVONotificationKeyPathKey] = keyPath;
    
    if (kvoInfo->_block) {
        kvoInfo->_block(observer, object, [changeDic copy]);
    }
    else if (kvoInfo->_action) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [observer performSelector: kvoInfo->_action withObject: object withObject: [changeDic copy]];
#pragma clang diagnostic pop
    }
    else if (kvoInfo->_context) {
        [observer observeValueForKeyPath: keyPath ofObject: object change: change context: kvoInfo->_context];
    }
    else {
        NSAssert(NO, @"kvoInfo is invalid, block && action && context is nil");
    }
}

@end

@implementation NSObject (WXSafeKVO)

#pragma mark - API
- (void)wx_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: options block: block];
    [self.kvoController addKVOInfo: kvoInfo];
}

- (void)wx_addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    for (NSString *keyPath in keyPaths) {
        [self wx_addObserver: observer forKeyPath: keyPath options: options block: block];
    }
}

- (void)wx_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options action:(SEL)action {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: options action: action];
    [self.kvoController addKVOInfo: kvoInfo];
}

- (void)wx_addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options action:(SEL)action {
    for (NSString *keyPath in keyPaths) {
        [self wx_addObserver: observer forKeyPath: keyPath options: options action: action];
    }
}

- (void)wx_addObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: options context: context];
    [self.kvoController addKVOInfo: kvoInfo];
}

- (void)wx_addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context {
    for (NSString *keyPath in keyPaths) {
        [self wx_addObserver: observer forKeyPath: keyPath options: options context: context];
    }
}

- (void)wx_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: kNilOptions block: nil action: nil context: context];
    [self.kvoController removeKVOInfo: kvoInfo];
}

- (void)wx_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: kNilOptions block: nil action: nil context: NULL];
    [self.kvoController removeKVOInfo: kvoInfo];
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

@end
