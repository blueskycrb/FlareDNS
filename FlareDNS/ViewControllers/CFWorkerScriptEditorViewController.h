//
//  CFWorkerScriptEditorViewController.h
//  FlareDNS
//

#import <UIKit/UIKit.h>
#import "CFZone.h"
#import "CFWorkerScript.h"

NS_ASSUME_NONNULL_BEGIN

@interface CFWorkerScriptEditorViewController : UIViewController

- (instancetype)initWithZone:(CFZone *)zone script:(CFWorkerScript *)script;

@end

NS_ASSUME_NONNULL_END