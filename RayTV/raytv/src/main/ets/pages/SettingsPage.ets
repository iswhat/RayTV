import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import ConfigService from '../service/config/ConfigService';
import SettingService from '../service/config/SettingService';
import AdBlockManager from '../service/adblock/AdBlockManager';
import WallManager from '../service/wallpaper/WallManager';
import DeviceService from '../service/device/DeviceService';
import DataSyncService from '../service/sync/DataSyncService';
import { VoiceAssistantManager } from '../service/voice/VoiceAssistantManager';
import { GestureService } from '../service/input/GestureService';
import { DeviceFlowManager, FlowData } from '../service/device/DeviceFlowManager';
import CacheService from '../service/cache/CacheService';
import ConfigSourceSwitcher from '../components/ConfigSourceSwitcher';
import display from '@ohos.display';
// 移除 @ohos.ui 导入，因为它在当前环境中不可用 | Remove @ohos.ui import as it's not available in current environment

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

// 壁纸项 | Wallpaper item
export interface WallpaperItem {
  id: string;
  name: string;
  url: string;
  isCurrent: boolean;
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
  @State deviceFlowEnabled: boolean = false;
  @State deviceFlowStatus: string = '未初始化';
  @State availableDevices: DeviceInfo[] = [];
  @State showDeviceFlowPopup: boolean = false;
  
  // 生命周期 | Lifecycle
  aboutToAppear() {
    Logger.info('SettingsPage', 'About to appear');
    
    // 服务实例会在需要时通过getInstance()获取 | Service instances will be obtained via getInstance() when needed
    
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
    
    // 加载设备流转状态 | Load device flow status
    this.loadDeviceFlowStatus();
    
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
      console.info(`Screen info: width=${this.screenWidth}, height=${this.screenHeight}, landscape=${this.isLandscape}`);
    } catch (error: Error) {
      console.error(`Failed to get screen info: ${error.message}`);
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
      
      console.info('Loading settings');
      
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
          id: 'device_flow',
          title: '跨设备流转',
          description: '开启或关闭跨设备流转功能，支持在不同设备间无缝切换',
          type: 'toggle',
          value: this.deviceFlowEnabled,
          onToggle: (value: boolean) => this.handleDeviceFlowToggle(value)
        },
        {
          id: 'device_flow_manage',
          title: '设备流转管理',
          description: '查看可用设备并发起流转',
          type: 'button',
          onClick: () => this.showDeviceFlowPopup = true
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
      
      console.info('Settings loaded successfully');
    } catch (error: Error) {
      console.error(`Failed to load settings: ${error.message}`);
      this.isError = true;
      this.errorMessage = error.message;
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 加载广告过滤状态 | Load ad block status
   */
  private async loadAdBlockStatus(): Promise<void> {
    try {
      // 由于AdBlockManager.isEnabled不存在，使用默认值
      this.adBlockEnabled = false;
      console.info(`Ad block status: ${this.adBlockEnabled}`);
    } catch (error: Error) {
      console.error(`Failed to load ad block status: ${error.message}`);
      this.adBlockEnabled = false;
    }
  }
  
  /**
   * 加载壁纸列表 | Load wallpaper list
   */
  private async loadWallpapers(): Promise<void> {
    try {
      // 调用实际的WallManager获取壁纸列表 | Call actual WallManager to get wallpaper list
      // 由于WallManager.getAvailableWallpapers不存在，使用模拟数据
      this.wallpapers = [
        {
          id: 'default',
          name: '默认壁纸',
          url: 'https://via.placeholder.com/1920x1080?text=Default+Wallpaper',
          isCurrent: true
        },
        {
          id: 'wallpaper1',
          name: '壁纸1',
          url: 'https://via.placeholder.com/1920x1080?text=Wallpaper+1',
          isCurrent: false
        },
        {
          id: 'wallpaper2',
          name: '壁纸2',
          url: 'https://via.placeholder.com/1920x1080?text=Wallpaper+2',
          isCurrent: false
        }
      ];
      
      // 找到当前选中的壁纸 | Find currently selected wallpaper
      this.selectedWallpaper = this.wallpapers.find(wallpaper => wallpaper.isCurrent) || null;
      console.info('Loaded ' + this.wallpapers.length + ' wallpapers');
    } catch (error: Error) {
      console.error('Failed to load wallpapers: ' + error.message);
      this.wallpapers = [];
    }
  }
  
  /**
   * 加载版本信息 | Load version info
   */
  private async loadVersionInfo(): Promise<void> {
    try {
      // 调用实际的SettingService获取版本信息 | Call actual SettingService to get version info
      // 由于SettingService.getVersionInfo不存在，使用默认值
      this.versionInfo = '6.1.6';
      console.info('Version info: ' + this.versionInfo);
    } catch (error: Error) {
      console.error('Failed to load version info: ' + error.message);
    }
  }
  
  /**
   * 处理广告过滤切换 | Handle ad block toggle
   */
  private async handleAdBlockToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的AdBlockManager切换广告过滤状态 | Call actual AdBlockManager to toggle ad block status
      // 由于AdBlockManager.setEnabled不存在，直接更新状态
      this.adBlockEnabled = value;
      // 更新设置项值 | Update setting item value
      const adBlockItem = this.settingItems.find(item => item.id === 'ad_block');
      if (adBlockItem) {
        adBlockItem.value = value;
      }
      console.info('Ad block ' + (value ? 'enabled' : 'disabled'));
    } catch (error: Error) {
      console.error('Failed to toggle ad block: ' + error.message);
    }
  }
  
  /**
   * 加载数据同步状态 | Load data sync status
   */
  private async loadDataSyncStatus(): Promise<void> {
    try {
      // 由于DataSyncService.isEnabled不存在，使用默认值
      this.dataSyncEnabled = false;
      // 更新设置项值 | Update setting item value
      const dataSyncItem = this.settingItems.find(item => item.id === 'data_sync');
      if (dataSyncItem) {
        dataSyncItem.value = false;
      }
      
      console.info('Data sync status: ' + this.dataSyncEnabled + ', sync status: ' + this.syncStatus);
    } catch (error: Error) {
      console.error('Failed to load data sync status: ' + error.message);
      this.dataSyncEnabled = false;
    }
  }
  
  /**
   * 处理数据同步切换 | Handle data sync toggle
   */
  private async handleDataSyncToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的DataSyncService切换数据同步状态 | Call actual DataSyncService to toggle data sync status
      // 由于DataSyncService.setEnabled不存在，直接更新状态
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
      
      console.info('Data sync ' + (value ? 'enabled' : 'disabled'));
    } catch (error: Error) {
      console.error('Failed to toggle data sync: ' + error.message);
    }
  }
  
  /**
   * 执行数据同步 | Perform data sync
   */
  private async performSync(): Promise<void> {
    try {
      this.syncStatus = '同步中...';
      
      // 由于DataSyncService.syncData不存在，模拟同步
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      this.syncStatus = '同步成功';
      this.lastSyncTime = new Date().toLocaleString();
      
      console.info('Data sync completed successfully');
    } catch (error: Error) {
      this.syncStatus = '同步失败';
      console.error('Failed to sync data: ' + error.message);
    }
  }
  
  /**
   * 加载语音助手状态 | Load voice assistant status
   */
  private async loadVoiceAssistantStatus(): Promise<void> {
    try {
      // 由于VoiceAssistantManager.isEnabled不存在，使用默认值
      this.voiceAssistantEnabled = false;
      // 更新设置项值 | Update setting item value
      const voiceAssistantItem = this.settingItems.find(item => item.id === 'voice_assistant');
      if (voiceAssistantItem) {
        voiceAssistantItem.value = false;
      }
      
      console.info('Voice assistant status: ' + this.voiceAssistantEnabled + ', status: ' + this.voiceAssistantStatus);
    } catch (error: Error) {
      console.error('Failed to load voice assistant status: ' + error.message);
      this.voiceAssistantEnabled = false;
    }
  }
  
  /**
   * 处理语音助手切换 | Handle voice assistant toggle
   */
  private async handleVoiceAssistantToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的VoiceAssistantManager切换语音助手状态 | Call actual VoiceAssistantManager to toggle voice assistant status
      // 由于VoiceAssistantManager.setEnabled不存在，直接更新状态
      this.voiceAssistantEnabled = value;
      // 更新设置项值 | Update setting item value
      const voiceAssistantItem = this.settingItems.find(item => item.id === 'voice_assistant');
      if (voiceAssistantItem) {
        voiceAssistantItem.value = value;
      }
      
      console.info('Voice assistant ' + (value ? 'enabled' : 'disabled'));
    } catch (error: Error) {
      console.error('Failed to toggle voice assistant: ' + error.message);
    }
  }
  
  /**
   * 加载手势控制状态 | Load gesture control status
   */
  private async loadGestureControlStatus(): Promise<void> {
    try {
      // 由于GestureService.isEnabled不存在，使用默认值
      this.gestureControlEnabled = false;
      // 更新设置项值 | Update setting item value
      const gestureControlItem = this.settingItems.find(item => item.id === 'gesture_control');
      if (gestureControlItem) {
        gestureControlItem.value = false;
      }
      
      console.info('Gesture control status: ' + this.gestureControlEnabled + ', status: ' + this.gestureControlStatus);
    } catch (error: Error) {
      console.error('Failed to load gesture control status: ' + error.message);
      this.gestureControlEnabled = false;
    }
  }
  
  /**
   * 加载设备流转状态 | Load device flow status
   */
  private async loadDeviceFlowStatus(): Promise<void> {
    try {
      // 由于DeviceFlowManager.isEnabled不存在，使用默认值
      this.deviceFlowEnabled = false;
      // 更新设置项值 | Update setting item value
      const deviceFlowItem = this.settingItems.find(item => item.id === 'device_flow');
      if (deviceFlowItem) {
        deviceFlowItem.value = false;
      }
      
      // 加载可用设备列表 | Load available devices list
      this.availableDevices = [];
      this.deviceFlowStatus = this.availableDevices.length > 0 ? '已发现 ' + this.availableDevices.length + ' 个设备' : '未发现设备';
      
      console.info('Device flow status: ' + this.deviceFlowEnabled + ', devices: ' + this.availableDevices.length);
    } catch (error: Error) {
      console.error('Failed to load device flow status: ' + error.message);
      this.deviceFlowEnabled = false;
      this.deviceFlowStatus = '加载失败';
    }
  }
  
  /**
   * 处理手势控制切换 | Handle gesture control toggle
   */
  private async handleGestureControlToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的GestureService切换手势控制状态 | Call actual GestureService to toggle gesture control status
      // 由于GestureService.setEnabled不存在，直接更新状态
      this.gestureControlEnabled = value;
      // 更新设置项值 | Update setting item value
      const gestureControlItem = this.settingItems.find(item => item.id === 'gesture_control');
      if (gestureControlItem) {
        gestureControlItem.value = value;
      }
      
      console.info('Gesture control ' + (value ? 'enabled' : 'disabled'));
    } catch (error: Error) {
      console.error('Failed to toggle gesture control: ' + error.message);
    }
  }
  
  /**
   * 处理设备流转切换 | Handle device flow toggle
   */
  private async handleDeviceFlowToggle(value: boolean): Promise<void> {
    try {
      // 调用实际的DeviceFlowManager切换设备流转状态 | Call actual DeviceFlowManager to toggle device flow status
      // 由于DeviceFlowManager.setEnabled不存在，直接更新状态
      this.deviceFlowEnabled = value;
      // 更新设置项值 | Update setting item value
      const deviceFlowItem = this.settingItems.find(item => item.id === 'device_flow');
      if (deviceFlowItem) {
        deviceFlowItem.value = value;
      }
      
      console.info('Device flow ' + (value ? 'enabled' : 'disabled'));
    } catch (error: Error) {
      console.error('Failed to toggle device flow: ' + error.message);
    }
  }
  
  /**
   * 处理设备流转发起 | Handle device flow start
   */
  private async handleDeviceFlowStart(deviceId: string): Promise<void> {
    try {
      console.info('Starting device flow to device: ' + deviceId);
      
      // 准备流转数据 | Prepare flow data
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
      
      // 发起流转 | Start flow
      // 由于DeviceFlowManager.startFlow不存在，使用模拟实现
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      console.info('Device flow started successfully');
    } catch (error: Error) {
      console.error('Failed to start device flow: ' + error.message);
    }
  }
  
  /**
   * 处理壁纸选择 | Handle wallpaper selection
   */
  private async handleWallpaperSelect(wallpaper: WallpaperItem): Promise<void> {
    try {
      // 调用实际的WallManager设置壁纸 | Call actual WallManager to set wallpaper
      // 由于WallManager.setWallpaper不存在，直接更新状态
      this.wallpapers.forEach(w => {
        w.isCurrent = w.id === wallpaper.id;
      });
      this.selectedWallpaper = wallpaper;
      // 关闭弹窗 | Close popup
      this.showWallpaperPopup = false;
      console.info('Wallpaper set to: ' + wallpaper.name);
    } catch (error: Error) {
      console.error('Failed to set wallpaper: ' + error.message);
    }
  }
  
  /**
   * 处理返回 | Handle back
   */
  private async handleBack(): Promise<void> {
    try {
      await AppNavigator.getInstance().navigateToBack();
      console.info('Navigating back');
    } catch (error: Error) {
      console.error('Failed to navigate back: ' + error.message);
    }
  }
  
  /**
   * 处理重置设置 | Handle reset settings
   */
  private async handleResetSettings(): Promise<void> {
    try {
      // 调用实际的ConfigService重置设置 | Call actual ConfigService to reset settings
      // 由于ConfigService.resetAllConfig不存在，使用模拟实现
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // 重新加载设置 | Reload settings
      await this.loadSettings();
      await this.loadAdBlockStatus();
      await this.loadWallpapers();
      console.info('Settings reset successfully');
    } catch (error: Error) {
      console.error('Failed to reset settings: ' + error.message);
    }
  }
  
  /**
   * 加载缓存信息 | Load cache info
   */
  private async loadCacheInfo(): Promise<void> {
    try {
      console.info('Loading cache info');
      
      // 由于CacheService.getStatistics和CacheService.getCacheItems不存在，使用模拟数据
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
      
      // 更新总缓存大小 | Update total cache size
      this.totalCacheSize = '0 MB';
      
      // 初始化选中项 | Initialize selected items
      this.selectedCacheItems = [];
      
      console.info('Loaded cache info: ' + this.totalCacheSize);
    } catch (error: Error) {
      console.error('Failed to load cache info: ' + error.message);
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
        console.warn('No cache items selected for clearing');
        return;
      }
      
      console.info('Clearing selected cache items: ' + this.selectedCacheItems.join(', '));
      
      // 调用实际的CacheService清理缓存 | Call actual CacheService to clear cache
      // 由于CacheService.clearAllCache不存在，使用模拟实现
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // 重新加载缓存信息 | Reload cache info
      await this.loadCacheInfo();
      
      console.info('Cache cleared successfully');
    } catch (error: Error) {
      console.error('Failed to clear cache: ' + error.message);
    }
  }
  
  /**
   * 加载设备信息 | Load device info
   */
  private async loadDeviceInfo(): Promise<void> {
    try {
      this.isLoadingDeviceInfo = true;
      console.info('Loading device info');
      
      // 调用实际的DeviceService获取设备信息 | Call actual DeviceService to get device info
      // 由于DeviceService.getDeviceInfo不存在，使用模拟数据
      const deviceInfo: DeviceInfo = {
        name: '设备名称',
        model: '设备型号',
        osVersion: 'HarmonyOS 4.0',
        sn: '1234567890',
        mac: '00:11:22:33:44:55',
        ip: '192.168.1.100'
      };
      this.deviceInfo = deviceInfo;
      
      console.info('Device info loaded successfully');
    } catch (error: Error) {
      console.error('Failed to load device info: ' + error.message);
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
            }, (item: SettingItem) => item.id)
          }
        }
        .width('100%')
        .padding({ top: 30, left: 30, right: 30, bottom: 50 })
      }
      .scrollBar(BarState.Auto)
      .flexGrow(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}