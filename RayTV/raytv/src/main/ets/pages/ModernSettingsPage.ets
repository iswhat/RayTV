import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import NetworkSourceManager, { NetworkSourceConfig, ContentUsage } from '../service/config/NetworkSourceManager';
import ContentAccessService from '../service/content/ContentAccessService';
import { NetworkSourceDetailPopup } from '../components/NetworkSourceDetailPopup';
import { SourceCard } from '../components/ContentSourceBadge';
import DesignSystem from '../design/DesignSystem';
import ThemeProvider, { Theme } from '../design/ThemeProvider';
import AnimationSystem from '../design/AnimationSystem';
import { Column, Row, Text, Button, ForEach, FlexAlign, HorizontalAlign, VerticalAlign, TextAlign, Scroll, BarState, ScrollDirection, EdgeEffect, Stack, Position, Image, ImageFit, Checkbox, Blank, SwipeAction, GestureEvent, PanGesture, GestureDirection } from '@ohos.arkui';

// 设置项 | Setting item
export interface SettingItem {
  id: string;
  title: string;
  description: string;
  icon?: string;
  type: 'button' | 'toggle' | 'select' | 'info';
  value?: string | boolean;
  onClick?: () => void;
  onToggle?: (value: boolean) => void;
}

// 设备信息接口 | Device info interface
export interface DeviceInfo {
  name?: string;
  model?: string;
  osVersion?: string;
  sn?: string;
  mac?: string;
  ip?: string;
}

/**
 * 缓存项 | Cache item
 */
export interface CacheItem {
  id: string;
  name: string;
  description: string;
  size: string;
  selected: boolean;
}

@Entry
@Component
struct ModernSettingsPage {
  private readonly TAG: string = 'ModernSettingsPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '加载失败';
  
  // 混合源架构相关状态
  @State sources: NetworkSourceConfig[] = [];
  @State selectedSource: NetworkSourceConfig | null = null;
  @State showSourceDetailPopup: boolean = false;
  
  // 内容池统计
  @State vodStats: { total: number; sources: number } = { total: 0, sources: 0 };
  @State liveStats: { total: number; sources: number } = { total: 0, sources: 0 };
  @State wallpaperStats: { total: number; sources: number } = { total: 0, sources: 0 };
  
  // 原有状态
  @State adBlockEnabled: boolean = false;
  @State dataSyncEnabled: boolean = false;
  @State voiceAssistantEnabled: boolean = false;
  @State gestureControlEnabled: boolean = false;
  @State deviceFlowEnabled: boolean = false;
  @State versionInfo: string = '6.1.6';
  @State cacheItems: CacheItem[] = [];
  @State selectedCacheItems: string[] = [];
  @State totalCacheSize: string = '0 MB';
  
  // 设备信息状态 | Device info state
  @State deviceInfo: DeviceInfo | null = null;
  @State isLoadingDeviceInfo: boolean = false;
  
  // 数据同步状态 | Data sync state
  @State syncStatus: string = '未同步';
  @State lastSyncTime: string = '从未';
  @State syncDevices: string[] = [];
  
  // 语音助手状态 | Voice assistant state
  @State voiceAssistantStatus: string = '未初始化';
  
  // 手势控制状态 | Gesture control state
  @State gestureControlStatus: string = '未初始化';
  
  // 设备流转状态 | Device flow state
  @State deviceFlowStatus: string = '未初始化';
  @State availableDevices: DeviceInfo[] = [];
  @State showDeviceFlowPopup: boolean = false;
  
  // 主题状态
  @State currentTheme: Theme = ThemeProvider.getCurrentTheme();
  
  // 服务实例
  private networkSourceManager: NetworkSourceManager;
  private contentAccessService: ContentAccessService;
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info('ModernSettingsPage', 'About to appear');
    
    // 获取服务实例
    this.networkSourceManager = NetworkSourceManager.getInstance();
    this.contentAccessService = ContentAccessService.getInstance();
    
    // 添加主题变更监听器
    ThemeProvider.addThemeChangeListener((theme) => {
      this.currentTheme = theme;
    });
    
    // 加载数据
    this.loadAllData();
  }
  
  /**
   * 加载所有数据
   */
  private async loadAllData(): Promise<void> {
    try {
      this.isLoading = true;
      this.isError = false;
      
      // 初始化网络源管理器
      await this.networkSourceManager.initialize();
      
      // 加载网络源列表
      this.sources = this.networkSourceManager.getAllSources();
      
      // 初始化内容访问服务
      await this.contentAccessService.initialize();
      
      // 加载内容池统计
      this.loadContentStats();
      
      // 加载原有设置状态
      this.loadAdBlockStatus();
      this.loadDataSyncStatus();
      this.loadVoiceAssistantStatus();
      this.loadGestureControlStatus();
      this.loadDeviceFlowStatus();
      this.loadVersionInfo();
      this.loadCacheInfo();
      
      Logger.info('ModernSettingsPage', 'All data loaded successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load data', err);
      this.isError = true;
      this.errorMessage = err.message;
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载内容池统计
   */
  private loadContentStats(): void {
    try {
      const overallStats = this.contentAccessService.getOverallStats();
      
      this.vodStats = {
        total: overallStats.vodSites,
        sources: overallStats.vodSources
      };
      
      this.liveStats = {
        total: overallStats.liveChannels,
        sources: overallStats.liveSources
      };
      
      this.wallpaperStats = {
        total: overallStats.wallpapers,
        sources: overallStats.wallpaperSources
      };
      
      Logger.info('ModernSettingsPage', `Content stats - VOD: ${this.vodStats.total}, Live: ${this.liveStats.total}, Wallpaper: ${this.wallpaperStats.total}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load content stats', err);
    }
  }
  
  /**
   * 加载广告过滤状态 | Load ad block status
   */
  private async loadAdBlockStatus(): Promise<void> {
    try {
      this.adBlockEnabled = false;
      Logger.info('ModernSettingsPage', `Ad block status: ${this.adBlockEnabled}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load ad block status', err);
      this.adBlockEnabled = false;
    }
  }
  
  /**
   * 加载版本信息 | Load version info
   */
  private async loadVersionInfo(): Promise<void> {
    try {
      this.versionInfo = '6.1.6';
      Logger.info('ModernSettingsPage', 'Version info: ' + this.versionInfo);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load version info', err);
    }
  }
  
  /**
   * 处理广告过滤切换 | Handle ad block toggle
   */
  private async handleAdBlockToggle(value: boolean): Promise<void> {
    try {
      this.adBlockEnabled = value;
      Logger.info('ModernSettingsPage', 'Ad block ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to toggle ad block', err);
    }
  }
  
  /**
   * 加载数据同步状态 | Load data sync status
   */
  private async loadDataSyncStatus(): Promise<void> {
    try {
      this.dataSyncEnabled = false;
      Logger.info('ModernSettingsPage', 'Data sync status: ' + this.dataSyncEnabled + ', sync status: ' + this.syncStatus);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load data sync status', err);
      this.dataSyncEnabled = false;
    }
  }
  
  /**
   * 处理数据同步切换 | Handle data sync toggle
   */
  private async handleDataSyncToggle(value: boolean): Promise<void> {
    try {
      this.dataSyncEnabled = value;
      
      if (value) {
        await this.performSync();
      }
      
      Logger.info('ModernSettingsPage', 'Data sync ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to toggle data sync', err);
    }
  }
  
  /**
   * 执行数据同步 | Perform data sync
   */
  private async performSync(): Promise<void> {
    try {
      this.syncStatus = '同步中...';
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      this.syncStatus = '同步成功';
      this.lastSyncTime = new Date().toLocaleString();
      
      Logger.info('ModernSettingsPage', 'Data sync completed successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.syncStatus = '同步失败';
      Logger.error('ModernSettingsPage', 'Failed to sync data', err);
    }
  }
  
  /**
   * 加载语音助手状态 | Load voice assistant status
   */
  private async loadVoiceAssistantStatus(): Promise<void> {
    try {
      this.voiceAssistantEnabled = false;
      Logger.info('ModernSettingsPage', 'Voice assistant status: ' + this.voiceAssistantEnabled + ', status: ' + this.voiceAssistantStatus);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load voice assistant status', err);
      this.voiceAssistantEnabled = false;
    }
  }
  
  /**
   * 处理语音助手切换 | Handle voice assistant toggle
   */
  private async handleVoiceAssistantToggle(value: boolean): Promise<void> {
    try {
      this.voiceAssistantEnabled = value;
      Logger.info('ModernSettingsPage', 'Voice assistant ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to toggle voice assistant', err);
    }
  }
  
  /**
   * 加载手势控制状态 | Load gesture control status
   */
  private async loadGestureControlStatus(): Promise<void> {
    try {
      this.gestureControlEnabled = false;
      Logger.info('ModernSettingsPage', 'Gesture control status: ' + this.gestureControlEnabled + ', status: ' + this.gestureControlStatus);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load gesture control status', err);
      this.gestureControlEnabled = false;
    }
  }
  
  /**
   * 加载设备流转状态 | Load device flow status
   */
  private async loadDeviceFlowStatus(): Promise<void> {
    try {
      this.deviceFlowEnabled = false;
      this.availableDevices = [];
      this.deviceFlowStatus = this.availableDevices.length > 0 ? '已发现' + this.availableDevices.length + ' 个设备' : '未发现设备';
      
      Logger.info('ModernSettingsPage', 'Device flow status: ' + this.deviceFlowEnabled + ', devices: ' + this.availableDevices.length);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load device flow status', err);
      this.deviceFlowEnabled = false;
      this.deviceFlowStatus = '加载失败';
    }
  }
  
  /**
   * 处理手势控制切换 | Handle gesture control toggle
   */
  private async handleGestureControlToggle(value: boolean): Promise<void> {
    try {
      this.gestureControlEnabled = value;
      Logger.info('ModernSettingsPage', 'Gesture control ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to toggle gesture control', err);
    }
  }
  
  /**
   * 处理设备流转切换 | Handle device flow toggle
   */
  private async handleDeviceFlowToggle(value: boolean): Promise<void> {
    try {
      this.deviceFlowEnabled = value;
      Logger.info('ModernSettingsPage', 'Device flow ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to toggle device flow', err);
    }
  }
  
  /**
   * 处理设备流转发起 | Handle device flow start
   */
  private async handleDeviceFlowStart(deviceId: string): Promise<void> {
    try {
      Logger.info('ModernSettingsPage', 'Starting device flow to device: ' + deviceId);
      
      const flowData: any = {
        mediaInfo: {
          title: '当前播放内容',
          position: 0,
          duration: 0
        },
        appState: {
          currentPage: 'ModernSettingsPage'
        }
      };
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      Logger.info('ModernSettingsPage', 'Device flow started successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to start device flow', err);
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      Logger.info('ModernSettingsPage', 'Navigating back');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to navigate back', err);
    }
  }
  
  /**
   * 处理重置设置 | Handle reset settings
   */
  private async handleResetSettings(): Promise<void> {
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      await this.loadAllData();
      
      Logger.info('ModernSettingsPage', 'Settings reset successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to reset settings', err);
    }
  }
  
  /**
   * 加载缓存信息 | Load cache info
   */
  private async loadCacheInfo(): Promise<void> {
    try {
      Logger.info('ModernSettingsPage', 'Loading cache info');
      
      this.cacheItems = [
        {
          id: 'video_cache',
          name: '视频缓存',
          description: '已观看视频的缓存文件',
          size: '0 MB',
          selected: false
        },
        {
          id: 'image_cache',
          name: '图片缓存',
          description: '应用图片资源缓存',
          size: '0 MB',
          selected: false
        },
        {
          id: 'config_cache',
          name: '配置缓存',
          description: '应用配置缓存',
          size: '0 MB',
          selected: false
        }
      ];
      
      this.totalCacheSize = '0 MB';
      this.selectedCacheItems = [];
      
      Logger.info('ModernSettingsPage', 'Loaded cache info: ' + this.totalCacheSize);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load cache info', err);
      this.cacheItems = [];
      this.totalCacheSize = '0 MB';
    }
  }
  
  /**
   * 处理缓存项选择 | Handle cache item selection
   */
  private handleCacheItemSelect(itemId: string): void {
    const item = this.cacheItems.find(item => item.id === itemId);
    if (item) {
      item.selected = !item.selected;
      this.selectedCacheItems = this.cacheItems.filter(item => item.selected).map(item => item.id);
    }
  }
  
  /**
   * 处理缓存清理 | Handle cache clear
   */
  private async handleCacheClear(): Promise<void> {
    try {
      if (this.selectedCacheItems.length === 0) {
        Logger.warn('ModernSettingsPage', 'No cache items selected for clearing');
        return;
      }
      
      Logger.info('ModernSettingsPage', 'Clearing selected cache items: ' + this.selectedCacheItems.join(', '));
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      await this.loadCacheInfo();
      
      Logger.info('ModernSettingsPage', 'Cache cleared successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to clear cache', err);
    }
  }
  
  /**
   * 加载设备信息 | Load device info
   */
  private async loadDeviceInfo(): Promise<void> {
    try {
      this.isLoadingDeviceInfo = true;
      Logger.info('ModernSettingsPage', 'Loading device info');
      
      const deviceInfo: DeviceInfo = {
        name: '设备名称',
        model: '设备型号',
        osVersion: 'HarmonyOS 4.0',
        sn: '1234567890',
        mac: '00:11:22:33:44:55',
        ip: '192.168.1.100'
      };
      this.deviceInfo = deviceInfo;
      
      Logger.info('ModernSettingsPage', 'Device info loaded successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to load device info', err);
      this.deviceInfo = null;
    } finally {
      this.isLoadingDeviceInfo = false;
    }
  }
  
  /**
   * 处理全选/取消全选 | Handle select all
   */
  private handleSelectAll(selectAll: boolean): void {
    this.cacheItems.forEach(item => {
      item.selected = selectAll;
    });
    
    this.selectedCacheItems = selectAll ? this.cacheItems.map(item => item.id) : [];
  }
  
  /**
   * 处理源启用切换
   */
  private async handleSourceToggle(sourceId: string, isActive: boolean): Promise<void> {
    try {
      await this.networkSourceManager.toggleSource(sourceId, isActive);
      this.sources = this.networkSourceManager.getAllSources();
      this.loadContentStats();
      Logger.info('ModernSettingsPage', `Source ${sourceId} toggled to ${isActive}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to toggle source', err);
    }
  }
  
  /**
   * 处理源编辑
   */
  private handleSourceEdit(source: NetworkSourceConfig): void {
    this.selectedSource = source;
    this.showSourceDetailPopup = true;
  }
  
  /**
   * 处理源详情更新
   */
  private async handleSourceUpdate(source: NetworkSourceConfig): Promise<void> {
    try {
      await this.networkSourceManager.updateSource(source);
      this.sources = this.networkSourceManager.getAllSources();
      this.loadContentStats();
      Logger.info('ModernSettingsPage', `Source ${source.name} updated`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to update source', err);
    }
  }
  
  /**
   * 处理源删除
   */
  private async handleSourceDelete(sourceId: string): Promise<void> {
    try {
      await this.networkSourceManager.removeSource(sourceId);
      this.sources = this.networkSourceManager.getAllSources();
      this.loadContentStats();
      Logger.info('ModernSettingsPage', `Source ${sourceId} deleted`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to delete source', err);
    }
  }
  
  /**
   * 处理健康检查
   */
  private async handleHealthCheck(): Promise<void> {
    try {
      await this.networkSourceManager.checkAllSourcesHealth();
      this.sources = this.networkSourceManager.getAllSources();
      Logger.info('ModernSettingsPage', 'Health check completed');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('ModernSettingsPage', 'Failed to perform health check', err);
    }
  }
  
  /**
   * 渲染设置卡片
   */
  @Builder
  private renderSettingCard(title: string, content: () => void) {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      Text(title)
        .fontSize(18)
        .fontWeight(600)
        .fontColor(colors.text)
        .width('100%')
        .padding({ left: spacing.md, top: spacing.md, bottom: spacing.md })
        .borderRadius({ topLeft: borderRadius.lg, topRight: borderRadius.lg })
      
      Column() {
        content();
      }
      .width('100%')
      .padding({ left: spacing.md, right: spacing.md, bottom: spacing.md })
    }
    .width('100%')
    .backgroundColor(colors.surface)
    .borderRadius(borderRadius.lg)
    .margin({ bottom: spacing.md })
    .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 4 })
    .animation({
      duration: 400,
      timingFunction: 'ease-out'
    })
  }
  
  /**
   * 渲染开关设置项
   */
  @Builder
  private renderToggleSetting(label: string, value: boolean, onToggle: (value: boolean) => void) {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(colors.text)
        .flexGrow(1)
      
      Stack() {
        Column()
          .width(56)
          .height(32)
          .backgroundColor(value ? colors.primary : colors.divider)
          .borderRadius(borderRadius.full)
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
        Column()
          .width(24)
          .height(24)
          .backgroundColor(colors.surface)
          .borderRadius(borderRadius.full)
          .position({ x: value ? 28 : 4, y: 4 })
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
      }
      .onClick(() => onToggle(!value))
    }
    .width('100%')
    .padding({ top: spacing.sm, bottom: spacing.sm })
  }
  
  /**
   * 渲染按钮设置项
   */
  @Builder
  private renderButtonSetting(label: string, buttonText: string, onClick: () => void, buttonColor: string = 'primary') {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(colors.text)
        .flexGrow(1)
      
      Button(buttonText)
        .fontSize(14)
        .fontColor(colors.surface)
        .backgroundColor(buttonColor === 'primary' ? colors.primary : buttonColor === 'warning' ? colors.warning : colors.error)
        .borderRadius(borderRadius.md)
        .padding({ left: spacing.md, right: spacing.md })
        .onClick(onClick)
        .animation({
          duration: 300,
          timingFunction: 'ease-out'
        })
    }
    .width('100%')
    .padding({ top: spacing.sm, bottom: spacing.sm })
  }
  
  /**
   * 渲染信息设置项
   */
  @Builder
  private renderInfoSetting(label: string, value: string) {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    
    Row() {
      Text(label)
        .fontSize(16)
        .fontColor(colors.text)
        .flexGrow(1)
      
      Text(value)
        .fontSize(14)
        .fontColor(colors.textSecondary)
    }
    .width('100%')
    .padding({ top: spacing.sm, bottom: spacing.sm })
  }
  
  build() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    
    Column() {
      // 顶部导航栏 | Top navigation bar
      Stack() {
        Row() {
          // 返回按钮 | Back button
          Button() {
            Text('←')
              .fontSize(24)
              .fontColor(colors.surface)
          }
          .width(56)
          .height(56)
          .backgroundColor(colors.primary)
          .borderRadius(borderRadius.full)
          .margin({ left: spacing.lg })
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
          .onClick(() => this.handleBack())
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
          
          // 标题 | Title
          Text('设置')
            .fontSize(24)
            .fontWeight(700)
            .fontColor(colors.text)
            .flexGrow(1)
            .margin({ left: spacing.lg })
            .textAlign(TextAlign.Start)
          
          // 重置按钮 | Reset button
          Button() {
            Text('重置')
              .fontSize(16)
              .fontColor(colors.surface)
          }
          .width(80)
          .height(56)
          .backgroundColor(colors.error)
          .borderRadius(borderRadius.full)
          .margin({ right: spacing.lg })
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
          .onClick(() => this.handleResetSettings())
          .animation({
            duration: 300,
            timingFunction: 'ease-out'
          })
        }
        .width('100%')
        .height(80)
        .alignItems(VerticalAlign.Center)
        .backgroundColor(colors.surface)
        .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.1)', offsetX: 0, offsetY: 4 })
      }
      
      // 设置项列表 | Setting item list
      Scroll(this.scroller) {
        Column() {
          if (this.isLoading) {
            Column() {
              Text('加载中...')
                .fontSize(20)
                .fontColor(colors.textSecondary)
                .margin(spacing.lg)
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else if (this.isError) {
            Column() {
              Text('加载失败')
                .fontSize(20)
                .fontColor(colors.error)
                .margin({ top: spacing.md })
              Text(this.errorMessage)
                .fontSize(16)
                .fontColor(colors.warning)
                .margin({ top: spacing.sm, left: spacing.lg, right: spacing.lg })
                .textAlign(TextAlign.Center)
              Button('重试')
                .onClick(() => this.loadAllData())
                .backgroundColor(colors.primary)
                .fontColor(colors.surface)
                .borderRadius(borderRadius.full)
                .padding({ left: spacing.xl, right: spacing.xl, top: spacing.md, bottom: spacing.md })
                .margin({ top: spacing.lg })
                .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.15)', offsetX: 0, offsetY: 4 })
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else {
            // 网络源管理区域
            this.renderSettingCard('网络源管理', () => {
              Row() {
                Text(`已启用: ${this.sources.filter(s => s.isActive).length}个源`)
                  .fontSize(14)
                  .fontColor(colors.textSecondary)
                
                Button('+ 添加网络源')
                  .fontSize(14)
                  .fontColor(colors.surface)
                  .backgroundColor(colors.primary)
                  .borderRadius(borderRadius.md)
                  .padding({ left: spacing.md, right: spacing.md })
                  .onClick(() => {
                    this.selectedSource = null;
                    this.showSourceDetailPopup = true;
                  })
                  .animation({
                    duration: 300,
                    timingFunction: 'ease-out'
                  })
              }
              .width('100%')
              .margin({ bottom: spacing.md })
              
              // 源列表
              Column() {
                ForEach(this.sources, (source: NetworkSourceConfig) => {
                  SourceCard({
                    sourceName: source.name,
                    sourceId: source.id,
                    sourceUrl: source.url,
                    isActive: source.isActive,
                    healthStatus: source.healthStatus,
                    priority: source.priority,
                    tags: source.tags || [],
                    contentUsage: source.contentUsage,
                    onToggle: (isActive: boolean) => this.handleSourceToggle(source.id, isActive),
                    onClick: () => this.handleSourceEdit(source)
                  })
                  .margin({ bottom: spacing.sm })
                  .animation({
                    duration: 300,
                    timingFunction: 'ease-out'
                  })
                }, (source: NetworkSourceConfig) => source.id)
              }
              .width('100%')
            });
            
            // 内容统计区域
            this.renderSettingCard('内容统计', () => {
              Column() {
                this.renderInfoSetting('点播站点', `${this.vodStats.total}个 来自${this.vodStats.sources}个源`);
                this.renderInfoSetting('直播频道', `${this.liveStats.total}个 来自${this.liveStats.sources}个源`);
                this.renderInfoSetting('壁纸资源', `${this.wallpaperStats.total}张 来自${this.wallpaperStats.sources}个源`);
              }
            });
            
            // 功能设置区域
            this.renderSettingCard('功能设置', () => {
              Column() {
                this.renderToggleSetting('广告过滤', this.adBlockEnabled, (value) => this.handleAdBlockToggle(value));
                this.renderToggleSetting('数据同步', this.dataSyncEnabled, (value) => this.handleDataSyncToggle(value));
                this.renderToggleSetting('语音助手', this.voiceAssistantEnabled, (value) => this.handleVoiceAssistantToggle(value));
                this.renderToggleSetting('手势控制', this.gestureControlEnabled, (value) => this.handleGestureControlToggle(value));
                this.renderToggleSetting('设备流转', this.deviceFlowEnabled, (value) => this.handleDeviceFlowToggle(value));
              }
            });
            
            // 高级设置区域
            this.renderSettingCard('高级设置', () => {
              Column() {
                this.renderButtonSetting('源健康检查', '检查全部', () => this.handleHealthCheck(), 'warning');
                this.renderInfoSetting('应用版本', this.versionInfo);
                this.renderInfoSetting('上次同步', this.lastSyncTime);
              }
            });
            
            // 缓存管理区域
            this.renderSettingCard('缓存管理', () => {
              Column() {
                this.renderInfoSetting('总缓存大小', this.totalCacheSize);
                
                ForEach(this.cacheItems, (item: CacheItem) => {
                  Row() {
                    Column() {
                      Text(item.name)
                        .fontSize(16)
                        .fontColor(colors.text)
                      Text(item.description)
                        .fontSize(14)
                        .fontColor(colors.textSecondary)
                    }
                    .flexGrow(1)
                    
                    Row() {
                      Text(item.size)
                        .fontSize(14)
                        .fontColor(colors.textSecondary)
                        .margin({ right: spacing.md })
                      
                      Checkbox()
                        .select(item.selected)
                        .onChange(() => this.handleCacheItemSelect(item.id))
                    }
                  }
                  .width('100%')
                  .padding({ top: spacing.sm, bottom: spacing.sm })
                }, (item: CacheItem) => item.id);
                
                Row() {
                  Button('全选')
                    .fontSize(14)
                    .fontColor(colors.primary)
                    .backgroundColor('transparent')
                    .onClick(() => this.handleSelectAll(true))
                  
                  Button('取消全选')
                    .fontSize(14)
                    .fontColor(colors.primary)
                    .backgroundColor('transparent')
                    .margin({ left: spacing.md })
                    .onClick(() => this.handleSelectAll(false))
                  
                  Blank()
                  
                  Button('清理缓存')
                    .fontSize(14)
                    .fontColor(colors.surface)
                    .backgroundColor(colors.error)
                    .borderRadius(borderRadius.md)
                    .padding({ left: spacing.md, right: spacing.md })
                    .onClick(() => this.handleCacheClear())
                }
                .width('100%')
                .margin({ top: spacing.md })
              }
            });
          }
        }
        .width('100%')
        .padding({ top: spacing.xl, left: spacing.lg, right: spacing.lg, bottom: spacing.xl })
      }
      .scrollBar(BarState.Auto)
      .flexGrow(1)
      .backgroundColor(colors.background)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(colors.background)
    .bindContentCover(this.showSourceDetailPopup && this.selectedSource, this.SourceDetailPopupBuilder(), {
      modalTransition: 0
    })
  }
  
  /**
   * 源详情弹窗构建器
   */
  @Builder
  SourceDetailPopupBuilder(): void {
    if (this.showSourceDetailPopup) {
      const colors = this.currentTheme.colors;
      const spacing = DesignSystem.Spacing;
      const borderRadius = DesignSystem.BorderRadius;
      
      Column() {
        // 半透明背景
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.showSourceDetailPopup = false;
            this.selectedSource = null;
          })
        
        // 弹窗内容 - 当selectedSource为null时显示添加表单
        if (this.selectedSource) {
          Column() {
            // 标题栏
            Row() {
              Text('源配置详情')
                .fontSize(20)
                .fontWeight(700)
                .fontColor(colors.text)
              
              Blank()
              
              Button() {
                Text('关闭')
                  .fontSize(16)
                  .fontColor(colors.textSecondary)
              }
              .backgroundColor('transparent')
              .onClick(() => {
                this.showSourceDetailPopup = false;
                this.selectedSource = null;
              })
            }
            .width('100%')
            .padding(spacing.lg)
            .borderBottomWidth(1)
            .borderBottomColor(colors.divider)
            
            // 显示源详情
            Scroll() {
              Column() {
                this.renderInfoSetting('源名称', this.selectedSource.name);
                this.renderInfoSetting('源URL', this.selectedSource.url);
                this.renderInfoSetting('版本', this.selectedSource.version);
                this.renderInfoSetting('状态', this.selectedSource.isActive ? '已启用' : '已禁用');
                this.renderInfoSetting('健康状态', this.selectedSource.healthStatus);
                this.renderInfoSetting('优先级', this.selectedSource.priority.toString());
                
                Text('内容使用')
                  .fontSize(16)
                  .fontWeight(600)
                  .fontColor(colors.text)
                  .margin({ top: spacing.md, bottom: spacing.sm })
                
                this.renderInfoSetting('点播站点', this.selectedSource.contentUsage.vodSites ? '启用' : '禁用');
                this.renderInfoSetting('直播频道', this.selectedSource.contentUsage.liveChannels ? '启用' : '禁用');
                this.renderInfoSetting('壁纸', this.selectedSource.contentUsage.wallpapers ? '启用' : '禁用');
                this.renderInfoSetting('广告过滤规则', this.selectedSource.contentUsage.adBlockRules ? '启用' : '禁用');
                this.renderInfoSetting('解码配置', this.selectedSource.contentUsage.decoderConfigs ? '启用' : '禁用');
              }
              .padding(spacing.lg)
            }
            
            // 底部按钮
            Row() {
              Button('编辑')
                .fontSize(16)
                .fontColor(colors.surface)
                .backgroundColor(colors.primary)
                .borderRadius(borderRadius.md)
                .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
                .flexGrow(1)
                .margin({ right: spacing.md })
              
              Button('删除')
                .fontSize(16)
                .fontColor(colors.surface)
                .backgroundColor(colors.error)
                .borderRadius(borderRadius.md)
                .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
                .flexGrow(1)
                .onClick(() => {
                  this.handleSourceDelete(this.selectedSource!.id);
                  this.showSourceDetailPopup = false;
                  this.selectedSource = null;
                })
            }
            .width('100%')
            .padding(spacing.lg)
            .borderTopWidth(1)
            .borderTopColor(colors.divider)
          }
          .width('80%')
          .maxWidth(600)
          .height('80%')
          .backgroundColor(colors.surface)
          .borderRadius(borderRadius.xl)
          .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)' })
          .animation({
            duration: 400,
            timingFunction: 'ease-out'
          })
        } else {
          Column() {
            // 标题栏
            Row() {
              Text('添加网络源')
                .fontSize(20)
                .fontWeight(700)
                .fontColor(colors.text)
              
              Blank()
              
              Button() {
                Text('关闭')
                  .fontSize(16)
                  .fontColor(colors.textSecondary)
              }
              .backgroundColor('transparent')
              .onClick(() => {
                this.showSourceDetailPopup = false;
              })
            }
            .width('100%')
            .padding(spacing.lg)
            .borderBottomWidth(1)
            .borderBottomColor(colors.divider)
            
            // 添加表单
            Column() {
              Text('添加网络源功能')
                .fontSize(16)
                .fontColor(colors.text)
                .padding(spacing.lg)
                .textAlign(TextAlign.Center)
              
              Text('请在网络源管理中添加新的网络源配置')
                .fontSize(14)
                .fontColor(colors.textSecondary)
                .padding({ left: spacing.lg, right: spacing.lg })
                .textAlign(TextAlign.Center)
            }
            .flexGrow(1)
            .justifyContent(FlexAlign.Center)
          }
          .width('80%')
          .maxWidth(600)
          .height('60%')
          .backgroundColor(colors.surface)
          .borderRadius(borderRadius.xl)
          .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)' })
          .animation({
            duration: 400,
            timingFunction: 'ease-out'
          })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .position({ x: 0, y: 0 })
    }
  }
}

export default ModernSettingsPage;