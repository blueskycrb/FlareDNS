//
//  CFWorkerScriptEditorViewController.m
//  FlareDNS
//

#import "CFWorkerScriptEditorViewController.h"
#import "CFAPIService.h"
#import "UIColor+FlareDNS.h"

@interface CFWorkerScriptEditorViewController () <UITextViewDelegate>

@property (nonatomic, strong) CFZone *zone;
@property (nonatomic, strong) CFWorkerScript *script;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, copy) NSString *originalContent;

@end

@implementation CFWorkerScriptEditorViewController

- (instancetype)initWithZone:(CFZone *)zone script:(CFWorkerScript *)script {
    self = [super init];
    if (self) {
        _zone = zone;
        _script = script;
        _originalContent = @"";
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.script.name;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveTapped)],
        [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"safari"] style:UIBarButtonItemStylePlain target:self action:@selector(openDashboardTapped)]
    ];
    [self setupUI];
    [self loadScriptContent];
}

- (void)setupUI {
    if (@available(iOS 26.0, *)) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor cf_primaryBackgroundColor];
    }

    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.delegate = self;
    self.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.smartQuotesType = UITextSmartQuotesTypeNo;
    self.textView.smartDashesType = UITextSmartDashesTypeNo;
    self.textView.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.textView.textContainerInset = UIEdgeInsetsMake(16, 12, 16, 12);
    self.textView.alwaysBounceVertical = YES;

    if (@available(iOS 26.0, *)) {
        self.textView.backgroundColor = [UIColor systemBackgroundColor];
        self.textView.textColor = [UIColor labelColor];
    } else {
        self.textView.backgroundColor = [UIColor cf_primaryBackgroundColor];
        self.textView.textColor = [UIColor cf_primaryTextColor];
    }

    [self.view addSubview:self.textView];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.textView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.textView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.textView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.textView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)loadScriptContent {
    if (self.zone.accountID.length == 0 || self.script.name.length == 0) {
        [self showAlertWithTitle:@"Missing Script" message:@"This Worker script cannot be loaded without an account ID and script name."];
        return;
    }

    [self.activityIndicator startAnimating];
    self.textView.editable = NO;
    [[CFAPIService shared] fetchWorkerScriptContentForAccountID:self.zone.accountID scriptName:self.script.name completion:^(NSString * _Nullable content, NSError * _Nullable error) {
        [self.activityIndicator stopAnimating];
        self.textView.editable = YES;
        if (error) {
            [self showAlertWithTitle:@"Load Failed" message:error.localizedDescription];
            return;
        }
        self.originalContent = content ?: @"";
        self.textView.text = self.originalContent;
    }];
}

- (void)saveTapped {
    NSString *content = self.textView.text ?: @"";
    if (content.length == 0) {
        [self showAlertWithTitle:@"Empty Script" message:@"Worker script content cannot be empty."];
        return;
    }

    [self.activityIndicator startAnimating];
    self.view.userInteractionEnabled = NO;
    [[CFAPIService shared] updateWorkerScriptContentForAccountID:self.zone.accountID scriptName:self.script.name content:content completion:^(BOOL success, NSError * _Nullable error) {
        [self.activityIndicator stopAnimating];
        self.view.userInteractionEnabled = YES;
        if (error) {
            [self showAlertWithTitle:@"Save Failed" message:error.localizedDescription];
        } else {
            self.originalContent = content;
            [self showAlertWithTitle:@"Saved" message:@"Worker script content has been updated."];
        }
    }];
}

- (void)openDashboardTapped {
    NSString *encodedScript = [self.script.name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"https://dash.cloudflare.com/%@/workers/services/view/%@/production", self.zone.accountID ?: @"", encodedScript ?: self.script.name];
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.isMovingFromParentViewController && ![self.originalContent isEqualToString:(self.textView.text ?: @"")]) {
        [self.view endEditing:YES];
    }
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end