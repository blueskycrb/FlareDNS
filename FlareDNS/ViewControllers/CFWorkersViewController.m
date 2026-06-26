//
//  CFWorkersViewController.m
//  FlareDNS
//

#import "CFWorkersViewController.h"
#import "CFAPIService.h"
#import "CFWorkerScriptEditorViewController.h"
#import "UIColor+FlareDNS.h"

typedef NS_ENUM(NSInteger, CFWorkersSection) {
    CFWorkersSectionPages = 0,
    CFWorkersSectionScripts,
    CFWorkersSectionRoutes,
    CFWorkersSectionKV,
    CFWorkersSectionCount
};

@interface CFWorkersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CFZone *zone;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, copy) NSArray<CFPagesProject *> *pagesProjects;
@property (nonatomic, copy, nullable) NSString *pagesErrorMessage;
@property (nonatomic, copy) NSArray<CFWorkerScript *> *scripts;
@property (nonatomic, copy) NSArray<CFWorkerRoute *> *routes;
@property (nonatomic, copy) NSArray<CFKVNamespace *> *namespaces;

@end

@implementation CFWorkersViewController

- (instancetype)initWithZone:(CFZone *)zone {
    self = [super init];
    if (self) {
        _zone = zone;
        _pagesProjects = @[];
        _pagesErrorMessage = nil;
        _scripts = @[];
        _routes = @[];
        _namespaces = @[];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Workers & Pages";
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addRouteTapped)];
    [self setupUI];
    [self loadData];
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

- (void)loadData {
    if (self.zone.accountID.length == 0) {
        [self showAlertWithTitle:@"Missing Account" message:@"This zone does not include an account ID."];
        return;
    }

    [self.activityIndicator startAnimating];
    dispatch_group_t group = dispatch_group_create();
    __block NSError *firstError = nil;

    dispatch_group_enter(group);
    [[CFAPIService shared] fetchPagesProjectsForAccountID:self.zone.accountID completion:^(NSArray<CFPagesProject *> * _Nullable projects, NSError * _Nullable error) {
        if (!error) {
            self.pagesProjects = projects ?: @[];
            self.pagesErrorMessage = nil;
        } else {
            self.pagesProjects = @[];
            self.pagesErrorMessage = error.localizedDescription;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[CFAPIService shared] fetchWorkerScriptsForAccountID:self.zone.accountID completion:^(NSArray<CFWorkerScript *> * _Nullable scripts, NSError * _Nullable error) {
        if (!error) {
            self.scripts = scripts ?: @[];
        } else if (!firstError) {
            firstError = error;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[CFAPIService shared] fetchWorkerRoutesForZoneID:self.zone.zoneID completion:^(NSArray<CFWorkerRoute *> * _Nullable routes, NSError * _Nullable error) {
        if (!error) {
            self.routes = routes ?: @[];
        } else if (!firstError) {
            firstError = error;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_enter(group);
    [[CFAPIService shared] fetchKVNamespacesForAccountID:self.zone.accountID completion:^(NSArray<CFKVNamespace *> * _Nullable namespaces, NSError * _Nullable error) {
        if (!error) {
            self.namespaces = namespaces ?: @[];
        } else if (!firstError) {
            firstError = error;
        }
        dispatch_group_leave(group);
    }];

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [self.activityIndicator stopAnimating];
        [self.tableView reloadData];
        if (firstError) {
            [self showAlertWithTitle:@"Partial Load Failed" message:firstError.localizedDescription];
        }
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return CFWorkersSectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case CFWorkersSectionPages: return MAX(self.pagesProjects.count, 1);
        case CFWorkersSectionScripts: return MAX(self.scripts.count, 1);
        case CFWorkersSectionRoutes: return MAX(self.routes.count, 1);
        case CFWorkersSectionKV: return MAX(self.namespaces.count, 1);
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case CFWorkersSectionPages: return @"PAGES PROJECTS";
        case CFWorkersSectionScripts: return @"WORKER SCRIPTS";
        case CFWorkersSectionRoutes: return @"WORKER ROUTES";
        case CFWorkersSectionKV: return @"KV NAMESPACES";
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == CFWorkersSectionPages) {
        return @"Tap a Pages project to open its production domain, latest deployment URL, or Dashboard.";
    }
    if (section == CFWorkersSectionScripts) {
        return @"Tap a script to edit code, bind a route, or open it in Cloudflare Dashboard.";
    }
    if (section == CFWorkersSectionRoutes) {
        return @"Routes bind URL patterns on this zone to Worker scripts. Tap a route to open it.";
    }
    if (section == CFWorkersSectionKV) {
        return @"Tap a namespace to preview up to 100 keys.";
    }
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    if (@available(iOS 26.0, *)) {
        cell.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
        cell.textLabel.textColor = [UIColor labelColor];
        cell.detailTextLabel.textColor = [UIColor secondaryLabelColor];
    } else {
        cell.backgroundColor = [UIColor cf_secondaryBackgroundColor];
        cell.textLabel.textColor = [UIColor cf_primaryTextColor];
        cell.detailTextLabel.textColor = [UIColor cf_secondaryTextColor];
    }

    if (indexPath.section == CFWorkersSectionPages) {
        if (self.pagesProjects.count == 0) {
            cell.textLabel.text = @"No Pages projects";
            cell.detailTextLabel.text = self.pagesErrorMessage.length > 0 ? self.pagesErrorMessage : @"No Pages projects found for this account.";
            return cell;
        }
        CFPagesProject *project = self.pagesProjects[indexPath.row];
        cell.textLabel.text = project.name;
        cell.detailTextLabel.text = [project displayURLString] ?: @"Tap to open project links";
        cell.imageView.image = [UIImage systemImageNamed:@"globe"];
        cell.imageView.tintColor = [UIColor systemCyanColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else if (indexPath.section == CFWorkersSectionScripts) {
        if (self.scripts.count == 0) {
            cell.textLabel.text = @"No Worker scripts";
            cell.detailTextLabel.text = @"Create scripts in Cloudflare or deploy with Wrangler.";
            return cell;
        }
        CFWorkerScript *script = self.scripts[indexPath.row];
        cell.textLabel.text = script.name;
        cell.detailTextLabel.text = script.modifiedOn.length > 0 ? [NSString stringWithFormat:@"Modified %@", script.modifiedOn] : @"Tap to manage script";
        cell.imageView.image = [UIImage systemImageNamed:@"bolt.fill"];
        cell.imageView.tintColor = [UIColor systemOrangeColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else if (indexPath.section == CFWorkersSectionRoutes) {
        if (self.routes.count == 0) {
            cell.textLabel.text = @"No routes";
            cell.detailTextLabel.text = @"Use + or tap a script to bind a pattern.";
            return cell;
        }
        CFWorkerRoute *route = self.routes[indexPath.row];
        cell.textLabel.text = route.pattern;
        cell.detailTextLabel.text = route.scriptName.length > 0 ? route.scriptName : @"No script";
        cell.imageView.image = [UIImage systemImageNamed:@"point.3.connected.trianglepath.dotted"];
        cell.imageView.tintColor = [UIColor systemBlueColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    } else {
        if (self.namespaces.count == 0) {
            cell.textLabel.text = @"No KV namespaces";
            cell.detailTextLabel.text = @"KV permissions are required to list namespaces.";
            return cell;
        }
        CFKVNamespace *namespace = self.namespaces[indexPath.row];
        cell.textLabel.text = namespace.title;
        cell.detailTextLabel.text = namespace.namespaceID;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.imageView.image = [UIImage systemImageNamed:@"shippingbox.fill"];
        cell.imageView.tintColor = [UIColor systemPurpleColor];
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == CFWorkersSectionPages && indexPath.row < self.pagesProjects.count) {
        [self showActionsForPagesProject:self.pagesProjects[indexPath.row]];
    } else if (indexPath.section == CFWorkersSectionScripts && indexPath.row < self.scripts.count) {
        [self showActionsForScript:self.scripts[indexPath.row]];
    } else if (indexPath.section == CFWorkersSectionRoutes && indexPath.row < self.routes.count) {
        [self showActionsForRoute:self.routes[indexPath.row]];
    } else if (indexPath.section == CFWorkersSectionKV && indexPath.row < self.namespaces.count) {
        [self showKeysForNamespace:self.namespaces[indexPath.row]];
    }
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != CFWorkersSectionRoutes || indexPath.row >= self.routes.count) {
        return nil;
    }

    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(__unused UIContextualAction * _Nonnull action, __unused UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        CFWorkerRoute *route = self.routes[indexPath.row];
        [[CFAPIService shared] deleteWorkerRouteWithID:route.routeID forZoneID:self.zone.zoneID completion:^(BOOL success, NSError * _Nullable error) {
            if (error) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription];
                completionHandler(NO);
            } else {
                [self loadData];
                completionHandler(YES);
            }
        }];
    }];

    return [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
}

#pragma mark - Actions

- (void)showActionsForPagesProject:(CFPagesProject *)project {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:project.name message:project.latestCommitMessage preferredStyle:UIAlertControllerStyleActionSheet];

    NSString *primaryURL = [project primaryURLString];
    if (primaryURL.length > 0) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Open Production URL" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            [self openURLString:primaryURL];
        }]];
    }

    if (project.latestDeploymentURL.length > 0) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Open Latest Deployment" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            [self openURLString:project.latestDeploymentURL];
        }]];
    }

    for (NSString *domain in project.domains) {
        NSString *urlString = ([domain hasPrefix:@"http://"] || [domain hasPrefix:@"https://"]) ? domain : [@"https://" stringByAppendingString:domain];
        [sheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Open %@", domain] style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            [self openURLString:urlString];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Open Pages Dashboard" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [self openPagesDashboardForProjectName:project.name];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showActionsForScript:(CFWorkerScript *)script {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:script.name message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Edit Script" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        CFWorkerScriptEditorViewController *editor = [[CFWorkerScriptEditorViewController alloc] initWithZone:self.zone script:script];
        [self.navigationController pushViewController:editor animated:YES];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Bind Route" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [self addRouteForScript:script];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Open Dashboard" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        [self openDashboardForScriptName:script.name];
    }]];

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)showActionsForRoute:(CFWorkerRoute *)route {
    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:route.pattern message:route.scriptName preferredStyle:UIAlertControllerStyleActionSheet];

    NSURL *routeURL = [self URLFromWorkerRoutePattern:route.pattern];
    if (routeURL) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Open Route URL" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            [[UIApplication sharedApplication] openURL:routeURL options:@{} completionHandler:nil];
        }]];
    }

    if (route.scriptName.length > 0) {
        [sheet addAction:[UIAlertAction actionWithTitle:@"Open Worker Dashboard" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
            [self openDashboardForScriptName:route.scriptName];
        }]];
    }

    [sheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:sheet animated:YES completion:nil];
}

- (void)addRouteTapped {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Add Worker Route"
                                                                   message:@"Bind a URL pattern to a Worker script."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [NSString stringWithFormat:@"%@/*", self.zone.name];
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = self.scripts.firstObject.name ?: @"worker-script-name";
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Add" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        NSString *pattern = [alert.textFields[0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSString *scriptName = [alert.textFields[1].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (pattern.length == 0 || scriptName.length == 0) {
            [self showAlertWithTitle:@"Error" message:@"Pattern and script name are required."];
            return;
        }

        [[CFAPIService shared] createWorkerRouteForZoneID:self.zone.zoneID pattern:pattern scriptName:scriptName completion:^(CFWorkerRoute * _Nullable route, NSError * _Nullable error) {
            if (error) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription];
            } else {
                [self loadData];
            }
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)addRouteForScript:(CFWorkerScript *)script {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Bind Worker Route"
                                                                   message:@"Bind this Worker to a URL pattern on the current zone."
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.placeholder = [NSString stringWithFormat:@"%@/*", self.zone.name];
        textField.text = [NSString stringWithFormat:@"%@/*", self.zone.name];
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;
    }];

    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Bind" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction * _Nonnull action) {
        NSString *pattern = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (pattern.length == 0) {
            [self showAlertWithTitle:@"Error" message:@"Pattern is required."];
            return;
        }
        [[CFAPIService shared] createWorkerRouteForZoneID:self.zone.zoneID pattern:pattern scriptName:script.name completion:^(CFWorkerRoute * _Nullable route, NSError * _Nullable error) {
            if (error) {
                [self showAlertWithTitle:@"Error" message:error.localizedDescription];
            } else {
                [self loadData];
            }
        }];
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showKeysForNamespace:(CFKVNamespace *)namespace {
    [self.activityIndicator startAnimating];
    [[CFAPIService shared] fetchKVKeysForAccountID:self.zone.accountID namespaceID:namespace.namespaceID completion:^(NSArray<NSString *> * _Nullable keys, NSError * _Nullable error) {
        [self.activityIndicator stopAnimating];
        if (error) {
            [self showAlertWithTitle:@"Error" message:error.localizedDescription];
            return;
        }

        NSString *message = keys.count > 0 ? [keys componentsJoinedByString:@"\n"] : @"No keys found.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:namespace.title
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

- (void)openPagesDashboardForProjectName:(NSString *)projectName {
    NSString *encodedProject = [projectName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"https://dash.cloudflare.com/%@/pages/view/%@", self.zone.accountID ?: @"", encodedProject ?: projectName];
    [self openURLString:urlString];
}

- (void)openDashboardForScriptName:(NSString *)scriptName {
    NSString *encodedScript = [scriptName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"https://dash.cloudflare.com/%@/workers/services/view/%@/production", self.zone.accountID ?: @"", encodedScript ?: scriptName];
    [self openURLString:urlString];
}

- (void)openURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

- (NSURL *)URLFromWorkerRoutePattern:(NSString *)pattern {
    if (pattern.length == 0) {
        return nil;
    }

    NSString *cleaned = [pattern stringByReplacingOccurrencesOfString:@"*" withString:@""];
    cleaned = [cleaned stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    while ([cleaned hasSuffix:@"/"] && cleaned.length > 1) {
        cleaned = [cleaned substringToIndex:cleaned.length - 1];
    }
    if (![cleaned hasPrefix:@"http://"] && ![cleaned hasPrefix:@"https://"]) {
        cleaned = [@"https://" stringByAppendingString:cleaned];
    }
    return [NSURL URLWithString:cleaned];
}

- (void)showAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
