// 项目根目录hvigor配置
// 使用DevEco Studio内置的hvigor-ohos-plugin，不通过ohpm安装

import { projectTaskDag } from '@ohos/hvigor';

export default {
  system: projectTaskDag,  /* Defines the task script of the project. */
  plugins: []             /* Custom plugin list. This project uses the built-in plugin of DevEco Studio, so the configuration is empty. */
}