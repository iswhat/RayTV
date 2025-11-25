import { hapTasks } from '@ohos/hvigor-ohos-plugin';

// Module-level Hvigor configuration
const config: any = {
  system: [
    {
      name: 'hap',
      apply: hapTasks
    }
  ],
  plugins: []
};

export default config;