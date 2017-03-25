//
//  CentralManager.h
//  CoreBluetoothDemo
//
//  Created by IDSBG-00 on 2017/3/24.
//  Copyright © 2017年 iRonCheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@interface CentralManager : NSObject


//系统蓝牙设备管理对象，可以把他理解为主设备，通过他，可以去扫描和链接外设
@property (nonatomic, strong) CBCentralManager *manager;

@property (nonatomic, strong) CBPeripheral *myPeripheral;

@property (nonatomic, strong) CBCharacteristic *character;

//用于保存被发现设备
//@property (nonatomic, strong) NSMutableArray *peripherals;

- (instancetype)init;

//写数据
- (void)writeCharacteristic:(CBPeripheral *)peripheral
             characteristic:(CBCharacteristic *)characteristic
                      value:(NSData *)value;
//设置通知
- (void)notifyCharacteristic:(CBPeripheral *)peripheral
              characteristic:(CBCharacteristic *)characteristic;

//取消通知
- (void)cancelNotifyCharacteristic:(CBPeripheral *)peripheral
                    characteristic:(CBCharacteristic *)characteristic;

//停止扫描并断开连接
- (void)disconnectPeripheral:(CBCentralManager *)centralManager
                  peripheral:(CBPeripheral *)peripheral;

@end
