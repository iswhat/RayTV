import { appTasks } from '@ohos/hvigor-ohos-plugin';

// 定义Hvigor配置的具体类型
interface HvigorConfig {
  system: typeof appTasks;
  plugins: Array<any>;
}

// Hvigor configuration with proper typing
const config: HvigorConfig = {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
};

export default config;