//
//  ViewController.h
//  CoreData-Concurrency
//
//  Created by apple on 2017/12/21.
//  Copyright © 2017年 zjbojin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *inputName;
@property (weak, nonatomic) IBOutlet UITextField *inputNumber;
@property (weak, nonatomic) IBOutlet UITextField *inputSex;
@property (weak, nonatomic) IBOutlet UITextField *inputAge;

@end

