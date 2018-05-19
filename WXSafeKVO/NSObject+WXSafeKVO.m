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

@interface NSObject (WXSafeKVOSwizzled)

- (void)wx_addObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context;

- (void)wx_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath context:(void*)context;

- (void)wx_removeObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath;

@end

@interface _WXKVOInfo: NSObject {
    @public
    __weak NSObject *_observer;
    NSString *_keyPath;
    NSKeyValueObservingOptions _options;
    WXKVONotificationBlock _block;
    SEL _action;
    void *_context;
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

- (void)addKVOInfo:(_WXKVOInfo*)info;
- (void)removeKVOInfo:(_WXKVOInfo*)info;

@end

@implementation _WXKVOController

- (void)dealloc {
    [self.observerInfos enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableSet<_WXKVOInfo *> * _Nonnull obj, BOOL * _Nonnull stop) {
        NSSet<_WXKVOInfo*> *registeredInfos = [obj copy];
        for (_WXKVOInfo *info in registeredInfos) {
            [self removeKVOInfo: info];
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
        [self.observed wx_addObserver: self forKeyPath: info->_keyPath options: info->_options context: (__bridge void*)info];
    }
    else {
        //the observer has already been added, do nothing
    }
}

- (void)removeKVOInfo:(_WXKVOInfo *)info {
    NSMutableSet<_WXKVOInfo*> *registeredInfos = self.observerInfos[info->_keyPath];
    if (nil == registeredInfos) {
        return;
    }
    
    _WXKVOInfo *savedInfo = [registeredInfos member: info];
    if (nil == savedInfo) {
        //the observer has not been added, do nothing
    }
    else {
        [self.observed wx_removeObserver: self forKeyPath: info->_keyPath context: (__bridge void*)savedInfo];
        [registeredInfos removeObject: savedInfo];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    _WXKVOInfo *kvoInfo = (__bridge _WXKVOInfo*)context;
    NSObject *observer = kvoInfo->_observer;
    if (nil == observer) {
        NSMutableSet<_WXKVOInfo*> *registeredInfos = self.observerInfos[keyPath];
        [registeredInfos removeObject: kvoInfo];
        return;
    }
    
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

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Method origin = class_getInstanceMethod(self,    @selector(addObserver:forKeyPath:options:context:));
        Method hooked = class_getInstanceMethod(self, @selector(wx_addObserver:forKeyPath:options:context:));
        method_exchangeImplementations(origin, hooked);
        
        origin = class_getInstanceMethod(self,    @selector(removeObserver:forKeyPath:context:));
        hooked = class_getInstanceMethod(self, @selector(wx_removeObserver:forKeyPath:context:));
        method_exchangeImplementations(origin, hooked);
        
        origin = class_getInstanceMethod(self,    @selector(removeObserver:forKeyPath:));
        hooked = class_getInstanceMethod(self, @selector(wx_removeObserver:forKeyPath:));
        method_exchangeImplementations(origin, hooked);
    });
}

#pragma mark - API
- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: options block: block];
    [self.kvoController addKVOInfo: kvoInfo];
}

- (void)addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options block:(WXKVONotificationBlock)block {
    for (NSString *keyPath in keyPaths) {
        [self addObserver: observer forKeyPath: keyPath options: options block: block];
    }
}

- (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options action:(SEL)action {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: options action: action];
    [self.kvoController addKVOInfo: kvoInfo];
}

- (void)addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options action:(SEL)action {
    for (NSString *keyPath in keyPaths) {
        [self addObserver: observer forKeyPath: keyPath options: options action: action];
    }
}

- (void)addObserver:(NSObject *)observer forKeyPaths:(NSArray<NSString *> *)keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context {
    for (NSString *keyPath in keyPaths) {
        [self addObserver: observer forKeyPath: keyPath options: options context: context];
    }
}

#pragma mark - Swizzled
- (void)wx_addObserver:(NSObject*)observer forKeyPath:(NSString*)keyPath options:(NSKeyValueObservingOptions)options context:(void*)context {
    _WXKVOInfo *kvoInfo = [[_WXKVOInfo alloc] initWithObserver: observer keyPath: keyPath options: options context: context];
    [self.kvoController addKVOInfo: kvoInfo];
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
