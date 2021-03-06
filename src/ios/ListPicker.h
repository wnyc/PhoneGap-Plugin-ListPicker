#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface ListPicker : CDVPlugin <UIActionSheetDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate> {
}

#pragma mark - Properties

@property (nonatomic, copy) NSString* callbackId;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) NSArray *items;
@property (nonatomic) BOOL isVisible;
@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UIView *touchInterceptorView;

#pragma mark - Instance methods

- (void)showPicker:(CDVInvokedUrlCommand*)command;

@end