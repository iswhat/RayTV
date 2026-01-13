// MainAbility.ets - Main ability class // 主Ability类
// Entry point for the RayTV application // RayTV应用的入口点
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import display from '@ohos.display';
import { setupGlobalErrorHandler } from './common/util/ErrorHandler';

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
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onCreate');
    
    // Set up global error handler
    setupGlobalErrorHandler();
    
    // Initialize DataSyncService
    import('../service/sync/DataSyncService').then(({ default: DataSyncService }) => {
      const dataSyncService = DataSyncService.getInstance();
      dataSyncService.initialize(this).catch(error => {
        hilog.error(0x0000, 'MainAbility', 'Failed to initialize DataSyncService: %{public}s', error instanceof Error ? error.message : String(error));
      });
    });
    
    // Initialize VoiceAssistantManager
    import('../service/voice/VoiceAssistantManager').then(({ VoiceAssistantManager }) => {
      const voiceAssistantManager = VoiceAssistantManager.getInstance();
      voiceAssistantManager.initialize(this).catch(error => {
        hilog.error(0x0000, 'MainAbility', 'Failed to initialize VoiceAssistantManager: %{public}s', error instanceof Error ? error.message : String(error));
      });
    });
    
    // Initialize GestureService
    import('../service/input/GestureService').then(({ GestureService }) => {
      const gestureService = GestureService.getInstance();
      gestureService.initialize(this).catch(error => {
        hilog.error(0x0000, 'MainAbility', 'Failed to initialize GestureService: %{public}s', error instanceof Error ? error.message : String(error));
      });
    });
  }

  /**
   * Called when the ability is destroyed
   * 当Ability销毁时调用
   */
  onDestroy(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onDestroy');
  }

  /**
   * Called when the window stage is created
   * 当窗口舞台创建时调用
   * @param windowStage Window stage object
   * @param windowStage 窗口舞台对象
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      // Set WindowStage event callback | 设置WindowStage的事件回调
      windowStage.on('windowStageEvent', () => {
        hilog.info(0x0000, 'MainAbility', 'WindowStage event occurred');
      });

      // Set window rotation support | 设置窗口支持旋转方向
      windowStage.getMainWindow().then((mainWindow) => {
        // Allow screen rotation | 允许屏幕旋转
        mainWindow.setPreferredOrientation(1); // 1 means AUTO_ROTATION | 1表示自动旋转
      });

      // Set UI page loading | 设置UI页面加载
      windowStage.loadContent('pages/MainPage', (err, data) => {
        if (err && err.code) {
          hilog.error(0x0000, 'MainAbility', 'Failed to load content: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(0x0000, 'MainAbility', 'Succeeded in loading content: %{public}s', JSON.stringify(data));
      });
    } catch (error) {
      hilog.error(0x0000, 'MainAbility', 'WindowStage creation failed: %{public}s', 
        error instanceof Error ? error.message : String(error));
      // Can add recovery logic or error handling | 可以添加恢复逻辑或错误处理
    }
  }

  /**
   * Called when the window stage is destroyed
   * 当窗口舞台销毁时调用
   */
  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onWindowStageDestroy');
  }

  /**
   * Called when the ability is brought to the foreground
   * 当Ability进入前台时调用
   */
  onForeground(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onForeground');
  }

  /**
   * Called when the ability is sent to the background
   * 当Ability进入后台时调用
   */
  onBackground(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onBackground');
  }
}



