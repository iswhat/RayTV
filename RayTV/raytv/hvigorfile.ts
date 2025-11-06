import { hapTasks } from '@ohos/hvigor-ohos-plugin';

// Hvigor configuration - using any type to avoid TypeScript import issues
const config: any = {
  system: hapTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []       /* Custom plugin to extend the functionality of Hvigor. */
};

export default config;