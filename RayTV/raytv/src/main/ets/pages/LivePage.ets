import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import LiveStreamService from '../service/live/LiveStreamService';
import display from '@ohos.display';
import { FlexAlign, FlexDirection, SliderStyle, HorizontalAlign, VerticalAlign, Alignment } from '@ohos.arkui';

/**
 * 直播界面 | Live page
 * 实现直播内容的播放、频道切换和播放设置 | Implement live content playback, channel switching and playback settings
 */
interface ChannelCategory {
  id: string;
  name: string;
}

interface Channel {
  id: string;
  name: string;
  url: string;
  categoryId: string;
}

@Entry
@Component
struct LivePage {
  private readonly TAG: string = 'LivePage';
  
  // 状态管理 | State management
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '加载直播内容失败';
  @State currentChannel: Channel | null = null;
  @State channelCategories: ChannelCategory[] = [];
  @State channels: Channel[] = [];
  @State selectedCategory: string = '全部';
  @State showLeftControl: boolean = false;
  @State showRightControl: boolean = false;
  @State showProgressBar: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State isLandscape: boolean = true;
  @State volume: number = 50;
  @State brightness: number = 80;
  @State playbackSpeed: number = 1.0;
  @State currentProgress: number = 0;
  @State totalDuration: number = 3600;
  @State controlAutoHideTimer: number = 0;
  
  // 服务实例 | Service instances
  private liveStreamService: LiveStreamService = LiveStreamService.getInstance();
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'LivePage about to appear');
    this.initScreenInfo();
    this.loadLiveContent();
  }
  
  aboutToDisappear() {
    if (this.controlAutoHideTimer) {
      clearTimeout(this.controlAutoHideTimer);
    }
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to get screen info: ${error}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  // 加载直播内容 | Load live content
  private async loadLiveContent() {
    try {
      this.isLoading = true;
      this.isError = false;
      Logger.info(this.TAG, 'Loading live content...');
      
      // 使用LiveStreamService获取真实数据
      const result = await this.liveStreamService.getLiveChannels();
      
      if (result.isSuccess() && result.data) {
        // 处理返回的数据
        this.channelCategories = result.data.categories || [
          { id: 'all', name: '全部' },
          { id: 'cctv', name: '央视' },
          { id: 'provincial', name: '卫视' },
          { id: 'sports', name: '体育' },
          { id: 'movie', name: '电影' },
          { id: 'entertainment', name: '娱乐' }
        ];
        
        this.channels = result.data.channels || [
          { id: '1', name: 'CCTV-1', url: 'http://example.com/live/cctv1', categoryId: 'cctv' },
          { id: '2', name: 'CCTV-2', url: 'http://example.com/live/cctv2', categoryId: 'cctv' },
          { id: '3', name: 'CCTV-3', url: 'http://example.com/live/cctv3', categoryId: 'cctv' },
          { id: '4', name: '湖南卫视', url: 'http://example.com/live/hunan', categoryId: 'provincial' },
          { id: '5', name: '江苏卫视', url: 'http://example.com/live/jiangsu', categoryId: 'provincial' },
          { id: '6', name: '浙江卫视', url: 'http://example.com/live/zhejiang', categoryId: 'provincial' },
          { id: '7', name: 'CCTV-5', url: 'http://example.com/live/cctv5', categoryId: 'sports' },
          { id: '8', name: 'CCTV-6', url: 'http://example.com/live/cctv6', categoryId: 'movie' }
        ];
        
        // 默认选择第一个频道 | Default select first channel
        if (this.channels.length > 0) {
          this.currentChannel = this.channels[0];
          this.playChannel(this.channels[0]);
        }
      } else {
        // 加载失败，设置错误状态 | Loading failed, set error state
        this.isError = true;
        this.errorMessage = result.message || '加载直播内容失败';
        Logger.warn(this.TAG, `Failed to load live content: ${this.errorMessage}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load live content: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = errorMsg;
    } finally {
      this.isLoading = false;
    }
  }
  
  // 播放频道 | Play channel
  private async playChannel(channel: Channel) {
    try {
      Logger.info(this.TAG, `Playing channel: ${channel.name}, URL: ${channel.url}`);
      const result = await this.liveStreamService.playChannel(channel);
      if (!result.isSuccess()) {
        Logger.error(this.TAG, `Failed to play channel: ${result.message}`);
        this.isError = true;
        this.errorMessage = result.message || '播放频道失败';
      }
    } catch (error) {
      Logger.error(this.TAG, `Error playing channel: ${error}`);
      this.isError = true;
      this.errorMessage = '播放频道失败';
    }
  }
  
  // 处理频道切换 | Handle channel switch
  private handleChannelSwitch(channel: Channel) {
    Logger.info(this.TAG, `Channel switched to: ${channel.name}`);
    this.currentChannel = channel;
    this.showLeftControl = false;
    this.playChannel(channel);
  }
  
  // 处理分类切换 | Handle category switch
  private handleCategorySwitch(categoryId: string) {
    this.selectedCategory = categoryId;
    Logger.info(this.TAG, `Category switched to: ${categoryId}`);
    // 这里可以根据分类筛选频道
  }
  
  // 处理屏幕点击 | Handle screen click
  private handleScreenClick(x: number, y: number) {
    Logger.info(this.TAG, `Screen clicked at: x=${x}, y=${y}`);
    
    // 左侧点击 | Left side click
    if (x < this.screenWidth * 0.3) {
      this.showLeftControl = !this.showLeftControl;
      this.showRightControl = false;
      this.showProgressBar = false;
      this.resetControlAutoHide();
    }
    // 右侧点击 | Right side click
    else if (x > this.screenWidth * 0.7) {
      this.showRightControl = !this.showRightControl;
      this.showLeftControl = false;
      this.showProgressBar = false;
      this.resetControlAutoHide();
    }
    // 中间点击 | Middle click
    else {
      this.showLeftControl = false;
      this.showRightControl = false;
      this.showProgressBar = false;
    }
  }
  
  // 处理屏幕长按 | Handle screen long press
  private handleScreenLongPress() {
    Logger.info(this.TAG, 'Screen long pressed');
    this.showProgressBar = !this.showProgressBar;
    this.showLeftControl = false;
    this.showRightControl = false;
    this.resetControlAutoHide();
  }
  
  // 重置控制自动隐藏 | Reset control auto hide
  private resetControlAutoHide() {
    if (this.controlAutoHideTimer) {
      clearTimeout(this.controlAutoHideTimer);
    }
    
    if (this.showLeftControl || this.showRightControl || this.showProgressBar) {
      this.controlAutoHideTimer = setTimeout(() => {
        this.showLeftControl = false;
        this.showRightControl = false;
        this.showProgressBar = false;
      }, 5000);
    }
  }
  
  // 处理音量调节 | Handle volume adjustment
  private handleVolumeChange(value: number) {
    this.volume = Math.max(0, Math.min(100, value));
    Logger.info(this.TAG, `Volume changed to: ${this.volume}`);
    // 这里可以调用系统API调节音量
    this.liveStreamService.setVolume(this.volume);
  }
  
  // 处理亮度调节 | Handle brightness adjustment
  private handleBrightnessChange(value: number) {
    this.brightness = Math.max(0, Math.min(100, value));
    Logger.info(this.TAG, `Brightness changed to: ${this.brightness}`);
    // 这里可以调用系统API调节亮度
    this.liveStreamService.setBrightness(this.brightness);
  }
  
  // 处理播放速度调节 | Handle playback speed adjustment
  private handlePlaybackSpeedChange(speed: number) {
    this.playbackSpeed = speed;
    Logger.info(this.TAG, `Playback speed changed to: ${this.playbackSpeed}`);
    // 这里可以调用播放器API调节播放速度
    this.liveStreamService.setPlaybackSpeed(speed);
  }
  
  // 处理进度调节 | Handle progress adjustment
  private handleProgressChange(value: number) {
    this.currentProgress = Math.max(0, Math.min(this.totalDuration, value));
    Logger.info(this.TAG, `Progress changed to: ${this.currentProgress}`);
    // 这里可以调用播放器API调节进度
    this.liveStreamService.seekTo(value);
  }
  
  // 处理返回 | Handle back
  private handleBack() {
    AppNavigator.getInstance().navigateToBack();
  }
  
  // 获取筛选后的频道 | Get filtered channels
  private getFilteredChannels(): Channel[] {
    if (this.selectedCategory === '全部') {
      return this.channels;
    }
    return this.channels.filter(channel => channel.categoryId === this.selectedCategory);
  }
  
  // 渲染左侧控制区 | Render left control area
  @Builder
  renderLeftControl() {
    if (!this.showLeftControl) return;
    
    Column() {
      // 分类列表 | Category list
      Column() {
        Text('频道分类')
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#FFFFFF')
          .margin({ bottom: 20 })
        
        ForEach(this.channelCategories, (category: ChannelCategory) => {
          Text(category.name)
            .fontSize(16)
            .fontWeight(this.selectedCategory === category.id ? 700 : 400)
            .fontColor(this.selectedCategory === category.id ? '#007AFF' : '#FFFFFF')
            .padding(12)
            .backgroundColor(this.selectedCategory === category.id ? 'rgba(0, 122, 255, 0.3)' : 'rgba(0, 0, 0, 0.5)')
            .borderRadius(12)
            .margin({ bottom: 12 })
            .onClick(() => this.handleCategorySwitch(category.id))
            .focusable(true)
            .focusBorderWidth(2)
            .focusBorderColor('#007AFF')
        }, (category: ChannelCategory) => category.id)
      }
      .padding(24)
      .backgroundColor('rgba(0, 0, 0, 0.7)')
      .borderRadius(16)
      .margin({ bottom: 24 })
      
      // 频道列表 | Channel list
      Column() {
        Text('频道列表')
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#FFFFFF')
          .margin({ bottom: 20 })
        
        Scroll() {
          Column() {
            ForEach(this.getFilteredChannels(), (channel: Channel) => {
              Text(channel.name)
                .fontSize(16)
                .fontWeight(this.currentChannel?.id === channel.id ? 700 : 400)
                .fontColor(this.currentChannel?.id === channel.id ? '#007AFF' : '#FFFFFF')
                .padding(14)
                .backgroundColor(this.currentChannel?.id === channel.id ? 'rgba(0, 122, 255, 0.3)' : 'rgba(0, 0, 0, 0.5)')
                .borderRadius(12)
                .margin({ bottom: 12 })
                .onClick(() => this.handleChannelSwitch(channel))
                .focusable(true)
                .focusBorderWidth(2)
                .focusBorderColor('#007AFF')
            }, (channel: Channel) => channel.id)
          }
          .padding(4)
        }
      }
      .padding(24)
      .backgroundColor('rgba(0, 0, 0, 0.7)')
      .borderRadius(16)
      .height('60%')
    }
    .width('35%')
    .height('100%')
    .padding(24)
    .alignItems(HorizontalAlign.Start)
  }
  
  // 渲染右侧控制区 | Render right control area
  @Builder
  renderRightControl() {
    if (!this.showRightControl) return;
    
    Column() {
      // 播放设置 | Playback settings
      Column() {
        Text('播放设置')
          .fontSize(18)
          .fontWeight(700)
          .fontColor('#FFFFFF')
          .margin({ bottom: 24 })
        
        // 音量调节 | Volume adjustment
        Column() {
          Text(`音量: ${this.volume}%`)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ bottom: 12 })
          
          Row() {
            Text('0')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ right: 12 })
            
            Slider({
              value: this.volume,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
            .width('80%')
            .blockColor('#007AFF')
            .trackColor('#FFFFFF')
            .selectedColor('#007AFF')
            .onChange((value: number) => this.handleVolumeChange(value))
            
            Text('100')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ left: 12 })
          }
        }
        .margin({ bottom: 24 })
        
        // 亮度调节 | Brightness adjustment
        Column() {
          Text(`亮度: ${this.brightness}%`)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ bottom: 12 })
          
          Row() {
            Text('0')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ right: 12 })
            
            Slider({
              value: this.brightness,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
            .width('80%')
            .blockColor('#007AFF')
            .trackColor('#FFFFFF')
            .selectedColor('#007AFF')
            .onChange((value: number) => this.handleBrightnessChange(value))
            
            Text('100')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .margin({ left: 12 })
          }
        }
        .margin({ bottom: 24 })
        
        // 播放速度调节 | Playback speed adjustment
        Column() {
          Text(`播放速度: ${this.playbackSpeed}x`)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ bottom: 12 })
          
          Row() {
            Button('0.5x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 0.5 ? '#007AFF' : 'rgba(255, 255, 255, 0.3)')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .margin({ right: 12 })
              .onClick(() => this.handlePlaybackSpeedChange(0.5))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#007AFF')
            
            Button('1.0x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 1.0 ? '#007AFF' : 'rgba(255, 255, 255, 0.3)')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .margin({ right: 12 })
              .onClick(() => this.handlePlaybackSpeedChange(1.0))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#007AFF')
            
            Button('1.5x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 1.5 ? '#007AFF' : 'rgba(255, 255, 255, 0.3)')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .margin({ right: 12 })
              .onClick(() => this.handlePlaybackSpeedChange(1.5))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#007AFF')
            
            Button('2.0x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 2.0 ? '#007AFF' : 'rgba(255, 255, 255, 0.3)')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .onClick(() => this.handlePlaybackSpeedChange(2.0))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor('#007AFF')
          }
        }
      }
      .padding(24)
      .backgroundColor('rgba(0, 0, 0, 0.7)')
      .borderRadius(16)
    }
    .width('35%')
    .height('100%')
    .padding(24)
    .alignItems(HorizontalAlign.End)
  }
  
  // 渲染进度条 | Render progress bar
  @Builder
  renderProgressBar() {
    if (!this.showProgressBar) return;
    
    Column() {
      Row() {
        Text(this.formatTime(this.currentProgress))
          .fontSize(16)
          .fontColor('#FFFFFF')
          .margin({ right: 24 })
        
        Slider({
          value: this.currentProgress,
          min: 0,
          max: this.totalDuration,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('80%')
        .blockColor('#007AFF')
        .trackColor('#FFFFFF')
        .selectedColor('#007AFF')
        .onChange((value: number) => this.handleProgressChange(value))
        
        Text(this.formatTime(this.totalDuration))
          .fontSize(16)
          .fontColor('#FFFFFF')
          .margin({ left: 24 })
      }
    }
    .width('100%')
    .padding(30)
    .position({ y: this.screenHeight * 0.8 })
  }
  
  // 渲染加载状态 | Render loading state
  @Builder
  renderLoading() {
    Column() {
      Text('正在加载直播内容...')
        .fontSize(18)
        .fontColor('#FFFFFF')
        .margin(30)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.8)')
  }
  
  // 渲染错误状态 | Render error state
  @Builder
  renderError() {
    Column() {
      Text('加载失败')
        .fontSize(20)
        .fontColor('#FF5252')
        .margin({ bottom: 12 })
      
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .margin({ bottom: 24 })
      
      Button('重试')
        .backgroundColor('#007AFF')
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .padding({ left: 24, right: 24, top: 12, bottom: 12 })
        .onClick(() => this.loadLiveContent())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor('#007AFF')
      
      Button('返回')
        .backgroundColor('#444444')
        .fontColor('#FFFFFF')
        .borderRadius(12)
        .padding({ left: 24, right: 24, top: 12, bottom: 12 })
        .margin({ top: 16 })
        .onClick(() => this.handleBack())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor('#007AFF')
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.8)')
  }
  
  // 格式化时间 | Format time
  private formatTime(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }
  
  build() {
    Column() {
      // 直播播放区域 | Live playback area
      Stack({
        alignContent: Alignment.Center
      }) {
        // 背景 | Background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#000000')
          .onClick((event) => this.handleScreenClick(event.touches[0].x, event.touches[0].y))
          .onLongPress(() => this.handleScreenLongPress())
        
        // 直播内容 | Live content
        if (this.isLoading) {
          this.renderLoading();
        } else if (this.isError) {
          this.renderError();
        } else if (this.currentChannel) {
          Column() {
            // 这里应该使用Video组件播放直播内容
            // 由于是模拟，使用占位符
            Text(`正在播放: ${this.currentChannel.name}`)
              .fontSize(24)
              .fontColor('#FFFFFF')
              .margin(30)
            
            Text('直播内容播放区域')
              .fontSize(18)
              .fontColor('rgba(255, 255, 255, 0.7)')
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .height('100%')
        }
        
        // 左侧控制区 | Left control area
        this.renderLeftControl()
        
        // 右侧控制区 | Right control area
        this.renderRightControl()
        
        // 进度条 | Progress bar
        this.renderProgressBar()
        
        // 返回按钮 | Back button
        Button('返回')
          .position({ top: 40, left: 40 })
          .backgroundColor('rgba(0, 0, 0, 0.6)')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .padding({ left: 20, right: 20, top: 10, bottom: 10 })
          .onClick(() => this.handleBack())
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor('#007AFF')
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
}
