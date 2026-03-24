// 主Ability | Main ability class
// RayTV应用的入口点 | Entry point for the RayTV application
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import Logger from './common/util/Logger';
import { setupGlobalErrorHandler } from './common/util/ErrorHandler';
import { DeviceFlowManager, RestoreFlowParams, FlowData } from './service/device/DeviceFlowManager';
import DataSyncService from './service/sync/DataSyncService';
import { VoiceAssistantManager } from './service/voice/VoiceAssistantManager';
import { GestureServiceInstance } from './service/input/GestureService';
import { initializeDI } from './common/di/ServiceRegistry';

const TAG: string = 'MainAbility';

// 定义用户偏好接口 | Define user preferences interface
export interface UserPreferences {
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
  isPlaying?: boolean;
  currentPage?: string;
  userPreferences?: UserPreferences;
}

// 定义媒体信息接口 | Define media information interface
export interface MediaInfo {
  mediaId?: string;
  title?: string;
  currentTime?: number;
  duration?: number;
  playbackRate?: number;
}

// 定义额外参数接口 | Define extra parameters interface
export interface ExtraParams {
  key?: string;
  value?: string | number | boolean | string[];
}

// 定义跨设备迁移参数接口 | Define cross-device migration params interface
export interface FlowParams {
  deviceId?: string;
  appState?: AppState;
  mediaInfo?: MediaInfo;
  timestamp?: number;
  extraParams?: ExtraParams;
}

/**
 * MainAbility class
 * 主Ability
 * Entry point for the RayTV application
 * RayTV应用的入口点
 */
export default class MainAbility extends UIAbility {
  /**
   * Called when the ability is created
   * 当Ability创建时调用
   */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, 'Ability onCreate');

    // Set up global error handler
    try {
      setupGlobalErrorHandler();
    } catch (error) {
      Logger.error(TAG, 'Failed to setup global error handler', error as Error);
    }

    // Initialize dependency injection container
    try {
      initializeDI();
    } catch (error) {
      Logger.error(TAG, 'Failed to initialize DI container', error as Error);
    }

    // Initialize services (non-blocking, with individual error handling)
    this.initializeServices(want);
  }

  /**
   * Initialize application services
   * 初始化应用服务（每个服务独立错误处理，任一服务失败不影响其他服务和应用启动）
   */
  private initializeServices(want: Want): void {
    Logger.info(TAG, 'Starting service initialization');

    // 1. 初始化VoiceAssistantManager（初始化时间短、依赖少）
    const voiceAssistantManager = VoiceAssistantManager.getInstance();
    voiceAssistantManager.initialize()
      .then(() => {
        Logger.info(TAG, 'VoiceAssistantManager initialized successfully');
      })
      .catch((error: Error) => {
        // 服务初始化失败时记录错误但不崩溃，应用可降级运行
        Logger.warn(TAG, `VoiceAssistantManager initialization failed (degraded mode): ${error.message}`);
      });

    // 2. 初始化GestureService（模块加载即初始化）
    try {
      // GestureServiceInstance 在导入时已初始化
      void GestureServiceInstance;
      Logger.info(TAG, 'GestureService already initialized');
    } catch (error) {
      Logger.warn(TAG, `GestureService initialization failed (degraded mode): ${(error as Error).message}`);
    }

    // 3. 初始化DataSyncService（中等初始化时间）
    const dataSyncService = DataSyncService.getInstance();
    dataSyncService.initialize(this.context)
      .then(() => {
        Logger.info(TAG, 'DataSyncService initialized successfully');
      })
      .catch((error: Error) => {
        Logger.warn(TAG, `DataSyncService initialization failed (degraded mode): ${error.message}`);
      });

    // 4. 初始化DeviceFlowManager（初始化时间较长、依赖较多）
    const deviceFlowManager = DeviceFlowManager.getInstance();
    deviceFlowManager.initialize()
      .then((): Promise<void> => {
        Logger.info(TAG, 'DeviceFlowManager initialized successfully');
        // 处理跨设备迁移参数（如果有）
        if (want?.parameters) {
          Logger.info(TAG, 'Received cross-device migration params');
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
        Logger.warn(TAG, `DeviceFlowManager initialization or migration failed (degraded mode): ${error.message}`);
      });

    Logger.info(TAG, 'Service initialization sequence started');
  }

  /**
   * Called when the ability is destroyed
   * 当Ability销毁时调用
   */
  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
  }

  /**
   * Called when the window stage is created
   * 当窗口舞台创建时调用
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      // 设置WindowStage的事件回调 | Set WindowStage event callback
      windowStage.on('windowStageEvent', (_event: object) => {
        Logger.info(TAG, 'WindowStage event occurred');
      });

      // 设置窗口支持自动旋转 | Set window rotation support
      windowStage.getMainWindow().then((mainWindow) => {
        // 1 = AUTO_ROTATION
        mainWindow.setPreferredOrientation(1);
      }).catch((error: Error) => {
        Logger.warn(TAG, `Failed to set window orientation: ${error.message}`);
      });

      // 加载主页面 | Load main page
      windowStage.loadContent('pages/MainPage', (err, data) => {
        if (err && err.code) {
          Logger.error(TAG, `Failed to load content: ${JSON.stringify(err)}`);
          return;
        }
        Logger.info(TAG, `Succeeded in loading content: ${JSON.stringify(data)}`);
      });
    } catch (error) {
      Logger.error(TAG, `WindowStage creation failed: ${(error as Error).message}`);
      // 尝试在没有旋转设置的情况下加载页面作为降级方案
      try {
        windowStage.loadContent('pages/MainPage', (_err, _data) => {});
      } catch (fallbackError) {
        Logger.error(TAG, `Fallback page load also failed: ${(fallbackError as Error).message}`);
      }
    }
  }

  /**
   * Called when the window stage is destroyed
   */
  onWindowStageDestroy(): void {
    Logger.info(TAG, 'Ability onWindowStageDestroy');
  }

  /**
   * Called when the ability is brought to the foreground
   */
  onForeground(): void {
    Logger.info(TAG, 'Ability onForeground');
  }

  /**
   * Called when the ability is sent to the background
   */
  onBackground(): void {
    Logger.info(TAG, 'Ability onBackground');
  }
}
