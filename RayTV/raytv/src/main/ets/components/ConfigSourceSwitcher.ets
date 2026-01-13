import { LineManager, LineItem } from '../service/config/LineManager';
import Logger from '../common/util/Logger';
import display from '@ohos.display';
import { FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign } from '@ohos/arkui';

const TAG = 'ConfigSourceSwitcher';

// 配置源切换器组件 | Config source switcher component
@Entry
@Component
struct ConfigSourceSwitcher {
  private readonly lineManager: LineManager = LineManager.getInstance();
  private lines: LineItem[] = [];
  private currentLineId: string = '';
  private isLoading: boolean = true;
  private isError: boolean = false;
  private errorMessage: string = '';
  private isLandscape: boolean = false;
  private screenWidth: number = 0;
  private screenHeight: number = 0;
  private popupWidth: number = 0;
  private popupHeight: number = 0;
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(TAG, 'ConfigSourceSwitcher about to appear');
    this.initScreenInfo();
    this.loadLines();
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      
      // 计算弹窗大小 | Calculate popup size
      if (this.isLandscape) {
        this.popupWidth = Math.min(800, this.screenWidth * 0.7);
        this.popupHeight = Math.min(600, this.screenHeight * 0.8);
      } else {
        this.popupWidth = Math.min(400, this.screenWidth * 0.9);
        this.popupHeight = Math.min(500, this.screenHeight * 0.7);
      }
      
      Logger.info(TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}, popupSize=${this.popupWidth}x${this.popupHeight}`);
    } catch (error) {
      Logger.error(TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
      this.popupWidth = 800;
      this.popupHeight = 600;
    }
  }
  
  // 加载线路列表 | Load lines
  private async loadLines() {
    try {
      this.isLoading = true;
      this.isError = false;
      
      // 初始化线路管理器 | Initialize line manager
      await this.lineManager.initialize();
      
      // 获取所有线路 | Get all lines
      this.lines = this.lineManager.getAllLines();
      
      // 获取当前线路 | Get current line
      const currentLine = this.lineManager.getCurrentLine();
      this.currentLineId = currentLine?.id || '';
      
      Logger.info(TAG, `Loaded ${this.lines.length} lines, current line: ${this.currentLineId}`);
    } catch (error) {
      Logger.error(TAG, `Failed to load lines: ${error}`);
      this.isError = true;
      this.errorMessage = `加载线路失败: ${error instanceof Error ? error.message : String(error)}`;
    } finally {
      this.isLoading = false;
    }
  }
  
  // 处理线路切换 | Handle line switch
  private async handleLineSwitch(lineId: string) {
    try {
      Logger.info(TAG, `Switching to line: ${lineId}`);
      
      // 调用线路管理器切换线路 | Call line manager to switch line
      const result = await this.lineManager.switchToLine(lineId);
      
      if (result.success) {
        // 更新当前线路 | Update current line
        this.currentLineId = lineId;
        Logger.info(TAG, `Successfully switched to line: ${lineId}`);
      } else {
        Logger.error(TAG, `Failed to switch line: ${result.message}`);
        this.isError = true;
        this.errorMessage = result.message || '切换线路失败';
      }
    } catch (error) {
      Logger.error(TAG, `Failed to switch line: ${error}`);
      this.isError = true;
      this.errorMessage = `切换线路失败: ${error instanceof Error ? error.message : String(error)}`;
    }
  }
  
  // 处理关闭弹窗 | Handle close popup
  private handleClose() {
    // 这里应该调用关闭弹窗的逻辑 | Should call close popup logic here
    Logger.info(TAG, 'Closing config source switcher');
  }
  
  // 渲染线路项 | Render line item
  @Builder
  renderLineItem(line: LineItem) {
    const isCurrent = line.id === this.currentLineId;
    
    Column() {
      Row() {
        // 线路名称 | Line name
        Text(line.name)
          .fontSize(this.isLandscape ? 20 : 18)
          .fontWeight(isCurrent ? 700 : 500)
          .fontColor(isCurrent ? '#FFFFFF' : '#333333')
          .flexGrow(1)
          .margin({ right: 20 })
        
        // 源数量 | Source count
        Text(`${line.sourceCount} 个源`)
          .fontSize(this.isLandscape ? 16 : 14)
          .fontColor(isCurrent ? '#E0E0E0' : '#666666')
          .margin({ right: 20 })
        
        // 响应时间 | Response time
        if (line.responseTime) {
          Text(`${line.responseTime}ms`)
            .fontSize(this.isLandscape ? 16 : 14)
            .fontColor(isCurrent ? '#E0E0E0' : '#666666')
            .margin({ right: 20 })
        }
        
        // 当前线路标识 | Current line indicator
        if (isCurrent) {
          Text('当前')
            .fontSize(this.isLandscape ? 16 : 14)
            .fontColor('#FFEB3B')
            .fontWeight(600)
        }
      }
      .width('100%')
      .padding({ top: 15, bottom: 15, left: 20, right: 20 })
      
      // 线路描述 | Line description
      if (line.description) {
        Text(line.description)
          .fontSize(this.isLandscape ? 14 : 12)
          .fontColor(isCurrent ? '#E0E0E0' : '#999999')
          .margin({ left: 20, right: 20, bottom: 10 })
          .maxLines(2)
      }
      
      // 线路URL | Line URL
      Text(line.url)
        .fontSize(this.isLandscape ? 14 : 12)
        .fontColor(isCurrent ? '#E0E0E0' : '#999999')
        .margin({ left: 20, right: 20, bottom: 15 })
        .maxLines(1)
    }
    .width('100%')
    .backgroundColor(isCurrent ? '#4CAF50' : '#FFFFFF')
    .borderRadius(12)
    .margin({ bottom: 15 })
    .shadow({ 
      radius: isCurrent ? 8 : 4, 
      color: isCurrent ? 'rgba(76, 175, 80, 0.3)' : 'rgba(0, 0, 0, 0.1)', 
      offsetY: 4 
    })
    .onClick(() => this.handleLineSwitch(line.id))
    .focusable(true)
    .onFocus(() => {
      Logger.info(TAG, `Line item focused: ${line.name}`);
    })
  }
  
  // 渲染加载状态 | Render loading state
  @Builder
  renderLoading() {
    Column() {
      Text('加载中...')
        .fontSize(20)
        .fontColor('#666666')
        .margin(40)
        .fontWeight(500)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(this.popupHeight - 120)
  }
  
  // 渲染错误状态 | Render error state
  @Builder
  renderError() {
    Column() {
      Text('加载失败')
        .fontSize(20)
        .fontColor('#FF5252')
        .margin({ top: 20 })
        .fontWeight(600)
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#FF9800')
        .margin({ top: 10, left: 30, right: 30 })
        .textAlign(TextAlign.Center)
      Button('重试')
        .onClick(() => this.loadLines())
        .backgroundColor('#4CAF50')
        .fontColor('white')
        .borderRadius(8)
        .padding({ left: 30, right: 30, top: 10, bottom: 10 })
        .margin({ top: 20 })
        .fontSize(16)
        .fontWeight(500)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(this.popupHeight - 120)
  }
  
  // 渲染空状态 | Render empty state
  @Builder
  renderEmpty() {
    Column() {
      Text('暂无配置线路')
        .fontSize(20)
        .fontColor('#999999')
        .margin({ top: 20 })
        .fontWeight(500)
      Text('请先添加配置源线路')
        .fontSize(16)
        .fontColor('#CCCCCC')
        .margin({ top: 10, left: 30, right: 30 })
        .textAlign(TextAlign.Center)
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(this.popupHeight - 120)
  }
  
  // 渲染线路列表 | Render line list
  @Builder
  renderLineList() {
    if (this.isLoading) {
      this.renderLoading();
    } else if (this.isError) {
      this.renderError();
    } else if (this.lines.length === 0) {
      this.renderEmpty();
    } else {
      Column() {
        ForEach(this.lines, (line: LineItem) => {
          this.renderLineItem(line);
        }, (line: LineItem) => line.id)
      }
      .width('100%')
      .padding({ top: 20, bottom: 20, left: 20, right: 20 })
    }
  }
  
  build() {
    Column() {
      // 弹窗标题 | Popup title
      Row() {
        Text('切换配置源')
          .fontSize(this.isLandscape ? 24 : 20)
          .fontWeight(700)
          .fontColor('#333333')
          .flexGrow(1)
          .textAlign(TextAlign.Center)
        
        // 关闭按钮 | Close button
        Button() {
          Text('×')
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .width(40)
        .height(40)
        .backgroundColor('#9E9E9E')
        .borderRadius(20)
        .margin({ right: 20 })
        .onClick(() => this.handleClose())
        .focusable(true)
        .onFocus(() => {
          Logger.info(TAG, 'Close button focused');
        })
      }
      .width('100%')
      .height(80)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderBottomWidth(2)
      .borderBottomColor('#E0E0E0')
      
      // 线路列表 | Line list
      this.renderLineList()
      
      // 提示信息 | Tips
      if (!this.isLoading && !this.isError && this.lines.length > 0) {
        Text('点击线路切换配置源，当前线路会高亮显示')
          .fontSize(this.isLandscape ? 14 : 12)
          .fontColor('#999999')
          .textAlign(TextAlign.Center)
          .margin({ bottom: 20 })
      }
    }
    .width(this.popupWidth)
    .height(this.popupHeight)
    .backgroundColor('#FFFFFF')
    .borderRadius(20)
    .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.3)', offsetY: 10 })
    .position({
      x: (this.screenWidth - this.popupWidth) / 2,
      y: (this.screenHeight - this.popupHeight) / 2
    })
  }
}

export default ConfigSourceSwitcher;