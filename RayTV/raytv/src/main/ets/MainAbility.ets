// 主Ability | Main ability class
// RayTV应用的入口点 | Entry point for the RayTV application
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import window from '@ohos.window';
import Logger from './common/util/Logger';
import { setupGlobalErrorHandler, handleError, getFriendlyErrorMessage, ErrorType } from './common/util/ErrorHandler';
import { initializeDI } from './common/di/ServiceRegistry';
import { DIContainer } from './common/di/Container';
import ServiceInitManager from './common/manager/ServiceInitManager';
import ConfigService from './service/config/ConfigService';

const TAG: string = 'MainAbility';

// 窗口旋转常量 | Window rotation constants
export const WindowOrientation = {
  AUTO_ROTATION: 1,
  PORTRAIT: 2,
  LANDSCAPE: 3
};

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
      const errorInfo = handleError(error, 'SETUP_ERROR_HANDLER');
      Logger.error(TAG, `Failed to setup global error handler: ${errorInfo.message}`);
      // 即使错误处理设置失败，应用仍继续运行
    }

    // Initialize dependency injection container
    try {
      initializeDI();
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_DI');
      Logger.error(TAG, `Failed to initialize DI container: ${errorInfo.message}`);
      // 即使DI容器初始化失败，应用仍继续运行，使用降级方案
    }

    // Initialize configuration service
    this.initializeConfig();

    // Initialize services using ServiceInitManager (non-blocking, with individual error handling)
    ServiceInitManager.initializeServices(want, this.context);
  }

  /**
   * Initialize configuration service
   * 初始化配置服务
   */
  private async initializeConfig(): Promise<void> {
    try {
      const configService = ConfigService.getInstance();
      // 确保配置服务初始化
      await configService.getFullConfig();
      Logger.info(TAG, 'Configuration service initialized successfully');
      
      // 加载应用配置
      await this.loadAppConfig();
    } catch (error) {
      const errorInfo = handleError(error, 'INITIALIZE_CONFIG');
      Logger.error(TAG, `Failed to initialize configuration service: ${errorInfo.message}`);
      // 即使配置服务初始化失败，应用仍继续运行
    }
  }

  /**
   * Load application configuration
   * 加载应用配置
   */
  private async loadAppConfig(): Promise<void> {
    try {
      const configService = ConfigService.getInstance();
      const displayConfig = await configService.getPartialConfig('display');
      
      // 应用显示配置
      Logger.info(TAG, `Loaded display config: ${JSON.stringify(displayConfig)}`);
      
      // 可以在这里根据配置调整应用行为
      // 例如：设置主题、语言等
    } catch (error) {
      const errorInfo = handleError(error, 'LOAD_APP_CONFIG');
      Logger.error(TAG, `Failed to load application configuration: ${errorInfo.message}`);
    }
  }

  /**
   * Get configuration value
   * 获取配置值
   * @param key Config key
   * @returns Config value
   */
  public async getConfig(key: string): Promise<any> {
    try {
      const configService = ConfigService.getInstance();
      const response = await configService.getConfig(key as any);
      return response.data;
    } catch (error) {
      const errorInfo = handleError(error, 'GET_CONFIG');
      Logger.error(TAG, `Failed to get config: ${errorInfo.message}`);
      return null;
    }
  }

  /**
   * Update configuration value
   * 更新配置值
   * @param key Config key
   * @param value Config value
   * @returns Whether the update was successful
   */
  public async updateConfig(key: string, value: any): Promise<boolean> {
    try {
      const configService = ConfigService.getInstance();
      const response = await configService.setConfig(key as any, value);
      return response.success;
    } catch (error) {
      const errorInfo = handleError(error, 'UPDATE_CONFIG');
      Logger.error(TAG, `Failed to update config: ${errorInfo.message}`);
      return false;
    }
  }



  /**
   * Called when the ability is destroyed
   * 当Ability销毁时调用
   */
  onDestroy(): void {
    Logger.info(TAG, 'Ability onDestroy');
    
    // 清理服务资源 | Clean up service resources
    try {
      // 重置服务初始化管理器状态
      const serviceInitManager = ServiceInitManager.getInstance();
      serviceInitManager.reset();
      Logger.info(TAG, 'Service initialization manager reset successfully');
      
      // 清理依赖注入容器
      const container = DIContainer.getInstance();
      container.clearSingleton();
      Logger.info(TAG, 'Service resources cleaned up successfully');
    } catch (error) {
      const errorInfo = handleError(error, 'CLEANUP_SERVICES');
      Logger.error(TAG, `Failed to clean up service resources: ${errorInfo.message}`);
    }
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
        mainWindow.setPreferredOrientation(WindowOrientation.AUTO_ROTATION);
      }).catch((error: Error) => {
        const errorInfo = handleError(error, 'SET_WINDOW_ORIENTATION');
        Logger.warn(TAG, `Failed to set window orientation: ${errorInfo.message}`);
        // 即使窗口旋转设置失败，应用仍继续运行
      });

      // 加载主页面 | Load main page
      windowStage.loadContent('pages/MainPage', (err, data) => {
        if (err && err.code) {
          const errorInfo = handleError(err, 'LOAD_CONTENT');
          Logger.error(TAG, `Failed to load content: ${errorInfo.message}`);
          // 尝试使用备用页面作为降级方案
          this.tryLoadFallbackPage(windowStage);
          return;
        }
        Logger.info(TAG, `Succeeded in loading content: ${JSON.stringify(data)}`);
      });
    } catch (error) {
      const errorInfo = handleError(error, 'WINDOW_STAGE_CREATE');
      Logger.error(TAG, `WindowStage creation failed: ${errorInfo.message}`);
      // 尝试在没有旋转设置的情况下加载页面作为降级方案
      this.tryLoadFallbackPage(windowStage);
    }
  }

  /**
   * Try to load fallback page | 尝试加载备用页面
   * @param windowStage Window stage | 窗口舞台
   */
  private tryLoadFallbackPage(windowStage: window.WindowStage): void {
    try {
      windowStage.loadContent('pages/MainPage', (err, data) => {
        if (err && err.code) {
          const errorInfo = handleError(err, 'LOAD_FALLBACK_CONTENT');
          Logger.error(TAG, `Fallback page load also failed: ${errorInfo.message}`);
          // 此时应用可能无法正常启动，需要向用户显示错误信息
          this.showErrorNotification('应用启动失败，请重启应用后重试');
        } else {
          Logger.info(TAG, `Fallback page loaded successfully: ${JSON.stringify(data)}`);
        }
      });
    } catch (fallbackError) {
      const errorInfo = handleError(fallbackError, 'FALLBACK_ERROR');
      Logger.error(TAG, `Fallback page load also failed: ${errorInfo.message}`);
      // 此时应用可能无法正常启动，需要向用户显示错误信息
      this.showErrorNotification('应用启动失败，请重启应用后重试');
    }
  }

  /**
   * Show error notification | 显示错误通知
   * @param message Error message | 错误信息
   */
  private showErrorNotification(message: string): void {
    // 在实际应用中，这里可以使用系统通知或弹窗来显示错误信息
    // 由于ArkTS环境的限制，这里仅记录错误信息
    Logger.error(TAG, `Error notification: ${message}`);
    // 示例：如果有UI相关的API，可以在这里实现弹窗显示
    // 例如：prompt.showToast({ message: message });
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
