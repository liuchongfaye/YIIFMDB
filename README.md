# YIIFMDB 介绍
基于FMDB的进一步封装：纯面向对象(其思想源自php的[yii 2架构](https://www.yiichina.com/doc/guide/2.0))，实现了model与数据库的一一映射，并且在大多数情况下，对数据库的操作比如增删改查等操作，完全不需要写sql语句。  

blog:https://www.jianshu.com/p/482ef2ad3e66

NSUserDefaultsModel:https://github.com/liuchongfaye/NSUserDefaultsModel (NSUserDefaults改进方案)

其中主要有两个类：YIIParameters和YIIFMDB，具体用法如下：

## YIIParameters 用法

**YIIParameters类**  
YIIParameters是对sql语句当中**where**之后的参数进行封装的类，其中涉及到的操作有**and**,**or**,**limit**,**order by**，分别代表着**与**,**或**,**限制**,**排序**，具体用法如下:  

**and(与操作)**  
> -(void)andWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(YIIParametersRelationType)relationType  

在sql语句的where后面增加一个and操作，比如筛选出年龄(age)在10-20之间的参数，代码如下：  
```
  // 配置age在大于10且小于20的参数
  YIIParameters *parameters = [[YIIParameters alloc] init];
  [parameters andWhere:@"age" value:@"10" relationType:YIIParametersRelationTypeGreaterThan];
  [parameters andWhere:@"age" value:@"20" relationType:YIIParametersRelationTypeLessThan];
```
其中这个**YIIParametersRelationType**这个枚举决定方法当中的key和value之间的关系，包括=,!=,>,>=,<,<=,这些都有其对应的枚举值，但是这些只适用于字段属性是**integer**时有用。除了以上这些还有一个**like**,用于字符串运算，比如筛选名称(name)跟"lc"相类似的可以设置为：
```
[parameters andWhere:@"name" value:@"lc" relationType:YIIParametersRelationTypeLike];
```

**or(或操作)**
> -(void)orWhere:(NSString * _Nonnull)column value:(id _Nonnull)value relationType:(YIIParametersRelationType)relationType

在sql语句的where后面增加一个or操作,比如执行以上and操作之后，在加上一个或者年龄(age)大于30之间的参数,代码如下:
```
  // 配置age在大于30的参数
  [parameters andWhere:@"age" value:@"30" relationType:YIIParametersRelationTypeGreaterThan];
```
**Warning**:值得一提的是，倘或where之后只有一个条件，那么**and**和**or**是一样的。比如只是仅仅只是帅选出年龄(age)大于30之间的参数。  

**limit(数量限制)**  
> @property (nonatomic, assign) NSInteger limitCount;
在sql语句的where后面增加筛选数据的数量限制，比如将数量限制在10，那么代码如下:
```
parameters.limitCount = 10;
```

**order by(排序)**
> -(void)orderByColumn:(NSString * _Nonnull)column orderType:(YIIParametersOrderType)orderType

在sql语句的where后面增加一个排序限制，比如根据年龄(age)进行升序，代码如下:
```
[parameters orderByColumn:@"age" orderType:YIIParametersOrderTypeAsc];
```
这里涉及到一个枚举**YIIParametersOrderType**，其中**YIIParametersOrderTypeAsc为升序，YIIParametersOrderTypeDesc为降序**.  

根据**and**,**or**,**limit**,**order by**这四个操作可以实现比较复杂的语句，比如：请筛选出年龄age在10到20之间，或者age>30，并且根据年纪选出最大的10人，代码如下：  
```
  YIIParameters *parameters = [[YIIParameters alloc] init];
  // 配置age在大于10且小于20的参数，两个and操作
  [parameters andWhere:@"age" value:@"10" relationType:YIIParametersRelationTypeGreaterThan];
  [parameters andWhere:@"age" value:@"20" relationType:YIIParametersRelationTypeLessThan];
  // 配置age在大于30的参数，or操作
  [parameteror orWhere:@"age" value:@"30" relationType:YIIParametersRelationTypeGreaterThan];
  // 数量限制在10个
  parameters.limitCount = 10;
  // 根据年龄进行降序
  [parameters orderByColumn:@"age" orderType:YIIParametersOrderTypeDesc];
```

**最终形成的where参数**
> @property (nonatomic, copy)   NSString *whereParameters;

最终形成的where之后的参数可以从**YIIParameters**这个类的**whereParameters**属性获得。  
如果都不能满足,那么自己设置这个参数。  

这里YIIParameters介绍完了，以下是YIIFMDB类的使用：

### YIIFMDB 类
以上的YIIParameters介绍了sql语句当中where之后参数的设置，而YIIFMDB类则是对数据库操作的封装，比如增删改查等，具体用法如下：  

**获取单例**
```
YIIFMDB *db = [YIIFMDB shareDatabase]; // 推荐使用
// 或者
YIIFMDB *db = [YIIFMDB shareDatabaseForName:@"ABC.sqlite" path:path]; // 自定义数据库名字和路径，在第一次实例的时候传入，以后使用上面方法即可。
```

**主键的字段**  
> @property (nonatomic, readonly, copy)   NSString *primaryKey; // 返回"yii_pkID",我自己在创建数据库是配置的主键字段

**是否打印log**
> @property (nonatomic, assign) BOOL shouldOpenDebugLog;  // 默认为NO，如果设为YES，那么会在控制器后台打印数据库操作相关的一些信息

**创建一张表**
```
[[YIIFMDB shareDatabase] createTableWithModelClass:[LCVideoModel class] excludedProperties:nil tableName:@"Video"];
```
此方法是创建一张名为@"Video"表，并且，表里面的字段也就是LCVideoModel里面的属性，字段的数据类型也对应LCVideoModel里面的数据类型

**插入一条数据(增)**
```
  LCVideoModel *model = [[LCVideoModel alloc] init];
  model.name = [NSString stringWithFormat:@"lc%d", (arc4random() % 100)];
  model.gender = arc4random() % 2;
  model.age = arc4random() % 80;
  model.floatNumber = (arc4random() % 20) / 100.0;
  model.doubleNumber = (arc4random() % 20) / 100.0;
  model.isMan = arc4random() % 2;
  model.number = @(arc4random() % 10);
            
  YIIFMDB *db = [YIIFMDB shareDatabase];
  BOOL isSuccess = [db insertWithModel:model tableName:tableName];  //插入一条数据
  [db insertWithModels:@[model] tableName:tableName];     // 批量插入数据
```
  
**删除数据(删)**  
> -(BOOL)deleteFromTable:(NSString * _Nonnull)tableName whereParameters:(YIIParameters *)parameters; // 根据参数删除一条数据,YIIParameters参考上面  
  -(BOOL)deleteAllDataFromTable:(NSString * _Nonnull)tableName; //  删除表中的所有数据
  
 ```
  YIIFMDB *db = [YIIFMDB shareDatabase];
  YIIParameters *parameters = [[YIIParameters alloc] init];
  // db.primaryKey 是数据库的主键,这条语句意思是删除主键 = 1的那条数据
  [parameters andWhere:db.primaryKey value:@"1" relationType:YIIParametersRelationTypeEqualTo];
  [db deleteFromTable:tableName whereParameters:parameters];
 ```
  
**更改数据(改)**
> -(BOOL)updateTable:(NSString * _Nonnull)tableName dictionary:(NSDictionary * _Nonnull)dictionary whereParameters:(YIIParameters *)parameters; // 更新一条数据

```
  YIIFMDB *db = [YIIFMDB shareDatabase];
  YIIParameters *parameters = [[YIIParameters alloc] init];
  // 参数设置为主键 = 10
  [parameters andWhere:db.primaryKey value:@"10" relationType:YIIParametersRelationTypeEqualTo];
  // 将主键为10的那条数据的name更改为monkey
  [db updateTable:tableName dictionary:@{@"name": @"monkey"} whereParameters:parameters];
```

**查询数据**
> -(NSArray *)queryFromTable:(NSString * _Nonnull)tableName model:(Class _Nonnull)modelClass whereParameters:(YIIParameters *)parameters; // 根据YIIParameters条件从表为tableName的查询数据

```
  YIIFMDB *db = [YIIFMDB shareDatabase];
  YIIParameters *parameters = [[YIIParameters alloc] init];
  [parameters andWhere:db.primaryKey value:@"5" relationType:YIIParametersRelationTypeLessThan];
  NSLog(@"主键值小于5的所有数据:%@", [db queryFromTable:tableName model:[LCVideoModel class] whereParameters:parameters]);
```
**表是否存在**
> -(BOOL)existTable:(NSString * _Nonnull)tableName; // tableName为表的名字

**为表增加一个属性**
> -(BOOL)alterTable:(NSString * _Nonnull)tableName column:(NSString * _Nonnull)column type:(YIIFMDBValueType)type;

其中YIIFMDBValueType为表支持的类型，包含**字符串(YIIFMDBValueTypeString)**,**整型(YIIFMDBValueTypeInteger)**,**浮点型(YIIFMDBValueTypeFloat)**,**二进制(YIIFMDBValueTypeData)**。

**删除一张表(不推荐使用)**
> -(BOOL)dropTable:(NSString * _Nonnull)tableName;

**获取表中所有字段名**
> -(NSArray<NSString *> *)getAllColumnsFromTable:(NSString * _Nonnull)tableName;

**表中的数据个数**
> -(long long int)numberOfItemsFromTable:(NSString * _Nonnull)tableName whereParameters:(YIIParameters * _Nullable)parameters; // parameters表示筛选参数,参考上面的**YIIParameters**

**数学相关操作**
> -(double)numberWithMathType:(YIIFMDBMathType)type table:(NSString * _Nonnull)tableName column:(NSString * _Nonnull)column whereParameters:(YIIParameters * _Nullable)parameters; // 对表中的某一个字段进行数学相关运算，比如求和，平均值，最大值，最小值

其中YIIFMDBMathType是一个枚举，分别对应着**求和(YIIFMDBMathTypeSum)**,**平均值(YIIFMDBMathTypeAvg)**,**最大值(YIIFMDBMathTypeMax)**,**最小值(YIIFMDBMathTypeMin)**.

**线程安全操作(队列和事务)**  

由于FMDB本身就是是不安全的，上面的方法也是不安全的，为了保证其安全则需要结合队列和事务操作，参考FMDB的队列和事务。
> -(void)inDatabase:(dispatch_block_t)block;  // 将数据库相关操作写在block里可保证线程安全

```
  YIIFMDB *db = [YIIFMDB shareDatabase];
   [db inDatabase:^{
       // 增删改查放在此代码块里执行则可以保证线程安全
   }];
```

> -(void)inTransaction:(void(^)(BOOL *rollback))block; // 在block里写入代码可执行回滚操作
```
  YIIFMDB *db = [YIIFMDB shareDatabase];
  [db inTransaction:^(BOOL *rollback) {
  // 如果某一个操作失误，则可以执行回滚操作
  BOOL isSuccess = YES;   // 数据库操作是否操作成功
  if (!isSuccess) {
      *rollback = YES;  //  回滚操作
                    
      return ;
     }
  }];
```

#### 安装

cocoapods安装:在podfile里写入：  

> pod 'YIIFMDB'

然后在执行pod install，等待安装完毕，在需要使用的类当中导入当前库，比如```@import YIIFMDB;```。  

如果未使用cocoapods，那么就下载此工程，将包含YIIFMDB类和YIIParameters类的文件夹导入到工程当中,随后在使用的类当中导入引入YIIFMDB.h的头文件即刻，比如```#import "YIIFMDB.h"```。  

