// Module-level Hvigor configuration
const config = {
  system: [
    {
      name: 'hap',
      apply: require('@ohos/hvigor-ohos-plugin').hapTasks
    }
  ],
  plugins: []
};

export default config;