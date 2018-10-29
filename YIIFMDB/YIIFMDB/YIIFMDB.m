//
//  YIIFMDB.m
//  FMDataBaseManager
//
//  Created by 刘冲 on 2018/10/22.
//  Copyright © 2018年 lc. All rights reserved.
//

#import "YIIFMDB.h"
#import "FMDB.h"
#import <objc/runtime.h>

@interface YIIFMDB ()

@property (nonatomic, copy)     NSString *databasePath;
@property (nonatomic, strong)   FMDatabaseQueue *databaseQueue;
@property (nonatomic, strong)   FMDatabase *database;

@end

@implementation YIIFMDB {
    // 保证创建sql语句时的线程安全
    dispatch_semaphore_t _sqlLock;
}

static NSString * const yii_primary_key  = @"yii_pkID";     // 主键
static NSString * const yii_sql_text    = @"text";          // 字符串
static NSString * const yii_sql_real    = @"real";          // 浮点型
static NSString * const yii_sql_blob    = @"blob";          // 二进制
static NSString * const yii_sql_integer = @"integer";       // 整型

#pragma mark - Override Methods

- (FMDatabaseQueue *)databaseQueue {
    if (!_databaseQueue) {
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:self.databasePath];
        // 关闭当前数据库
        [self.database close];
        // 将FMDatabaseQueue当中的数据库替换掉当前的数据库
        self.database = [_databaseQueue valueForKey:@"_db"];
    }
    
    return _databaseQueue;
}

#pragma mark - 创建单例

+ (instancetype)shareDatabase {
    return [self shareDatabaseForName:nil path:nil];
}

+ (instancetype)shareDatabaseForName:(NSString *)dataBaseName path:(NSString *)dataBasePath {
    static dispatch_once_t onceToken;
    static YIIFMDB *yiiFMDB = nil;
    dispatch_once(&onceToken, ^{
        yiiFMDB = [[YIIFMDB alloc] init];
        
        NSString *dbName = dataBaseName ? : @"YIIFMDB.sqlite";
        NSString *dbPath = nil;
        if (dataBasePath) {
            dbPath = [dataBasePath stringByAppendingPathComponent:dbName];
        } else {
            dbPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:dbName];
        }
        
        FMDatabase *dataBase = [FMDatabase databaseWithPath:dbPath];
        yiiFMDB.database = dataBase;
        yiiFMDB.databasePath = dbPath;
    });
    
    if (![yiiFMDB.database open]) {
        [yiiFMDB log:@"数据库未能打开"];
    }
    
    return yiiFMDB;
}

- (instancetype)init {
    if (self = [super init]) {
        _sqlLock = dispatch_semaphore_create(1);
    }
    
    return self;
}

#pragma mark - 数据库相关属性

- (FMDatabase *)currentDatabase {
    return self.database;
}

- (NSString *)currentDatabasePath {
    return self.databasePath;
}

- (NSString *)primaryKey {
    return yii_primary_key;
}

#pragma mark - 根据ModelClass去创建表

- (BOOL)createTableWithModelClass:(Class)modelClass excludedProperties:(NSArray<NSString *> *)excludedProperties tableName:(NSString *)tableName {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];

        return NO;
    }
    
    YIILock(_sqlLock);
    NSString *pkID = yii_primary_key;
    NSMutableString *sqliteString = [NSMutableString  stringWithFormat:@"create table if not exists %@ (%@ integer primary key", tableName, pkID];
    YIIUnlock(_sqlLock);
    
    // 基于runtime获取model的所有属性以及类型
    NSDictionary *properties = [self getPropertiesWithModel:modelClass];
    for (NSString *key in properties) {
        if ([excludedProperties containsObject:key]) {
            continue;
        }
        
        [sqliteString appendFormat:@", %@ %@", key, properties[key]];
    }
    [sqliteString appendString:@")"];
    
    BOOL isSuccess = [self.database executeUpdate:sqliteString];
    
    return isSuccess;
}

#pragma mark - 插入

- (BOOL)insertWithModel:(id)model tableName:(NSString *)tableName {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return NO;
    }
    
    if (model) {
        YIILock(_sqlLock);
        NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"insert into %@ (", tableName];
        NSArray *columns = [self getAllColumnsFromTable:tableName dataBase:self.database isIncludingPrimaryKey:NO];
        NSMutableArray *values = [NSMutableArray array];
        for (int index = 0; index < columns.count; index++) {
            [values addObject:@"?"];
        }
        [sqliteString appendFormat:@"%@) values (%@)", [columns componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
        YIIUnlock(_sqlLock);
        
        NSArray *arguments = [self getValuesFromModel:model columns:columns];
        BOOL isSuccess = [self.database executeUpdate:sqliteString withArgumentsInArray:arguments];
        
        if (!isSuccess) {
            [self log:[NSString stringWithFormat:@"插入数据失败，错误的model = %@", model]];
        }
        
        return isSuccess;
    } else {
        
        return NO;
    }
}

- (void)insertWithModels:(NSArray *)models tableName:(NSString *)tableName {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return;
    }
    
    if (models && [models isKindOfClass:[NSArray class]] && models.count > 0) {
        // 这里实际上可以与上面的方法混合使用，但是这个样子的话，初始化sqlite语句的时候就会出现多次运算，为了效率，这里与上面的方法进行了解耦
        YIILock(_sqlLock);
        NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"insert into %@ (", tableName];
        
        NSArray *columns = [self getAllColumnsFromTable:tableName dataBase:self.database isIncludingPrimaryKey:NO];
        NSMutableArray *values = [NSMutableArray array];
        for (int index = 0; index < columns.count; index++) {
            [values addObject:@"?"];
        }
        [sqliteString appendFormat:@"%@) values (%@)", [columns componentsJoinedByString:@","], [values componentsJoinedByString:@","]];
        YIIUnlock(_sqlLock);
        
        for (id model in models) {
            NSArray *arguments = [self getValuesFromModel:model columns:columns];
            
            BOOL isSuccess = [self.database executeUpdate:sqliteString withArgumentsInArray:arguments];
            if (!isSuccess) {
                [self log:[NSString stringWithFormat:@"插入数据失败，错误的model = %@", model]];
            }
        }
    } else {
        [self log:@"插入数据的数据源有误"];
    }
}

#pragma mark - 删除

- (BOOL)deleteFromTable:(NSString *)tableName whereParameters:(YIIParameters *)parameters {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return NO;
    }
    
    YIILock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"delete from %@", tableName];
    if (parameters && YIIIsStringValid(parameters.whereParameters)) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    YIIUnlock(_sqlLock);
    
    BOOL isSuccess = [self.database executeUpdate:sqliteString];
    
    return isSuccess;
}

- (BOOL)deleteAllDataFromTable:(NSString *)tableName {
    return [self deleteFromTable:tableName whereParameters:nil];
}

#pragma mark - 更改数据

- (BOOL)updateTable:(NSString *)tableName dictionary:(NSDictionary *)dictionary whereParameters:(YIIParameters *)parameters {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return NO;
    }
    
    if (dictionary.allKeys.count <= 0) {
        [self log:@"要更新的数据不能为nil"];
        return NO;
    }
    
    YIILock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"update %@ set ", tableName];
    NSMutableArray *values = [NSMutableArray array];
    for (NSString *key in dictionary) {
        if ([key isEqualToString:yii_primary_key]) {
            continue;
        }
        
        [sqliteString appendFormat:@"%@ = ? ", key];
        [values addObject:dictionary[key]];
    }
    YIIUnlock(_sqlLock);
    
    if (values.count > 0) {
        if (YIIIsStringValid(parameters.whereParameters)) {
            [sqliteString appendFormat:@"where %@", parameters.whereParameters];
        } else {
            [self log:@"sql语句当中,where后面的参数为nil"];
            [sqliteString deleteCharactersInRange:NSMakeRange(sqliteString.length-1, 1)];
        }
        
        return [self.database executeUpdate:sqliteString withArgumentsInArray:values];
    } else {
        [self log:@"要更新的数据不能仅仅含有主键"];
        
        return NO;
    }
}

#pragma mark - 查询数据

- (NSArray *)queryFromTable:(NSString *)tableName model:(Class)modelClass whereParameters:(YIIParameters *)parameters {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return nil;
    }
    
    YIILock(_sqlLock);
    NSMutableArray *array = [NSMutableArray array];
    
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"select * from %@", tableName];
    if (parameters && YIIIsStringValid(parameters.whereParameters)) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    YIIUnlock(_sqlLock);
    
    NSDictionary *properties = [self getPropertiesWithModel:modelClass];
    FMResultSet *resultSet = [self.database executeQuery:sqliteString];
    while ([resultSet next]) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        for (NSString *key in properties) {
            NSString *type = properties[key];
            // 根据数据类型从数据库当中获取数据
            if ([type isEqualToString:yii_sql_text]) {
                // 字符串
                dict[key] = [resultSet stringForColumn:key] ? : @"";
            } else if ([type isEqualToString:yii_sql_integer]) {
                // 整型
                dict[key] = @([resultSet longLongIntForColumn:key]);
            } else if ([type isEqualToString:yii_sql_real]) {
                // 浮点型
                dict[key] = @([resultSet doubleForColumn:key]);
            } else if ([type isEqualToString:yii_sql_blob]) {
                // 二进制
                id value = [resultSet dataForColumn:key];
                if (value) {
                    dict[key] = value;
                }
            }
        }
        
        [array addObject:dict];
    }
    
    return (array.count > 0 ? array : nil);
}

#pragma mark - 除去增删改查之外常用的功能

- (BOOL)openDatabase {
    return [self.database open];
}

- (BOOL)closeDatabase {
    return [self.database close];
}

- (BOOL)existTable:(NSString *)tableName {
    if (YIIIsStringValid(tableName)) {
        FMResultSet *resultSet = [self.database executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
        while ([resultSet next])
        {
            NSInteger count = [resultSet intForColumn:@"count"];
            return ((count == 0) ? NO : YES);
        }
        
        return NO;
    } else {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return NO;
    }
}

- (BOOL)alterTable:(NSString *)tableName column:(NSString *)column type:(YIIFMDBValueType)type {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return NO;
    }
    
    if (!YIIIsStringValid(column)) {
        [self log:@"要新增的column必须是字符串，且不能为nil"];
        
        return NO;
    }
    
    YIILock(_sqlLock);
    NSString *typeString = nil;
    switch (type) {
        case YIIFMDBValueTypeString:
            typeString = yii_sql_text;
            break;
        case YIIFMDBValueTypeInteger:
            typeString = yii_sql_integer;
            break;
        case YIIFMDBValueTypeFloat:
            typeString = yii_sql_real;
            break;
        case YIIFMDBValueTypeData:
            typeString = yii_sql_blob;
            break;
        default:
            typeString = @"";
            break;
    }
    NSString *sqliteString = [NSString stringWithFormat:@"alter table %@ add column %@ %@", tableName, column, typeString];
    YIIUnlock(_sqlLock);
    
    return [self.database executeUpdate:sqliteString];
}

- (BOOL)dropTable:(NSString *)tableName {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];

        return NO;
    }
    
    YIILock(_sqlLock);
    NSString *sqliteString = [NSString stringWithFormat:@"drop table %@", tableName];
    YIIUnlock(_sqlLock);
    
    return [self.database executeUpdate:sqliteString];
}

- (NSArray<NSString *> *)getAllColumnsFromTable:(NSString *)tableName {
    return [self getAllColumnsFromTable:tableName dataBase:self.database isIncludingPrimaryKey:YES];
}

- (long long int)numberOfItemsFromTable:(NSString *)tableName whereParameters:(YIIParameters * _Nullable)parameters {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
    }
    
    YIILock(_sqlLock);
    NSMutableString *sqliteString = [NSMutableString stringWithFormat:@"select count(*) as 'count' from %@", tableName];
    if (parameters && YIIIsStringValid(parameters.whereParameters)) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    YIIUnlock(_sqlLock);
    FMResultSet *resultSet = [self.database executeQuery:sqliteString];
    while ([resultSet next]) {
        return [resultSet longLongIntForColumn:@"count"];
    }
    
    return 0;
}

- (double)numberWithMathType:(YIIFMDBMathType)type table:(NSString *)tableName column:(NSString *)column whereParameters:(YIIParameters *)parameters {
    if (!YIIIsStringValid(tableName)) {
        [self log:@"tableName必须是字符串，且不能为nil"];
        
        return 0.0;
    }
    
    if (!YIIIsStringValid(column)) {
        [self log:@"要新增的column必须是字符串，且不能为nil"];
        
        return 0.0;
    }
    
    YIILock(_sqlLock);
    NSMutableString *sqliteString = nil;
    NSString *operation = nil;
    switch (type) {
        case YIIFMDBMathTypeSum:
            operation = @"sum";
            break;
        case YIIFMDBMathTypeAvg:
            operation = @"avg";
            break;
        case YIIFMDBMathTypeMax:
            operation = @"max";
            break;
        case YIIFMDBMathTypeMin:
            operation = @"min";
            break;
        default:
            break;
    }
    if (YIIIsStringValid(operation)) {
        sqliteString = [NSMutableString stringWithFormat:@"select %@(%@) %@Count from %@", operation, column, operation, tableName];
    } else {
        [self log:@"不支持当前运算"];
    }
    
    if (parameters && YIIIsStringValid(parameters.whereParameters)) {
        [sqliteString appendFormat:@" where %@", parameters.whereParameters];
    }
    YIIUnlock(_sqlLock);
    FMResultSet *resultSet = [self.database executeQuery:sqliteString];
    double value = 0.0;
    while ([resultSet next]) {
        value = [resultSet doubleForColumn:[NSString stringWithFormat:@"%@Count", operation]];
    }
    
    return value;
}

#pragma mark - 线程安全操作

- (void)inDatabase:(dispatch_block_t)block {
    [self.databaseQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (block) {
            block();
        }
    }];
}

- (void)inTransaction:(void (^)(BOOL *))block {
    [self.databaseQueue inTransaction:^(FMDatabase * _Nonnull db, BOOL * _Nonnull rollback) {
        if (block) {
            block(rollback);
        }
    }];
}

#pragma mark - 数据库相关操作

// 获取数据库里的所有元素
- (NSArray<NSString *> *)getAllColumnsFromTable:(NSString *)tableName dataBase:(FMDatabase *)dataBase isIncludingPrimaryKey:(BOOL)isIncluding {
    NSMutableArray *columns = [NSMutableArray array];
    
    FMResultSet *resultSet = [dataBase getTableSchema:tableName];
    while ([resultSet next]) {
        NSString *columnName = [resultSet stringForColumn:@"name"];
        if ([columnName isEqualToString:yii_primary_key] && !isIncluding) {
            continue;
        }
        [columns addObject:columnName];
    }
    
    return columns;
}

#pragma mark - Private Method

/**
 *  基于runtime获取model的所有属性以及类型
 *  根据传入的ModelClass去获取所有的属性的key以及类型type，返回值的字典的key就是modelClass的属性，value就是modelClass的属性对应的type
 */
- (NSDictionary *)getPropertiesWithModel:(Class)modelClass {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    unsigned int count;
    objc_property_t *propertyList = class_copyPropertyList(modelClass, &count);
    for (int index = 0; index < count; index++) {
        objc_property_t property = propertyList[index];
        NSString *key = [NSString stringWithFormat:@"%s", property_getName(property)];
        NSString *type = nil;
        NSString *attributes = [NSString stringWithFormat:@"%s", property_getAttributes(property)];
        
        if ([attributes hasPrefix:@"T@\"NSString\""]) {
            type = yii_sql_text;
        } else if ([attributes hasPrefix:@"Tf"] || [attributes hasPrefix:@"Td"]) {
            type = yii_sql_real;
        } else if ([attributes hasPrefix:@"T@\"NSData\""]) {
            type = yii_sql_blob;
        } else if ([attributes hasPrefix:@"Ti"] || [attributes hasPrefix:@"TI"] || [attributes hasPrefix:@"Tl"] || [attributes hasPrefix:@"TL"] || [attributes hasPrefix:@"Tq"] || [attributes hasPrefix:@"TQ"] || [attributes hasPrefix:@"Ts"] || [attributes hasPrefix:@"TS"] || [attributes hasPrefix:@"TB"] || [attributes hasPrefix:@"T@\"NSNumber\""]) {
            type = yii_sql_integer;
        }
        
        if (type) {
            [dict setObject:type forKey:key];
        } else {
            [self log:[NSString stringWithFormat:@"不支持的属性:key = %@, attributes = %@", key, attributes]];
        }
    }
    
    free(propertyList);
    
    return dict;
}

// 根据keys获取到model里面的所有values
- (NSArray *)getValuesFromModel:(id _Nonnull)model columns:(NSArray *)columns {
    NSMutableArray *array = [NSMutableArray array];
    for (NSString *column in columns) {
        id value = [model valueForKey:column];
        [array addObject:value ? : @""];
    }
    
    return array;
}

BOOL YIIIsStringValid(id object) {
    return [object isKindOfClass:[NSString class]] && ((NSString*)object).length > 0;
}

// 加锁
void YIILock(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

// 解锁
void YIIUnlock(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_signal(semaphore);
}

// 打印log
- (void)log:(NSString *)string {
    if (self.shouldOpenDebugLog) {
        NSLog(@"%@", string);
    }
}

@end
