// RayTV项目的hvigor配置文件
// 使用DevEco Studio内置的hvigor-ohos-plugin

import { appTasks } from '@ohos/hvigor-ohos-plugin';
import { hapTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: appTasks,
  modules: [
    {
      name: 'raytv',
      path: './raytv',
      hvigorfile: './raytv/hvigorfile.ts',
      tasks: hapTasks
    }
  ]
}