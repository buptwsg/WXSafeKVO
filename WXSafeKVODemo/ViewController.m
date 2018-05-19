//
//  ViewController.m
//  WXSafeKVODemo
//
//  Created by Shuguang Wang on 2018/5/10.
//  Copyright © 2018年 Shuguang Wang. All rights reserved.
//

#import "ViewController.h"
#import "NSObject+WXSafeKVO.h"

static void *context = &context;

@interface ViewController ()

@property (strong, nonatomic) UIView *observee;
@property (strong, nonatomic) dispatch_queue_t queue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.observee = [[UIView alloc] initWithFrame: CGRectMake(0, 0, 200, 200)];
    self.observee.center = self.view.center;
    self.observee.backgroundColor = [UIColor redColor];
    [self.view addSubview: self.observee];
    
    NSLog(@"kvo context = %p", context);
    [self.observee addObserver: self forKeyPath: @"backgroundColor" options: NSKeyValueObservingOptionInitial action: @selector(kvoSelector:change:)];
    [self.observee addObserver: self forKeyPath: @"backgroundColor" options: NSKeyValueObservingOptionInitial block:^(id  _Nonnull observer, id  _Nonnull object, NSDictionary<NSKeyValueChangeKey,id> * _Nonnull change) {
        NSLog(@"observer is %@, object is %@, change is %@", observer, object, change);
        [self.observee removeObserver: self forKeyPath: @"backgroundColor"];
    }];
    [self.observee addObserver: self forKeyPath: @"backgroundColor" options: NSKeyValueObservingOptionInitial context: context];
    
    self.queue = dispatch_queue_create("com.haha.test", DISPATCH_QUEUE_SERIAL);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        dispatch_async(self.queue, ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.observee removeFromSuperview];
                self.observee = nil;
            });
        });
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)kvoSelector: (id)object change: (NSDictionary*)change {
    NSLog(@"selector, object is %@, change is %@", object, change);
    [self.observee removeObserver: self forKeyPath: @"backgroundColor"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"kvo callback, context = %p", context);
}

@end


@implementation Observer


@end

