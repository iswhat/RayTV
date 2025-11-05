#!/usr/bin/env node

/**
 * 构建集成脚本
 * 将代码检查集成到HarmonyOS构建流程中
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class BuildIntegration {
  constructor() {
    this.buildConfig = this.loadBuildConfig();
    this.results = {
      preBuild: { success: false, output: '' },
      build: { success: false, output: '' },
      postBuild: { success: false, output: '' }
    };
  }

  /**
   * 加载构建配置
   */
  loadBuildConfig() {
    const configPath = path.join(process.cwd(), 'build-profile.json5');
    
    if (!fs.existsSync(configPath)) {
      console.warn('⚠️ 未找到build-profile.json5配置文件');
      return {};
    }

    try {
      const configContent = fs.readFileSync(configPath, 'utf8');
      // 使用JSON5解析器处理JSON5格式（支持注释和尾随逗号）
      const JSON5 = require('json5');
      return JSON5.parse(configContent);
    } catch (error) {
      console.error('❌ 构建配置文件解析失败:', error.message);
      return {};
    }
  }

  /**
   * 执行完整的构建流程
   */
  async runFullBuild(buildType = 'debug') {
    console.log('🚀 开始执行完整构建流程...');
    console.log('='.repeat(60));

    try {
      // 1. 预构建检查
      await this.runPreBuildChecks();
      
      // 2. 执行构建
      await this.runBuild(buildType);
      
      // 3. 构建后检查
      await this.runPostBuildChecks();
      
      // 4. 生成构建报告
      this.generateBuildReport();
      
    } catch (error) {
      console.error('❌ 构建流程失败:', error.message);
      process.exit(1);
    }
  }

  /**
   * 执行预构建检查
   */
  async runPreBuildChecks() {
    console.log('\n🔍 执行预构建检查...');
    
    const checks = [
      { name: '代码规范检查', command: 'node scripts/code-linter.js' },
      { name: '配置文件验证', command: 'node scripts/validate-config.js' }
    ];

    for (const check of checks) {
      console.log(`\n📋 执行: ${check.name}`);
      
      try {
        const output = execSync(check.command, { 
          encoding: 'utf8',
          stdio: 'pipe'
        });
        
        console.log(`✅ ${check.name} 通过`);
        this.results.preBuild.output += `\n${check.name}: 通过\n${output}`;
        
      } catch (error) {
        console.error(`❌ ${check.name} 失败:`, error.message);
        this.results.preBuild.success = false;
        throw new Error(`预构建检查失败: ${check.name}`);
      }
    }
    
    this.results.preBuild.success = true;
    console.log('✅ 所有预构建检查通过');
  }

  /**
   * 执行构建
   */
  async runBuild(buildType) {
    console.log('\n🔨 执行构建...');
    
    const buildCommand = `ohos build -b ${buildType}`;
    
    try {
      console.log(`执行命令: ${buildCommand}`);
      const output = execSync(buildCommand, { 
        encoding: 'utf8',
        stdio: 'pipe',
        cwd: process.cwd()
      });
      
      this.results.build.output = output;
      this.results.build.success = true;
      
      console.log('✅ 构建成功');
      
      // 检查构建产物
      this.checkBuildArtifacts(buildType);
      
    } catch (error) {
      console.error('❌ 构建失败:', error.message);
      this.results.build.success = false;
      this.results.build.output = error.stdout || error.message;
      throw error;
    }
  }

  /**
   * 检查构建产物
   */
  checkBuildArtifacts(buildType) {
    const artifacts = [
      `build/outputs/${buildType}/entry-unsigned.hap`,
      `build/outputs/${buildType}/entry-unsigned.app`,
      `build/outputs/${buildType}/packages/phone`
    ];

    console.log('\n📦 检查构建产物...');
    
    artifacts.forEach(artifact => {
      if (fs.existsSync(artifact)) {
        const stats = fs.statSync(artifact);
        console.log(`✅ ${artifact} (${this.formatFileSize(stats.size)})`);
      } else {
        console.warn(`⚠️ 构建产物不存在: ${artifact}`);
      }
    });
  }

  /**
   * 格式化文件大小
   */
  formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }

  /**
   * 执行构建后检查
   */
  async runPostBuildChecks() {
    console.log('\n🔍 执行构建后检查...');
    
    const checks = [
      { 
        name: 'HAP包验证', 
        command: 'node scripts/validate-hap.js build/outputs/debug/entry-unsigned.hap'
      },
      { 
        name: '包大小检查', 
        command: 'node scripts/check-bundle-size.js'
      }
    ];

    for (const check of checks) {
      console.log(`\n📋 执行: ${check.name}`);
      
      try {
        if (fs.existsSync(check.command.split(' ')[2])) {
          const output = execSync(check.command, { 
            encoding: 'utf8',
            stdio: 'pipe'
          });
          
          console.log(`✅ ${check.name} 通过`);
          this.results.postBuild.output += `\n${check.name}: 通过\n${output}`;
        } else {
          console.log(`⏭️ ${check.name} 跳过（文件不存在）`);
        }
        
      } catch (error) {
        console.warn(`⚠️ ${check.name} 警告:`, error.message);
        this.results.postBuild.output += `\n${check.name}: 警告 - ${error.message}`;
      }
    }
    
    this.results.postBuild.success = true;
    console.log('✅ 构建后检查完成');
  }

  /**
   * 生成构建报告
   */
  generateBuildReport() {
    console.log('\n📊 构建报告');
    console.log('='.repeat(60));
    
    const success = this.results.preBuild.success && 
                   this.results.build.success && 
                   this.results.postBuild.success;
    
    console.log(`预构建检查: ${this.results.preBuild.success ? '✅' : '❌'}`);
    console.log(`构建过程: ${this.results.build.success ? '✅' : '❌'}`);
    console.log(`构建后检查: ${this.results.postBuild.success ? '✅' : '⚠️'}`);
    
    console.log('\n' + '='.repeat(60));
    
    if (success) {
      console.log('🎉 构建流程完全成功！');
      
      // 显示构建产物信息
      this.showBuildArtifactsInfo();
      
    } else {
      console.log('❌ 构建流程存在问题');
      
      if (!this.results.preBuild.success) {
        console.log('\n🔧 问题分析: 预构建检查失败');
        console.log('建议: 修复代码规范问题后重新构建');
      } else if (!this.results.build.success) {
        console.log('\n🔧 问题分析: 构建过程失败');
        console.log('建议: 检查构建配置和依赖关系');
      }
    }
    
    // 保存构建报告到文件
    this.saveBuildReport();
  }

  /**
   * 显示构建产物信息
   */
  showBuildArtifactsInfo() {
    const buildDir = 'build/outputs/debug';
    
    if (fs.existsSync(buildDir)) {
      console.log('\n📦 构建产物:');
      
      const files = fs.readdirSync(buildDir, { recursive: true });
      
      files.forEach(file => {
        if (file.endsWith('.hap') || file.endsWith('.app')) {
          const filePath = path.join(buildDir, file);
          const stats = fs.statSync(filePath);
          console.log(`   📄 ${file} (${this.formatFileSize(stats.size)})`);
        }
      });
    }
  }

  /**
   * 保存构建报告到文件
   */
  saveBuildReport() {
    const report = {
      timestamp: new Date().toISOString(),
      results: this.results,
      summary: {
        preBuildSuccess: this.results.preBuild.success,
        buildSuccess: this.results.build.success,
        postBuildSuccess: this.results.postBuild.success,
        overallSuccess: this.results.preBuild.success && this.results.build.success
      }
    };
    
    const reportDir = 'build/reports';
    if (!fs.existsSync(reportDir)) {
      fs.mkdirSync(reportDir, { recursive: true });
    }
    
    const reportFile = path.join(reportDir, `build-report-${Date.now()}.json`);
    fs.writeFileSync(reportFile, JSON.stringify(report, null, 2));
    
    console.log(`\n📄 构建报告已保存: ${reportFile}`);
  }

  /**
   * 快速构建（跳过检查）
   */
  async runQuickBuild(buildType = 'debug') {
    console.log('⚡ 执行快速构建（跳过检查）...');
    
    try {
      const buildCommand = `ohos build -b ${buildType}`;
      const output = execSync(buildCommand, { 
        encoding: 'utf8',
        stdio: 'inherit',
        cwd: process.cwd()
      });
      
      console.log('✅ 快速构建成功');
      return true;
      
    } catch (error) {
      console.error('❌ 快速构建失败:', error.message);
      return false;
    }
  }
}

// CLI接口
async function main() {
  const integration = new BuildIntegration();
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    return;
  }

  if (args.includes('--quick') || args.includes('-q')) {
    await integration.runQuickBuild(args[1] || 'debug');
  } else if (args.includes('--pre-check') || args.includes('-p')) {
    await integration.runPreBuildChecks();
  } else {
    await integration.runFullBuild(args[0] || 'debug');
  }
}

function showHelp() {
  console.log(`
构建集成脚本

用法:
  node build-integration.js [构建类型] [选项]

构建类型:
  debug     调试构建（默认）
  release   发布构建

选项:
  --quick, -q       快速构建（跳过检查）
  --pre-check, -p   仅执行预构建检查
  --help, -h        显示帮助信息

示例:
  node build-integration.js              # 完整调试构建
  node build-integration.js release      # 完整发布构建
  node build-integration.js --quick      # 快速调试构建
  node build-integration.js --pre-check  # 仅执行预构建检查
  `);
}

// 执行主函数
if (require.main === module) {
  main().catch(error => {
    console.error('构建流程出错:', error);
    process.exit(1);
  });
}

module.exports = BuildIntegration;