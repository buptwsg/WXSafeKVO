//
//  NSObject+WXDeallocBlock.m
//  WXSafeKVO
//
//  Created by Shuguang Wang on 2018/5/27.
//  Copyright © 2018年 Shuguang Wang. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+WXDeallocBlock.h"

@interface _WXParasite: NSObject

@property (nonatomic, copy) void (^deallocBlock)(void);

@end

@implementation _WXParasite

- (void)dealloc {
    if (self.deallocBlock) {
        self.deallocBlock();
    }
}

@end

@implementation NSObject (WXDeallocBlock)

- (void)wx_addDeallocBlock:(void (^)(void))block {
    @synchronized (self) {
        static NSString *kAssociatedKey = nil;
        NSMutableArray *parasiteList = objc_getAssociatedObject(self, &kAssociatedKey);
        if (!parasiteList) {
            parasiteList = [NSMutableArray array];
            objc_setAssociatedObject(self, &kAssociatedKey, parasiteList, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        
        _WXParasite *parasite = [[_WXParasite alloc] init];
        parasite.deallocBlock = block;
        [parasiteList addObject: parasite];
    }
}
@end
