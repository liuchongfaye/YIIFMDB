//
//  LCVideoModel.h
//  YIIFMDB_Demo
//
//  Created by 刘冲 on 2018/10/29.
//  Copyright © 2018年 lc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCVideoModel : NSObject

@property (nonatomic, copy)    NSString *name;
@property (nonatomic, assign)  NSInteger gender;
@property (nonatomic, assign)  long age;
@property (nonatomic, assign)  float floatNumber;
@property (nonatomic, assign)  double doubleNumber;
@property (nonatomic, assign)  BOOL isMan;
@property (nonatomic, strong)  NSNumber *number;

@end
