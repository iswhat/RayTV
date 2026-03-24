import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ContentAccessService from '../service/content/ContentAccessService';
import LivePlaybackService, { LivePlaybackStatus } from '../service/live/LivePlaybackService';
import { LiveChannelWithSource, LiveCategory } from '../service/live/LiveChannelTypes';
import EventBusUtil from '../common/util/EventBusUtil';
import display from '@ohos.display';
import VirtualList from '../components/VirtualList';
import { VirtualListItem } from '../types/VirtualListTypes';
import ContentSourceBadge from '../components/ContentSourceBadge';
import DesignSystem from '../design/DesignSystem';
import AnimationSystem from '../design/AnimationSystem';
import ThemeProvider, { Theme } from '../design/ThemeProvider';
import { Video, ImageFit } from '@ohos.multimedia.media';
import Strings from '../common/resources/Strings';


/**
 * 直播界面 | Live page
 * 实现直播内容的播放、频道切换和播放设置 | Implement live content playback, channel switching and playback settings
 */

@Entry
@Component
struct LivePage {
  private readonly TAG: string = 'LivePage';
  private contentService: ContentAccessService = ContentAccessService.getInstance();
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '';
  @State errorActionText: string = '';
  @State errorActionHandler: (() => void) | undefined = undefined;
  @State currentChannel: LiveChannelWithSource | null = null;
  @State channelCategories: ChannelCategory[] = [];
  @State channels: LiveChannelWithSource[] = [];
  @State selectedCategory: string = 'all';
  @State showLeftControl: boolean = false;
  @State showRightControl: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State isLandscape: boolean = true;
  @State volume: number = 50;
  @State brightness: number = 80;
  @State playbackSpeed: number = 1.0;
  @State controlAutoHideTimer: number = 0;
  @State currentTheme: Theme = ThemeProvider.getCurrentTheme();
  @State showQuickChannelSwitcher: boolean = false;
  @State recentChannels: LiveChannelWithSource[] = [];
  @State playbackStatus: LivePlaybackStatus = LivePlaybackStatus.IDLE;
  @State isReconnecting: boolean = false;
  @State reconnectAttempt: number = 0;
  
  // 服务实例 | Service instances
  private livePlaybackService: LivePlaybackService = LivePlaybackService.getInstance();
  private eventBus: EventBusUtil = EventBusUtil.getInstance();
  // 主题变更监听器，需要保存引用以便移除 | Theme change listener reference for proper cleanup
  private themeChangeListener: ((theme: Theme) => void) | null = null;
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'LivePage about to appear');
    // 添加主题变更监听器
    this.themeChangeListener = (theme) => {
      this.currentTheme = theme;
    };
    ThemeProvider.addThemeChangeListener(this.themeChangeListener);
    this.initScreenInfo();
    this.initServices();
    this.loadLiveContent();
  }
  
  // 初始化服务 | Initialize services
  private initServices() {
    try {
      // 初始化LivePlaybackService
      this.livePlaybackService.initialize();
      Logger.info(this.TAG, 'LivePlaybackService initialized successfully');
      
      // 监听播放状态变化
      this.eventBus.on('live:statusChanged', (data: Record<string, Object>) => {
        if (data.status) {
          this.handlePlaybackStatusChange(data.status as LivePlaybackStatus);
        }
      });
      
      // 监听错误事件
      this.eventBus.on('live:error', (data: Record<string, Object>) => {
        if (data.error) {
          const error = data.error as { code: number; message: string };
          this.handlePlaybackError(error);
        }
      });
      
      // 监听重连事件
      this.eventBus.on('live:reconnecting', (data: Record<string, Object>) => {
        const attempt = data.attempt as number;
        Logger.info(this.TAG, `Reconnecting... Attempt ${attempt}`);
        this.isReconnecting = true;
        this.reconnectAttempt = attempt;
      });
      
      this.eventBus.on('live:reconnected', () => {
        Logger.info(this.TAG, 'Reconnected successfully');
        this.isReconnecting = false;
        this.reconnectAttempt = 0;
      });
      
    } catch (error) {
      Logger.error(this.TAG, 'Failed to initialize LivePlaybackService', error as Error);
    }
  }
  
  aboutToDisappear() {
    if (this.controlAutoHideTimer) {
      clearTimeout(this.controlAutoHideTimer);
      this.controlAutoHideTimer = 0;
    }
    
    // 停止播放
    this.livePlaybackService.stop();
    
    // 移除事件监听
    this.eventBus.off('live:statusChanged');
    this.eventBus.off('live:error');
    this.eventBus.off('live:reconnecting');
    this.eventBus.off('live:reconnected');
    
    // 移除主题监听器
    if (this.themeChangeListener) {
      ThemeProvider.removeThemeChangeListener(this.themeChangeListener);
      this.themeChangeListener = null;
    }
  }
  
  // 处理播放状态变化
  private handlePlaybackStatusChange(status: LivePlaybackStatus): void {
    this.playbackStatus = status;
    switch (status) {
      case LivePlaybackStatus.CONNECTING:
        Logger.info(this.TAG, 'Connecting to live stream...');
        break;
      case LivePlaybackStatus.PLAYING:
        Logger.info(this.TAG, 'Live stream playing');
        break;
      case LivePlaybackStatus.BUFFERING:
        Logger.info(this.TAG, 'Live stream buffering...');
        break;
      case LivePlaybackStatus.ERROR:
        Logger.error(this.TAG, 'Live stream error');
        break;
      case LivePlaybackStatus.STOPPED:
        Logger.info(this.TAG, 'Live stream stopped');
        break;
      default:
        break;
    }
  }
  
  // 处理播放错误
  private handlePlaybackError(error: { code: number; message: string }): void {
    this.isError = true;
    
    // 根据错误类型提供不同的处理建议
    let errorMessage = '';
    let actionText = '';
    let actionHandler: (() => void) | undefined;
    
    switch (error.code) {
      case 404:
      case 403:
      case 401:
        errorMessage = `源地址失效或权限不足: ${error.message}`;
        actionText = '切换线路';
        actionHandler = () => this.switchToNextParseLine();
        break;
        
      case -1: // 网络错误
      case -2: // 连接超时
        errorMessage = `网络连接失败: ${error.message}`;
        actionText = '重试连接';
        actionHandler = () => this.retryCurrentChannel();
        break;
        
      case -3: // 解码错误
        errorMessage = `视频解码失败: ${error.message}`;
        actionText = '切换源';
        actionHandler = () => this.switchSource();
        break;
        
      default:
        errorMessage = `播放错误: ${error.message} (错误码: ${error.code})`;
        actionText = '重试';
        actionHandler = () => this.retryCurrentChannel();
    }
    
    this.errorMessage = errorMessage;
    this.errorActionText = actionText;
    this.errorActionHandler = actionHandler;
    
    Logger.error(this.TAG, `Playback error: ${error.code} - ${error.message}`);
    
    // 错误上报 | Report error
    this.reportError(error);
  }
  
  // 错误上报 | Report error
  private reportError(error: { code: number; message: string }): void {
    try {
      const errorData = {
        code: error.code,
        message: error.message,
        channel: this.currentChannel?.name,
        source: this.currentChannel?.sourceName,
        timestamp: Date.now()
      };
      
      // 这里可以实现错误上报逻辑
      Logger.warn(this.TAG, `Error reported: ${JSON.stringify(errorData)}`);
    } catch (reportError) {
      Logger.warn(this.TAG, 'Failed to report error');
    }
  }

  // 重试当前频道 | Retry current channel
  private async retryCurrentChannel(): Promise<void> {
    if (this.currentChannel) {
      this.isError = false;
      this.errorMessage = '';
      this.errorActionText = '';
      this.errorActionHandler = undefined;
      await this.playChannel(this.currentChannel);
    }
  }

  // 切换到下一条解析线路 | Switch to next parse line
  private async switchToNextParseLine(): Promise<void> {
    // 这里可以实现切换解析线路的逻辑
    // 暂时先重试当前频道
    await this.retryCurrentChannel();
  }

  // 切换源 | Switch source
  private async switchSource(): Promise<void> {
    // 这里可以实现切换源的逻辑
    // 暂时先重试当前频道
    await this.retryCurrentChannel();
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
      Logger.info(this.TAG, Strings.livePage.loading);
      
      // 从ContentAccessService获取直播数据
      const allChannels = this.contentService.getAllLiveChannels();
      
      if (allChannels && allChannels.length > 0) {
        // 提取分类 | Extract categories
        const categoriesSet = new Set<string>();
        
        allChannels.forEach(channel => {
          if (channel.group) {
            categoriesSet.add(channel.group);
          }
        });
        
        this.channelCategories = [
          { id: 'all', name: '全部' },
          ...Array.from(categoriesSet).map(cat => ({ id: cat, name: cat }))
        ];
        
        this.channels = allChannels;
        
        // 默认选择第一个频道 | Default select first channel
        if (this.channels.length > 0) {
          this.currentChannel = this.channels[0];
          this.addToRecentChannels(this.channels[0]);
          this.playChannel(this.channels[0]);
        }
      } else {
        // 无直播数据 | No live data
        this.isError = true;
        this.errorMessage = Strings.livePage.noData;
        Logger.warn(this.TAG, Strings.livePage.noData);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load live content: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = `加载失败: ${errorMsg}`;
    } finally {
      this.isLoading = false;
    }
  }
  
  // 添加到最近频道 | Add to recent channels
  private addToRecentChannels(channel: LiveChannelWithSource) {
    // 移除已存在的相同频道
    this.recentChannels = this.recentChannels.filter(c => c.id !== channel.id || c.sourceId !== channel.sourceId);
    // 添加到开头
    this.recentChannels.unshift(channel);
    // 限制最近频道数量
    if (this.recentChannels.length > 10) {
      this.recentChannels = this.recentChannels.slice(0, 10);
    }
  }
  
  // 播放频道 | Play channel
  private async playChannel(channel: LiveChannelWithSource) {
    try {
      Logger.info(this.TAG, `Playing channel: ${channel.name}, URL: ${channel.url}, Source: ${channel.sourceName}`);
      
      // 清除错误状态
      this.isError = false;
      this.errorMessage = '';
      
      // 播放频道
      const success = await this.livePlaybackService.playChannel(channel);
      
      if (success) {
        this.currentChannel = channel;
        this.addToRecentChannels(channel);
        Logger.info(this.TAG, `Channel ${channel.name} started successfully`);
      } else {
        Logger.error(this.TAG, `Failed to start channel ${channel.name}`);
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to play channel: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = `播放失败: ${errorMsg}`;
    }
  }
  
  // 处理频道切换 | Handle channel switch
  private handleChannelSwitch(channel: LiveChannelWithSource) {
    Logger.info(this.TAG, `Channel switched to: ${channel.name}, Source: ${channel.sourceName}`);
    this.currentChannel = channel;
    this.addToRecentChannels(channel);
    this.showLeftControl = false;
    this.showQuickChannelSwitcher = false;
    this.playChannel(channel);
  }
  
  // 处理分类切换 | Handle category switch
  private handleCategorySwitch(categoryId: string) {
    this.selectedCategory = categoryId;
    Logger.info(this.TAG, `Category switched to: ${categoryId}`);
  }
  
  // 处理屏幕点击 | Handle screen click
  private handleScreenClick(x: number, y: number) {
    Logger.info(this.TAG, `Screen clicked at: x=${x}, y=${y}`);
    
    // 左侧点击 | Left side click
    if (x < this.screenWidth * 0.3) {
      this.showLeftControl = !this.showLeftControl;
      this.showRightControl = false;
      this.showQuickChannelSwitcher = false;
      this.resetControlAutoHide();
    }
    // 右侧点击 | Right side click
    else if (x > this.screenWidth * 0.7) {
      this.showRightControl = !this.showRightControl;
      this.showLeftControl = false;
      this.showQuickChannelSwitcher = false;
      this.resetControlAutoHide();
    }
    // 底部点击 | Bottom click
    else if (y > this.screenHeight * 0.8) {
      this.showQuickChannelSwitcher = !this.showQuickChannelSwitcher;
      this.showLeftControl = false;
      this.showRightControl = false;
      this.resetControlAutoHide();
    }
    // 中间点击 | Middle click
    else {
      this.showLeftControl = false;
      this.showRightControl = false;
      this.showQuickChannelSwitcher = false;
    }
  }
  
  // 处理屏幕长按 | Handle screen long press
  private handleScreenLongPress() {
    Logger.info(this.TAG, 'Screen long pressed - live stream does not support seeking, progress bar hidden');
    // 直播流不支持 seek 操作，长按不应显示进度条
    // 改为显示/隐藏快速频道切换器
    this.showQuickChannelSwitcher = !this.showQuickChannelSwitcher;
    this.showLeftControl = false;
    this.showRightControl = false;
    this.showProgressBar = false; // 始终不显示进度条
    this.resetControlAutoHide();
  }
  
  // 重置控制自动隐藏 | Reset control auto hide
  private resetControlAutoHide() {
    if (this.controlAutoHideTimer) {
      clearTimeout(this.controlAutoHideTimer);
    }
    
    if (this.showLeftControl || this.showRightControl || this.showQuickChannelSwitcher) {
      this.controlAutoHideTimer = setTimeout(() => {
        this.showLeftControl = false;
        this.showRightControl = false;
        this.showQuickChannelSwitcher = false;
      }, 5000);
    }
  }
  
  // 处理音量调节 | Handle volume adjustment
  private handleVolumeChange(value: number) {
    this.volume = Math.max(0, Math.min(100, value));
    Logger.info(this.TAG, `Volume changed to: ${this.volume}`);
    this.livePlaybackService.setVolume(this.volume / 100);
  }
  
  // 增加音量 | Increase volume
  private increaseVolume(): void {
    const newVolume = Math.min(100, this.volume + 5);
    this.setVolume(newVolume);
  }
  
  // 减少音量 | Decrease volume
  private decreaseVolume(): void {
    const newVolume = Math.max(0, this.volume - 5);
    this.setVolume(newVolume);
  }
  
  // 设置音量 | Set volume
  private setVolume(volume: number): void {
    this.volume = volume;
    this.livePlaybackService.setVolume(volume / 100);
    Logger.debug(this.TAG, `Volume set to ${volume}%`);
  }
  
  // 切换静音 | Toggle mute
  private toggleMute(): void {
    const currentVolume = this.livePlaybackService.getVolume();
    if (currentVolume > 0) {
      this.livePlaybackService.setVolume(0);
      this.volume = 0;
    } else {
      this.livePlaybackService.setVolume(0.5);
      this.volume = 50;
    }
  }
  
  // 处理亮度调节 | Handle brightness adjustment
  private handleBrightnessChange(value: number) {
    this.brightness = Math.max(0, Math.min(100, value));
    Logger.info(this.TAG, `Brightness changed to: ${this.brightness}`);
  }
  
  // 处理播放速度调节 | Handle playback speed adjustment
  private handlePlaybackSpeedChange(speed: number) {
    this.playbackSpeed = speed;
    Logger.info(this.TAG, `Playback speed changed to: ${this.playbackSpeed}`);
  }
  
  // 切换到下一个频道 | Switch to next channel
  private async switchToNextChannel(): Promise<void> {
    const success = await this.livePlaybackService.switchToNextChannel();
    if (success) {
      const newChannel = this.livePlaybackService.getCurrentChannel();
      if (newChannel) {
        this.currentChannel = newChannel;
      }
    }
  }
  
  // 切换到上一个频道 | Switch to previous channel
  private async switchToPreviousChannel(): Promise<void> {
    const success = await this.livePlaybackService.switchToPreviousChannel();
    if (success) {
      const newChannel = this.livePlaybackService.getCurrentChannel();
      if (newChannel) {
        this.currentChannel = newChannel;
      }
    }
  }
  

  
  // 处理返回 | Handle back
  private handleBack() {
    AppNavigator.getInstance().navigateToBack();
  }
  
  // 获取筛选后的频道 | Get filtered channels
  private getFilteredChannels(): LiveChannelWithSource[] {
    if (this.selectedCategory === 'all') {
      return this.channels;
    }
    return this.channels.filter(channel => channel.group === this.selectedCategory);
  }
  
  // 渲染左侧控制区 | Render left control area
  @Builder
  renderLeftControl() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    if (!this.showLeftControl) return;
    
    Column() {
      // 分类列表 | Category list
      Column() {
        Text('频道分类')
          .fontSize(18)
          .fontWeight(700)
          .fontColor(colors.text)
          .margin({ bottom: spacing.lg })
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
        
        ForEach(this.channelCategories, (category: ChannelCategory) => {
          Text(category.name)
            .fontSize(16)
            .fontWeight(this.selectedCategory === category.id ? 700 : 400)
            .fontColor(this.selectedCategory === category.id ? colors.primary : colors.text)
            .padding(spacing.md)
            .backgroundColor(this.selectedCategory === category.id ? `${colors.primary}20` : colors.surface)
            .borderRadius(borderRadius.md)
            .margin({ bottom: spacing.sm })
            .onClick(() => this.handleCategorySwitch(category.id))
            .focusable(true)
            .focusBorderWidth(2)
            .focusBorderColor(colors.primary)
            .animation({
              duration: 300,
              timingFunction: 'ease-out'
            })
        }, (category: ChannelCategory) => category.id)
      }
      .padding(spacing.lg)
      .backgroundColor(colors.surface)
      .borderRadius(borderRadius.lg)
      .margin({ bottom: spacing.lg })
      .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 8 })
      .animation({
        duration: 400,
        timingFunction: 'ease-out'
      })
      
      // 频道列表 | Channel list
        Column() {
          Text('频道列表')
            .fontSize(18)
            .fontWeight(700)
            .fontColor(colors.text)
            .margin({ bottom: spacing.lg })
            .animation({
              duration: 300,
              delay: 100,
              timingFunction: 'ease-out'
            })
          
          // 将Channel转换为VirtualListItem并使用VirtualList优化性能
          VirtualList({
            items: this.getFilteredChannels().map((channel, index) => ({
              id: `${channel.id}_${channel.sourceId}`,
              index,
              data: channel as Object
            })),
            estimatedItemHeight: 80,
            bufferSize: 3,
            renderItem: (item: VirtualListItem, index: number) => {
              const channel = item.data as LiveChannelWithSource;
              return Column() {
                Row() {
                  Text(channel.name)
                    .fontSize(16)
                    .fontWeight(this.currentChannel?.id === channel.id && this.currentChannel?.sourceId === channel.sourceId ? 700 : 400)
                    .fontColor(this.currentChannel?.id === channel.id && this.currentChannel?.sourceId === channel.sourceId ? colors.primary : colors.text)
                    .flexGrow(1)
                  
                  ContentSourceBadge({
                    sourceName: channel.sourceName,
                    sourceId: channel.sourceId
                  })
                }
                .width('100%')
              }
              .padding(spacing.md)
              .backgroundColor(this.currentChannel?.id === channel.id && this.currentChannel?.sourceId === channel.sourceId ? `${colors.primary}20` : colors.surface)
              .borderRadius(borderRadius.md)
              .margin({ bottom: spacing.sm })
              .onClick(() => this.handleChannelSwitch(channel))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
              .animation({
                duration: 300,
                timingFunction: 'ease-out'
              });
            }
          })
        }
        .padding(spacing.lg)
        .backgroundColor(colors.surface)
        .borderRadius(borderRadius.lg)
        .height('60%')
        .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 8 })
        .animation({
          duration: 400,
          delay: 100,
          timingFunction: 'ease-out'
        })
    }
    .width('35%')
    .height('100%')
    .padding(spacing.lg)
    .alignItems(HorizontalAlign.Start)
  }
  
  // 渲染右侧控制区 | Render right control area
  @Builder
  renderRightControl() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    if (!this.showRightControl) return;
    
    Column() {
      // 播放设置 | Playback settings
      Column() {
        Text('播放设置')
          .fontSize(18)
          .fontWeight(700)
          .fontColor(colors.text)
          .margin({ bottom: spacing.lg })
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
        
        // 音量调节 | Volume adjustment
        Column() {
          Text(`音量: ${this.volume}%`)
            .fontSize(16)
            .fontColor(colors.text)
            .margin({ bottom: spacing.md })
          
          Row() {
            Text('🔇')
              .fontSize(16)
              .margin({ right: spacing.sm })
            
            Slider({
              value: this.volume,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
            .width('80%')
            .blockColor(colors.primary)
            .trackColor(colors.divider)
            .selectedColor(colors.primary)
            .onChange((value: number) => this.handleVolumeChange(value))
            
            Text('🔊')
              .fontSize(16)
              .margin({ left: spacing.sm })
          }
        }
        .margin({ bottom: spacing.lg })
        .animation({
          duration: 300,
          delay: 50,
          timingFunction: 'ease-out'
        })
        
        // 亮度调节 | Brightness adjustment
        Column() {
          Text(`亮度: ${this.brightness}%`)
            .fontSize(16)
            .fontColor(colors.text)
            .margin({ bottom: spacing.md })
          
          Row() {
            Text('🌙')
              .fontSize(16)
              .margin({ right: spacing.sm })
            
            Slider({
              value: this.brightness,
              min: 0,
              max: 100,
              step: 1,
              style: SliderStyle.OutSet
            })
            .width('80%')
            .blockColor(colors.primary)
            .trackColor(colors.divider)
            .selectedColor(colors.primary)
            .onChange((value: number) => this.handleBrightnessChange(value))
            
            Text('☀️')
              .fontSize(16)
              .margin({ left: spacing.sm })
          }
        }
        .margin({ bottom: spacing.lg })
        .animation({
          duration: 300,
          delay: 100,
          timingFunction: 'ease-out'
        })
        
        // 播放速度调节 | Playback speed adjustment
        Column() {
          Text(`播放速度: ${this.playbackSpeed}x`)
            .fontSize(16)
            .fontColor(colors.text)
            .margin({ bottom: spacing.md })
          
          Row() {
            Button('0.5x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 0.5 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 0.5 ? colors.surface : colors.primary)
              .borderRadius(borderRadius.md)
              .margin({ right: spacing.sm })
              .onClick(() => this.handlePlaybackSpeedChange(0.5))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
            
            Button('1.0x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 1.0 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 1.0 ? colors.surface : colors.primary)
              .borderRadius(borderRadius.md)
              .margin({ right: spacing.sm })
              .onClick(() => this.handlePlaybackSpeedChange(1.0))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
            
            Button('1.5x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 1.5 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 1.5 ? colors.surface : colors.primary)
              .borderRadius(borderRadius.md)
              .margin({ right: spacing.sm })
              .onClick(() => this.handlePlaybackSpeedChange(1.5))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
            
            Button('2.0x')
              .fontSize(14)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 2.0 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 2.0 ? colors.surface : colors.primary)
              .borderRadius(borderRadius.md)
              .onClick(() => this.handlePlaybackSpeedChange(2.0))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
          }
        }
        .animation({
          duration: 300,
          delay: 150,
          timingFunction: 'ease-out'
        })
      }
      .padding(spacing.lg)
      .backgroundColor(colors.surface)
      .borderRadius(borderRadius.lg)
      .shadow({ radius: 12, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 8 })
      .animation({
        duration: 400,
        timingFunction: 'ease-out'
      })
    }
    .width('35%')
    .height('100%')
    .padding(spacing.lg)
    .alignItems(HorizontalAlign.End)
  }
  

  
  // 渲染快速频道切换器 | Render quick channel switcher
  @Builder
  renderQuickChannelSwitcher() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    if (!this.showQuickChannelSwitcher) return;
    
    Column() {
      Text('最近频道')
        .fontSize(16)
        .fontWeight(600)
        .fontColor(colors.text)
        .margin({ bottom: spacing.md })
        
      Scroll() {
        Row() {
          ForEach(this.recentChannels, (channel: LiveChannelWithSource) => {
            Column() {
              Stack() {
                Column()
                  .width(80)
                  .height(80)
                  .backgroundColor(colors.primary)
                  .borderRadius(borderRadius.lg)
                Text('📺')
                  .fontSize(32)
                  .fontColor(colors.surface)
              }
              Text(channel.name)
                .fontSize(12)
                .fontColor(colors.text)
                .margin({ top: spacing.xs })
                .maxLines(2)
                .width(80)
                .textAlign(TextAlign.Center)
            }
            .width(100)
            .margin({ right: spacing.md })
            .onClick(() => this.handleChannelSwitch(channel))
          }, (channel: LiveChannelWithSource) => `${channel.id}_${channel.sourceId}`)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .padding(spacing.lg)
    .position({ y: this.screenHeight * 0.7 })
    .backgroundColor(`${colors.surface}CC`)
    .borderRadius(24)
    .animation({
      duration: 300,
      timingFunction: 'ease-out'
    })
  }
  
  // 渲染加载状态 | Render loading state
  @Builder
  renderLoading() {
    const colors = this.currentTheme.colors;
    
    Column() {
      Text('正在加载直播内容...')
        .fontSize(18)
        .fontColor(colors.text)
        .margin(30)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(`${colors.background}CC`)
  }
  
  // 渲染错误状态 | Render error state
  @Builder
  renderError() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      Text('加载失败')
        .fontSize(20)
        .fontColor(colors.error)
        .margin({ bottom: spacing.sm })
      
      Text(this.errorMessage)
        .fontSize(16)
        .fontColor(colors.text)
        .margin({ bottom: spacing.lg })
        .textAlign(TextAlign.Center)
        .width('80%')
      
      // 显示错误操作按钮（如果有）
      if (this.errorActionText && this.errorActionHandler) {
        Button(this.errorActionText)
          .backgroundColor(colors.primary)
          .fontColor(colors.surface)
          .borderRadius(borderRadius.md)
          .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
          .onClick(() => {
            if (this.errorActionHandler) {
              this.errorActionHandler();
            }
          })
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor(colors.primary)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
          .margin({ bottom: spacing.sm })
      } else {
        // 默认重试按钮
        Button('重试')
          .backgroundColor(colors.primary)
          .fontColor(colors.surface)
          .borderRadius(borderRadius.md)
          .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
          .onClick(() => this.loadLiveContent())
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor(colors.primary)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
          .margin({ bottom: spacing.sm })
      }
      
      Button('返回')
        .backgroundColor(colors.surface)
        .fontColor(colors.text)
        .borderRadius(borderRadius.md)
        .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
        .onClick(() => this.handleBack())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor(colors.primary)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(`${colors.background}CC`)
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
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      // 直播播放区域 | Live playback area
      Stack({
        alignContent: Alignment.Center
      }) {
        // 背景 | Background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(colors.background)
          .onClick((event) => this.handleScreenClick(event.touches[0].x, event.touches[0].y))
          .onLongPress(() => this.handleScreenLongPress())
        
        // 直播内容 | Live content
        if (this.isLoading) {
          this.renderLoading();
        } else if (this.isError) {
          this.renderError();
        } else if (this.currentChannel) {
          Stack() {
            // 使用Video组件播放直播内容
            Video({
              src: this.currentChannel.url,
              currentProgressRate: this.playbackSpeed
            })
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .controls(false)
            .autoPlay(true)
            .loop(true)
            
            // 频道信息叠加层
            Column() {
              Row() {
                Text(`正在播放: ${this.currentChannel.name}`)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
                  .backgroundColor('rgba(0, 0, 0, 0.5)')
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .borderRadius(12)
                  .margin({ left: spacing.lg, top: spacing.lg })
              }
              .justifyContent(FlexAlign.Start)
              .width('100%')
            }
            .position({ top: 0, left: 0 })
            
            // 播放状态指示器
            if (this.isReconnecting) {
              Column() {
                Text(`正在重连... (${this.reconnectAttempt})`)
                  .fontSize(14)
                  .fontColor('#FFFFFF')
                  .backgroundColor('rgba(0, 0, 0, 0.7)')
                  .padding({ left: 16, right: 16, top: 8, bottom: 8 })
                  .borderRadius(20)
              }
              .position({ bottom: spacing.lg, right: spacing.lg })
            }
          }
          .width('100%')
          .height('100%')
        }
        
        // 左侧控制区 | Left control area
        this.renderLeftControl()
        
        // 右侧控制区 | Right control area
        this.renderRightControl()
        
        // 快速频道切换器 | Quick channel switcher
        this.renderQuickChannelSwitcher()
        
        // 返回按钮 | Back button
        Button('返回')
          .position({ top: spacing.lg, left: spacing.lg })
          .backgroundColor(`${colors.surface}CC`)
          .fontColor(colors.text)
          .borderRadius(borderRadius.md)
          .padding({ left: spacing.md, right: spacing.md, top: spacing.sm, bottom: spacing.sm })
          .onClick(() => this.handleBack())
          .focusable(true)
          .focusBorderWidth(2)
          .focusBorderColor(colors.primary)
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.background)
  }
}