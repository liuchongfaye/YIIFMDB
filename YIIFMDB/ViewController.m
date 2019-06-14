//
//  ViewController.m
//  YIIFMDB_Demo
//
//  Created by 刘冲 on 2018/10/29.
//  Copyright © 2018年 lc. All rights reserved.
//

#import "ViewController.h"
#import "LCVideoModel.h"
#import "YIIFMDB.h"

@interface ViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<NSArray<NSString *> *> *objects;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"YIIFMDB使用,以LCVideoModel为例";
    
    // 初始化数据源
    self.objects = @[ @[@"sql语句where配置:and(&&,与)",
                        @"sql语句where配置:or(||,或)",
                        @"sql语句where配置:count(数量)",
                        @"sql语句where配置:order(排序)",
                        @"sql语句where配置:综合运用",
                        ],
                      @[@"基于LCVideoModel创建一张表",
                        @"基于LCVideoModel插入一条数据",
                        @"基于LCVideoModel批量插入100条数据",
                        @"删除一条数据(YIIParameters配置参数)",
                        @"基于LCVideoModel更改一条数据",
                        @"查询数据(YIIParameters配置参数)",
                        @"表是否存在",
                        @"为数据库增加一个字段",
                        @"获取表中所有字段",
                        @"获取表中符合条件的个数(YIIParameters配置参数)"],
                      @[@"某一个字段的总和(sum,以主键为例)",
                        @"某一个字段的平均值(avg,以主键为例)",
                        @"某一个字段的最大值(max,以主键为例)",
                        @"某一个字段的最小值(min,以主键为例)"],
                      @[@"队列",
                        @"事务"],
                      ];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
    if (@available(iOS 11.0, *)) {
        tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentAutomatic;
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UITableView 代理

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return @"sql语句where之后的参数配置";
    }
    
    if (section == 1) {
        return @"数据库相关操作(包括增删改查)";
    }
    
    if (section == 2) {
        return @"数据库数学运算";
    }
    
    if (section == 3) {
        return @"线程安全操作(队列与事务)";
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.objects.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.objects[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellID = @"ID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    cell.textLabel.text = self.objects[indexPath.section][indexPath.row];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            // 配置yii_pkID在大于10且小于20的参数
            YIIParameters *parameters = [[YIIParameters alloc] init];
            [parameters andWhere:@"yii_pkID" value:@"10" relationType:YIIParametersRelationTypeGreaterThan];
            [parameters andWhere:@"yii_pkID" value:@"20" relationType:YIIParametersRelationTypeLessThan];
            NSLog(@"where参数为:%@", parameters.whereParameters);
        }
        
        if (indexPath.row == 1) {
            // 配置yii_pkID在小于10或者大于20的参数
            YIIParameters *parameters = [[YIIParameters alloc] init];
            [parameters orWhere:@"yii_pkID" value:@"10" relationType:YIIParametersRelationTypeLessThan];
            [parameters orWhere:@"yii_pkID" value:@"20" relationType:YIIParametersRelationTypeGreaterThan];
            NSLog(@"where参数为:%@", parameters.whereParameters);
        }
        
        if (indexPath.row == 2) {
            // 配置选取数据的数量为10
            YIIParameters *parameters = [[YIIParameters alloc] init];
            parameters.limitCount = 10;
            NSLog(@"where参数为:%@", parameters.whereParameters);
        }
        
        if (indexPath.row == 3) {
            // 根据某一个字段进行排序(升序为YIIParametersOrderTypeAsc,降序为YIIParametersOrderTypeDesc)
            YIIParameters *parameters = [[YIIParameters alloc] init];
            [parameters orderByColumn:@"yii_pkID" orderType:YIIParametersOrderTypeAsc];
            NSLog(@"where参数为:%@", parameters.whereParameters);
        }
        
        if (indexPath.row == 4) {
            // 参数设置：获取yii_pkID在10到50之间的数据，或者yii_pkID大于100，并且yii_pkID进行降序排列，还要将数量限制在20个
            YIIParameters *parameters = [[YIIParameters alloc] init];
            // yii_pkID在10-50配置(and操作)
            [parameters andWhere:@"yii_pkID" value:@"10" relationType:YIIParametersRelationTypeGreaterThan];
            [parameters andWhere:@"yii_pkID" value:@"50" relationType:YIIParametersRelationTypeLessThan];
            // yii_pkID大于100(or操作)
            [parameters orWhere:@"yii_pkID" value:@"100" relationType:YIIParametersRelationTypeGreaterThan];
            // yii_pkID降序排列
            [parameters orderByColumn:@"yii_pkID" orderType:YIIParametersOrderTypeDesc];
            // 数量限制在20个
            parameters.limitCount = 20;
            
            NSLog(@"where参数为:%@", parameters.whereParameters);
        }
    }
    
    if (indexPath.section == 1) {
        NSString *tableName = @"video";
        if (indexPath.row == 0) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            BOOL isSuccess = [db createTableWithModelClass:[LCVideoModel class] excludedProperties:nil tableName:tableName];
            if (isSuccess) {
                NSLog(@"创建一张表成功");
            } else {
                NSLog(@"创建一张表失败");
            }
        }
        
        if (indexPath.row == 1) {
            LCVideoModel *model = [[LCVideoModel alloc] init];
            model.name = [NSString stringWithFormat:@"lc%d", arc4random() % 100];
            model.gender = arc4random() % 2;
            model.age = arc4random() % 80;
            model.floatNumber = (arc4random() % 20) / 100.0;
            model.doubleNumber = (arc4random() % 20) / 100.0;
            model.isMan = arc4random() % 2;
            model.number = @(arc4random() % 10);
            
            YIIFMDB *db = [YIIFMDB shareDatabase];
            BOOL isSuccess = [db insertWithModel:model tableName:tableName];
            if (isSuccess) {
                NSLog(@"插入一条数据成功");
            } else {
                NSLog(@"插入一条数据失败");
            }
        }
        
        if (indexPath.row == 2) {
            NSMutableArray *array = [NSMutableArray array];
            for (int index = 0; index < 100; index++) {
                LCVideoModel *model = [[LCVideoModel alloc] init];
                model.name = [NSString stringWithFormat:@"lc%d", (arc4random() % 100)];
                model.gender = arc4random() % 2;
                model.age = arc4random() % 80;
                model.floatNumber = (arc4random() % 20) / 100.0;
                model.doubleNumber = (arc4random() % 20) / 100.0;
                model.isMan = arc4random() % 2;
                model.number = @(arc4random() % 10);
                [array addObject:model];
            }
            
            YIIFMDB *db = [YIIFMDB shareDatabase];
            [db insertWithModels:array tableName:tableName];
        }
        
        if (indexPath.row == 3) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            YIIParameters *parameters = [[YIIParameters alloc] init];
            parameters.whereParameters = @"name = 'lc17'";
            // db.primaryKey 是数据库的主键,这条语句意思是删除主键 = 1的那条数据
            //            [parameters andWhere:db.primaryKey value:@"1" relationType:YIIParametersRelationTypeEqualTo];
            BOOL isSuccess = [db deleteFromTable:tableName whereParameters:parameters];
            if (isSuccess) {
                NSLog(@"删除数据成功");
            } else {
                NSLog(@"删除数据失败");
            }
        }
        
        if (indexPath.row == 4) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            YIIParameters *parameters = [[YIIParameters alloc] init];
            [parameters andWhere:db.primaryKey value:@"10" relationType:YIIParametersRelationTypeEqualTo];
            
            
            BOOL isSuccess = [db updateTable:tableName dictionary:@{@"name": @"monkey"} whereParameters:parameters];
            if (isSuccess) {
                NSLog(@"更新数据成功");
            } else {
                NSLog(@"更新数据失败");
            }
        }
        
        if (indexPath.row == 5) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            YIIParameters *parameters = [[YIIParameters alloc] init];
            [parameters andWhere:db.primaryKey value:@"5" relationType:YIIParametersRelationTypeLessThan];
            
            NSLog(@"主键值小于5的所有数据:%@", [db queryFromTable:tableName model:[LCVideoModel class] whereParameters:parameters]);
        }
        
        if (indexPath.row == 6) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            BOOL isExist = [db existTable:tableName];
            if (isExist) {
                NSLog(@"表存在");
            } else {
                NSLog(@"表不存在");
            }
        }
        
        if (indexPath.row == 7) {
            // 为数据库增加一个字段:字段名为description,字符串类型，类型参考YIIFMDBValueType
            YIIFMDB *db = [YIIFMDB shareDatabase];
            BOOL isSuccess = [db alterTable:tableName column:@"description" type:YIIFMDBValueTypeString];
            if (isSuccess) {
                NSLog(@"增加一个字段成功");
            } else {
                NSLog(@"增加一个字段失败");
            }
        }
        
        if (indexPath.row == 8) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            NSLog(@"表中所有字段为：%@", [db getAllColumnsFromTable:tableName]);
        }
        
        if (indexPath.row == 9) {
            // 获取主键>10的数据个数
            YIIFMDB *db = [YIIFMDB shareDatabase];
            YIIParameters *parameters = [[YIIParameters alloc] init];
            [parameters andWhere:db.primaryKey value:@"10" relationType:YIIParametersRelationTypeGreaterThan];
            NSLog(@"获取主键>10的数据个数为：%lld", [db numberOfItemsFromTable:tableName whereParameters:parameters]);
        }
    }
    
    if (indexPath.section == 2) {
        NSString *tableName = @"video";
        if (indexPath.row == 0) {
            // 左右主键的值加起来的综合
            YIIFMDB *db = [YIIFMDB shareDatabase];
            NSLog(@"主键值的总和为:%f", [db numberWithMathType:YIIFMDBMathTypeSum table:tableName column:db.primaryKey whereParameters:nil]);
        }
        
        if (indexPath.row == 1) {
            // 左右主键的值的平均值
            YIIFMDB *db = [YIIFMDB shareDatabase];
            NSLog(@"主键值的平均值为:%f", [db numberWithMathType:YIIFMDBMathTypeAvg table:tableName column:db.primaryKey whereParameters:nil]);
        }
        
        if (indexPath.row == 2) {
            // 左右主键的最大值
            YIIFMDB *db = [YIIFMDB shareDatabase];
            NSLog(@"主键值的最大值为:%f", [db numberWithMathType:YIIFMDBMathTypeMax table:tableName column:db.primaryKey whereParameters:nil]);
        }
        
        if (indexPath.row == 3) {
            // 左右主键的最小值
            YIIFMDB *db = [YIIFMDB shareDatabase];
            NSLog(@"主键值的最小值为:%f", [db numberWithMathType:YIIFMDBMathTypeMin table:tableName column:db.primaryKey whereParameters:nil]);
        }
    }
    
    if (indexPath.section == 3) {
        if (indexPath.row == 0) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            [db inDatabase:^{
                // 增删改查放在此代码块里执行则可以保证线程安全
            }];
        }
        
        if (indexPath.row == 1) {
            YIIFMDB *db = [YIIFMDB shareDatabase];
            [db inTransaction:^(BOOL *rollback) {
                // 如果某一个操作失误，则可以执行回滚操作
                BOOL isSuccess = YES;   // 数据库操作是否操作成功
                if (!isSuccess) {
                    *rollback = YES;
                    
                    return ;
                }
            }];
        }
    }
}

@end
