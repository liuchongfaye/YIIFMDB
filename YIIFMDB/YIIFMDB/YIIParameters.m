//
//  YIIParameters.m
//  FMDataBaseManager
//
//  Created by 刘冲 on 2018/10/22.
//  Copyright © 2018年 lc. All rights reserved.
//

#import "YIIParameters.h"

@interface YIIParameters ()

@property (nonatomic, strong) NSMutableArray<NSString *> *andParameters;    // and参数
@property (nonatomic, strong) NSMutableArray<NSString *> *orParameters;     // or参数
@property (nonatomic, copy)   NSString *orderString;                        // 排序语句


@end

@implementation YIIParameters

#pragma mark - Override Methods

- (NSMutableArray<NSString *> *)andParameters {
    if (!_andParameters) {
        _andParameters = [NSMutableArray array];
    }
    
    return _andParameters;
}

- (NSMutableArray<NSString *> *)orParameters {
    if (!_orParameters) {
        _orParameters = [NSMutableArray array];
    }
    
    return _orParameters;
}

- (NSString *)whereParameters {
    if (_whereParameters) {
        return _whereParameters;
    } else {
        NSMutableString *string = [NSMutableString string];
        NSString *andString = [self.andParameters componentsJoinedByString:@" and "];
        NSString *orString  = [self.orParameters componentsJoinedByString:@" or "];
        if (andString && andString.length > 0) {
            [string appendFormat:@"%@", andString];
        }
        
        if (orString && orString.length > 0) {
            [string appendFormat:@"%@%@", (string.length > 0 ? @" or " : @""), orString];
        }
        
        if (self.orderString) {
            [string appendFormat:@" %@", self.orderString];
        }
        
        if (self.limitCount > 0) {
            [string appendFormat:@" limit %ld", (long)self.limitCount];
        }
        
        return (NSString *)(string.length > 0 ? string : nil);
    }
}

#pragma mark - 配置参数

- (void)andWhere:(NSString *)column value:(id)value relationType:(YIIParametersRelationType)relationType {
    NSString *string = nil;
    switch (relationType) {
        case YIIParametersRelationTypeEqualTo:
            string = [NSString stringWithFormat:@"%@ = %@", column, value];
            break;
        case YIIParametersRelationTypeUnequalTo:
            string = [NSString stringWithFormat:@"%@ != %@", column, value];
            break;
        case YIIParametersRelationTypeGreaterThan:
            string = [NSString stringWithFormat:@"%@ > %@", column, value];
            break;
        case YIIParametersRelationTypeGreaterThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ >= %@", column, value];
            break;
        case YIIParametersRelationTypeLessThan:
            string = [NSString stringWithFormat:@"%@ < %@", column, value];
            break;
        case YIIParametersRelationTypeLessThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ <= %@", column, value];
            break;
        case YIIParametersRelationTypeLike:
            string = [NSString stringWithFormat:@"%@ like '%@'", column, value];
            break;
        default:
            break;
    }
    if (string) {
        [self.andParameters addObject:string];
    }
}

- (void)orWhere:(NSString *)column value:(id)value relationType:(YIIParametersRelationType)relationType {
    NSString *string = nil;
    switch (relationType) {
        case YIIParametersRelationTypeEqualTo:
            string = [NSString stringWithFormat:@"%@ = %@", column, value];
            break;
        case YIIParametersRelationTypeUnequalTo:
            string = [NSString stringWithFormat:@"%@ != %@", column, value];
            break;
        case YIIParametersRelationTypeGreaterThan:
            string = [NSString stringWithFormat:@"%@ > %@", column, value];
            break;
        case YIIParametersRelationTypeGreaterThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ >= %@", column, value];
            break;
        case YIIParametersRelationTypeLessThan:
            string = [NSString stringWithFormat:@"%@ < %@", column, value];
            break;
        case YIIParametersRelationTypeLessThanOrEqualTo:
            string = [NSString stringWithFormat:@"%@ <= %@", column, value];
            break;
        default:
            break;
    }
    if (string) {
        [self.orParameters addObject:string];
    }
}

- (void)orderByColumn:(NSString *)column orderType:(YIIParametersOrderType)orderType {
    if (orderType == YIIParametersOrderTypeAsc) {
        self.orderString = [NSString stringWithFormat:@"order by %@ asc", column];
    } else if (orderType == YIIParametersOrderTypeDesc) {
        self.orderString = [NSString stringWithFormat:@"order by %@ desc", column];
    }
}

@end
