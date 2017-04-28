//
//  ViewController.m
//  MacTest
//
//  Created by 天机否 on 17/4/24.
//  Copyright © 2017年 tianjifou. All rights reserved.
//

#import "ViewController.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    __weak ViewController*weakSelf = self;
    [self.exBox setSuccessBlock:^(NSString * str) {
        weakSelf.path = str;
        weakSelf.nameLabel.title = @"拖入成功，无需再拖";
        [weakSelf clearZip];
    }];
    
    [self.exBox2 setSuccessBlock:^(NSString * str) {
        weakSelf.zipPath = str;
        weakSelf.zipContentLabel.title = @"拖入成功";
    }];
   
}

- (IBAction)startAction:(id)sender {
    
    NSString*localPath = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"uploadservice/public"];
    NSString*zipPath = [self.zipPath stringByDeletingLastPathComponent];
    NSString*zipName = [[[self.zipPath componentsSeparatedByString:@"/"] lastObject] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSMutableArray*arrArgs = [NSMutableArray arrayWithObjects:@"-l",@"-c", nil];
   
        if(self.path&&self.path.length>0&&self.zipPath&&self.zipPath.length>0){
           
            [arrArgs addObject:[NSString stringWithFormat:@"cd %@;rm %@;cd %@;cp %@ %@;cd %@;npm start",localPath,zipName,zipPath,zipName,localPath,localPath]];
           
            [self executeTask:arrArgs success:nil];
            self.textView.string = [NSString stringWithFormat:@"http://%@:3000/%@",[self getIPAddress],zipName];

        }
    }


-(void)clearZip {
    NSString*localPath = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"uploadservice/public"];
     NSMutableArray*arrArgs = [NSMutableArray arrayWithObjects:@"-l",@"-c", nil];
    [arrArgs addObject:[NSString stringWithFormat:@"ls %@",localPath]];
     __weak ViewController*weakSelf = self;
    [self executeTask:arrArgs success:^(NSString *str) {
        NSArray*arr = [str componentsSeparatedByString:@"\n"];
        for(NSString*str in arr){
            if ([str rangeOfString:@".log"].location != NSNotFound ||[str rangeOfString:@".zip"].location != NSNotFound) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                    [weakSelf executeTask:@[@"-l",@"-c",[NSString stringWithFormat:@"cd %@;rm %@",localPath,str]] success:nil];
                });
            }
        }
    }];
}

-(void)executeTask:(NSArray*)arrArgs success:(void(^)(NSString*str))successBlock{
    
    NSTask*task  = [[NSTask alloc]init];
    task.arguments = arrArgs;
    task.currentDirectoryPath = [[self.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"uploadservice/public"];
    task.launchPath = @"/bin/bash";
    
    NSPipe*outPipe = [[NSPipe alloc]init];
    NSPipe*errorPipe = [[NSPipe alloc]init];
    task.standardOutput = outPipe;
    task.standardError = errorPipe;
    [task launch];
    
   
//    [task waitUntilExit];
       dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [[outPipe fileHandleForReading]readInBackgroundAndNotify];
        NSData*outData = [[outPipe fileHandleForReading] availableData];
        [[errorPipe fileHandleForReading]readInBackgroundAndNotify];
        NSData*errorData = [[errorPipe fileHandleForReading]availableData];
        
        
        NSString*outStr = [[NSString alloc]initWithData:outData encoding:NSUTF8StringEncoding];
        NSString*errorStr = [[NSString alloc]initWithData:errorData encoding:NSUTF8StringEncoding];
        if(errorStr&&errorStr.length>0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"执行命令有误：%@",errorStr);
            });
        }
        if(outStr&&outStr.length>0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(successBlock){
                    successBlock(outStr);
                }
                NSLog(@"成功了啊%@",outStr);
            });
        }
        
        
    });
}
- (NSString *)getIPAddress {
    
    NSString *address = @"error";
    
    struct ifaddrs *interfaces = NULL;
    
    struct ifaddrs *temp_addr = NULL;
    
    int success = 0;
       success = getifaddrs(&interfaces);
    
    if (success == 0) {
        temp_addr = interfaces;
        
        while(temp_addr != NULL) {
            
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                        address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
                
            }
            
            temp_addr = temp_addr->ifa_next;
        }
        
    }
  
    
    freeifaddrs(interfaces);
    
    return address;
}
- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
@implementation ExBox

-(void)drawRect:(NSRect)dirtyRect{
    [super drawRect:dirtyRect];
    [self registerForDraggedTypes:@[NSFilenamesPboardType]];
}
-(NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    return NSDragOperationCopy;
}

-(BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSArray*arr = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    if(arr.count>0){
        for (NSString*str  in arr) {
            if ([str rangeOfString:@"."].location != NSNotFound) {
                if(self.successBlock){
                    self.successBlock(str);
                }
                return YES;
            }else {
                NSAlert*alert = [[NSAlert alloc]init];
                alert.messageText = @"请按照提示拖入文件";
                alert.informativeText = @"骚年，按提示拖入文件啊！！！";
                alert.showsHelp = YES;
                [alert beginSheetModalForWindow:self.window completionHandler:nil];
            }
        }
    }
    
    return NO;
}
@end
