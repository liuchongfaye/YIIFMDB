//
//  YIIParameters.h
//  FMDataBaseManager
//
//  Created by 刘冲 on 2018/10/22.
//  Copyright © 2018年 lc. All rights reserved.
//

//  Github: https://github.com/liuchongfaye/YIIFMDB

#import <Foundation/Foundation.h>

// 参数相关的关系
typedef NS_ENUM(NSUInteger, YIIParametersRelationType) {
    YIIParametersRelationTypeEqualTo,               // 数学运算@"=",等于
    YIIParametersRelationTypeUnequalTo,             // 数学运算@"!=",不等于
    YIIParametersRelationTypeGreaterThan,           // 数学运算@">",大于
    YIIParametersRelationTypeGreaterThanOrEqualTo,  // 数学运算@">=",大于等于
    YIIParametersRelationTypeLessThan,              // 数学运算@"<",小于
    YIIParametersRelationTypeLessThanOrEqualTo,     // 数学运算@"<=",小于等于
    YIIParametersRelationTypeLike,                  // 字符串运算@"like",模糊查询
};

// 排序顺序
typedef NS_ENUM(NSUInteger, YIIParametersOrderType) {
    YIIParametersOrderTypeAsc,                      // 升序
    YIIParametersOrderTypeDesc,                     // 降序
};

@interface YIIParameters : NSObject

#pragma mark - sql语句当中为where之后的条件增加参数

/**
 *  筛选条件的数量限制
 */
@property (nonatomic, assign) NSInteger limitCount;

/**
 *  and(&&，与)操作
 *  @param column           数据库中表的key值
 *  @param value            column值对应的value值
 *  @param relationType     column与value之间的关系
 *  比如只执行[andWhere:@"age" value:18 relationType:YIIParametersRelationTypeGreaterThan],那么where后面的参数会变成"age > 18"
 */
- (void)andWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(YIIParametersRelationType)relationType;

/**
 *  or(||，或)操作
 *  @param column           数据库中表的key值
 *  @param value            column值对应的value值
 *  @param relationType     column与value之间的关系
 *  比如只执行[andWhere:@"age" value:18 relationType:YIIParametersRelationTypeGreaterThan],那么where后面的参数会变成"age > 18"
 */
- (void)orWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(YIIParametersRelationType)relationType;

/**
 *  设置排序结果
 *  @param column           排序的字段
 *  @param orderType        排序选择，有升序和降序
 *  比如执行[ orderByColumn:@"yii_pkID" orderType:YIIParametersOrderTypeAsc],那么对应的sql语句就是@"order by yii_pkID asc",意思就是根据"yii_plID"来进行升序排列
 */
- (void)orderByColumn:(NSString * _Nonnull)column orderType:(YIIParametersOrderType)orderType;

/**
 *  sql语句的参数，也就是sql语句当中，where之后的参数.
 *  值得一提的是，如果设置了这个参数，那么在属性whereParameters上面的方法都无效
 *  如果不设置这个参数，那么调用此属性的get方法则会获取到以上的方法所形成的sql语句
 */
@property (nonatomic, copy)   NSString *whereParameters;

@end
