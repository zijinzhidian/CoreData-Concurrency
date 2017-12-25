//
//  ViewController.m
//  CoreData-Concurrency
//
//  Created by apple on 2017/12/21.
//  Copyright © 2017年 zjbojin. All rights reserved.
//

#import "ViewController.h"
#import "Students+CoreDataClass.h"
#import "MyClass+CoreDataClass.h"
#import <CoreData/CoreData.h>

@interface ViewController ()

@property(nonatomic,strong)NSPersistentStoreCoordinator *storeCoordinator;   //全局共享的存储调度器
@property(nonatomic,strong)NSManagedObjectContext *mainContext;         //全局的MOC,负责与UI进行协作
@property(nonatomic,strong)NSManagedObjectContext *privateContext;       //私有的MOC,负责后台处理耗时的操作

@end

@implementation ViewController

#pragma mark - Life Cycle
- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"%@",NSHomeDirectory());
    
}

#pragma mark - Private Actions
/**
 获取班级(根据班级的唯一ID查询,若有则返回,若无则创建并返回)

 */
- (MyClass *)getClassEntity {
    
    NSManagedObjectContext *context = self.privateContext;
    
    //创建查询请求
    NSFetchRequest *selectRequst = [[NSFetchRequest alloc] initWithEntityName:@"MyClass"];
    //查询条件
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"classroomID = %@",@"四年级一班"];
    selectRequst.predicate = predicate;
    //获取查询数据
    NSArray *resultArray = [context executeFetchRequest:selectRequst error:nil];
    //判断'四年级一班'是否存在
    if (resultArray.count > 0) {
        
        return [resultArray firstObject];
        
    } else {
        
        MyClass *class = [NSEntityDescription insertNewObjectForEntityForName:@"MyClass" inManagedObjectContext:context];
        class.classroomID = @"四年级一班";
    
        //保存,提交改变
        NSError *errorSave = nil;
        if ([context hasChanges] && ![context save:&errorSave]) {
            NSLog(@"添加失败:%@",errorSave);
        }
        return class;
        
    }
}

#pragma mark - Public Actions
- (IBAction)insert:(id)sender {
    
    NSManagedObjectContext *context = self.privateContext;
    NSString *name = self.inputName.text;
    NSString *sex = self.inputSex.text;
    NSInteger number = [self.inputNumber.text integerValue];
    NSInteger age = [self.inputAge.text integerValue];
    
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        
        //设置通知,通知主线程合并
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(merger:) name:NSManagedObjectContextDidSaveNotification object:context];
        
        //创建MO,并使用MOC进行监听
        Students *student = [NSEntityDescription insertNewObjectForEntityForName:@"Students" inManagedObjectContext:context];
        student.name = name;
        student.age = age;
        student.number = number;
        student.sex = sex;
        
        //建立和班级的联系,将学生添加到班级中
        [[weakSelf getClassEntity] addIncludeStudentsObject:student];
        
        //保存,提交改变
        NSError *errorSave = nil;
        if ([context hasChanges] && ![context save:&errorSave]) {
            NSLog(@"添加失败:%@",errorSave);
        }
        
    }];
    
#warning 测试
//    self.inputAge.text = [NSString stringWithFormat:@"%d",arc4random_uniform(100)];
//
//    //让更新的操作沉睡3秒
//    [self update:nil];
//
//    NSLog(@"这里检测是否会阻塞主线程");
//
//    [self select:nil];
/*----让更新的操作沉睡三秒-----*/
    //没有阻塞主线程,但是阻塞了查询操作
    //阻塞查询操作的原因--->performBlock:该方法只会新开一个新线程,即使调用多次performBlock。也就是所有调用了performBlock方法的函数,都会在同一个新开的线程里面同步执行。
    
}

- (IBAction)delete:(id)sender {
    
    NSManagedObjectContext *context = self.privateContext;
    NSInteger number = [self.inputNumber.text integerValue];
    
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        
        //设置通知,通知主线程合并
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(merger:) name:NSManagedObjectContextDidSaveNotification object:context];
        
        //创建删除请求
        NSFetchRequest *deleteRequest = [[NSFetchRequest alloc] initWithEntityName:@"Students"];
        //条件
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number = %d", number];
        deleteRequest.predicate = predicate;
        //查询返回需要删除的对象数据
        NSError *error = nil;
        NSArray *deleteArray = [context executeFetchRequest:deleteRequest error:&error];
        if (!error) {
            //标记删除,让MOC进行删除操作
            for (Students *stu in deleteArray) {
                [context deleteObject:stu];
            }
        } else {
            NSLog(@"删除失败:%@",error);
        }
        //保存,提交改变
        NSError *errorSave = nil;
        if ([context hasChanges] && ![context save:&errorSave]) {
            NSLog(@"保存失败:%@",errorSave);
        }
        
    }];
    
}

- (IBAction)update:(id)sender {
    
    NSManagedObjectContext *context = self.privateContext;
    NSString *name = self.inputName.text;
    NSString *sex = self.inputSex.text;
    NSInteger number = [self.inputNumber.text integerValue];
    NSInteger age = [self.inputAge.text integerValue];
    
    __weak typeof(self) weakSelf = self;
    [context performBlock:^{
        
        //创建更新请求
        NSFetchRequest *updateRequest = [[NSFetchRequest alloc] initWithEntityName:@"Students"];
        //设置通知,通知主线程合并
        [[NSNotificationCenter defaultCenter] addObserver:weakSelf selector:@selector(merger:) name:NSManagedObjectContextDidSaveNotification object:context];
        //条件
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number = %d",number];
        updateRequest.predicate = predicate;
        //查询数据
        NSError *error = nil;
        NSArray *resultArray = [context executeFetchRequest:updateRequest error:&error];
        if (!error) {
            for (Students *stu in resultArray) {
                if (name.length > 0) {
                    stu.name = name;
                }
                if (age > 0) {
                    stu.age = age;
                }
                if (sex.length > 0) {
                    stu.sex = sex;
                }
            }
        } else {
            NSLog(@"修改失败:%@",error);
        }
        //保存,提交改变
        NSError *errorSave = nil;
        if ([context hasChanges] && ![context save:&errorSave]) {
            NSLog(@"保存失败:%@",errorSave);
        }
        
    }];
    
}

- (IBAction)select:(id)sender {
    
    NSManagedObjectContext *context = self.privateContext;

    [context performBlock:^{

        //创建查询请求
        NSFetchRequest *selectRequst = [[NSFetchRequest alloc] initWithEntityName:@"Students"];
        //获取查询数据
        NSError *error = nil;
        NSArray *resultArray = [context executeFetchRequest:selectRequst error:&error];

        //打印
        if (!error) {
            for (Students *stu in resultArray) {
                NSLog(@"%d---%@---%d岁---%@",stu.number,stu.name,stu.age,stu.sex);
                NSLog(@"所属班级:%@",stu.belongToClass.classroomID);
            }
        } else {
            NSLog(@"查询失败:%@",error);
        }

    }];
    
}


/**
 查询班级下的所有学生

 */
- (IBAction)selectClass:(id)sender {
    
    NSManagedObjectContext *context = self.privateContext;
    
    [context performBlock:^{
        
        NSFetchRequest *selectRequest = [[NSFetchRequest alloc] initWithEntityName:@"MyClass"];
        NSError *error = nil;
        NSArray *resultArray = [context executeFetchRequest:selectRequest error:&error];
        if (!error) {
            for (MyClass *class in resultArray) {
                for (Students *stu in class.includeStudents) {
                    NSLog(@"%@",stu.name);
                }
            }
        } else {
            NSLog(@"查询班级失败:%@",error);
        }
        
    }];
    
}


/**
 批量更新(iOS8.0+)

 */
- (IBAction)batchUpdate:(id)sender {
    
    //创建批量更新请求
    NSBatchUpdateRequest *batchUpdateRequest = [[NSBatchUpdateRequest alloc] initWithEntityName:@"Students"];
    //条件(学号大于10)
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"number > 10"];
    batchUpdateRequest.predicate = predicate;
    //更改字段(字典的key为需要更新的字段名,value为更新的新值)
    batchUpdateRequest.propertiesToUpdate = @{@"age":@20};
    //指定的返回类型
    //NSStatusOnlyResultType:返回BOOL类型,表示更新是否执行成功
    //NSUpdatedObjectIDsResultType:返回更新成功的对象的ID,NSArray类型
    //NSUpdatedObjectsCountResultType:
    batchUpdateRequest.resultType = NSUpdatedObjectIDsResultType;
    //更新
    NSError *error = nil;
    NSBatchUpdateResult *result = [self.privateContext executeRequest:batchUpdateRequest error:&error];
    if (!error) {
        NSLog(@"%@",result);
    } else {
        NSLog(@"批量更新失败:%@",error);
    }
    //更新MOC中的托管对象，使MOC和本地持久化区数据同步,否则context不知道数据库的变化,查询到的还是旧数据(两种方法)
//    [self.privateContext refreshAllObjects];
    
//    获取更新的对象ID
    NSArray *updateObjectIDs = result.result;
    //设置字典
    NSDictionary *updateDic = @{NSUpdatedObjectsKey:updateObjectIDs};
    //通知context更新
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:updateDic intoContexts:@[self.privateContext,self.mainContext]];
    
}


/**
 批量删除(iOS9.0+)

 */
- (IBAction)batchDelete:(id)sender {
    
    NSFetchRequest *deleteRequest = [[NSFetchRequest alloc] initWithEntityName:@"Students"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age > 20"];
    deleteRequest.predicate = predicate;
    
    //批量删除请求
    NSBatchDeleteRequest *batchDeleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:deleteRequest];
    
    batchDeleteRequest.resultType = NSUpdatedObjectIDsResultType;
    NSError *error = nil;
    NSBatchDeleteResult *result = [self.privateContext executeRequest:batchDeleteRequest error:&error];
    if (!error) {
        NSLog(@"%@",result);
    } else {
        NSLog(@"批量删除失败:%@",error);
    }
    
    //更新MOC中的托管对象，使MOC和本地持久化区数据同步(两种方法)
    //    [self.privateContext refreshAllObjects];
    
    //获取删除的对象的ID
    NSArray *deletedObjectIDs = result.result;
    //设置字典
    NSDictionary *deletedDic = @{NSDeletedObjectsKey:deletedObjectIDs};
    //通知context删除
    [NSManagedObjectContext mergeChangesFromRemoteContextSave:deletedDic intoContexts:@[self.privateContext,self.mainContext]];
    
}

#pragma mark - Notification Action
- (void)merger:(NSNotification *)notification {
    
    id object = notification.object;
    //私有context保存后通知主context合并
    if (![object isEqual:self.mainContext]) {
        [self.mainContext mergeChangesFromContextDidSaveNotification:notification];
    }
    
}

#pragma mark - Getters And setters
- (NSPersistentStoreCoordinator *)storeCoordinator {
    if (_storeCoordinator == nil) {
        
        //获取模型文件路径(文件名.momd)
        NSURL *URL = [[NSBundle mainBundle] URLForResource:@"Schoole.momd" withExtension:nil];
        //根据模型文件创建模型对象
        NSManagedObjectModel *objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:URL];
        //创建存储调度器
        _storeCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:objectModel];
        //定义数据库的名称和路径,有则打开,无则创建(.db或.sqlite)
        NSURL *databaseURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/CoreData.sqlite",NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0]]];
        //打开或者创建数据库文件(NSSQLiteStoreType:一般采用SQLite数据库类型)
        NSError *error = nil;
        [_storeCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:databaseURL options:nil error:&error];
        
    }
    return _storeCoordinator;
}

- (NSManagedObjectContext *)mainContext {
    if (_mainContext == nil) {
        
        //主线程的MOC
        _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        //建立联系
        _mainContext.persistentStoreCoordinator = self.storeCoordinator;
        
    }
    return _mainContext;
}

- (NSManagedObjectContext *)privateContext {
    if (_privateContext == nil) {
        
        //后台线程的MOC
        _privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        //建立联系
        _privateContext.persistentStoreCoordinator = self.storeCoordinator;
        
    }
    return _privateContext;
}

@end
