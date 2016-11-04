//
//  ViewController.m
//  socketdemo
//
//  Created by tm on 2016/11/3.
//  Copyright © 2016年 tm. All rights reserved.
//
#import <arpa/inet.h>
#import <netdb.h>
#import "ViewController.h"
#import "GCDAsyncSocket.h"
//#include <arpa/inet.h>
#include <net/if.h>
#include <ifaddrs.h>
//#import <ifaddrs.h>
#import <arpa/inet.h>
@interface ViewController ()<GCDAsyncSocketDelegate>
@property (nonatomic ,strong) GCDAsyncSocket *socket;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *local = [self getIpAddresses];
    NSLog(@"%@",local);
}

- (NSString *)localIPAddress
{
    NSString *localIP = nil;
    struct ifaddrs *addrs;
    if (getifaddrs(&addrs)==0) {
        const struct ifaddrs *cursor = addrs;
        while (cursor != NULL) {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                //NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                //if ([name isEqualToString:@"en0"]) // Wi-Fi adapter
                {
                    localIP = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return localIP;
}

//获取ip地址
- (NSString *)getIpAddresses{
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"])
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
//    return [address UTF8String];
    return address;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    NSString * host =@"192.168.11.184";
//    NSNumber * port = @9999;
//    
//    // 创建 socket
//    int socketFileDescriptor = socket(AF_INET, SOCK_STREAM, 0);
//    if (-1 == socketFileDescriptor) {
//        NSLog(@"创建失败");
//        return;
//    }
//    
//    // 获取 IP 地址
//    struct hostent * remoteHostEnt = gethostbyname([host UTF8String]);
//    if (NULL == remoteHostEnt) {
//        close(socketFileDescriptor);
//        NSLog(@"%@",@"无法解析服务器的主机名");
//        return;
//    }
//    
//    struct in_addr * remoteInAddr = (struct in_addr *)remoteHostEnt->h_addr_list[0];
//    
//    // 设置 socket 参数
//    struct sockaddr_in socketParameters;
//    socketParameters.sin_family = AF_INET;
//    socketParameters.sin_addr = *remoteInAddr;
//    socketParameters.sin_port = htons([port intValue]);
//    
//    // 连接 socket
//    int ret = connect(socketFileDescriptor, (struct sockaddr *) &socketParameters, sizeof(socketParameters));
//    if (-1 == ret) {
//        close(socketFileDescriptor);
//        NSLog(@"连接失败");
//        return;
//    }
//    
//    NSLog(@"连接成功");
}

- (IBAction)connectBtnClick:(UIButton *)sender {
    
    // 1.与服务器通过三次握手建立连接
    NSString *host = @"192.168.11.184";
    int port = 9999;
    
    //创建一个socket对象
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    
    //连接
    NSError *error = nil;
    [_socket connectToHost:host onPort:port error:&error];
    
    if (error) {
        NSLog(@"%@",error);
    }
    
}

- (IBAction)sendData:(UIButton *)sender {
    NSData *data=[@"Hello from iPhone" dataUsingEncoding:NSUTF8StringEncoding];
    [_socket writeData:data withTimeout:-1 tag:1];
}

#pragma mark -socket的代理
#pragma mark 连接成功
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port{
    NSLog(@"%s",__func__);
}

- (IBAction)deconnect:(UIButton *)sender {
    [_socket disconnectAfterWriting];
}

#pragma mark 断开连接
-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err{
    if (err) {
        NSLog(@"连接失败");
    }else{
        NSLog(@"正常断开");
    }
}


#pragma mark 数据发送成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    NSLog(@"%s",__func__);
    
    //发送完数据手动读取，-1不设置超时
    [sock readDataWithTimeout:-1 tag:tag];
    
}

#pragma mark 读取数据
-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *receiverStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%s %@",__func__,receiverStr);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
