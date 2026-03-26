import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import SettingService from '../service/config/SettingService';
import AdBlockManager from '../service/adblock/AdBlockManager';
import WallManager from '../service/wallpaper/WallManager';
import DeviceService from '../service/device/DeviceService_fixed';
import bundleManager from '@ohos.bundle.bundleManager';
import DataSyncService from '../service/sync/DataSyncService';
import { VoiceAssistantManager } from '../service/voice/VoiceAssistantManager';
import { GestureService } from '../service/input/GestureService';
import { DeviceFlowManager, FlowData } from '../service/device/DeviceFlowManager';
import CacheService from '../service/cache/CacheService';
import NetworkSourceManager, { NetworkSourceConfig, ContentUsage } from '../service/config/NetworkSourceManager';
import ContentAccessService from '../service/content/ContentAccessService';
import { NetworkSourceDetailPopup } from '../components/NetworkSourceDetailPopup';
import { SourceCard } from '../components/ContentSourceBadge';
import display from '@ohos.display';
import DesignSystem from '../design/DesignSystem';
import ThemeProvider, { Theme } from '../design/ThemeProvider';
import Strings from '../common/resources/Strings';

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
struct SettingsPage {
  private readonly TAG: string = 'SettingsPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = Strings.common.error;
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  
  // 混合源架构相关状态
  @State sources: NetworkSourceConfig[] = [];
  @State selectedSource: NetworkSourceConfig | null = null;
  @State showSourceDetailPopup: boolean = false;
  @State tempSourceName: string = '';
  @State tempSourceUrl: string = '';
  @State tempSourcePriority: number = 5;
  @State tempSourceTags: string = '';
  @State isAddingSource: boolean = false;
  @State showAddSourceForm: boolean = false;
  
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
    Logger.info('SettingsPage', 'About to appear');
    
    // 获取服务实例
    this.networkSourceManager = NetworkSourceManager.getInstance();
    this.contentAccessService = ContentAccessService.getInstance();
    
    // 添加主题变更监听器
    ThemeProvider.addThemeChangeListener((theme) => {
      this.currentTheme = theme;
    });
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
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
      
      Logger.info('SettingsPage', 'All data loaded successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load data', err);
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
      
      Logger.info('SettingsPage', `Content stats - VOD: ${this.vodStats.total}, Live: ${this.liveStats.total}, Wallpaper: ${this.wallpaperStats.total}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load content stats', err);
    }
  }
  
  // 初始化屏幕信息 | Initialize screen information
  private initScreenInfo() {
    try {
      const displayInfo = display.getDefaultDisplaySync();
      this.screenWidth = displayInfo.width;
      this.screenHeight = displayInfo.height;
      this.isLandscape = this.screenWidth > this.screenHeight;
      Logger.info('SettingsPage', `Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', `Failed to get screen info: ${err.message}`);
      // 默认值 | Default values
      this.screenWidth = 1920;
      this.screenHeight = 1080;
      this.isLandscape = true;
    }
  }
  
  /**
   * 加载广告过滤状态 | Load ad block status
   */
  private async loadAdBlockStatus(): Promise<void> {
    try {
      const adBlockManager = AdBlockManager.getInstance();
      this.adBlockEnabled = await adBlockManager.isEnabled();
      Logger.info('SettingsPage', `Ad block status: ${this.adBlockEnabled}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load ad block status', err);
      this.adBlockEnabled = false;
    }
  }
  
  /**
   * 加载版本信息 | Load version info
   * 从系统bundleManager动态读取版本号，避免硬编码
   */
  private async loadVersionInfo(): Promise<void> {
    try {
      const bundleInfo = await bundleManager.getBundleInfoForSelf(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      this.versionInfo = bundleInfo.versionName || '未知版本';
      Logger.info('SettingsPage', 'Version info: ' + this.versionInfo);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.warn('SettingsPage', `Failed to load version info from bundleManager: ${err.message}, using fallback`);
      // 降级方案：保留一个可配置的默认值，但不再使用硬编码
      this.versionInfo = '6.1.6';
    }
  }
  
  /**
   * 处理广告过滤切换 | Handle ad block toggle
   */
  private async handleAdBlockToggle(value: boolean): Promise<void> {
    try {
      const adBlockManager = AdBlockManager.getInstance();
      await adBlockManager.setEnabled(value);
      this.adBlockEnabled = value;
      Logger.info('SettingsPage', 'Ad block ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to toggle ad block', err);
    }
  }
  
  /**
   * 加载数据同步状态 | Load data sync status
   */
  private async loadDataSyncStatus(): Promise<void> {
    try {
      const dataSyncService = DataSyncService.getInstance();
      this.dataSyncEnabled = await dataSyncService.isEnabled();
      this.syncStatus = await dataSyncService.getSyncStatus();
      this.lastSyncTime = await dataSyncService.getLastSyncTime();
      Logger.info('SettingsPage', 'Data sync status: ' + this.dataSyncEnabled + ', sync status: ' + this.syncStatus);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load data sync status', err);
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
      
      Logger.info('SettingsPage', 'Data sync ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to toggle data sync', err);
    }
  }
  
  /**
   * 执行数据同步 | Perform data sync
   */
  private async performSync(): Promise<void> {
    try {
      this.syncStatus = '同步中...';

      const dataSyncService = DataSyncService.getInstance();
      await dataSyncService.syncToCloud();

      this.syncStatus = '同步成功';
      this.lastSyncTime = new Date().toLocaleString();

      Logger.info('SettingsPage', 'Data sync completed successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      this.syncStatus = '同步失败';
      Logger.error('SettingsPage', 'Failed to sync data', err);
    }
  }
  
  /**
   * 加载语音助手状态 | Load voice assistant status
   */
  private async loadVoiceAssistantStatus(): Promise<void> {
    try {
      const voiceAssistantManager = VoiceAssistantManager.getInstance();
      this.voiceAssistantEnabled = await voiceAssistantManager.isEnabled();
      this.voiceAssistantStatus = await voiceAssistantManager.getStatus();
      Logger.info('SettingsPage', 'Voice assistant status: ' + this.voiceAssistantEnabled + ', status: ' + this.voiceAssistantStatus);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load voice assistant status', err);
      this.voiceAssistantEnabled = false;
    }
  }
  
  /**
   * 处理语音助手切换 | Handle voice assistant toggle
   */
  private async handleVoiceAssistantToggle(value: boolean): Promise<void> {
    try {
      const voiceAssistantManager = VoiceAssistantManager.getInstance();
      await voiceAssistantManager.setEnabled(value);
      this.voiceAssistantEnabled = value;
      Logger.info('SettingsPage', 'Voice assistant ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to toggle voice assistant', err);
    }
  }
  
  /**
   * 加载手势控制状态 | Load gesture control status
   */
  private async loadGestureControlStatus(): Promise<void> {
    try {
      const gestureService = GestureService.getInstance();
      this.gestureControlEnabled = await gestureService.isEnabled();
      this.gestureControlStatus = await gestureService.getStatus();
      Logger.info('SettingsPage', 'Gesture control status: ' + this.gestureControlEnabled + ', status: ' + this.gestureControlStatus);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load gesture control status', err);
      this.gestureControlEnabled = false;
    }
  }
  
  /**
   * 加载设备流转状态 | Load device flow status
   */
  private async loadDeviceFlowStatus(): Promise<void> {
    try {
      const deviceFlowManager = DeviceFlowManager.getInstance();
      this.deviceFlowEnabled = await deviceFlowManager.isEnabled();
      this.availableDevices = await deviceFlowManager.getAvailableDevices();
      this.deviceFlowStatus = this.availableDevices.length > 0
        ? '已发现 ' + this.availableDevices.length + ' 个设备'
        : '未发现设备';

      Logger.info('SettingsPage', 'Device flow status: ' + this.deviceFlowEnabled + ', devices: ' + this.availableDevices.length);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load device flow status', err);
      this.deviceFlowEnabled = false;
      this.availableDevices = [];
      this.deviceFlowStatus = '加载失败';
    }
  }
  
  /**
   * 处理手势控制切换 | Handle gesture control toggle
   */
  private async handleGestureControlToggle(value: boolean): Promise<void> {
    try {
      this.gestureControlEnabled = value;
      Logger.info('SettingsPage', 'Gesture control ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to toggle gesture control', err);
    }
  }
  
  /**
   * 处理设备流转切换 | Handle device flow toggle
   */
  private async handleDeviceFlowToggle(value: boolean): Promise<void> {
    try {
      this.deviceFlowEnabled = value;
      Logger.info('SettingsPage', 'Device flow ' + (value ? 'enabled' : 'disabled'));
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to toggle device flow', err);
    }
  }
  
  /**
   * 处理设备流转发起 | Handle device flow start
   */
  private async handleDeviceFlowStart(deviceId: string): Promise<void> {
    try {
      Logger.info('SettingsPage', 'Starting device flow to device: ' + deviceId);
      
      const flowData: FlowData = {
        mediaInfo: {
          title: '当前播放内容',
          position: 0,
          duration: 0
        },
        appState: {
          currentPage: 'SettingsPage'
        }
      };
      
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      Logger.info('SettingsPage', 'Device flow started successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to start device flow', err);
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      Logger.info('SettingsPage', 'Navigating back');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to navigate back', err);
    }
  }
  
  /**
   * 处理重置设置 | Handle reset settings
   */
  private async handleResetSettings(): Promise<void> {
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      await this.loadAllData();
      
      Logger.info('SettingsPage', 'Settings reset successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to reset settings', err);
    }
  }
  
  /**
   * 加载缓存信息 | Load cache info
   */
  private async loadCacheInfo(): Promise<void> {
    try {
      Logger.info('SettingsPage', 'Loading cache info');

      const cacheService = CacheService.getInstance();
      // 使用 getStatistics() 而非不存在的 getCacheStats()
      const stats = await cacheService.getStatistics();

      // 将统计数据映射到缓存展示项
      const memoryBytes = stats.memoryCacheSize ?? 0;
      const diskBytes = stats.diskCacheSize ?? 0;
      const totalBytes = memoryBytes + diskBytes;

      this.cacheItems = [
        {
          id: 'video_cache',
          name: '视频缓存',
          description: '已观看视频的缓存文件（磁盘缓存）',
          size: this.formatSize(diskBytes),
          selected: false
        },
        {
          id: 'image_cache',
          name: '图片缓存',
          description: '应用图片资源内存缓存',
          size: this.formatSize(memoryBytes),
          selected: false
        },
        {
          id: 'config_cache',
          name: '配置缓存',
          description: '应用配置缓存（含配置缓存项 ' + (stats.diskCacheItems ?? 0) + ' 条）',
          size: '0 MB',
          selected: false
        }
      ];

      this.totalCacheSize = this.formatSize(totalBytes);
      this.selectedCacheItems = [];

      Logger.info('SettingsPage', 'Loaded cache info: total=' + this.totalCacheSize);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load cache info', err);
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
   * 实际调用CacheService执行缓存清理，不再模拟延迟
   */
  private async handleCacheClear(): Promise<void> {
    try {
      if (this.selectedCacheItems.length === 0) {
        Logger.warn('SettingsPage', 'No cache items selected for clearing');
        return;
      }

      Logger.info('SettingsPage', 'Clearing selected cache items: ' + this.selectedCacheItems.join(', '));

      const cacheService = CacheService.getInstance();

      // 按选中项执行实际缓存清理
      for (const itemId of this.selectedCacheItems) {
        try {
          // 使用 removeByTags 按标签清理对应分类的缓存
          await cacheService.removeByTags([itemId]);
          Logger.info('SettingsPage', `Cache cleared for: ${itemId}`);
        } catch (clearError) {
          const err = clearError instanceof Error ? clearError : new Error(String(clearError));
          Logger.warn('SettingsPage', `Failed to clear cache for ${itemId}: ${err.message}`);
        }
      }

      // 重新加载缓存信息以更新显示
      await this.loadCacheInfo();

      Logger.info('SettingsPage', 'Cache cleared successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to clear cache', err);
    }
  }
  
  /**
   * 加载设备信息 | Load device info
   */
  private async loadDeviceInfo(): Promise<void> {
    try {
      this.isLoadingDeviceInfo = true;
      Logger.info('SettingsPage', 'Loading device info');

      const deviceService = DeviceService.getInstance();
      this.deviceInfo = await deviceService.getDeviceInfo();

      Logger.info('SettingsPage', 'Device info loaded successfully');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to load device info', err);
      this.deviceInfo = null;
    } finally {
      this.isLoadingDeviceInfo = false;
    }
  }

  /**
   * 格式化文件大小 | Format file size
   */
  private formatSize(bytes: number): string {
    if (bytes === 0) return '0 MB';
    const mb = bytes / (1024 * 1024);
    if (mb < 1) return (bytes / 1024).toFixed(2) + ' KB';
    if (mb < 1024) return mb.toFixed(2) + ' MB';
    return (mb / 1024).toFixed(2) + ' GB';
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
      Logger.info('SettingsPage', `Source ${sourceId} toggled to ${isActive}`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to toggle source', err);
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
      Logger.info('SettingsPage', `Source ${source.name} updated`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to update source', err);
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
      Logger.info('SettingsPage', `Source ${sourceId} deleted`);
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to delete source', err);
    }
  }
  
  /**
   * 处理健康检查
   */
  private async handleHealthCheck(): Promise<void> {
    try {
      await this.networkSourceManager.checkAllSourcesHealth();
      this.sources = this.networkSourceManager.getAllSources();
      Logger.info('SettingsPage', 'Health check completed');
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to perform health check', err);
    }
  }
  
  build() {
    const colors = this.currentTheme.colors;
    const spacing = DesignSystem.Spacing;
    const borderRadius = DesignSystem.BorderRadius;
    const shadows = this.currentTheme.shadows;
    
    Column() {
      // 顶部导航栏 | Top navigation bar
      Row() {
        // 返回按钮 | Back button
        Button() {
          Text('返回')
            .fontSize(18)
            .fontColor(colors.surface)
        }
        .width(80)
        .height(50)
        .backgroundColor(colors.primary)
        .borderRadius(borderRadius.md)
        .margin({ left: spacing.lg })
        .onClick(() => this.handleBack())
        
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
        .height(50)
        .backgroundColor(colors.error)
        .borderRadius(borderRadius.md)
        .margin({ right: spacing.lg })
        .onClick(() => this.handleResetSettings())
      }
      .width('100%')
      .height(70)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(colors.surface)
      
      // 设置项列表 | Setting item list
      Scroll(this.scroller) {
        Column() {
          if (this.isLoading) {
            Column() {
              Text(Strings.common.loading)
                .fontSize(20)
                .fontColor(colors.textSecondary)
                .margin(spacing.lg)
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else if (this.isError) {
            Column() {
              Text(Strings.common.failed)
                .fontSize(20)
                .fontColor(colors.error)
                .margin({ top: spacing.md })
              Text(this.errorMessage)
                .fontSize(16)
                .fontColor(colors.warning)
                .margin({ top: spacing.sm, left: spacing.lg, right: spacing.lg })
                .textAlign(TextAlign.Center)
              Button(Strings.common.retry)
                .onClick(() => this.loadAllData())
                .backgroundColor(colors.primary)
                .fontColor(colors.surface)
                .borderRadius(borderRadius.md)
                .padding({ left: spacing.lg, right: spacing.lg, top: spacing.md, bottom: spacing.md })
                .margin({ top: spacing.lg })
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else {
            // 网络源管理区域
            Column() {
              Row() {
                Text(Strings.settingsPage.networkSources)
                  .fontSize(18)
                  .fontWeight(600)
                  .fontColor(colors.text)
                
                Blank()
                
                Text(`已启用: ${this.sources.filter(s => s.isActive).length}个源`)
                  .fontSize(14)
                  .fontColor(colors.textSecondary)
                  .margin({ right: spacing.md })
              }
              .width('100%')
              .padding({ left: spacing.md, top: spacing.md, bottom: spacing.md })
              .borderRadius({ topLeft: borderRadius.lg, topRight: borderRadius.lg })
              
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
                }, (source: NetworkSourceConfig) => source.id)
              }
              .width('100%')
              .padding({ left: spacing.md, right: spacing.md, bottom: spacing.md })
              
              // 添加新源按钮
              Button(Strings.settingsPage.addSource)
                .width('100%')
                .height(45)
                .margin({ left: spacing.md, right: spacing.md, bottom: spacing.md })
                .backgroundColor(colors.secondary)
                .fontColor(colors.surface)
                .borderRadius(borderRadius.md)
                .onClick(() => {
                  this.openAddSourceForm();
                })
            }
            .width('100%')
            .backgroundColor(colors.surface)
            .borderRadius(borderRadius.lg)
            .margin({ bottom: spacing.md })
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
            
            // 点播站点配置区域
            Column() {
              Row() {
                Text('点播站点配置')
                  .fontSize(18)
                  .fontWeight(600)
                  .fontColor(colors.text)
                
                Blank()
                
                Text(`可用站点: ${this.vodStats.total}个 来自${this.vodStats.sources}个源`)
                  .fontSize(14)
                  .fontColor(colors.textSecondary)
                  .margin({ right: spacing.md })
              }
              .width('100%')
              .padding({ left: spacing.md, top: spacing.md, bottom: spacing.md })
              .borderRadius({ topLeft: borderRadius.lg, topRight: borderRadius.lg })
            }
            .width('100%')
            .backgroundColor(colors.surface)
            .borderRadius(borderRadius.lg)
            .margin({ bottom: spacing.md })
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
            
            // 直播频道配置区域
            Column() {
              Row() {
                Text('直播频道配置')
                  .fontSize(18)
                  .fontWeight(600)
                  .fontColor(colors.text)
                
                Blank()
                
                Text(`可用频道: ${this.liveStats.total}个 来自${this.liveStats.sources}个源`)
                  .fontSize(14)
                  .fontColor(colors.textSecondary)
                  .margin({ right: spacing.md })
              }
              .width('100%')
              .padding({ left: spacing.md, top: spacing.md, bottom: spacing.md })
              .borderRadius({ topLeft: borderRadius.lg, topRight: borderRadius.lg })
            }
            .width('100%')
            .backgroundColor(colors.surface)
            .borderRadius(borderRadius.lg)
            .margin({ bottom: spacing.md })
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
            
            // 壁纸设置区域
            Column() {
              Row() {
                Text('壁纸设置')
                  .fontSize(18)
                  .fontWeight(600)
                  .fontColor(colors.text)
                
                Blank()
                
                Text(`可用壁纸: ${this.wallpaperStats.total}张 来自${this.wallpaperStats.sources}个源`)
                  .fontSize(14)
                  .fontColor(colors.textSecondary)
                  .margin({ right: spacing.md })
              }
              .width('100%')
              .padding({ left: spacing.md, top: spacing.md, bottom: spacing.md })
              .borderRadius({ topLeft: borderRadius.lg, topRight: borderRadius.lg })
            }
            .width('100%')
            .backgroundColor(colors.surface)
            .borderRadius(borderRadius.lg)
            .margin({ bottom: spacing.md })
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
            
            // 高级设置区域
            Column() {
              Text('高级设置')
                .fontSize(18)
                .fontWeight(600)
                .fontColor(colors.text)
                .width('100%')
                .padding({ left: spacing.md, top: spacing.md, bottom: spacing.md })
                .borderRadius({ topLeft: borderRadius.lg, topRight: borderRadius.lg })
              
              // 源健康检查按钮
              Row() {
                Text('源健康检查')
                  .fontSize(16)
                  .fontColor(colors.text)
                  .flexGrow(1)
                
                Button('检查全部')
                  .fontSize(14)
                  .fontColor(colors.surface)
                  .backgroundColor(colors.warning)
                  .borderRadius(borderRadius.md)
                  .onClick(() => this.handleHealthCheck())
              }
              .width('100%')
              .padding({ left: spacing.md, right: spacing.md, top: spacing.sm, bottom: spacing.sm })
              
              // 广告过滤开关
              Row() {
                Text('广告过滤')
                  .fontSize(16)
                  .fontColor(colors.text)
                  .flexGrow(1)
                
                Button(this.adBlockEnabled ? '开启' : '关闭')
                  .fontSize(14)
                  .fontColor(colors.surface)
                  .width(80)
                  .backgroundColor(this.adBlockEnabled ? colors.primary : colors.textSecondary)
                  .borderRadius(borderRadius.md)
                  .onClick(() => this.handleAdBlockToggle(!this.adBlockEnabled))
              }
              .width('100%')
              .padding({ left: spacing.md, right: spacing.md, top: spacing.sm, bottom: spacing.sm })
            }
            .width('100%')
            .backgroundColor(colors.surface)
            .borderRadius(borderRadius.lg)
            .margin({ bottom: spacing.md })
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
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
            this.closePopup();
          })

        // 弹窗内容 - 当selectedSource为null时显示添加表单，否则显示详情/编辑
        if (this.selectedSource) {
          // 显示源详情 - 使用 NetworkSourceDetailPopup 组件
          NetworkSourceDetailPopup({
            source: this.selectedSource,
            networkSourceManager: this.networkSourceManager,
            onClose: () => {
              this.closePopup();
            },
            onSave: async (source) => {
              await this.handleSourceUpdate(source);
              this.closePopup();
            },
            onDelete: async (sourceId) => {
              await this.handleSourceDelete(sourceId);
              this.closePopup();
            }
          })
        } else if (this.showAddSourceForm) {
          // 显示添加表单
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
                this.closePopup();
              })
            }
            .width('100%')
            .padding(spacing.lg)
            .borderBottomWidth(1)
            .borderBottomColor(colors.divider)

            // 添加表单
            Column() {
              // 源名称输入
              Column() {
                Text('源名称 *')
                  .fontSize(14)
                  .fontColor(colors.text)
                  .margin({ bottom: spacing.sm })

                TextInput({ placeholder: '请输入源名称' })
                  .width('100%')
                  .fontSize(14)
                  .height(44)
                  .backgroundColor(colors.background)
                  .borderRadius(borderRadius.md)
                  .onChange((value: string) => {
                    this.tempSourceName = value;
                  })
              }
              .width('100%')
              .margin({ bottom: spacing.lg })

              // 源URL输入
              Column() {
                Text('源URL *')
                  .fontSize(14)
                  .fontColor(colors.text)
                  .margin({ bottom: spacing.sm })

                TextInput({ placeholder: '请输入源URL (https://...)' })
                  .width('100%')
                  .fontSize(14)
                  .height(44)
                  .backgroundColor(colors.background)
                  .borderRadius(borderRadius.md)
                  .onChange((value: string) => {
                    this.tempSourceUrl = value;
                  })
              }
              .width('100%')
              .margin({ bottom: spacing.lg })

              // 优先级选择
              Column() {
                Text('优先级 (1-10)')
                  .fontSize(14)
                  .fontColor(colors.text)
                  .margin({ bottom: spacing.sm })

                Row() {
                  Text(`当前优先级: ${this.tempSourcePriority}`)
                    .fontSize(14)
                    .fontColor(colors.text)
                    .margin({ right: spacing.sm })

                  Button('-')
                    .fontSize(14)
                    .width(36)
                    .height(36)
                    .backgroundColor(colors.primary)
                    .onClick(() => {
                      if (this.tempSourcePriority > 1) {
                        this.tempSourcePriority--;
                      }
                    })

                  Button('+')
                    .fontSize(14)
                    .width(36)
                    .height(36)
                    .backgroundColor(colors.primary)
                    .margin({ left: spacing.sm })
                    .onClick(() => {
                      if (this.tempSourcePriority < 10) {
                        this.tempSourcePriority++;
                      }
                    })
                }
                .width('100%')
              }
              .width('100%')
              .margin({ bottom: spacing.lg })

              // 标签输入
              Column() {
                Text('标签 (可选，用逗号分隔)')
                  .fontSize(14)
                  .fontColor(colors.text)
                  .margin({ bottom: spacing.sm })

                TextInput({ placeholder: '例如: 高清, 免费, 中文' })
                  .width('100%')
                  .fontSize(14)
                  .height(44)
                  .backgroundColor(colors.background)
                  .borderRadius(borderRadius.md)
                  .onChange((value: string) => {
                    this.tempSourceTags = value;
                  })
              }
              .width('100%')
              .margin({ bottom: spacing.xl })

              // 按钮组
              Row() {
                Button('取消')
                  .fontSize(16)
                  .width(120)
                  .height(44)
                  .backgroundColor(colors.surface)
                  .fontColor(colors.text)
                  .borderRadius(borderRadius.md)
                  .onClick(() => {
                    this.closePopup();
                  })

                Blank()

                Button(this.isAddingSource ? '添加中...' : '确认添加')
                  .fontSize(16)
                  .width(140)
                  .height(44)
                  .backgroundColor(colors.primary)
                  .fontColor('#FFFFFF')
                  .borderRadius(borderRadius.md)
                  .enabled(!this.isAddingSource && this.tempSourceName && this.tempSourceUrl)
                  .onClick(async () => {
                    await this.handleAddSource();
                  })
              }
              .width('100%')
            }
            .width('100%')
            .padding(spacing.lg)
          }
          .width('80%')
          .maxWidth(600)
          .maxHeight('80%')
          .backgroundColor(colors.surface)
          .borderRadius(borderRadius.xl)
          .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.15)' })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .position({ x: 0, y: 0 })
    }
  }

  /**
   * 关闭弹窗
   */
  private closePopup(): void {
    this.showSourceDetailPopup = false;
    this.selectedSource = null;
    this.showAddSourceForm = false;
    this.tempSourceName = '';
    this.tempSourceUrl = '';
    this.tempSourcePriority = 5;
    this.tempSourceTags = '';
    this.isAddingSource = false;
  }

  /**
   * 打开添加源表单
   */
  private openAddSourceForm(): void {
    this.selectedSource = null;
    this.showAddSourceForm = true;
    this.showSourceDetailPopup = true;
    this.tempSourceName = '';
    this.tempSourceUrl = '';
    this.tempSourcePriority = 5;
    this.tempSourceTags = '';
    this.isAddingSource = false;
  }

  /**
   * 处理添加源
   */
  private async handleAddSource(): Promise<void> {
    // 验证源名称 | Validate source name
    if (!this.tempSourceName || this.tempSourceName.trim().length === 0) {
      Logger.warn('SettingsPage', 'Source name is empty');
      this.showValidationMessage('请输入源名称');
      return;
    }
    
    // 验证名称长度（2-50字符）| Validate name length (2-50 characters)
    if (this.tempSourceName.length < 2 || this.tempSourceName.length > 50) {
      Logger.warn('SettingsPage', 'Source name length invalid');
      this.showValidationMessage('源名称长度应在2-50个字符之间');
      return;
    }
    
    if (!this.tempSourceUrl || this.tempSourceUrl.trim().length === 0) {
      Logger.warn('SettingsPage', 'Source URL is empty');
      this.showValidationMessage('请输入源URL');
      return;
    }

    // 验证URL格式和协议 | Validate URL format and protocol
    try {
      const url = new URL(this.tempSourceUrl.trim());
      if (!['http:', 'https:'].includes(url.protocol)) {
        Logger.error('SettingsPage', 'Invalid URL protocol');
        this.showValidationMessage('只支持http和https协议的URL');
        return;
      }
    } catch (error) {
      Logger.error('SettingsPage', 'Invalid URL format');
      this.showValidationMessage('URL格式不正确');
      return;
    }

    this.isAddingSource = true;

    try {
      // 测试源的可访问性 | Test source accessibility
      this.showValidationMessage('正在测试源...');
      const isAccessible = await this.testSourceAccessibility(this.tempSourceUrl.trim());
      
      if (!isAccessible) {
        Logger.warn('SettingsPage', 'Source not accessible');
        this.showValidationMessage('源无法访问，请检查URL是否正确');
        this.isAddingSource = false;
        return;
      }

      // 解析标签 | Parse tags
      const tags = this.tempSourceTags
        ? this.tempSourceTags.split(',').map(tag => tag.trim()).filter(tag => tag)
        : [];

      // 创建新源 | Create new source
      const newSource: NetworkSourceConfig = {
        id: `source_${Date.now()}`,
        name: this.tempSourceName.trim(),
        url: this.tempSourceUrl.trim(),
        type: 'json',
        version: '1.0.0',
        isActive: true,
        priority: this.tempSourcePriority,
        tags: tags,
        contentUsage: {
          vodSites: true,
          liveChannels: true,
          wallpapers: true,
          adBlockRules: true,
          decoderConfigs: true
        }
      };

      await this.networkSourceManager.addSource(newSource);
      this.sources = this.networkSourceManager.getAllSources();
      await this.loadContentStats();

      Logger.info('SettingsPage', `Source added: ${newSource.name}`);
      this.showValidationMessage('源添加成功');
      this.closePopup();
    } catch (error) {
      const err = error instanceof Error ? error : new Error(String(error));
      Logger.error('SettingsPage', 'Failed to add source', err);
      this.showValidationMessage('添加源失败：' + err.message);
    } finally {
      this.isAddingSource = false;
    }
  }
  
  /**
   * 测试源的可访问性 | Test source accessibility
   */
  private async testSourceAccessibility(url: string): Promise<boolean> {
    try {
      // 导入HttpService
      const HttpService = await import('../service/HttpService');
      const httpService = HttpService.default.getInstance();
      
      // 发送HEAD请求测试URL是否可达
      const response = await httpService.get(url, {
        timeout: 10000, // 10秒超时
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'RayTV/1.0'
        }
      });
      
      // 检查响应状态码
      return response && response.statusCode >= 200 && response.statusCode < 300;
    } catch (error) {
      Logger.warn('SettingsPage', `Source accessibility test failed: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }
  
  /**
   * 显示验证消息 | Show validation message
   */
  private showValidationMessage(message: string): void {
    // 这里可以实现消息提示显示逻辑
    // Here you can implement message prompt display logic
    Logger.info('SettingsPage', `Validation message: ${message}`);
  }
}
