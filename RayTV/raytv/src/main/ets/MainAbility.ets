// 主Ability类 | Main ability class
// RayTV应用的入口点 | Entry point for the RayTV application
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import { setupGlobalErrorHandler } from './common/util/ErrorHandler';
import { DeviceFlowManager, RestoreFlowParams, FlowData } from './service/device/DeviceFlowManager';
import DataSyncService from './service/sync/DataSyncService';
import { VoiceAssistantManager } from './service/voice/VoiceAssistantManager';
import { GestureServiceInstance } from './service/input/GestureService';
import { initializeDI } from './common/di/ServiceRegistry';

// 定义用户偏好接口 | Define user preferences interface
export interface UserPreferences {
  // 用户偏好属性 | User preferences properties
  theme?: string;
  language?: string;
  autoPlay?: boolean;
  playbackRate?: number;
  volume?: number;
  brightness?: number;
  subtitlesEnabled?: boolean;
  notificationsEnabled?: boolean;
}

// 定义应用状态接口 | Define application state interface
export interface AppState {
  // 应用状态属性 | Application state properties
  isPlaying?: boolean;
  currentPage?: string;
  userPreferences?: UserPreferences;
}

// 定义媒体信息接口 | Define media information interface
export interface MediaInfo {
  // 媒体信息属性 | Media information properties
  mediaId?: string;
  title?: string;
  currentTime?: number;
  duration?: number;
  playbackRate?: number;
}

// 定义额外参数接口 | Define extra parameters interface
export interface ExtraParams {
  // 额外参数属性 | Extra parameters properties
  key?: string;
  value?: string | number | boolean | string[];
}

// 定义跨设备迁移参数接口 | Define cross-device migration params interface
export interface FlowParams {
  // 设备ID | Device ID
  deviceId?: string;
  // 应用状态 | Application state
  appState?: AppState;
  // 媒体信息 | Media information
  mediaInfo?: MediaInfo;
  // 时间戳 | Timestamp
  timestamp?: number;
  // 其他参数 | Other parameters
  extraParams?: ExtraParams;
}

/**
 * MainAbility class
 * 主Ability类
 * Entry point for the RayTV application
 * RayTV应用的入口点
 */
export default class MainAbility extends UIAbility {
  /**
   * Called when the ability is created
   * 当Ability创建时调用
   * @param want Want object containing ability information
   * @param want 包含Ability信息的Want对象
   * @param launchParam Launch parameters
   * @param launchParam 启动参数
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('MainAbility: Ability创建 | Ability onCreate');
    
    // Set up global error handler
    setupGlobalErrorHandler();
    
    // Initialize dependency injection container
    initializeDI();
    
    // Initialize services
    this.initializeServices(want);
  }

  /**
   * Initialize application services
   * 初始化应用服务
   * @param want Want object containing ability information
   * @param want 包含Ability信息的Want对象
   */
  private initializeServices(want: Want): void {
    console.info('MainAbility: 开始初始化服务 | Starting service initialization');
    
    // 1. 首先初始化依赖较少、初始化时间较短的服务
    // Initialize VoiceAssistantManager (short initialization time, fewer dependencies)
    const voiceAssistantManager = VoiceAssistantManager.getInstance();
    voiceAssistantManager.initialize()
      .then(() => {
        console.info('MainAbility: VoiceAssistantManager初始化成功 | VoiceAssistantManager initialized successfully');
      })
      .catch((error: Error) => {
        console.error('MainAbility: 初始化VoiceAssistantManager失败: %{public}s | Failed to initialize VoiceAssistantManager: %{public}s', error.message);
      });
    
    // 2. 初始化GestureService
    try {
      // GestureServiceInstance is already initialized
      console.info('MainAbility: GestureService已初始化 | GestureService already initialized');
    } catch (error: Error) {
      console.error('MainAbility: 初始化GestureService失败: %{public}s | Failed to initialize GestureService: %{public}s', error.message);
    }
    
    // 3. 然后初始化依赖中等、初始化时间中等的服务
    // Initialize DataSyncService (medium initialization time, medium dependencies)
    const dataSyncService = DataSyncService.getInstance();
    dataSyncService.initialize(this.context)
      .then(() => {
        console.info('MainAbility: DataSyncService初始化成功 | DataSyncService initialized successfully');
      })
      .catch((error: Error) => {
        console.error('MainAbility: 初始化DataSyncService失败: %{public}s | Failed to initialize DataSyncService: %{public}s', error.message);
      });
    
    // 4. 最后初始化依赖较多、初始化时间较长的服务
    // Initialize DeviceFlowManager (longer initialization time, more dependencies)
    const deviceFlowManager = DeviceFlowManager.getInstance();
    deviceFlowManager.initialize()
      .then((): Promise<void> => {
        console.info('MainAbility: DeviceFlowManager初始化成功 | DeviceFlowManager initialized successfully');
        // Handle cross-device migration params if present
        if (want?.parameters) {
          console.info('MainAbility: 收到跨设备迁移参数 | Received cross-device migration params');
          const flowParams = want.parameters['flowParams'] as FlowData;
          if (flowParams) {
            const restoreParams: RestoreFlowParams = {
              data: flowParams
            };
            return deviceFlowManager.restoreFromFlowParams(restoreParams);
          }
        }
        return Promise.resolve<void>(undefined);
      })
      .catch((error: Error) => {
        console.error('MainAbility: 初始化DeviceFlowManager或处理迁移失败: %{public}s | Failed to initialize DeviceFlowManager or handle migration: %{public}s', error.message);
      });
    
    console.info('MainAbility: 服务初始化序列已启动 | Service initialization sequence started');
  }

  /**
   * Called when the ability is destroyed
   * 当Ability销毁时调用
   */
  onDestroy(): void {
    console.info('MainAbility: Ability销毁 | Ability onDestroy');
  }

  /**
   * Called when the window stage is created
   * 当窗口舞台创建时调用
   * @param windowStage Window stage object
   * @param windowStage 窗口舞台对象
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      // 设置WindowStage的事件回调 | Set WindowStage event callback
      windowStage.on('windowStageEvent', (event: object) => {
        console.info('MainAbility: WindowStage事件发生 | WindowStage event occurred');
      });

      // 设置窗口支持旋转方向 | Set window rotation support
      windowStage.getMainWindow().then((mainWindow) => {
        // 允许屏幕旋转 | Allow screen rotation
        mainWindow.setPreferredOrientation(1); // 1表示自动旋转 | 1 means AUTO_ROTATION
      });

      // 设置UI页面加载 | Set UI page loading
      windowStage.loadContent('pages/MainPage', (err, data) => {
        if (err && err.code) {
          console.error('MainAbility: 加载内容失败: %{public}s | Failed to load content: %{public}s', JSON.stringify(err));
          return;
        }
        console.info('MainAbility: 加载内容成功: %{public}s | Succeeded in loading content: %{public}s', JSON.stringify(data));
      });
    } catch (error: Error) {
      console.error('MainAbility: WindowStage创建失败: %{public}s | WindowStage creation failed: %{public}s', error.message);
      // 可以添加恢复逻辑或错误处理 | Can add recovery logic or error handling
    }
  }

  /**
   * Called when the window stage is destroyed
   * 当窗口舞台销毁时调用
   */
  onWindowStageDestroy(): void {
    console.info('MainAbility: WindowStage销毁 | Ability onWindowStageDestroy');
  }

  /**
   * Called when the ability is brought to the foreground
   * 当Ability进入前台时调用
   */
  onForeground(): void {
    console.info('MainAbility: Ability进入前台 | Ability onForeground');
  }

  /**
   * Called when the ability is sent to the background
   * 当Ability进入后台时调用
   */
  onBackground(): void {
    console.info('MainAbility: Ability进入后台 | Ability onBackground');
  }
}



