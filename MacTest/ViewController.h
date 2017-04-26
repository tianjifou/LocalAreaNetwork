//
//  ViewController.h
//  MacTest
//
//  Created by 天机否 on 17/4/24.
//  Copyright © 2017年 tianjifou. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class ExBox;
@interface ViewController : NSViewController<NSDraggingDestination>
@property (weak) IBOutlet NSButton *start;
@property (weak) IBOutlet ExBox *exBox;
@property (weak) IBOutlet ExBox *exBox2;
@property (weak) IBOutlet NSTextFieldCell *nameLabel;
@property (weak) IBOutlet NSTextFieldCell *zipContentLabel;

@property (unsafe_unretained) IBOutlet NSTextView *textView;

@property(nonatomic,copy)NSString*path;
@property(nonatomic,copy)NSString*zipPath;

@end


@interface ExBox : NSBox
@property(nonatomic,copy)void(^successBlock)(NSString*path);
@end
