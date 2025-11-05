const fs = require('fs');
const path = require('path');

/**
 * 配置文件验证工具
 * 验证项目中的关键配置文件是否存在且格式正确
 */
class ConfigValidator {
  constructor() {
    this.projectRoot = path.resolve(__dirname, '..');
    console.log('项目根目录:', this.projectRoot);
    
    this.configFiles = [
      'oh-package.json5',
      '../build-profile.json5',  // build-profile.json5在父目录中
      'src/main/module.json5'
    ];
  }

  /**
   * 验证配置文件是否存在
   */
  validateConfigFiles() {
    console.log('🔍 验证配置文件存在性...');
    
    for (const configFile of this.configFiles) {
      const filePath = path.join(this.projectRoot, configFile);
      
      if (!fs.existsSync(filePath)) {
        throw new Error(`配置文件不存在: ${configFile}`);
      }
      
      console.log(`✅ ${configFile} 存在`);
    }
  }

  /**
   * 验证oh-package.json5格式
   */
  validatePackageConfig() {
    console.log('🔍 验证oh-package.json5格式...');
    
    const packagePath = path.join(this.projectRoot, 'oh-package.json5');
    const content = fs.readFileSync(packagePath, 'utf8');
    
    try {
      // 尝试解析JSON5格式
      const config = JSON.parse(content.replace(/\/\/.*\n/g, '').replace(/,\s*\}/g, '}'));
      
      // 检查必需字段
      if (!config.name || !config.version) {
        throw new Error('oh-package.json5缺少必需字段: name 或 version');
      }
      
      console.log('✅ oh-package.json5 格式正确');
    } catch (error) {
      throw new Error(`oh-package.json5 格式错误: ${error.message}`);
    }
  }

  /**
   * 验证build-profile.json5格式
   */
  validateBuildProfile() {
    console.log('🔍 验证build-profile.json5格式...');
    
    const profilePath = path.join(this.projectRoot, '../build-profile.json5');
    console.log('build-profile.json5路径:', profilePath);
    
    const content = fs.readFileSync(profilePath, 'utf8');
    console.log('文件内容前100字符:', content.substring(0, 100));
    
    try {
      // 简化验证：只检查文件内容是否包含必需的关键字
      if (!content.includes('"app"') || !content.includes('"modules"')) {
        console.log('app字段存在:', content.includes('"app"'));
        console.log('modules字段存在:', content.includes('"modules"'));
        throw new Error('build-profile.json5缺少必需字段: app 或 modules');
      }
      
      console.log('✅ build-profile.json5 格式正确');
    } catch (error) {
      throw new Error(`build-profile.json5 格式错误: ${error.message}`);
    }
  }

  /**
   * 运行所有验证
   */
  runAllValidations() {
    try {
      this.validateConfigFiles();
      this.validatePackageConfig();
      this.validateBuildProfile();
      
      console.log('🎉 所有配置文件验证通过！');
      return true;
    } catch (error) {
      console.error('❌ 配置文件验证失败:', error.message);
      return false;
    }
  }
}

// 主执行逻辑
if (require.main === module) {
  const validator = new ConfigValidator();
  const success = validator.runAllValidations();
  
  if (!success) {
    process.exit(1);
  }
}

module.exports = ConfigValidator;