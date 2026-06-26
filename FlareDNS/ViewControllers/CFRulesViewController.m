//
//  CFRulesViewController.m
//  FlareDNS
//

#import "CFRulesViewController.h"
#import "CFAPIService.h"
#import "CFRulesetRule.h"
#import "UIColor+FlareDNS.h"

typedef NS_ENUM(NSInteger, CFRulesSection) {
    CFRulesSectionRedirect = 0,
    CFRulesSectionCache,
    CFRulesSectionCount
};

@interface CFRulesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CFZone *zone;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, copy) NSArray<CFRulesetRule *> *redirectRules;
@property (nonatomic, copy) NSArray<CFRulesetRule *> *cacheRules;

@end

@implementation CFRulesViewController

- (instancetype)initWithZone:(CFZone *)zone {
    self = [super init];
    if (self) {
        _zone = zone;
        _redirectRules = @[];
        _cacheRules = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Rules";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRedirectRuleTapped)];
    [self setupUI];
    [self loadRules];
}

- (void)setupUI {
    if (@available(iOS 26.0, *)) {
        self.view.backgroundColor = [UIColor systemGroupedBackgroundColor];
    } else {
        self.view.backgroundColor = [UIColor cf_primaryBackgroundColor];
    }

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleInsetGrouped];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.backgroundColor = self.view.backgroundColor;
    [self.view addSubview:self.tableView];

    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    self.activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:self.activityIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)loadRules {
    [self.activityIndicator startAnimating];
    dispatch_group_t group = dispatch_group_create();
    __block NSError *firstError = nil;

    dispatch_group_enter(group);
    [[CFAPIService shared] fetchRulesForZoneID:self.zone.zoneID phase:CFRulesetPhaseDynamicRedirect completion:^(NSArray<CFRulesetRule *> * _Nullable rules, NSError * _Nullable error) {
        if (!error) {
            self.redirectRules = rules ?: @[];
        } else if (!firstError) {
            firstError = error;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[CFAPIService shared] fetchRulesForZoneID:self.zone.zoneID phase:CFRulesetPhaseCacheSettings completion:^(NSArray<CFRulesetRule *> * _Nullable rules, NSError * _Nullable error) {
        if (!error) {
            self.cacheRules = rules ?: @[];
        } else if (!firstError) {
            firstError = error;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        [self.tableView reloadData];
        if (firstError) {
            [self showAlertWithTitle:@"Rules Load Failed" message:firstError.localizedDescription];
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CFRulesSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return MAX([self rulesForSection:section].count, 1);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [CFRulesetRule displayNameForPhase:[self phaseForSection:section]];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == CFRulesSectionRedirect) {
        return @"Use + to create a static redirect rule. More rule types can still be edited in Cloudflare.";
    }
    return @"Cache Rules are listed here for quick enable, disable, and delete actions.";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<CFRulesetRule *> *rules = [self rulesForSection:indexPath.section];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];

    if (@available(iOS 26.0, *)) {
        cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        cell.textLabel.textColor = [UIColor labelColor];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    } else {
        cell.backgroundColor = [UIColor cf_secondaryBackgroundColor];
        cell.textLabel.textColor = [UIColor cf_primaryTextColor];
        cell.detailTextLabel.textColor = [UIColor cf_secondaryTextColor];
    }

    if (rules.count == 0) {
        cell.textLabel.text = [NSString stringWithFormat:@"No %@", [[CFRulesetRule displayNameForPhase:[self phaseForSection:indexPath.section]] lowercaseString]];
        cell.detailTextLabel.text = indexPath.section == CFRulesSectionRedirect ? @"Tap + to add a redirect rule." : @"Create Cache Rules in Cloudflare, then manage them here.";
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        return cell;
    }

    CFRulesetRule *rule = rules[indexPath.row];
    cell.textLabel.text = rule.descriptionText.length > 0 ? rule.descriptionText : @"Untitled Rule";
    cell.detailTextLabel.text = [self detailTextForRule:rule];
    cell.imageView.image = [UIImage systemImageNamed:(rule.phase == CFRulesetPhaseDynamicRedirect ? @"arrow.triangle.turn.up.right.circle.fill" : @"speedometer")];
    cell.imageView.tintColor = rule.enabled ? (rule.phase == CFRulesetPhaseDynamicRedirect ? [UIColor systemOrangeColor] : [UIColor systemBlueColor]) : [UIColor systemGrayColor];
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;

    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.on = rule.enabled;
    toggle.tag = (indexPath.section * 10000) + indexPath.row;
    [toggle addTarget:self action:@selector(ruleSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = toggle;

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSArray<CFRulesetRule *> *rules = [self rulesForSection:indexPath.section];
    if (indexPath.row >= rules.count) {
        return;
    }

    CFRulesetRule *rule = rules[indexPath.row];
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    [lines addObject:[NSString stringWithFormat:@"Type: %@", [CFRulesetRule shortNameForPhase:rule.phase]]];
    [lines addObject:[NSString stringWithFormat:@"Status: %@", rule.enabled ? @"Enabled" : @"Disabled"]];
    if (rule.expression.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"Expression: %@", rule.expression]];
    }
    if (rule.targetURL.length > 0) {
        [lines addObject:[NSString stringWithFormat:@"Target: %@", rule.targetURL]];
    }
    if (rule.statusCode > 0) {
        [lines addObject:[NSString stringWithFormat:@"Status Code: %ld", (long)rule.statusCode]];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:rule.descriptionText message:[lines componentsJoinedByString:@"\n\n"] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray<CFRulesetRule *> *rules = [self rulesForSection:indexPath.section];
    if (indexPath.row >= rules.count) {
        return nil;
    }

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(__unused UIContextualAction * _Nonnull action, __unused UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        CFRulesetRule *rule = rules[indexPath.row];
        [[CFAPIService shared] deleteRuleWithID:rule.ruleID forZoneID:self.zone.zoneID phase:rule.phase completion:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription];
                completionHandler(NO);
            } else {
                [self loadRules];
                completionHandler(YES);
            }
        }];
    }];

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark - Actions

- (void)ruleSwitchChanged:(UISwitch *)sender {
    NSInteger section = sender.tag / 10000;
    NSInteger row = sender.tag % 10000;
    NSArray<CFRulesetRule *> *rules = [self rulesForSection:section];
    if (row >= rules.count) {
        return;
    }

    CFRulesetRule *rule = rules[row];
    [[CFAPIService shared] setRuleEnabled:sender.on ruleID:rule.ruleID forZoneID:self.zone.zoneID phase:rule.phase completion:^(BOOL success, NSError * _Nullable error) {
        if (error) {
            sender.on = !sender.on;
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
        } else {
            [self loadRules];
        }
    }];
}

- (void)addRedirectRuleTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Redirect Rule" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"Description";
        textField.text = @"Redirect rule";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [NSString stringWithFormat:@"http.host eq \"%@\"", self.zone.name];
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [NSString stringWithFormat:@"https://%@/new-path", self.zone.name];
        textField.keyboardType = UIKeyboardTypeURL;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = @"301 or 302";
        textField.text = @"301";
        textField.keyboardType = UIKeyboardTypeNumberPad;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        NSString *description = [alert.textFields[0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *expression = [alert.textFields[1].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *targetURL = [alert.textFields[2].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSInteger statusCode = [alert.textFields[3].text integerValue];

        if (expression.length == 0 || targetURL.length == 0) {
            [self showAlertWithTitle:@"Error" message:@"Expression and target URL are required."];
            return;
        }
        if (statusCode != 301 && statusCode != 302 && statusCode != 307 && statusCode != 308) {
            [self showAlertWithTitle:@"Error" message:@"Use 301, 302, 307, or 308 as the status code."];
            return;
        }

        [[CFAPIService shared] createRedirectRuleForZoneID:self.zone.zoneID description:description expression:expression targetURL:targetURL statusCode:statusCode preserveQueryString:YES completion:^(CFRulesetRule * _Nullable rule, NSError * _Nullable error) {
            if (error) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription];
            } else {
                [self loadRules];
            }
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Helpers

- (NSArray<CFRulesetRule *> *)rulesForSection:(NSInteger)section {
    return section == CFRulesSectionRedirect ? self.redirectRules : self.cacheRules;
}

- (CFRulesetPhase)phaseForSection:(NSInteger)section {
    return section == CFRulesSectionRedirect ? CFRulesetPhaseDynamicRedirect : CFRulesetPhaseCacheSettings;
}

- (NSString *)detailTextForRule:(CFRulesetRule *)rule {
    if (rule.phase == CFRulesetPhaseDynamicRedirect && rule.targetURL.length > 0) {
        return [NSString stringWithFormat:@"%@ -> %@", rule.enabled ? @"Enabled" : @"Disabled", rule.targetURL];
    }
    if (rule.expression.length > 0) {
        return [NSString stringWithFormat:@"%@ - %@", rule.enabled ? @"Enabled" : @"Disabled", rule.expression];
    }
    return rule.enabled ? @"Enabled" : @"Disabled";
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
