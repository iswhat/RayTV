// ModernLivePage.ets
// 现代直播页面组件 - Modern live page component

import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ContentAccessService from '../service/content/ContentAccessService';
import display from '@ohos.display';
import { LiveChannelWithSource, LiveCategory } from '../service/live/LiveChannelTypes';

import {
  FlexAlign, FlexDirection, SliderStyle, HorizontalAlign, VerticalAlign, Alignment, TextAlign, BarState, ScrollDirection, EdgeEffect, GestureDirection, GestureEvent, PanGesture, GestureInfo, Column, Row, Text, Button, ForEach, Stack, Image, ImageFit
} from '@ohos.arkui';

import VirtualList from '../components/VirtualList';
import { VirtualListItem } from '../types/VirtualListTypes';
import ContentSourceBadge from '../components/ContentSourceBadge';
import ModernDesignSystem, { Theme } from '../design/ModernDesignSystem';

/**
 * 直播界面
 * 实现直播内容的播放、频道切换和播放设置
 * 使用LiveCategory作为ChannelCategory的类型别名以保持兼容
 */
type ChannelCategory = LiveCategory;

@Entry
@Component
struct ModernLivePage {
  private readonly TAG: string = 'ModernLivePage';
  private contentService: ContentAccessService = ContentAccessService.getInstance();
  private scroller: Scroller = new Scroller();
  
  // 状态管理
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '';
  @State currentChannel: LiveChannelWithSource | null = null;
  @State channelCategories: ChannelCategory[] = [];
  @State channels: LiveChannelWithSource[] = [];
  @State selectedCategory: string = 'all';
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
  @State currentTheme: Theme = ModernDesignSystem.getCurrentTheme();
  @State showQuickChannelSwitcher: boolean = false;
  @State recentChannels: LiveChannelWithSource[] = [];
  
  // 服务实例
  private liveStreamService: any = null;
  
  // 生命周期
  aboutToAppear() {
    Logger.info(this.TAG, 'ModernLivePage about to appear');
    
    // 初始化屏幕信息
    this.initScreenInfo();
    
    // 初始化服务
    this.initServices();
    
    // 加载直播内容
    this.loadLiveContent();
  }
  
  // 初始化服务
  private initServices() {
    try {
      // 尝试导入并初始化LiveStreamService
      // 实际应用中应该使用依赖注入或ServiceFactory
      const LiveStreamService = require('../service/live/LiveStreamService');
      this.liveStreamService = LiveStreamService.getInstance();
    } catch (error) {
      Logger.warn(this.TAG, 'LiveStreamService not available, using mock implementation');
      // 降级到模拟实现
      this.liveStreamService = {
        playChannel: async (channel: LiveChannelWithSource) => ({
          isSuccess: () => true,
          message: ''
        }),
        setVolume: (volume: number) => {},
        setBrightness: (brightness: number) => {},
        setPlaybackSpeed: (speed: number) => {},
        seekTo: (value: number) => {}
      };
    }
  }
  
  aboutToDisappear() {
    if (this.controlAutoHideTimer) {
      clearTimeout(this.controlAutoHideTimer);
    }
  }
  
  // 初始化屏幕信息
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info(this.TAG, `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Failed to get screen info: ${err.message}`);
      // 默认值
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  // 加载直播内容
  private async loadLiveContent() {
    try {
      this.isLoading = true;
      this.isError = false;
      Logger.info(this.TAG, 'Loading live content...');
      
      // 初始化内容访问服务
      await this.contentService.initialize();
      
      // 从ContentAccessService获取直播数据
      const allChannels = this.contentService.getAllLiveChannels();
      
      if (allChannels && allChannels.length > 0) {
        // 提取分类
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
        
        // 默认选择第一个频道
        if (this.channels.length > 0) {
          this.currentChannel = this.channels[0];
          this.addToRecentChannels(this.channels[0]);
          this.playChannel(this.channels[0]);
        }
      } else {
        // 无直播数据
        this.isError = true;
        this.errorMessage = '未配置直播源，请在设置中添加网络源';
        Logger.warn(this.TAG, 'No live data configured');
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
  
  // 添加到最近频道
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
  
  // 播放频道
  private async playChannel(channel: LiveChannelWithSource) {
    try {
      Logger.info(this.TAG, `Playing channel: ${channel.name}, URL: ${channel.url}, Source: ${channel.sourceName}`);
      
      if (!this.liveStreamService) {
        Logger.error(this.TAG, 'LiveStreamService not initialized');
        this.isError = true;
        this.errorMessage = '播放服务未初始化';
        return;
      }
      
      const result = await this.liveStreamService.playChannel(channel);
      if (!result.isSuccess()) {
        Logger.error(this.TAG, `Failed to play channel: ${result.message}`);
        this.isError = true;
        this.errorMessage = result.message || '播放频道失败';
      }
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error(this.TAG, `Error playing channel: ${err.message}`);
      this.isError = true;
      this.errorMessage = '播放频道失败';
    }
  }
  
  // 处理频道切换
  private handleChannelSwitch(channel: LiveChannelWithSource) {
    Logger.info(this.TAG, `Channel switched to: ${channel.name}, Source: ${channel.sourceName}`);
    this.currentChannel = channel;
    this.addToRecentChannels(channel);
    this.showLeftControl = false;
    this.showQuickChannelSwitcher = false;
    this.playChannel(channel);
  }
  
  // 处理分类切换
  private handleCategorySwitch(categoryId: string) {
    this.selectedCategory = categoryId;
    Logger.info(this.TAG, `Category switched to: ${categoryId}`);
  }
  
  // 处理屏幕点击
  private handleScreenClick(x: number, y: number) {
    Logger.info(this.TAG, `Screen clicked at: x=${x}, y=${y}`);
    
    // 左侧点击
    if (x < this.screenWidth * 0.3) {
      this.showLeftControl = !this.showLeftControl;
      this.showRightControl = false;
      this.showProgressBar = false;
      this.showQuickChannelSwitcher = false;
      this.resetControlAutoHide();
    }
    // 右侧点击
    else if (x > this.screenWidth * 0.7) {
      this.showRightControl = !this.showRightControl;
      this.showLeftControl = false;
      this.showProgressBar = false;
      this.showQuickChannelSwitcher = false;
      this.resetControlAutoHide();
    }
    // 底部点击
    else if (y > this.screenHeight * 0.8) {
      this.showQuickChannelSwitcher = !this.showQuickChannelSwitcher;
      this.showLeftControl = false;
      this.showRightControl = false;
      this.showProgressBar = false;
      this.resetControlAutoHide();
    }
    // 中间点击
    else {
      this.showLeftControl = false;
      this.showRightControl = false;
      this.showProgressBar = false;
      this.showQuickChannelSwitcher = false;
    }
  }
  
  // 处理屏幕长按
  private handleScreenLongPress() {
    Logger.info(this.TAG, 'Screen long pressed');
    this.showProgressBar = !this.showProgressBar;
    this.showLeftControl = false;
    this.showRightControl = false;
    this.showQuickChannelSwitcher = false;
    this.resetControlAutoHide();
  }
  
  // 重置控制自动隐藏
  private resetControlAutoHide() {
    if (this.controlAutoHideTimer) {
      clearTimeout(this.controlAutoHideTimer);
    }
    
    if (this.showLeftControl || this.showRightControl || this.showProgressBar || this.showQuickChannelSwitcher) {
      this.controlAutoHideTimer = setTimeout(() => {
        this.showLeftControl = false;
        this.showRightControl = false;
        this.showProgressBar = false;
        this.showQuickChannelSwitcher = false;
      }, 5000);
    }
  }
  
  // 处理音量调节
  private handleVolumeChange(value: number) {
    this.volume = Math.max(0, Math.min(100, value));
    Logger.info(this.TAG, `Volume changed to: ${this.volume}`);
    // 这里可以调用系统API调节音量
    this.liveStreamService.setVolume(this.volume);
  }
  
  // 处理亮度调节
  private handleBrightnessChange(value: number) {
    this.brightness = Math.max(0, Math.min(100, value));
    Logger.info(this.TAG, `Brightness changed to: ${this.brightness}`);
    // 这里可以调用系统API调节亮度
    this.liveStreamService.setBrightness(this.brightness);
  }
  
  // 处理播放速度调节
  private handlePlaybackSpeedChange(speed: number) {
    this.playbackSpeed = speed;
    Logger.info(this.TAG, `Playback speed changed to: ${this.playbackSpeed}`);
    // 这里可以调用播放器API调节播放速度
    this.liveStreamService.setPlaybackSpeed(speed);
  }
  
  // 处理进度调节
  private handleProgressChange(value: number) {
    this.currentProgress = Math.max(0, Math.min(this.totalDuration, value));
    Logger.info(this.TAG, `Progress changed to: ${this.currentProgress}`);
    // 这里可以调用播放器API调节进度
    this.liveStreamService.seekTo(value);
  }
  
  // 处理返回
  private handleBack() {
    AppNavigator.getInstance().navigateToBack();
  }
  
  // 获取筛选后的频道
  private getFilteredChannels(): LiveChannelWithSource[] {
    if (this.selectedCategory === 'all') {
      return this.channels;
    }
    return this.channels.filter(channel => channel.group === this.selectedCategory);
  }
  
  // 渲染左侧控制区
  @Builder
  renderLeftControl() {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    if (!this.showLeftControl) return;
    
    Column() {
      // 分类列表
      Column() {
        Text('频道分类')
          .fontSize(typography.h4.size)
          .fontWeight(typography.h4.fontWeight)
          .fontColor(colors.text)
          .margin({ bottom: spacing.lg })
          .animation(ModernDesignSystem.Animations.fadeIn)
        
        ForEach(this.channelCategories, (category: ChannelCategory) => {
          Text(category.name)
            .fontSize(typography.body.size)
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
            .animation(ModernDesignSystem.Animations.fadeIn)
        }, (category: ChannelCategory) => category.id)
      }
      .padding(spacing.lg)
      .backgroundColor(colors.surface)
      .borderRadius(borderRadius.lg)
      .margin({ bottom: spacing.lg })
      .shadow({
        radius: 12,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 8
      })
      .animation({
        ...ModernDesignSystem.Animations.fadeIn,
        duration: 400
      })
      
      // 频道列表
        Column() {
          Text('频道列表')
            .fontSize(typography.h4.size)
            .fontWeight(typography.h4.fontWeight)
            .fontColor(colors.text)
            .margin({ bottom: spacing.lg })
            .animation({
              ...ModernDesignSystem.Animations.fadeIn,
              delay: 100
            })
          
          // 将Channel转换为VirtualListItem
          const virtualItems = this.getFilteredChannels().map((channel, index) => ({
            id: `${channel.id}_${channel.sourceId}`,
            index,
            data: channel
          }));
          
          // 使用VirtualList优化性能
          VirtualList({
            items: virtualItems,
            estimatedItemHeight: 80,
            bufferSize: 3,
            renderItem: (item: VirtualListItem, index: number) => {
              const channel = item.data as LiveChannelWithSource;
              return Column() {
                Row() {
                  Text(channel.name)
                    .fontSize(typography.body.size)
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
              .animation(ModernDesignSystem.Animations.fadeIn);
            }
          })
        }
        .padding(spacing.lg)
        .backgroundColor(colors.surface)
        .borderRadius(borderRadius.lg)
        .height('60%')
        .shadow({
          radius: 12,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 8
        })
        .animation({
          ...ModernDesignSystem.Animations.fadeIn,
          delay: 100,
          duration: 400
        })
    }
    .width('35%')
    .height('100%')
    .padding(spacing.lg)
    .alignItems(HorizontalAlign.Start)
  }
  
  // 渲染右侧控制区
  @Builder
  renderRightControl() {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    if (!this.showRightControl) return;
    
    Column() {
      // 播放设置
      Column() {
        Text('播放设置')
          .fontSize(typography.h4.size)
          .fontWeight(typography.h4.fontWeight)
          .fontColor(colors.text)
          .margin({ bottom: spacing.lg })
          .animation(ModernDesignSystem.Animations.fadeIn)
        
        // 音量调节
        Column() {
          Text(`音量: ${this.volume}%`)
            .fontSize(typography.body.size)
            .fontColor(colors.text)
            .margin({ bottom: spacing.md })
          
          Row() {
            Text('🔇')
              .fontSize(typography.body.size)
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
              .fontSize(typography.body.size)
              .margin({ left: spacing.sm })
          }
        }
        .margin({ bottom: spacing.lg })
        .animation({
          ...ModernDesignSystem.Animations.fadeIn,
          delay: 50
        })
        
        // 亮度调节
        Column() {
          Text(`亮度: ${this.brightness}%`)
            .fontSize(typography.body.size)
            .fontColor(colors.text)
            .margin({ bottom: spacing.md })
          
          Row() {
            Text('🌙')
              .fontSize(typography.body.size)
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
              .fontSize(typography.body.size)
              .margin({ left: spacing.sm })
          }
        }
        .margin({ bottom: spacing.lg })
        .animation({
          ...ModernDesignSystem.Animations.fadeIn,
          delay: 100
        })
        
        // 播放速度调节
        Column() {
          Text(`播放速度: ${this.playbackSpeed}x`)
            .fontSize(typography.body.size)
            .fontColor(colors.text)
            .margin({ bottom: spacing.md })
          
          Row() {
            Button('0.5x')
              .fontSize(typography.caption.size)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 0.5 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 0.5 ? colors.onPrimary : colors.primary)
              .borderRadius(borderRadius.md)
              .margin({ right: spacing.sm })
              .onClick(() => this.handlePlaybackSpeedChange(0.5))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
            
            Button('1.0x')
              .fontSize(typography.caption.size)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 1.0 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 1.0 ? colors.onPrimary : colors.primary)
              .borderRadius(borderRadius.md)
              .margin({ right: spacing.sm })
              .onClick(() => this.handlePlaybackSpeedChange(1.0))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
            
            Button('1.5x')
              .fontSize(typography.caption.size)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 1.5 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 1.5 ? colors.onPrimary : colors.primary)
              .borderRadius(borderRadius.md)
              .margin({ right: spacing.sm })
              .onClick(() => this.handlePlaybackSpeedChange(1.5))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
            
            Button('2.0x')
              .fontSize(typography.caption.size)
              .padding(10)
              .backgroundColor(this.playbackSpeed === 2.0 ? colors.primary : `${colors.primary}20`)
              .fontColor(this.playbackSpeed === 2.0 ? colors.onPrimary : colors.primary)
              .borderRadius(borderRadius.md)
              .onClick(() => this.handlePlaybackSpeedChange(2.0))
              .focusable(true)
              .focusBorderWidth(2)
              .focusBorderColor(colors.primary)
          }
        }
        .animation({
          ...ModernDesignSystem.Animations.fadeIn,
          delay: 150
        })
      }
      .padding(spacing.lg)
      .backgroundColor(colors.surface)
      .borderRadius(borderRadius.lg)
      .shadow({
        radius: 12,
        color: 'rgba(0, 0, 0, 0.15)',
        offsetX: 0,
        offsetY: 8
      })
      .animation({
        ...ModernDesignSystem.Animations.fadeIn,
        duration: 400
      })
    }
    .width('35%')
    .height('100%')
    .padding(spacing.lg)
    .alignItems(HorizontalAlign.End)
  }
  
  // 渲染进度条
  @Builder
  renderProgressBar() {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const typography = ModernDesignSystem.Typography;
    
    if (!this.showProgressBar) return;
    
    Column() {
      Row() {
        Text(this.formatTime(this.currentProgress))
          .fontSize(typography.body.size)
          .fontColor(colors.text)
          .margin({ right: spacing.lg })
        
        Slider({
          value: this.currentProgress,
          min: 0,
          max: this.totalDuration,
          step: 1,
          style: SliderStyle.OutSet
        })
        .width('80%')
        .blockColor(colors.primary)
        .trackColor(colors.divider)
        .selectedColor(colors.primary)
        .onChange((value: number) => this.handleProgressChange(value))
        
        Text(this.formatTime(this.totalDuration))
          .fontSize(typography.body.size)
          .fontColor(colors.text)
          .margin({ left: spacing.lg })
      }
    }
    .width('100%')
    .padding(spacing.lg)
    .position({ y: this.screenHeight * 0.8 })
    .backgroundColor(`${colors.surface}CC`)
    .borderRadius(24)
    .animation(ModernDesignSystem.Animations.fadeIn)
  }
  
  // 渲染快速频道切换器
  @Builder
  renderQuickChannelSwitcher() {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    if (!this.showQuickChannelSwitcher) return;
    
    Column() {
      Text('最近频道')
        .fontSize(typography.h4.size)
        .fontWeight(typography.h4.fontWeight)
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
                  .fontColor(colors.onPrimary)
              }
              Text(channel.name)
                .fontSize(typography.caption.size)
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
    .animation(ModernDesignSystem.Animations.fadeIn)
  }
  
  // 渲染加载状态
  @Builder
  renderLoading() {
    const colors = this.currentTheme.colors;
    const typography = ModernDesignSystem.Typography;
    
    Column() {
      Text('正在加载直播内容...')
        .fontSize(typography.body.size)
        .fontColor(colors.text)
        .margin(30)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(`${colors.background}CC`)
  }
  
  // 渲染错误状态
  @Builder
  renderError() {
    const colors = this.currentTheme.colors;
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    Column() {
      Text('加载失败')
        .fontSize(typography.h4.size)
        .fontColor(colors.error)
        .margin({ bottom: spacing.sm })
      
      Text(this.errorMessage)
        .fontSize(typography.body.size)
        .fontColor(colors.text)
        .margin({ bottom: spacing.lg })
        .textAlign(TextAlign.Center)
        .width('80%')
      
      Button('重试')
        .backgroundColor(colors.primary)
        .fontColor(colors.onPrimary)
        .borderRadius(borderRadius.md)
        .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
        .onClick(() => this.loadLiveContent())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor(colors.primary)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
      
      Button('返回')
        .backgroundColor(colors.surface)
        .fontColor(colors.text)
        .borderRadius(borderRadius.md)
        .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
        .margin({ top: spacing.sm })
        .onClick(() => this.handleBack())
        .focusable(true)
        .focusBorderWidth(2)
        .focusBorderColor(colors.primary)
        .shadow({
          radius: 8,
          color: 'rgba(0, 0, 0, 0.15)',
          offsetX: 0,
          offsetY: 4
        })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height('100%')
    .backgroundColor(`${colors.background}CC`)
  }
  
  // 格式化时间
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
    const spacing = ModernDesignSystem.Spacing;
    const borderRadius = ModernDesignSystem.BorderRadius;
    const typography = ModernDesignSystem.Typography;
    
    Column() {
      // 直播播放区域
      Stack({
        alignContent: Alignment.Center
      }) {
        // 背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor(colors.background)
          .onClick((event) => this.handleScreenClick(event.touches[0].x, event.touches[0].y))
          .onLongPress(() => this.handleScreenLongPress())
        
        // 直播内容
        if (this.isLoading) {
          this.renderLoading();
        } else if (this.isError) {
          this.renderError();
        } else if (this.currentChannel) {
          Column() {
            // 这里应该使用Video组件播放直播内容
            // 由于是模拟，使用占位符
            Text(`正在播放: ${this.currentChannel.name}`)
              .fontSize(typography.h3.size)
              .fontColor(colors.text)
              .margin(spacing.lg)
              .animation(ModernDesignSystem.Animations.fadeIn)
            
            ContentSourceBadge({
              sourceName: this.currentChannel.sourceName,
              sourceId: this.currentChannel.sourceId
            })
            .margin({ bottom: spacing.lg })
            .animation({
              ...ModernDesignSystem.Animations.fadeIn,
              delay: 100
            })
            
            Text('直播内容播放区域')
              .fontSize(typography.body.size)
              .fontColor(colors.textSecondary)
              .animation({
                ...ModernDesignSystem.Animations.fadeIn,
                delay: 200
              })
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .height('100%')
        }
        
        // 左侧控制区
        this.renderLeftControl()
        
        // 右侧控制区
        this.renderRightControl()
        
        // 进度条
        this.renderProgressBar()
        
        // 快速频道切换器
        this.renderQuickChannelSwitcher()
        
        // 返回按钮
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
          .shadow({
            radius: 8,
            color: 'rgba(0, 0, 0, 0.15)',
            offsetX: 0,
            offsetY: 4
          })
          .animation(ModernDesignSystem.Animations.fadeIn)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.background)
  }
}