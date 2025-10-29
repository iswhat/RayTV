import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class MainAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam) {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 设置WindowStage的事件监听回调
    windowStage.on('windowStageEvent', (event) => {
      hilog.info(0x0000, 'MainAbility', 'WindowStage event: %{public}s', event.type);
    });

    // 设置UI页面加载
    windowStage.loadContent('pages/MainPage', (err, data) => {
      if (err.code) {
        hilog.error(0x0000, 'MainAbility', 'Failed to load content: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'MainAbility', 'Succeeded in loading content: %{public}s', JSON.stringify(data));
    });
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