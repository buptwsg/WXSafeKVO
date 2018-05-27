//
//  NSObject+WXDeallocBlock.h
//  WXSafeKVO
//
//  Created by Shuguang Wang on 2018/5/27.
//  Copyright © 2018年 Shuguang Wang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (WXDeallocBlock)

/**
 @brief add a block which will be called when the object is deallocated
 */
- (void)wx_addDeallocBlock: (void (^)(void))block;

@end
