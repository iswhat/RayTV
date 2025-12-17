import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import hilog from '@ohos.hilog';
import window from '@ohos.window';
import display from '@ohos.display';

export default class MainAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      // 设置WindowStage的事件监听回调
      windowStage.on('windowStageEvent', () => {
        hilog.info(0x0000, 'MainAbility', 'WindowStage event occurred');
      });

      // 设置窗口支持横竖屏切换
      windowStage.getMainWindow().then((mainWindow) => {
        // 设置窗口模式为自适应
        mainWindow.setWindowMode(window.WindowMode.FULLSCREEN);
        // 允许屏幕旋转
        mainWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION);
        // 设置窗口背景
        mainWindow.setBackgroundColor('#ffffff');
      });

      // 设置UI页面加载
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
      // 可以添加恢复逻辑或错误处理
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onBackground');
  }
}
