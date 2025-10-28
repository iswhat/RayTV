import UIAbility from '@ohos.app.ability.UIAbility';
import hilog from '@ohos.hilog';
import window from '@ohos.window';

export default class MainAbility extends UIAbility {
  onCreate(want, launchParam) {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onCreate');
  }

  onDestroy() {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
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

  onWindowStageDestroy() {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground() {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onForeground');
  }

  onBackground() {
    hilog.info(0x0000, 'MainAbility', '%{public}s', 'Ability onBackground');
  }
}