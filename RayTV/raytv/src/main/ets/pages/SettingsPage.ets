import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { ConfigService } from '../service/config/ConfigService';
import { SettingService } from '../service/config/SettingService';
import { AdBlockManager } from '../service/adblock/AdBlockManager';
import { WallManager } from '../service/wallpaper/WallManager';
import { DeviceService } from '../service/device/DeviceService';
import { DataSyncService } from '../service/sync/DataSyncService';
import { VoiceAssistantManager } from '../service/voice/VoiceAssistantManager';
import { GestureService } from '../service/input/GestureService';
import CacheService, { CacheType } from '../service/cache/CacheService';
import ConfigSourceSwitcher from '../components/ConfigSourceSwitcher';
import display from '@ohos.display';
import { ScrollDirection, BarState, FlexAlign, FlexDirection, ImageFit, TextAlign, VerticalAlign, HorizontalAlign } from '@ohos/arkui';

// 设置项 | Setting item
interface SettingItem {
  id: string;
  title: string;
  description: string;
  icon?: string;
  type: 'button' | 'toggle' | 'select' | 'info';
  value?: string | boolean;
  onClick?: () => void;
  onToggle?: (value: boolean) => void;
}

// 壁纸项 | Wallpaper item
interface WallpaperItem {
  id: string;
  name: string;
  url: string;
  isCurrent: boolean;
}

@Entry
@Component
struct SettingsPage {
  private readonly TAG: string = 'SettingsPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理 | State management
  @State settingItems: SettingItem[] = [];
  @State isLoading: boolean = true;
  @State isError: boolean = false;
  @State errorMessage: string = '加载失败';
  @State showConfigSourcePopup: boolean = false;
  @State showVideoSourcePopup: boolean = false;
  @State showWallpaperPopup: boolean = false;
  @State showLiveSourcePopup: boolean = false;
  @State showAdBlockPopup: boolean = false;
  @State showAboutPopup: boolean = false;
  @State showCachePopup: boolean = false;
  @State showDeviceInfoPopup: boolean = false;
  @State showDataSyncPopup: boolean = false;
  @State showVoiceAssistantPopup: boolean = false;
  @State showGestureControlPopup: boolean = false;
  @State isLandscape: boolean = false;
  @State screenWidth: number = 0;
  @State screenHeight: number = 0;
  @State adBlockEnabled: boolean = false;
  @State dataSyncEnabled: boolean = false;
  @State voiceAssistantEnabled: boolean = false;
  @State gestureControlEnabled: boolean = false;
  @State wallpapers: WallpaperItem[] = [];
  @State selectedWallpaper: WallpaperItem | null = null;
  @State versionInfo: string = '6.1.6';
  @State cacheItems: CacheItem[] = [];
  @State selectedCacheItems: string[] = [];
  @State totalCacheSize: string = '0 MB';
  // 设备信息状态 | Device info state
  @State deviceInfo: any = null;
  @State isLoadingDeviceInfo: boolean = false;
  // 数据同步状态 | Data sync state
  @State syncStatus: string = '未同步';
  @State lastSyncTime: string = '从未';
  @State syncDevices: string[] = [];
  // 语音助手状态 | Voice assistant state
  @State voiceAssistantStatus: string = '未初始化';
  // 手势控制状态 | Gesture control state
  @State gestureControlStatus: string = '未初始化';
  
  // 缓存项 | Cache item
  interface CacheItem {
    id: string;
    name: string;
    description: string;
    size: string;
    selected: boolean;
  }
  
  // 服务实例 | Service instances
  private cacheService: CacheService = CacheService.getInstance();
  
  // 服务实例 | Service instances
  private configService: ConfigService = ConfigService.getInstance();
  private settingService: SettingService = SettingService.getInstance();
  private adBlockManager: AdBlockManager = AdBlockManager.getInstance();
  private wallManager: WallManager = WallManager.getInstance();
  private deviceService: DeviceService = DeviceService.getInstance();
  private dataSyncService: DataSyncService = DataSyncService.getInstance();
  private voiceAssistantManager: VoiceAssistantManager = VoiceAssistantManager.getInstance();
  private gestureService: GestureService = GestureService.getInstance();
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info(this.TAG, 'SettingsPage about to appear');
    
    // 初始化屏幕信息 | Initialize screen information
    this.initScreenInfo();
    
    // 加载设置项 | Load setting items
    this.loadSettings();
    
    // 加载广告过滤状态 | Load ad block status
    this.loadAdBlockStatus();
    
    // 加载数据同步状态 | Load data sync status
    this.loadDataSyncStatus();
    
    // 加载语音助手状态 | Load voice assistant status
    this.loadVoiceAssistantStatus();
    
    // 加载手势控制状态 | Load gesture control status
    this.loadGestureControlStatus();
    
    // 加载壁纸列表 | Load wallpaper list
    this.loadWallpapers();
    
    // 加载版本信息 | Load version info
    this.loadVersionInfo();
    
    // 加载缓存信息 | Load cache info
    this.loadCacheInfo();
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
  
  /**
   * 加载设置项 | Load setting items
   */
  private async loadSettings(): Promise<void> {
    try {
      this.isLoading = true;
      this.isError = false;
      
      Logger.info(this.TAG, 'Loading settings');
      
      // 构建设置项 | Build setting items
      this.settingItems = [
        {
          id: 'config_source',
          title: '配置源管理',
          description: '添加、管理和切换配置源',
          type: 'button',
          onClick: () => this.showConfigSourcePopup = true
        },
        {
          id: 'video_source',
          title: '片源选择',
          description: '根据配置源读取可用片源',
          type: 'button',
          onClick: () => this.showVideoSourcePopup = true
        },
        {
          id: 'wallpaper',
          title: '软件壁纸',
          description: '切换应用壁纸',
          type: 'button',
          onClick: () => this.showWallpaperPopup = true
        },
        {
          id: 'live_source',
          title: '直播源设置',
          description: '切换直播源配置',
          type: 'button',
          onClick: () => this.showLiveSourcePopup = true
        },
        {
          id: 'ad_block',
          title: '广告过滤',
          description: '开启或关闭广告过滤',
          type: 'toggle',
          value: this.adBlockEnabled,
          onToggle: (value: boolean) => this.handleAdBlockToggle(value)
        },
        {
          id: 'data_sync',
          title: '数据同步',
          description: '开启或关闭多设备数据同步',
          type: 'toggle',
          value: this.dataSyncEnabled,
          onToggle: (value: boolean) => this.handleDataSyncToggle(value)
        },
        {
          id: 'voice_assistant',
          title: '语音助手',
          description: '开启或关闭语音助手功能',
          type: 'toggle',
          value: this.voiceAssistantEnabled,
          onToggle: (value: boolean) => this.handleVoiceAssistantToggle(value)
        },
        {
          id: 'gesture_control',
          title: '手势控制',
          description: '开启或关闭手势控制功能',
          type: 'toggle',
          value: this.gestureControlEnabled,
          onToggle: (value: boolean) => this.handleGestureControlToggle(value)
        },
        {
          id: 'cache',
          title: '缓存管理',
          description: '清理视频内容和设置配置缓存',
          type: 'button',
          onClick: () => this.showCachePopup = true
        },
        {
          id: 'device_info',
          title: '设备信息',
          description: '查看和管理设备信息',
          type: 'button',
          onClick: () => this.showDeviceInfoPopup = true
        },
        {
          id: 'about',
          title: '关于',
          description: '版本信息和其他信息',
          type: 'button',
          onClick: () => this.showAboutPopup = true
        }
      ];
      
      Logger.info(this.TAG, 'Settings loaded successfully');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load settings: ${errorMsg}`);
      this.isError = true;
      this.errorMessage = errorMsg;
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载广告过滤状态 | Load ad block status
   */
  private async loadAdBlockStatus(): Promise<void> {
    try {
      const status = await this.adBlockManager.isEnabled();
      this.adBlockEnabled = status;
      // 更新设置项值 | Update setting item value
      const adBlockItem = this.settingItems.find(item => item.id === 'ad_block');
      if (adBlockItem) {
        adBlockItem.value = status;
      }
      Logger.info(this.TAG, `Ad block status: ${status}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load ad block status: ${error}`);
      this.adBlockEnabled = false;
    }
  }
  
  /**
   * 加载壁纸列表 | Load wallpaper list
   */
  private async loadWallpapers(): Promise<void> {
    try {
      // 调用实际的WallManager获取壁纸列表 | Call actual WallManager to get wallpaper list
      const result = await this.wallManager.getAvailableWallpapers();
      
      if (result.isSuccess() && result.data) {
        this.wallpapers = result.data.map((wallpaper: any) => ({
          id: wallpaper.id || wallpaper.url,
          name: wallpaper.name || `壁纸${result.data.indexOf(wallpaper) + 1}`,
          url: wallpaper.url,
          isCurrent: wallpaper.isCurrent || false
        }));
        
        // 找到当前选中的壁纸 | Find currently selected wallpaper
        this.selectedWallpaper = this.wallpapers.find(wallpaper => wallpaper.isCurrent) || null;
        Logger.info(this.TAG, `Loaded ${this.wallpapers.length} wallpapers`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load wallpapers: ${error}`);
      this.wallpapers = [];
    }
  }
  
  /**
   * 加载版本信息 | Load version info
   */
  private async loadVersionInfo(): Promise<void> {
    try {
      // 调用实际的SettingService获取版本信息 | Call actual SettingService to get version info
      const result = await this.settingService.getVersionInfo();
      
      if (result.isSuccess() && result.data) {
        this.versionInfo = result.data.version || '6.1.6';
        Logger.info(this.TAG, `Version info: ${this.versionInfo}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to load version info: ${error}`);
    }
  }
  
  /**
   * 处理广告过滤切换 | Handle ad block toggle
   */
  private async handleAdBlockToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的AdBlockManager切换广告过滤状态 | Call actual AdBlockManager to toggle ad block status
      const result = await this.adBlockManager.setEnabled(value);
      
      if (result.isSuccess()) {
        this.adBlockEnabled = value;
        // 更新设置项值 | Update setting item value
        const adBlockItem = this.settingItems.find(item => item.id === 'ad_block');
        if (adBlockItem) {
          adBlockItem.value = value;
        }
        Logger.info(this.TAG, `Ad block ${value ? 'enabled' : 'disabled'}`);
      } else {
        Logger.error(this.TAG, `Failed to toggle ad block: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle ad block: ${error}`);
    }
  }
  
  /**
   * 加载数据同步状态 | Load data sync status
   */
  private async loadDataSyncStatus(): Promise<void> {
    try {
      const status = await this.dataSyncService.isEnabled();
      this.dataSyncEnabled = status;
      // 更新设置项值 | Update setting item value
      const dataSyncItem = this.settingItems.find(item => item.id === 'data_sync');
      if (dataSyncItem) {
        dataSyncItem.value = status;
      }
      
      // 加载同步状态信息 | Load sync status info
      const syncStatus = await this.dataSyncService.getSyncStatus();
      this.syncStatus = syncStatus.status || '未同步';
      this.lastSyncTime = syncStatus.lastSyncTime || '从未';
      this.syncDevices = syncStatus.devices || [];
      
      Logger.info(this.TAG, `Data sync status: ${status}, sync status: ${this.syncStatus}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load data sync status: ${error}`);
      this.dataSyncEnabled = false;
    }
  }
  
  /**
   * 处理数据同步切换 | Handle data sync toggle
   */
  private async handleDataSyncToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的DataSyncService切换数据同步状态 | Call actual DataSyncService to toggle data sync status
      const result = await this.dataSyncService.setEnabled(value);
      
      if (result.isSuccess()) {
        this.dataSyncEnabled = value;
        // 更新设置项值 | Update setting item value
        const dataSyncItem = this.settingItems.find(item => item.id === 'data_sync');
        if (dataSyncItem) {
          dataSyncItem.value = value;
        }
        
        // 如果开启同步，立即执行一次同步 | If enabled, perform a sync immediately
        if (value) {
          await this.performSync();
        }
        
        Logger.info(this.TAG, `Data sync ${value ? 'enabled' : 'disabled'}`);
      } else {
        Logger.error(this.TAG, `Failed to toggle data sync: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle data sync: ${error}`);
    }
  }
  
  /**
   * 执行数据同步 | Perform data sync
   */
  private async performSync(): Promise<void> {
    try {
      this.syncStatus = '同步中...';
      
      const result = await this.dataSyncService.syncData();
      
      if (result.isSuccess()) {
        this.syncStatus = '同步成功';
        this.lastSyncTime = new Date().toLocaleString();
        
        // 重新加载同步状态信息 | Reload sync status info
        const syncStatus = await this.dataSyncService.getSyncStatus();
        this.syncDevices = syncStatus.devices || [];
        
        Logger.info(this.TAG, 'Data sync completed successfully');
      } else {
        this.syncStatus = '同步失败';
        Logger.error(this.TAG, `Failed to sync data: ${result.message}`);
      }
    } catch (error) {
      this.syncStatus = '同步失败';
      Logger.error(this.TAG, `Failed to sync data: ${error}`);
    }
  }
  
  /**
   * 加载语音助手状态 | Load voice assistant status
   */
  private async loadVoiceAssistantStatus(): Promise<void> {
    try {
      const status = await this.voiceAssistantManager.isEnabled();
      this.voiceAssistantEnabled = status;
      // 更新设置项值 | Update setting item value
      const voiceAssistantItem = this.settingItems.find(item => item.id === 'voice_assistant');
      if (voiceAssistantItem) {
        voiceAssistantItem.value = status;
      }
      
      // 加载语音助手状态信息 | Load voice assistant status info
      const voiceStatus = await this.voiceAssistantManager.getStatus();
      this.voiceAssistantStatus = voiceStatus.status || '未初始化';
      
      Logger.info(this.TAG, `Voice assistant status: ${status}, status: ${this.voiceAssistantStatus}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load voice assistant status: ${error}`);
      this.voiceAssistantEnabled = false;
    }
  }
  
  /**
   * 处理语音助手切换 | Handle voice assistant toggle
   */
  private async handleVoiceAssistantToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的VoiceAssistantManager切换语音助手状态 | Call actual VoiceAssistantManager to toggle voice assistant status
      const result = await this.voiceAssistantManager.setEnabled(value);
      
      if (result.isSuccess()) {
        this.voiceAssistantEnabled = value;
        // 更新设置项值 | Update setting item value
        const voiceAssistantItem = this.settingItems.find(item => item.id === 'voice_assistant');
        if (voiceAssistantItem) {
          voiceAssistantItem.value = value;
        }
        
        // 如果开启语音助手，初始化语音识别 | If enabled, initialize voice recognition
        if (value) {
          await this.voiceAssistantManager.initializeVoiceRecognition();
        }
        
        Logger.info(this.TAG, `Voice assistant ${value ? 'enabled' : 'disabled'}`);
      } else {
        Logger.error(this.TAG, `Failed to toggle voice assistant: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle voice assistant: ${error}`);
    }
  }
  
  /**
   * 加载手势控制状态 | Load gesture control status
   */
  private async loadGestureControlStatus(): Promise<void> {
    try {
      const status = await this.gestureService.isEnabled();
      this.gestureControlEnabled = status;
      // 更新设置项值 | Update setting item value
      const gestureControlItem = this.settingItems.find(item => item.id === 'gesture_control');
      if (gestureControlItem) {
        gestureControlItem.value = status;
      }
      
      // 加载手势控制状态信息 | Load gesture control status info
      const gestureStatus = await this.gestureService.getStatus();
      this.gestureControlStatus = gestureStatus.status || '未初始化';
      
      Logger.info(this.TAG, `Gesture control status: ${status}, status: ${this.gestureControlStatus}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load gesture control status: ${error}`);
      this.gestureControlEnabled = false;
    }
  }
  
  /**
   * 处理手势控制切换 | Handle gesture control toggle
   */
  private async handleGestureControlToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的GestureService切换手势控制状态 | Call actual GestureService to toggle gesture control status
      const result = await this.gestureService.setEnabled(value);
      
      if (result.isSuccess()) {
        this.gestureControlEnabled = value;
        // 更新设置项值 | Update setting item value
        const gestureControlItem = this.settingItems.find(item => item.id === 'gesture_control');
        if (gestureControlItem) {
          gestureControlItem.value = value;
        }
        
        // 如果开启手势控制，初始化手势识别 | If enabled, initialize gesture recognition
        if (value) {
          await this.gestureService.initializeGestureRecognition();
        }
        
        Logger.info(this.TAG, `Gesture control ${value ? 'enabled' : 'disabled'}`);
      } else {
        Logger.error(this.TAG, `Failed to toggle gesture control: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle gesture control: ${error}`);
    }
  }
  
  /**
   * 处理壁纸选择 | Handle wallpaper selection
   */
  private async handleWallpaperSelect(wallpaper: WallpaperItem): Promise<void> {
    try {
      // 调用实际的WallManager设置壁纸 | Call actual WallManager to set wallpaper
      const result = await this.wallManager.setWallpaper(wallpaper.id);
      
      if (result.isSuccess()) {
        // 更新壁纸状态 | Update wallpaper status
        this.wallpapers.forEach(w => {
          w.isCurrent = w.id === wallpaper.id;
        });
        this.selectedWallpaper = wallpaper;
        // 关闭弹窗 | Close popup
        this.showWallpaperPopup = false;
        Logger.info(this.TAG, `Wallpaper set to: ${wallpaper.name}`);
      } else {
        Logger.error(this.TAG, `Failed to set wallpaper: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to set wallpaper: ${error}`);
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      Logger.info(this.TAG, 'Navigating back');
    } catch (error) {
      Logger.error(this.TAG, `Failed to navigate back: ${error}`);
    }
  }
  
  /**
   * 处理重置设置 | Handle reset settings
   */
  private async handleResetSettings(): Promise<void> {
    try {
      // 调用实际的ConfigService重置设置 | Call actual ConfigService to reset settings
      const result = await this.configService.resetAllConfig();
      
      if (result.isSuccess()) {
        // 重新加载设置 | Reload settings
        await this.loadSettings();
        await this.loadAdBlockStatus();
        await this.loadWallpapers();
        Logger.info(this.TAG, 'Settings reset successfully');
      } else {
        Logger.error(this.TAG, `Failed to reset settings: ${result.message}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to reset settings: ${error}`);
    }
  }
  
  /**
   * 加载缓存信息 | Load cache info
   */
  private async loadCacheInfo(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Loading cache info');
      
      // 模拟缓存数据 | Simulate cache data
      this.cacheItems = [
        {
          id: 'video_cache',
          name: '视频内容缓存',
          description: '优化视频内容进行流畅播放的缓存',
          size: '156 MB',
          selected: true
        },
        {
          id: 'config_cache',
          name: '设置配置缓存',
          description: '记录设置内容、配置源、片源选择等信息',
          size: '12 MB',
          selected: false
        },
        {
          id: 'playback_settings',
          name: '播放设置缓存',
          description: '记录播放倍速、片头片尾、播放进度等设置',
          size: '8 MB',
          selected: false
        }
      ];
      
      // 计算总缓存大小 | Calculate total cache size
      const totalSize = 156 + 12 + 8;
      this.totalCacheSize = `${totalSize} MB`;
      
      // 初始化选中项 | Initialize selected items
      this.selectedCacheItems = this.cacheItems.filter(item => item.selected).map(item => item.id);
      
      Logger.info(this.TAG, `Loaded cache info: ${this.totalCacheSize}`);
    } catch (error) {
      Logger.error(this.TAG, `Failed to load cache info: ${error}`);
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
      
      // 更新选中项列表 | Update selected items list
      this.selectedCacheItems = this.cacheItems.filter(item => item.selected).map(item => item.id);
    }
  }
  
  /**
   * 处理缓存清理 | Handle cache clear
   */
  private async handleCacheClear(): Promise<void> {
    try {
      if (this.selectedCacheItems.length === 0) {
        Logger.warn(this.TAG, 'No cache items selected for clearing');
        return;
      }
      
      Logger.info(this.TAG, `Clearing selected cache items: ${this.selectedCacheItems.join(', ')}`);
      
      // 调用实际的CacheService清理缓存 | Call actual CacheService to clear cache
      for (const itemId of this.selectedCacheItems) {
        if (itemId === 'video_cache') {
          await this.cacheService.clearCache(CacheType.VIDEO);
        } else if (itemId === 'config_cache') {
          await this.cacheService.clearCache(CacheType.CONFIG);
        } else if (itemId === 'playback_settings') {
          await this.cacheService.clearCache(CacheType.PLAYBACK_SETTINGS);
        }
      }
      
      // 重新加载缓存信息 | Reload cache info
      await this.loadCacheInfo();
      
      Logger.info(this.TAG, 'Cache cleared successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to clear cache: ${error}`);
    }
  }
  
  /**
   * 加载设备信息 | Load device info
   */
  private async loadDeviceInfo(): Promise<void> {
    try {
      this.isLoadingDeviceInfo = true;
      Logger.info(this.TAG, 'Loading device info');
      
      // 调用实际的DeviceService获取设备信息 | Call actual DeviceService to get device info
      const result = await this.deviceService.getDeviceInfo();
      
      if (result.isSuccess() && result.data) {
        this.deviceInfo = result.data;
        Logger.info(this.TAG, 'Device info loaded successfully');
      } else {
        Logger.warn(this.TAG, `Failed to load device info: ${result.message}`);
        this.deviceInfo = null;
      }
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      Logger.error(this.TAG, `Failed to load device info: ${errorMsg}`);
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
    
    // 更新选中项列表 | Update selected items list
    this.selectedCacheItems = selectAll ? this.cacheItems.map(item => item.id) : [];
  }
  
  // 渲染缓存管理弹窗 | Render cache management popup
  @Builder
  renderCachePopup() {
    if (this.showCachePopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showCachePopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('缓存管理')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showCachePopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
        // 总缓存大小 | Total cache size
        Row() {
          Text('总缓存大小:')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ right: 10 })
          
          Text(this.totalCacheSize)
            .fontSize(16)
            .fontColor('#FF5722')
            .fontWeight(600)
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 全选按钮 | Select all button
        Button() {
          Text(this.selectedCacheItems.length === this.cacheItems.length ? '取消全选' : '全选')
            .fontSize(14)
            .fontColor('#FFFFFF')
        }
        .width(120)
        .height(40)
        .backgroundColor('#2196F3')
        .borderRadius(6)
        .margin({ bottom: 20 })
        .onClick(() => this.handleSelectAll(this.selectedCacheItems.length !== this.cacheItems.length))
        
        // 缓存项列表 | Cache item list
        Column() {
          ForEach(this.cacheItems, (item: any) => {
            Row() {
              Button() {
                Text(item.selected ? '✓' : '')
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
              .width(40)
              .height(40)
              .backgroundColor(item.selected ? '#4CAF50' : '#E0E0E0')
              .borderRadius(6)
              .margin({ right: 15 })
              .onClick(() => this.handleCacheItemSelect(item.id))
              
              Column() {
                Row() {
                  Text(item.name)
                    .fontSize(16)
                    .fontWeight(500)
                    .fontColor('#333333')
                    .flexGrow(1)
                  
                  Text(item.size)
                    .fontSize(14)
                    .fontColor('#666666')
                }
                
                Text(item.description)
                  .fontSize(12)
                  .fontColor('#999999')
                  .margin({ top: 5 })
              }
              .flexGrow(1)
            }
            .width('100%')
            .padding(15)
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .margin({ bottom: 10 })
            .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 1 })
          })
        }
        .width('100%')
        .margin({ bottom: 20 })
        
        // 清理按钮 | Clear button
        Button() {
          Text('清理选中项')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height(50)
        .backgroundColor('#F44336')
        .borderRadius(8)
        .onClick(() => this.handleCacheClear())
        .enabled(this.selectedCacheItems.length > 0)
      }
      .width('80%')
      .maxWidth(600)
      .padding(24)
      .backgroundColor('#FFFFFF')
      .borderRadius(12)
      .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染设置项 | Render setting item
  @Builder
  renderSettingItem(item: SettingItem) {
    Column() {
      Row() {
        // 设置项信息 | Setting item info
        Column() {
          Text(item.title)
            .fontSize(18)
            .fontWeight(600)
            .fontColor('#333333')
            .margin({ bottom: 5 })
          
          Text(item.description)
            .fontSize(14)
            .fontColor('#666666')
        }
        .flexGrow(1)
        .alignItems(HorizontalAlign.Start)
        
        // 操作区域 | Action area
        Column() {
          if (item.type === 'button') {
            Button() {
              Text('设置')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
            .width(100)
            .height(40)
            .backgroundColor('#4CAF50')
            .borderRadius(6)
            .onClick(() => {
              if (item.onClick) {
                item.onClick();
              }
            })
          } else if (item.type === 'toggle') {
            Button() {
              Text(item.value === true ? '开启' : '关闭')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(80)
            .height(40)
            .backgroundColor(item.value === true ? '#4CAF50' : '#9E9E9E')
            .borderRadius(6)
            .onClick(() => {
              if (item.onToggle) {
                item.onToggle(item.value !== true);
              }
            })
          } else if (item.type === 'info') {
            Text(item.value as string)
              .fontSize(14)
              .fontColor('#666666')
          }
        }
        .margin({ left: 20 })
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#FFFFFF')
      .borderRadius(10)
      .margin({ bottom: 15 })
      .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
    }
    .width('100%')
  }
  
  // 渲染配置源弹窗 | Render config source popup
  @Builder
  renderConfigSourcePopup() {
    if (this.showConfigSourcePopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showConfigSourcePopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('配置源管理')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showConfigSourcePopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          // 配置源切换器 | Config source switcher
          ConfigSourceSwitcher({
            onClose: () => this.showConfigSourcePopup = false
          })
          .width('100%')
          .height(400)
        }
        .width('80%')
        .maxWidth(800)
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染壁纸选择弹窗 | Render wallpaper selection popup
  @Builder
  renderWallpaperPopup() {
    if (this.showWallpaperPopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showWallpaperPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('选择壁纸')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showWallpaperPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
          
          // 壁纸列表 | Wallpaper list
          Column() {
            ForEach(this.wallpapers, (wallpaper: WallpaperItem) => {
              Column() {
                Image(wallpaper.url || 'https://via.placeholder.com/200x100?text=Wallpaper')
                  .width('100%')
                  .height(150)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .backgroundColor('#F5F5F5')
                  .margin({ bottom: 10 })
                
                Row() {
                  Text(wallpaper.name)
                    .fontSize(16)
                    .fontColor('#333333')
                    .flexGrow(1)
                  
                  if (wallpaper.isCurrent) {
                    Text('当前')
                      .fontSize(14)
                      .fontColor('#4CAF50')
                  } else {
                    Button() {
                      Text('选择')
                        .fontSize(14)
                        .fontColor('#FFFFFF')
                    }
                    .width(80)
                    .height(36)
                    .backgroundColor('#2196F3')
                    .borderRadius(6)
                    .onClick(() => this.handleWallpaperSelect(wallpaper))
                  }
                }
              }
              .width('100%')
              .padding(15)
              .backgroundColor('#FFFFFF')
              .borderRadius(10)
              .margin({ bottom: 15 })
              .shadow({ radius: 2, color: 'rgba(0, 0, 0, 0.1)', offsetY: 2 })
            })
          }
          .width('100%')
        }
        .width('80%')
        .maxWidth(600)
        .maxHeight('80%')
        .padding(24)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染视频源弹窗 | Render video source popup
  @Builder
  renderVideoSourcePopup() {
    if (this.showVideoSourcePopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showVideoSourcePopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('片源选择')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showVideoSourcePopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          Text('片源选择功能正在开发中')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 30 })
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showVideoSourcePopup = false)
        }
        .width('60%')
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染直播源弹窗 | Render live source popup
  @Builder
  renderLiveSourcePopup() {
    if (this.showLiveSourcePopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showLiveSourcePopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('直播源设置')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showLiveSourcePopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          Text('直播源设置功能正在开发中')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 30 })
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showLiveSourcePopup = false)
        }
        .width('60%')
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染广告过滤弹窗 | Render ad block popup
  @Builder
  renderAdBlockPopup() {
    if (this.showAdBlockPopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showAdBlockPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('广告过滤设置')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showAdBlockPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          Text('广告过滤功能已集成到设置项中')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 30 })
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showAdBlockPopup = false)
        }
        .width('60%')
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染关于弹窗 | Render about popup
  @Builder
  renderAboutPopup() {
    if (this.showAboutPopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showAboutPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('关于 RayTV')
              .fontSize(24)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showAboutPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          Text(`版本: ${this.versionInfo}`)
            .fontSize(18)
            .fontColor('#4CAF50')
            .margin({ bottom: 15 })
          
          Text('RayTV 是一款功能强大的影视播放应用，支持多种视频源和直播源，提供流畅的观影体验。')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ bottom: 20 })
            .textAlign(TextAlign.Center)
          
          Text('© 2024 RayTV. All rights reserved.')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ bottom: 30 })
          
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showAboutPopup = false)
        }
        .width('60%')
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染设备信息弹窗 | Render device info popup
  @Builder
  renderDeviceInfoPopup() {
    if (this.showDeviceInfoPopup) {
      // 加载设备信息
      if (!this.deviceInfo) {
        this.loadDeviceInfo();
      }
      
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showDeviceInfoPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('设备信息')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showDeviceInfoPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          if (this.isLoadingDeviceInfo) {
            Text('加载中...')
              .fontSize(16)
              .fontColor('#666666')
              .margin({ bottom: 30 })
          } else if (!this.deviceInfo) {
            Text('获取设备信息失败')
              .fontSize(16)
              .fontColor('#FF5722')
              .margin({ bottom: 30 })
            
            Button() {
              Text('重试')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(100)
            .height(40)
            .backgroundColor('#4CAF50')
            .borderRadius(6)
            .onClick(() => this.loadDeviceInfo())
            .margin({ bottom: 20 })
          } else {
            Column() {
              // 设备基本信息 | Basic device info
              Text('基本信息')
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(600)
                .margin({ bottom: 15 })
              
              Row() {
                Text('设备型号:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(this.deviceInfo.model || '未知')
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('设备厂商:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(this.deviceInfo.manufacturer || '未知')
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('系统版本:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(this.deviceInfo.osVersion || '未知')
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              // 屏幕信息 | Screen info
              Text('屏幕信息')
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(600)
                .margin({ top: 20, bottom: 15 })
              
              Row() {
                Text('屏幕尺寸:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(`${this.screenWidth} × ${this.screenHeight}`)
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('屏幕方向:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(this.isLandscape ? '横屏' : '竖屏')
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              // 网络信息 | Network info
              Text('网络信息')
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(600)
                .margin({ top: 20, bottom: 15 })
              
              Row() {
                Text('网络状态:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(this.deviceInfo.networkStatus || '未知')
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('IP地址:')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width(100)
                
                Text(this.deviceInfo.ipAddress || '未知')
                  .fontSize(14)
                  .fontColor('#333333')
                  .flexGrow(1)
              }
              .width('100%')
              .margin({ bottom: 10 })
            }
            .width('100%')
            .margin({ bottom: 20 })
          }
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showDeviceInfoPopup = false)
        }
        .width('80%')
        .maxWidth(600)
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染数据同步弹窗 | Render data sync popup
  @Builder
  renderDataSyncPopup() {
    if (this.showDataSyncPopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showDataSyncPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('数据同步管理')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showDataSyncPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          // 同步状态信息 | Sync status info
          Column() {
            Row() {
              Text('同步状态:')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              
              Text(this.syncStatus)
                .fontSize(16)
                .fontColor(this.syncStatus === '同步成功' ? '#4CAF50' : this.syncStatus === '同步失败' ? '#FF5722' : '#333333')
                .flexGrow(1)
            }
            .width('100%')
            .margin({ bottom: 15 })
            
            Row() {
              Text('上次同步:')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              
              Text(this.lastSyncTime)
                .fontSize(16)
                .fontColor('#333333')
                .flexGrow(1)
            }
            .width('100%')
            .margin({ bottom: 15 })
            
            Row() {
              Text('同步设备:')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              
              Text(this.syncDevices.length > 0 ? `${this.syncDevices.length} 台设备` : '无')
                .fontSize(16)
                .fontColor('#333333')
                .flexGrow(1)
            }
            .width('100%')
            .margin({ bottom: 30 })
            
            // 同步设备列表 | Sync device list
            if (this.syncDevices.length > 0) {
              Text('同步设备列表')
                .fontSize(16)
                .fontColor('#333333')
                .fontWeight(600)
                .margin({ bottom: 15 })
              
              Column() {
                ForEach(this.syncDevices, (device: string) => {
                  Text(device)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ bottom: 8 })
                    .textAlign(TextAlign.Center)
                })
              }
              .width('100%')
              .margin({ bottom: 30 })
            }
          }
          .width('100%')
          .margin({ bottom: 20 })
        
          // 操作按钮 | Action buttons
          Row() {
            Button() {
              Text('立即同步')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(45)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .margin({ right: 15 })
            .onClick(() => this.performSync())
            
            Button() {
              Text('刷新状态')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(45)
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .onClick(() => this.loadDataSyncStatus())
          }
          .margin({ bottom: 20 })
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showDataSyncPopup = false)
        }
        .width('80%')
        .maxWidth(600)
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染语音助手弹窗 | Render voice assistant popup
  @Builder
  renderVoiceAssistantPopup() {
    if (this.showVoiceAssistantPopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showVoiceAssistantPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('语音助手管理')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showVoiceAssistantPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          // 语音助手状态信息 | Voice assistant status info
          Column() {
            Row() {
              Text('助手状态:')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              
              Text(this.voiceAssistantStatus)
                .fontSize(16)
                .fontColor(this.voiceAssistantStatus === '已初始化' ? '#4CAF50' : '#333333')
                .flexGrow(1)
            }
            .width('100%')
            .margin({ bottom: 30 })
            
            Text('语音助手功能支持以下命令:')
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(600)
              .margin({ bottom: 15 })
            
            Column() {
              Text('• 打开/关闭语音助手')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 播放/暂停视频')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 快进/快退视频')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 切换到下一集')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 打开/关闭弹幕')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
            }
            .width('100%')
            .margin({ bottom: 30 })
          }
          .width('100%')
          .margin({ bottom: 20 })
        
          // 操作按钮 | Action buttons
          Row() {
            Button() {
              Text('测试语音')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(45)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .margin({ right: 15 })
            .onClick(() => {
              // 测试语音助手
              this.voiceAssistantManager.testVoiceRecognition().catch(error => {
                Logger.error(this.TAG, `Failed to test voice recognition: ${error}`);
              });
            })
            
            Button() {
              Text('刷新状态')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(45)
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .onClick(() => this.loadVoiceAssistantStatus())
          }
          .margin({ bottom: 20 })
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showVoiceAssistantPopup = false)
        }
        .width('80%')
        .maxWidth(600)
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  // 渲染手势控制弹窗 | Render gesture control popup
  @Builder
  renderGestureControlPopup() {
    if (this.showGestureControlPopup) {
      Stack({
        alignContent: Alignment.Center
      }) {
        // 半透明背景 | Semi-transparent background
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.7)')
          .onClick(() => this.showGestureControlPopup = false)
        
        // 弹窗内容 | Popup content
        Column() {
          Row() {
            Text('手势控制管理')
              .fontSize(20)
              .fontWeight(700)
              .fontColor('#333333')
              .flexGrow(1)
              .textAlign(TextAlign.Center)
            
            Button() {
              Text('×')
                .fontSize(24)
                .fontColor('#999999')
            }
            .width(40)
            .height(40)
            .backgroundColor('transparent')
            .onClick(() => this.showGestureControlPopup = false)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .alignItems(VerticalAlign.Center)
          .margin({ bottom: 20 })
        
          // 手势控制状态信息 | Gesture control status info
          Column() {
            Row() {
              Text('控制状态:')
                .fontSize(16)
                .fontColor('#666666')
                .width(100)
              
              Text(this.gestureControlStatus)
                .fontSize(16)
                .fontColor(this.gestureControlStatus === '已初始化' ? '#4CAF50' : '#333333')
                .flexGrow(1)
            }
            .width('100%')
            .margin({ bottom: 30 })
            
            Text('手势控制支持以下手势:')
              .fontSize(16)
              .fontColor('#333333')
              .fontWeight(600)
              .margin({ bottom: 15 })
            
            Column() {
              Text('• 向上滑动: 增大音量')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 向下滑动: 减小音量')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 向左滑动: 快退视频')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 向右滑动: 快进视频')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
              Text('• 双击屏幕: 播放/暂停')
                .fontSize(14)
                .fontColor('#666666')
                .margin({ bottom: 8 })
            }
            .width('100%')
            .margin({ bottom: 30 })
          }
          .width('100%')
          .margin({ bottom: 20 })
        
          // 操作按钮 | Action buttons
          Row() {
            Button() {
              Text('测试手势')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(45)
            .backgroundColor('#2196F3')
            .borderRadius(8)
            .margin({ right: 15 })
            .onClick(() => {
              // 测试手势控制
              this.gestureService.testGestureRecognition().catch(error => {
                Logger.error(this.TAG, `Failed to test gesture recognition: ${error}`);
              });
            })
            
            Button() {
              Text('刷新状态')
                .fontSize(14)
                .fontColor('#FFFFFF')
            }
            .width(120)
            .height(45)
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .onClick(() => this.loadGestureControlStatus())
          }
          .margin({ bottom: 20 })
        
          Button() {
            Text('确定')
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
          .width(120)
          .height(45)
          .backgroundColor('#4CAF50')
          .borderRadius(8)
          .onClick(() => this.showGestureControlPopup = false)
        }
        .width('80%')
        .maxWidth(600)
        .padding(30)
        .backgroundColor('#FFFFFF')
        .borderRadius(12)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
  }
  
  build() {
    Column() {
      // 顶部导航栏 | Top navigation bar
      Row() {
        // 返回按钮 | Back button
        Button() {
          Text('返回')
            .fontSize(18)
            .fontColor('#FFFFFF')
        }
        .width(80)
        .height(50)
        .backgroundColor('#4CAF50')
        .borderRadius(8)
        .margin({ left: 30 })
        .onClick(() => this.handleBack())
        
        // 标题 | Title
        Text('设置')
          .fontSize(24)
          .fontWeight(700)
          .fontColor('#333333')
          .flexGrow(1)
          .margin({ left: 30 })
          .textAlign(TextAlign.Start)
        
        // 重置按钮 | Reset button
        Button() {
          Text('重置')
            .fontSize(16)
            .fontColor('#FFFFFF')
        }
        .width(80)
        .height(50)
        .backgroundColor('#F44336')
        .borderRadius(8)
        .margin({ right: 30 })
        .onClick(() => this.handleResetSettings())
      }
      .width('100%')
      .height(70)
      .alignItems(VerticalAlign.Center)
      .backgroundColor('#FFFFFF')
      .borderBottomWidth(1)
      .borderBottomColor('#E0E0E0')
      
      // 设置项列表 | Setting item list
      Scroll(this.scroller) {
        Column() {
          if (this.isLoading) {
            Column() {
              Text('加载中...')
                .fontSize(20)
                .fontColor('#666666')
                .margin(20)
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else if (this.isError) {
            Column() {
              Text('加载失败')
                .fontSize(20)
                .fontColor('#FF5252')
                .margin({ top: 15 })
              Text(this.errorMessage)
                .fontSize(16)
                .fontColor('#FF9800')
                .margin({ top: 8, left: 30, right: 30 })
                .textAlign(TextAlign.Center)
              Button('重试')
                .onClick(() => this.loadSettings())
                .backgroundColor('#4CAF50')
                .fontColor('white')
                .borderRadius(8)
                .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                .margin({ top: 20 })
            }
            .justifyContent(FlexAlign.Center)
            .height(500)
          } else {
            ForEach(this.settingItems, (item: SettingItem) => {
              this.renderSettingItem(item);
            }, (item: SettingItem) => item.id)
          }
        }
        .width('100%')
        .padding({ top: 30, left: 30, right: 30, bottom: 50 })
      }
      .scrollBar(BarState.Auto)
      .flexGrow(1)
      .backgroundColor('#F5F5F5')
      
      // 弹窗 | Popups
      this.renderConfigSourcePopup();
      this.renderVideoSourcePopup();
      this.renderWallpaperPopup();
      this.renderLiveSourcePopup();
      this.renderAdBlockPopup();
      this.renderAboutPopup();
      this.renderCachePopup();
      this.renderDeviceInfoPopup();
      this.renderDataSyncPopup();
      this.renderVoiceAssistantPopup();
      this.renderGestureControlPopup();
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
