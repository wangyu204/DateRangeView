//
//  ZXDateRangePickView.m
//  DateRangeDemo
//
//  Created by dengqi on 2018/5/3.
//  Copyright © 2018年 http://www.cnblogs.com/justqi/. All rights reserved.
//
#define XGButtonWidth         60.0

#define XGScreenBounds [UIScreen mainScreen].bounds
#define XGScreenWidth XGScreenBounds.size.width
#define XGScreenHeight XGScreenBounds.size.height

#import "ZXDateRangePickView.h"
#import "Defind.h"
#import "UIView+DQExtention.h"

CGFloat pickerViewH = 210;
CGFloat titleViewH = 80;
CGFloat bottomViewH = 210+80;

@interface ZXDateRangePickView()<UIPickerViewDelegate , UIPickerViewDataSource>

@property (strong, nonatomic)UIView *bottomView;
@property (strong, nonatomic)UIView *titleView;
@property (strong, nonatomic)UIView *buttonView;
@property (strong, nonatomic)UIPickerView *pickerViewLeft;
@property (strong, nonatomic)UIPickerView *pickerViewRight;

@property (strong, nonatomic) NSMutableArray        *hourOneArr;    //年份列表_起
@property (strong, nonatomic) NSMutableArray        *minuteOnehArr;   //月份列表_起
@property (strong, nonatomic) NSMutableArray        *hourTwoArr;    //年份列表_止
@property (strong, nonatomic) NSMutableArray        *minuteTwohArr;   //月份列表_止

@property (strong, nonatomic) NSString              *hourOneStr;    //年份_起
@property (strong, nonatomic) NSString              *minuteOneStr;    //月份_起

@property (strong, nonatomic) NSString              *hourTwoStr;    //年份_止
@property (strong, nonatomic) NSString              *minuteTwoStr;    //月份_止


@end

@implementation ZXDateRangePickView


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.frame = XGScreenBounds;
        //透明度不影响子视图
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];
    }
    return self;
}

//确认按钮，返回时间
-(void)sureBtnClick:(UIButton *)button{
    if (self.DidSelectDateBlock) {
        NSString *beginStr = [NSString stringWithFormat:@"%@:%@",_hourOneStr,_minuteOneStr];
        NSString *endStr = [NSString stringWithFormat:@"%@:%@",_hourTwoStr,_minuteTwoStr];
        
        if ([[NSString stringWithFormat:@"%@%@",_hourOneStr,_minuteOneStr] intValue]>[[NSString stringWithFormat:@"%@%@",_hourTwoStr,_minuteTwoStr] intValue]) {
            endStr = beginStr;
            NSLog(@"结束时间小于开始时间,将结束时间==开始时间");
        }
        
        self.DidSelectDateBlock(beginStr,endStr);
    }
    [self dismissPickerView];
}

-(void)canceBtnClick:(UIButton *)button{
    [self dismissPickerView];
    if (self.DidCanceBlock) {
        self.DidCanceBlock();
    }
}

-(void)dismissPickerView{
    if ([self superview]) {
        [UIView animateWithDuration:0.3 animations:^{
            self.bottomView.y = XGScreenHeight;
            self.pickerViewLeft.y = XGScreenHeight;
            self.pickerViewRight.y = XGScreenHeight;
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
            
        }];
    }
    
    for (UIView *subView in self.subviews) {
        [subView removeFromSuperview];
    }
    
    _hourOneStr = @"";
    _minuteOneStr = @"";
    _hourTwoStr = @"";
    _minuteTwoStr = @"";
    
    _hourOneArr = nil;
    _minuteOnehArr = nil;
    _hourTwoArr = nil;
    _minuteTwohArr = nil;
    
}

// 显示view(此方法是加载在window上 ,遮住导航条)
- (void)showViewWithBeginDate:(NSDate *)beginDate endDate:(NSDate *)endDate{
    
    //默认日期
    NSCalendar *calendar = [NSCalendar calendarWithIdentifier:NSCalendarIdentifierGregorian];
    if (!beginDate) {
        beginDate = [NSDate date];
    }
    NSDateComponents *componentBegin = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:beginDate];
    _hourOneStr = [NSString stringWithFormat:@"%.2d",(int)componentBegin.hour];
    _minuteOneStr = [NSString stringWithFormat:@"%.2d",(int)componentBegin.minute];
    
    
    if (!endDate) {
        endDate = [NSDate date];
    }
    NSDateComponents *componentEnd = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:endDate];
    _hourTwoStr = [NSString stringWithFormat:@"%.2d",(int)componentEnd.hour];
    _minuteTwoStr = [NSString stringWithFormat:@"%.2d",(int)componentEnd.minute];
    
    [self initData];
    [self addSubViews];
    [self readLoadData];
    
    [UIView animateWithDuration:0.3 animations:^{
        CGFloat posY = XGScreenHeight - pickerViewH;
        self.bottomView.y = posY-80;
        self.pickerViewLeft.y = posY;
        self.pickerViewRight.y = posY;
    } completion:nil];
}
-(void)addSubViews{
    UIWindow * window = [UIApplication sharedApplication].windows[0];
    [window addSubview:self];
    [self addSubview:self.bottomView];
    
    [self addSubview:self.pickerViewLeft];
    [self addSubview:self.pickerViewRight];
    
    [self intTitleView];
}

-(void)intTitleView{
    self.buttonView.frame = CGRectMake(0, 0, ScreenWidth, 45);
    self.buttonView.backgroundColor = UIColorFromRGB(0xedeff4);
    [self.titleView addSubview:self.buttonView];
    
    self.titleView.frame = CGRectMake(0, 0, ScreenWidth, titleViewH);
    self.titleView.backgroundColor = [UIColor whiteColor];
    [self.bottomView addSubview:self.titleView];
    
    UIButton *canceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    canceBtn.frame = CGRectMake(15, 7.5, 60, 30);
    [canceBtn setTitle:@"取消" forState:UIControlStateNormal];
    canceBtn.backgroundColor=UIColorFromRGB(0xcccccc);
    canceBtn.titleLabel.font=[UIFont systemFontOfSize:15.0];
    [canceBtn addTarget:self action:@selector(canceBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    canceBtn.layer.cornerRadius = 3;
    canceBtn.layer.masksToBounds = YES;
    
    UIButton *sureBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [sureBtn setTitle:@"确定" forState:UIControlStateNormal];
    sureBtn.frame = CGRectMake(ScreenWidth-75, 7.5, 60, 30);
    sureBtn.backgroundColor= UIColorFromRGB(0x3ea5eb);
    sureBtn.titleLabel.font=[UIFont systemFontOfSize:15.0];
    sureBtn.layer.cornerRadius = 3;
    sureBtn.layer.masksToBounds = YES;
    [sureBtn addTarget:self action:@selector(sureBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.titleView addSubview:canceBtn];
    [self.titleView addSubview:sureBtn];
    
    UILabel *titleLB = [self labelWithCenterText:@"选择时间区间" color:UIColorFromRGB(0x333333) font:[UIFont systemFontOfSize:15.0]];
    titleLB.frame = CGRectMake(75, 0, ScreenWidth-150, 45);
    [self.titleView addSubview:titleLB];
    
    
    
    UILabel *leftLB = [self labelWithCenterText:@"开始时间" color:UIColorFromRGB(0x333333) font:[UIFont systemFontOfSize:15.0]];
    leftLB.frame = CGRectMake(0, 60, ScreenWidth/2, 20);
    UILabel *rightLB = [self labelWithCenterText:@"结束时间" color:UIColorFromRGB(0x333333) font:[UIFont systemFontOfSize:15.0]];
    rightLB.frame = CGRectMake(ScreenWidth/2, 60, ScreenWidth/2, 20);
    [self.bottomView addSubview:leftLB];
    [self.bottomView addSubview:rightLB];
}

//创建文字居中的lable(未设置frame)
-(UILabel *)labelWithCenterText:(NSString *)text color:(UIColor *)textcolor font:(UIFont *)font
{
    UILabel *label=[[UILabel alloc] init];
    label.textAlignment=NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.text=text;
    label.textColor=textcolor;
    label.font=font;
    [label sizeToFit];//宽高自适应文字
    return label;
}

-(void)readLoadData{
    
    //左侧
    //年
    NSInteger yearIndex1 = [self.hourOneArr indexOfObject:[NSString stringWithFormat:@"%@",_hourOneStr]];
    [self.pickerViewLeft selectRow:yearIndex1 inComponent:0 animated:NO];
    //月
    NSInteger monthIndex1 = [self.minuteOnehArr indexOfObject:[NSString stringWithFormat:@"%@",_minuteOneStr]];
    [self.pickerViewLeft selectRow:monthIndex1 inComponent:1 animated:NO];
    
    
    [self setupSelectTextColor:self.pickerViewLeft];
    
    
    //右侧
    //年
    NSInteger yearIndex2 = [self.hourTwoArr indexOfObject:[NSString stringWithFormat:@"%@",_hourTwoStr]];
    [self.pickerViewRight selectRow:yearIndex2 inComponent:0 animated:NO];
    //月
    NSInteger monthIndex2 = [self.minuteTwohArr indexOfObject:[NSString stringWithFormat:@"%@",_minuteTwoStr]];
    [self.pickerViewRight selectRow:monthIndex2 inComponent:1 animated:NO];
    
    [self setupSelectTextColor:self.pickerViewRight];
    
}

-(void)setupSelectTextColor:(UIPickerView *)pickerView{
    NSInteger rowZero,rowOne;
    rowZero  = [pickerView selectedRowInComponent:0];
    rowOne   = [pickerView selectedRowInComponent:1];
    
    //从选择的Row取得View
    UIView *viewZero,*viewOne;
    viewZero  = [pickerView viewForRow:rowZero   forComponent:0];
    viewOne   = [pickerView viewForRow:rowOne    forComponent:1];
    
    //从取得的View取得上面UILabel
    UILabel *labZero,*labOne;
    labZero  = (UILabel *)[viewZero   viewWithTag:1000];
    labOne   = (UILabel *)[viewOne    viewWithTag:1000];
    
    labZero.textColor = UIColorFromRGB(0x3ea5eb);
    labOne.textColor = UIColorFromRGB(0x3ea5eb);
    
}


#pragma mark UIPickerViewDataSource 数据源方法

// 选中行
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
    if (pickerView.tag == 2017072601) {
        
        NSInteger rowZero,rowOne;
        rowZero  = [pickerView selectedRowInComponent:0];
        rowOne   = [pickerView selectedRowInComponent:1];
        
        _hourOneStr = _hourOneArr[rowZero];
        _minuteOneStr = _minuteOnehArr[rowOne];
        
        [self.pickerViewLeft reloadAllComponents];
        
        NSLog(@"%@--%@",_hourOneStr,_minuteOneStr);
        
        [self setupSelectTextColor:self.pickerViewLeft];
        
        
        
    }else{
        //取得选择的Row
        NSInteger rowZero,rowOne;
        rowZero  = [pickerView selectedRowInComponent:0];
        rowOne   = [pickerView selectedRowInComponent:1];
        
        _hourTwoStr = _hourTwoArr[rowZero];
        _minuteTwoStr = _minuteTwohArr[rowOne];
        
        [self.pickerViewRight reloadAllComponents];
        
        
        NSLog(@"%@--%@",_hourTwoStr,_minuteTwoStr);
        
        [self setupSelectTextColor:self.pickerViewRight];
    }
    
}

// 返回多少列
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 2;
    
}

// 返回多少行
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerView.tag == 2017072601) {
        if (component==0) {//年
            return self.hourOneArr.count;
        }else{//月
            return self.minuteOnehArr.count;
        }
    }else{
        if (component==0) {//年
            return self.hourTwoArr.count;
        }else{//月
            return self.minuteTwohArr.count;
        }
    }
    
    
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view
{
    //设置分割线的颜色
    for(UIView *singleLine in pickerView.subviews)
    {
        if (singleLine.frame.size.height < 1)
        {
            singleLine.backgroundColor = UIColorFromRGB(0xDBDDE1);
        }
    }
    
    //设置文字的属性
    UILabel *genderLabel = [UILabel new];
    genderLabel.tag = 1000;
    genderLabel.textAlignment = NSTextAlignmentCenter;
    genderLabel.textColor = UIColorFromRGB(0x333333);
    if (pickerView.tag == 2017072601) {
        if (component==0) {//年
            genderLabel.text = self.hourOneArr[row];
        }else if(component==1){//月
            genderLabel.text =self.minuteOnehArr[row];
        }
    }else{
        if (component==0) {//年
            genderLabel.text = self.hourTwoArr[row];
        }else if(component==1){//月
            genderLabel.text = self.minuteTwohArr[row];
        }
    }
    
    return genderLabel;
}


#pragma mark UIPickerViewDelegate 代理方法
//row高度
- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component{
    return 40.0f;
}


- (void)initData{
    
    if(!_hourOneArr){
        _hourOneArr = [self hourArrayAction];
    }
    if(!_minuteOnehArr){
        _minuteOnehArr = [self minuteArrayAction];
    }
    
    
    
    if(!_hourTwoArr){
        _hourTwoArr = [self hourArrayAction];
    }
    if(!_minuteTwohArr){
        _minuteTwohArr = [self minuteArrayAction];
    }
    
    
}

//当前时间的时间戳
-(long int)cNowTimestamp{
    NSDate *newDate = [NSDate date];
    long int timeSp = (long)[newDate timeIntervalSince1970];
    return timeSp;
}

//时间戳——字符串时间
-(NSString *)cStringFromTimestamp:(NSString *)timestamp{
    NSDate *timeData = [NSDate dateWithTimeIntervalSince1970:[timestamp intValue]];
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
    //[dateFormatter setDateFormat:@"yyyy年M月d日 H:mm"];
    [dateFormatter setDateFormat:@"yyyy"];
    NSString *strTime = [dateFormatter stringFromDate:timeData];
    return strTime;
}

//当前月份
-(NSString *)cMontFromTimestamp:(NSString *)timestamp{
    NSDate *timeData = [NSDate dateWithTimeIntervalSince1970:[timestamp intValue]];
    NSDateFormatter *dateFormatter =[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM"];
    NSString *strTime = [dateFormatter stringFromDate:timeData];
    return strTime;
}

//年份范围
-(NSMutableArray *)hourArrayAction{
    NSMutableArray *tempArry = [[NSMutableArray alloc] init];
    for (int i = 0; i <= 23 ; i ++) {
        [tempArry addObject:[NSString stringWithFormat:@"%.2d",i]];
    }
    return tempArry;
}

-(NSMutableArray *)minuteArrayAction{
    NSMutableArray *tempArry = [[NSMutableArray alloc] init];
    for (int i = 0; i <= 59 ; i ++) {
        [tempArry addObject:[NSString stringWithFormat:@"%.2d",i]];
    }
    return tempArry;
}

/*************根据年月获取天数数组--end*******************/

- (UIView *)bottomView {
    if (!_bottomView) {
        _bottomView= [[UIView alloc] initWithFrame:CGRectMake(0, XGScreenHeight, XGScreenWidth, bottomViewH)];
        _bottomView.backgroundColor=[UIColor whiteColor];
    }
    return _bottomView;
}

- (UIPickerView *)pickerViewLeft {
    if (!_pickerViewLeft) {
        _pickerViewLeft = [[UIPickerView alloc] initWithFrame:CGRectMake(0.0, XGScreenHeight, XGScreenWidth/2-5, pickerViewH)];
        [_pickerViewLeft setDelegate:self];
        _pickerViewLeft.tag = 2017072601;
        _pickerViewLeft.backgroundColor=[UIColor whiteColor];
        _pickerViewLeft.dataSource=self;
    }
    return _pickerViewLeft;
}
- (UIPickerView *)pickerViewRight {
    if (!_pickerViewRight) {
        _pickerViewRight = [[UIPickerView alloc] initWithFrame:CGRectMake(XGScreenWidth/2+10, XGScreenHeight, XGScreenWidth/2-5, pickerViewH)];
        [_pickerViewRight setDelegate:self];
        _pickerViewRight.tag = 2017072602;
        _pickerViewRight.backgroundColor=[UIColor whiteColor];
        _pickerViewRight.dataSource=self;
    }
    return _pickerViewRight;
}

-(UIView *)buttonView{
    if (!_buttonView ) {
        _buttonView = [[UIView alloc] init];
    }
    return _buttonView;
}

-(UIView *)titleView{
    if (!_titleView ) {
        _titleView = [[UIView alloc] init];
    }
    return _titleView;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self dismissPickerView];
}

@end





