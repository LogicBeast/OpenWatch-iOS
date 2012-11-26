//
//  OWLoginViewController.m
//  OpenWatch
//
//  Created by Christopher Ballinger on 11/12/12.
//  Copyright (c) 2012 OpenWatch FPC. All rights reserved.
//

#import "OWLoginViewController.h"
#import "OWStrings.h"
#import "OWSettingsController.h"
#import "OWAccountAPIClient.h"



#define PADDING 10.0f

@interface OWLoginViewController ()

@end

@implementation OWLoginViewController
@synthesize emailTextField, passwordTextField, loginButton, helpLabel;
@synthesize headerImageView, account, loginOrSignupSegmentedControl, logoutButton;

- (id)init
{
    self = [super init];
    if (self) {
        self.title = LOGIN_STRING;
        OWSettingsController *settingsController = [OWSettingsController sharedInstance];
        self.account = settingsController.account;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    
    self.loginOrSignupSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[LOGIN_STRING, SIGNUP_STRING]];
    [self.loginOrSignupSegmentedControl addTarget:self action:@selector(segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
    self.loginOrSignupSegmentedControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    self.loginOrSignupSegmentedControl.selectedSegmentIndex = 0;
    [self.scrollView addSubview:loginOrSignupSegmentedControl];
    
    [self setUpFields];

    self.helpLabel = [[UILabel alloc] init];
    self.helpLabel.textAlignment = UITextAlignmentCenter;
    self.helpLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.helpLabel.numberOfLines = 0;
    self.helpLabel.text = SIGNUP_HELP_STRING;
    self.helpLabel.shadowColor = [UIColor whiteColor];
    self.helpLabel.shadowOffset = CGSizeMake(0, 1);
    self.helpLabel.textColor = [UIColor darkGrayColor];
    self.helpLabel.backgroundColor = [UIColor clearColor];
    self.helpLabel.font = [UIFont systemFontOfSize:16.0f];
    

    
    self.loginButton = [[UIBarButtonItem alloc] initWithTitle:SUBMIT_STRING style:UIBarButtonItemStyleDone target:self action:@selector(loginButtonPressed:)];
    self.navigationItem.rightBarButtonItem = loginButton;
    
    self.logoutButton = [[UIBarButtonItem alloc] initWithTitle:LOGOUT_STRING style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonPressed:)];
    
    self.headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"openwatch.png"]];
    self.headerImageView.contentMode = UIViewContentModeCenter;
    [self.scrollView addSubview:headerImageView];

    
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.scrollView.frame = self.view.bounds;
    self.scrollView.contentSize = self.view.bounds.size;
    
    CGFloat padding = PADDING;
    self.headerImageView.frame = CGRectMake(padding, 0, self.view.frame.size.width-(padding*2), headerImageView.image.size.height+(padding*2));

    self.loginOrSignupSegmentedControl.frame = CGRectMake(padding, self.headerImageView.frame.size.height, self.view.frame.size.width-(padding*2), 35.0f);
    CGFloat loginTableViewYOrigin = loginOrSignupSegmentedControl.frame.size.height + loginOrSignupSegmentedControl.frame.origin.y;
    self.groupedTableView.frame = CGRectMake(0, loginTableViewYOrigin, self.view.frame.size.width, self.view.frame.size.height-loginTableViewYOrigin);
    
    [self refreshLoginButtons];
}

- (void) refreshLoginButtons {
    if ([account isLoggedIn]) {
        self.navigationItem.leftBarButtonItem = logoutButton;
        self.navigationItem.rightBarButtonItem = nil;
        self.emailTextField.enabled = NO;
        self.emailTextField.textColor = [UIColor lightGrayColor];
        self.passwordTextField.enabled = NO;
        self.passwordTextField.textColor = [UIColor lightGrayColor];
        self.loginOrSignupSegmentedControl.hidden = YES;
    } else {
        self.navigationItem.leftBarButtonItem = nil;
        self.navigationItem.rightBarButtonItem = loginButton;
        self.emailTextField.enabled = YES;
        self.emailTextField.textColor = self.textFieldTextColor;
        self.passwordTextField.enabled = YES;
        self.passwordTextField.textColor = self.textFieldTextColor;
        self.loginOrSignupSegmentedControl.hidden = NO;
    }
}


- (UIColor*) textFieldTextColor {
    return [UIColor colorWithRed:0.22 green:0.33 blue:0.53 alpha:1.0];
}

-(void)setUpFields
{
    self.emailTextField = [[UITextField alloc] init];
    self.emailTextField.delegate = self;
    self.emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.emailTextField.returnKeyType = UIReturnKeyDone;
    self.emailTextField.textColor = self.textFieldTextColor;
    self.emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailTextField.placeholder = REQUIRED_STRING;
    NSString *email = account.email;
    if (email) {
        self.emailTextField.text = email;
    }
    
    [self addCellInfoWithSection:0 row:0 labelText:EMAIL_STRING cellType:kCellTypeTextField userInputView:self.emailTextField];
    
    
    self.passwordTextField = [[UITextField alloc] init];
    self.passwordTextField.delegate = self;
    self.passwordTextField.secureTextEntry = YES;
    self.passwordTextField.returnKeyType = UIReturnKeyDone;
    self.passwordTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.passwordTextField.textColor = self.textFieldTextColor;
    self.passwordTextField.placeholder = REQUIRED_STRING;
    
    NSString *password = account.password;
    if (password) {
        self.passwordTextField.text = password;
    }
    
    [self addCellInfoWithSection:0 row:1 labelText:PASSWORD_STRING cellType:kCellTypeTextField userInputView:self.passwordTextField];
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableViewArray count];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.tableViewArray objectAtIndex:section] count];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}



- (void)loginButtonPressed:(id)sender {
    BOOL fields = [self checkFields];
    if(fields)
    {
        account.email = self.emailTextField.text;
        account.password = self.passwordTextField.text;
        
        if (loginOrSignupSegmentedControl.selectedSegmentIndex == 0) {
            [[OWAccountAPIClient sharedClient] loginWithAccount:account success:^{
                [self loginSuccess];
            } failure:^(NSString *reason) {
                [self loginFailure:reason];
            }];
        } else {
            [[OWAccountAPIClient sharedClient] signupWithAccount:account success:^{
                [self loginSuccess];
            } failure:^(NSString *reason) {
                [self loginFailure:reason];
            }];
        }
    }
}

- (void) loginFailure:(NSString*)reason {
    NSLog(@"Login failure: %@", reason);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:USER_PASS_WRONG_STRING delegate:nil cancelButtonTitle:OK_STRING otherButtonTitles:nil];
    [alert show];
}

- (void) loginSuccess {
    NSLog(@"Login Success");
    [self refreshLoginButtons];
    [self dismissViewControllerAnimated:YES completion:^{}];
}



- (void)logoutButtonPressed:(id)sender {
    [self.account clearAccountData];
    [self refreshLoginButtons];
    self.emailTextField.text = @"";
    self.passwordTextField.text = @"";
}


-(BOOL)checkFields
{
    BOOL fields = emailTextField.text && ![emailTextField.text isEqualToString:@""] && passwordTextField.text && ![passwordTextField.text isEqualToString:@""];
    
    if(!fields)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:ERROR_STRING message:USER_PASS_BLANK_STRING delegate:nil cancelButtonTitle:nil otherButtonTitles:OK_STRING, nil];
        [alert show];
    }
    
    return fields;
}

- (UIView*) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return helpLabel;
    }
    return nil;
}

-(CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        return 50.0f;
    }
    return 0.0f;
}

- (void) segmentedControlValueChanged:(id)sender {
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)keyboardWillShow: (NSNotification *) notif{
    [self.scrollView setContentOffset:CGPointMake(0, self.headerImageView.frame.size.height-PADDING) animated:YES];
}

- (void)keyboardWillHide: (NSNotification *) notif{
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

@end