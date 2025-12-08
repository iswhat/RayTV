// Script for compiling and building Hvigor.
// This script is mainly used to configure the compilation and construction information of the module.
// For more details, please refer to: https://developer.harmonyos.com/cn/docs/documentation/doc-references-v5/hvigorfile-0000001636095193-v5

import { hapTasks } from '@ohos/hvigor-ohos-plugin';

export default {
  system: hapTasks,
  plugins: []  /* Custom plugin list. This module uses the built-in plugin of DevEco Studio, so the configuration is empty. */
}