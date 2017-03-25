//
//  peripheralManager.m
//  CoreBluetoothDemo
//
//  Created by IDSBG-00 on 2017/3/24.
//  Copyright © 2017年 iRonCheng. All rights reserved.
//

#import "peripheralManager.h"
#import <CoreBluetooth/CoreBluetooth.h>

#define notiyCharacteristicUUID @"12345678-1234-1234-1234-0050E4C11111"
#define readCharacteristicUUID @"12345678-1234-1234-1234-0050E4C22222"
#define readwriteCharacteristicUUID @"12345678-1234-1234-1234-0050E4C33333"

#define ServiceUUID1 @"11111111-1111-1111-1111-111111111111"
#define ServiceUUID2 @"22222222-2222-2222-2222-222222222222"

#define LocalNameKey @"LocalNameKey"

@interface peripheralManager () <CBPeripheralManagerDelegate>
{
    CBPeripheralManager *manager;
    NSInteger serviceNum;
    NSTimer *timer;
}

@end

@implementation peripheralManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        /*
         和CBCentralManager类似，蓝牙设备打开需要一定时间，打开成功后会进入委托方法
         - (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral;
         模拟器永远也不会得CBPeripheralManagerStatePoweredOn状态
         */
        manager = [[CBPeripheralManager alloc] initWithDelegate:self queue:nil];
    }
    return self;
}

//peripheralManager状态改变
- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral{
    switch (peripheral.state) {
            //在这里判断蓝牙设别的状态  当开启了则可调用  setUp方法(自定义)
        case CBManagerStatePoweredOn:
            NSLog(@"powered on");
            [self setUp];
            break;
        case CBManagerStatePoweredOff:
            NSLog(@"powered off");
            break;
            
        default:
            break;
    }
}

//配置bluetooch的
-(void)setUp{
    
    //characteristics字段描述
    CBUUID *CBUUIDCharacteristicUserDescriptionStringUUID = [CBUUID UUIDWithString:CBUUIDCharacteristicUserDescriptionString];
    
    /*
     可以通知的Characteristic
     properties：CBCharacteristicPropertyNotify
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *notiyCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:notiyCharacteristicUUID] properties:CBCharacteristicPropertyNotify value:nil permissions:CBAttributePermissionsReadable];
    
    /*
     只读的Characteristic
     properties：CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable
     */
    CBMutableCharacteristic *readCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readCharacteristicUUID] properties:CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable];
    
    /*
     可读写的characteristics
     properties：CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead
     permissions CBAttributePermissionsReadable | CBAttributePermissionsWriteable
     */
    CBMutableCharacteristic *readwriteCharacteristic = [[CBMutableCharacteristic alloc]initWithType:[CBUUID UUIDWithString:readwriteCharacteristicUUID] properties:CBCharacteristicPropertyWrite | CBCharacteristicPropertyRead value:nil permissions:CBAttributePermissionsReadable | CBAttributePermissionsWriteable];
    
    
    //设置description
    CBMutableDescriptor *readwriteCharacteristicDescription1 = [[CBMutableDescriptor alloc]initWithType: CBUUIDCharacteristicUserDescriptionStringUUID value:@"name"];
    
    // 在characteristic 中加入 descriptoers
    [readwriteCharacteristic setDescriptors:@[readwriteCharacteristicDescription1]];
    
    
    //service1初始化并加入两个characteristics
    CBMutableService *service1 = [[CBMutableService alloc] initWithType:[CBUUID UUIDWithString:ServiceUUID1] primary:YES];
    [service1 setCharacteristics:@[notiyCharacteristic,readwriteCharacteristic]];
    
    //service2初始化并加入一个characteristics
    CBMutableService *service2 = [[CBMutableService alloc]initWithType:[CBUUID UUIDWithString:ServiceUUID2] primary:YES];
    [service2 setCharacteristics:@[readCharacteristic]];
    
    /* 
     *  manager 加入两个service
     *
     *  添加后就会调用代理的- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error
     */
    [manager addService:service1];
    [manager addService:service2];
}

//perihpheral添加了service
- (void)peripheralManager:(CBPeripheralManager *)peripheral didAddService:(CBService *)service error:(NSError *)error{
    if (error == nil) {
        serviceNum++;
    }
    
    //因为我们添加了2个服务，所以想两次都添加完成后才去发送广播
    if (serviceNum==2) {
    
        //添加服务后可以在此向外界发出通告广播 调用完这个方法后会调用代理的
        //(void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error
        [manager startAdvertising:@{CBAdvertisementDataServiceUUIDsKey:@[[CBUUID UUIDWithString:ServiceUUID1],[CBUUID UUIDWithString:ServiceUUID2]],CBAdvertisementDataLocalNameKey : LocalNameKey}];
    }
}

//peripheral开始发送advertising广播
- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error{
    NSLog(@"in peripheralManagerDidStartAdvertisiong");
}


//(被central)订阅了characteristics
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didSubscribeToCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"订阅了 %@的数据",characteristic.UUID);
    //每秒执行一次给主设备发送一个当前时间的秒数
    timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(sendData:) userInfo:characteristic  repeats:YES];
}

//取消订阅characteristics
- (void)peripheralManager:(CBPeripheralManager *)peripheral central:(CBCentral *)central didUnsubscribeFromCharacteristic:(CBCharacteristic *)characteristic{
    NSLog(@"取消订阅 %@的数据",characteristic.UUID);
    //取消回应
    [timer invalidate];
}

//发送数据，发送当前时间的秒数
- (BOOL)sendData:(NSTimer *)t {

    CBMutableCharacteristic *characteristic = t.userInfo;
    NSDateFormatter *dft = [[NSDateFormatter alloc] init];
    [dft setDateFormat:@"ss"];
    NSLog(@"%@",[dft stringFromDate:[NSDate date]]);
    
    //执行回应Central通知数据
    /*
     *  updateValue方法
     */
    return  [manager updateValue:[[dft stringFromDate:[NSDate date]] dataUsingEncoding:NSUTF8StringEncoding] forCharacteristic:(CBMutableCharacteristic *)characteristic onSubscribedCentrals:nil];
}


//读characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveReadRequest:(CBATTRequest *)request{

    NSLog(@"didReceiveReadRequest");
    
    //判断是否有读数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyRead) {
        NSData *data = request.characteristic.value;
        [request setValue:data];
        //对请求作出成功响应
        [manager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [manager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
}


//写characteristics请求
- (void)peripheralManager:(CBPeripheralManager *)peripheral didReceiveWriteRequests:(NSArray *)requests{
    NSLog(@"didReceiveWriteRequests");
    
    /* 这是收到的值 */
    CBATTRequest *request = requests[0];
    NSLog(@"request.value 1= %@",[[NSString alloc] initWithData:request.value encoding:NSUTF8StringEncoding]);
    
    
    //判断是否有写数据的权限
    if (request.characteristic.properties & CBCharacteristicPropertyWrite) {
        //需要转换成CBMutableCharacteristic对象才能进行写值
        CBMutableCharacteristic *c =(CBMutableCharacteristic *)request.characteristic;
        c.value = request.value;
        [manager respondToRequest:request withResult:CBATTErrorSuccess];
    }else{
        [manager respondToRequest:request withResult:CBATTErrorWriteNotPermitted];
    }
    
    
}

@end
