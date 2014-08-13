#import "ListPicker.h"
#import <Cordova/CDVDebug.h>

BOOL isOSAtLeast(NSString* version) {
    return [[[UIDevice currentDevice] systemVersion] compare:version options:NSNumericSearch] != NSOrderedAscending;
}


@implementation ListPicker

@synthesize callbackId = _callbackId;
@synthesize pickerView = _pickerView;
@synthesize actionSheet = _actionSheet;
@synthesize popoverController = _popoverController;
@synthesize view = _view;
@synthesize items = _items;
@synthesize isVisible = _isVisible;


- (int)getRowWithValue:(NSString * )name {
  for(int i = 0; i < [self.items count]; i++) {
    NSDictionary *item = [self.items objectAtIndex:i];
    if([name isEqualToString:[item objectForKey:@"value"]]) {
      return i;
    }
  }
  return -1;
}

- (void)showPicker:(CDVInvokedUrlCommand*)command {

    self.callbackId = command.callbackId;
    NSDictionary *options = [command.arguments objectAtIndex:0];

    // Compiling options with defaults
    NSString *title = [options objectForKey:@"title"] ?: @" ";
    NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"] ?: @"Done";
    NSString *cancelButtonLabel = [options objectForKey:@"cancelButtonLabel"] ?: @"Cancel";

    // Hold items in an instance variable
    self.items = [options objectForKey:@"items"];

    // Initialize the toolbar with Cancel and Done buttons and title
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, self.viewSize.width, 44)];
    toolbar.barStyle = isOSAtLeast(@"7.0") ? UIBarStyleDefault : UIBarStyleBlackTranslucent;
    NSMutableArray *buttons =[[NSMutableArray alloc] init];
    
    // Create Cancel button
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:cancelButtonLabel style:UIBarButtonItemStylePlain target:self action:@selector(didDismissWithCancelButton:)];
    [buttons addObject:cancelButton];
    
    // Create title label aligned to center and appropriate spacers
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [buttons addObject:flexSpace];
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor: isOSAtLeast(@"7.0") ? [UIColor blackColor] : [UIColor whiteColor]];
    [label setFont: [UIFont boldSystemFontOfSize:16]];
    [label setBackgroundColor:[UIColor clearColor]];
     label.text = title;
     UIBarButtonItem *labelButton = [[UIBarButtonItem alloc] initWithCustomView:label];
    [buttons addObject:labelButton];
    [buttons addObject:flexSpace];
     
     // Create Done button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:doneButtonLabel style:UIBarButtonItemStyleDone target:self action:@selector(didDismissWithDoneButton:)];
     [buttons addObject:doneButton];
     [toolbar setItems:buttons animated:YES];
     
    // Initialize the picker
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40.0f, self.viewSize.width, 216)];
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.delegate = self;

    // Define selected value
    if([options objectForKey:@"selectedValue"]) {
        int i = [self getRowWithValue:[options objectForKey:@"selectedValue"]];
        if (i != -1) [self.pickerView selectRow:i inComponent:0 animated:NO];
    }
   
    // Initialize the View that should conain the toolbar and picker
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.viewSize.width, 260)];
    [view setBackgroundColor:[UIColor whiteColor]];
    [view addSubview: toolbar];
    [view addSubview:self.pickerView];
  
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Check if device is iPad as we won't be able to use an ActionSheet there
        return [self presentPopoverForView:view];
    } else {
        if (isOSAtLeast(@"8.0"))  {
            // todo -- handle 8.0+ on iPad??
            if (_isVisible==false){
                _isVisible=true;
                
                self.view = [[UIView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, self.viewSize.width, 260)];
                [self.view setBackgroundColor:[UIColor whiteColor]];
                [self.view addSubview: toolbar];
                [self.view addSubview:self.pickerView];
            
                [self.viewController.view addSubview:self.view];
                [UIView beginAnimations:@"SlideUpListPicker" context:nil];
                [UIView setAnimationDuration:0.5];
                self.view.frame = CGRectOffset(self.viewController.view.frame, 0, [[UIScreen mainScreen] bounds].size.height-260);
                [UIView commitAnimations];
            }
        } else {
            return [self presentActionSheetForView:view];
        }
    }
}
     
-(void)presentActionSheetForView:(UIView *)view {
    
    // Calculate actionSheet height
    NSString *paddedSheetTitle = nil;
    CGFloat sheetHeight = self.viewSize.height - 47;
    if([self isViewPortrait]) {
        paddedSheetTitle = @"\n\n\n"; // Looks hacky
    } else {
        if(isOSAtLeast(@"5.0")) {
            sheetHeight = self.viewSize.width;
        } else {
            sheetHeight += 103;
        }
    }
    
    // ios7 picker draws a darkened alpha-only region on the first and last 8 pixels horizontally, but blurs the rest of its background. To make it whole popup appear to be edge-to-edge, we have to add blurring to the remaining left and right edges.
    if(isOSAtLeast(@"7.0")) {
        CGRect f = CGRectMake(0, self.pickerView.frame.origin.y, 8, self.pickerView.frame.size.height);
        UIToolbar* leftEdge = [[UIToolbar alloc]initWithFrame: f];
        f.origin.x = view.frame.size.width - 8;
        UIToolbar* rightEdge = [[UIToolbar alloc]initWithFrame: f];
        [view insertSubview: leftEdge atIndex: 0];
        [view insertSubview: rightEdge atIndex: 0];
    }
    
    // Create and style actionSheet, and append the view to it
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:paddedSheetTitle delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    [self.actionSheet setActionSheetStyle:UIActionSheetStyleBlackTranslucent];
    [self.actionSheet addSubview:view];
  
    // Toggle ActionSheet
    [self.actionSheet showInView:self.webView.superview];

    // Use beginAnimations for a smoother popup animation, otherwise the UIActionSheet pops into view
    [UIView beginAnimations:nil context:nil];
    [self.actionSheet setBounds:CGRectMake(0, 0, self.viewSize.width, sheetHeight)];
    [UIView commitAnimations];
}

-(void)presentPopoverForView:(UIView *)view {

    // Create a generic content view controller
    UIViewController* popoverContent = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    popoverContent.view = view;

    // Resize the popover view shown
    // in the current view to the view's size
    popoverContent.contentSizeForViewInPopover = view.frame.size;

    // Create a popover controller
    self.popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
    self.popoverController.delegate = self;
    
    // display the picker at the center of the view
    CGRect sourceRect = CGRectMake(self.webView.superview.center.x, self.webView.superview.center.y, 1, 1);

    //present the popover view non-modal with a
    //refrence to the button pressed within the current view
    [self.popoverController presentPopoverFromRect:sourceRect
                                            inView:self.webView.superview
                          permittedArrowDirections: 0
                                          animated:YES];

}

//
// Dismiss methods
//

// Picker with toolbar dismissed with done
- (IBAction)didDismissWithDoneButton:(id)sender {

  // Check if device is iPad
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    // Emulate a new delegate method
    [self popoverController:self.popoverController dismissWithClickedButtonIndex:1 animated:YES];
  } else {
      if (isOSAtLeast(@"8.0"))  {
          [self  sendResultsFromPickerView:self.pickerView withButtonIndex:1];
          [UIView animateWithDuration:0.5
                                delay:0.0
                              options: 0
                           animations:^{
                               self.view.frame = CGRectOffset(self.viewController.view.frame, 0, [[UIScreen mainScreen] bounds].size.height);
                               
                           }
                           completion:^(BOOL finished){
                               [self.view removeFromSuperview];
                               _isVisible=false;
                           }];
      
      } else {
          [self.actionSheet dismissWithClickedButtonIndex:1 animated:YES];
      }
  }
}

// Picker with toolbar dismissed with cancel
- (IBAction)didDismissWithCancelButton:(id)sender {
  // Check if device is iPad
  if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
    // Emulate a new delegate method
    [self popoverController:self.popoverController dismissWithClickedButtonIndex:0 animated:YES];
  } else {
      if (isOSAtLeast(@"8.0"))  {
          [self  sendResultsFromPickerView:self.pickerView withButtonIndex:0];
          [UIView animateWithDuration:0.5
                                delay:0.0
                              options: 0
                           animations:^{
                               self.view.frame = CGRectOffset(self.viewController.view.frame, 0, [[UIScreen mainScreen] bounds].size.height);
                               
                           }
                           completion:^(BOOL finished){
                               [self.view removeFromSuperview];
                               _isVisible=false;
                           }];
      } else {
          [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
      }
  }
}

// Popover generic dismiss - iPad
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

    // Simulate a cancel click
    [self sendResultsFromPickerView:self.pickerView withButtonIndex:0];
}

// Popover emulated button-powered dismiss - iPad
- (void)popoverController:(UIPopoverController *)popoverController dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(Boolean)animated {
  
  // Manually dismiss the popover
  [popoverController dismissPopoverAnimated:animated];
  
  // Retreive pickerView
  [self sendResultsFromPickerView:self.pickerView withButtonIndex:buttonIndex];
}

// ActionSheet generic dismiss - iPhone
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
  {
    // Simulate a cancel click
    [self sendResultsFromPickerView:self.pickerView withButtonIndex:buttonIndex];
  }

//
// Results
//

- (void)sendResultsFromPickerView:(UIPickerView *)pickerView withButtonIndex:(NSInteger)buttonIndex {

  // Build returned result
  NSInteger selectedRow = [pickerView selectedRowInComponent:0];
  NSString *selectedValue = [[self.items objectAtIndex:selectedRow] objectForKey:@"value"];
  
  // Create Plugin Result
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:selectedValue];

  // Checking if cancel was clicked
  if (buttonIndex == 0) {
    // Call the Failure Javascript function
    [self writeJavascript: [pluginResult toErrorCallbackString:self.callbackId]];
  }else {
    // Call the Success Javascript function
    [self writeJavascript: [pluginResult toSuccessCallbackString:self.callbackId]];
  }

}

//
// Picker delegate
//


// Listen picker selected row
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
}

// Tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return [self.items count];
}

// Tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

// Tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return [[self.items objectAtIndex:row] objectForKey:@"text"];
}

// Tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
  return pickerView.frame.size.width - 30;
}

//
// Utilities
//

- (CGSize) viewSize {
    if (![self isViewPortrait])
        return CGSizeMake(480, 320);
    return CGSizeMake(320, 480);
}

- (BOOL) isViewPortrait {
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

@end
