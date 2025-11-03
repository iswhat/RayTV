#!/usr/bin/env node

/**
 * ArkTS技术栈迁移工具
 * 自动修复组件导入和属性语法问题
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

class ArkTSMigrationTool {
  constructor() {
    this.stats = {
      filesProcessed: 0,
      importsFixed: 0,
      componentsFixed: 0,
      propertiesFixed: 0,
      errors: 0
    };
  }

  /**
   * 扫描项目目录
   */
  async scanProject(srcDir = './src') {
    console.log('🔍 开始扫描ArkTS项目...');
    
    if (!fs.existsSync(srcDir)) {
      console.error('❌ 源目录不存在:', srcDir);
      return;
    }

    const files = this.getAllFiles(srcDir, ['.ets', '.ts']);
    console.log(`📁 找到 ${files.length} 个文件需要检查`);

    for (const file of files) {
      await this.processFile(file);
    }

    this.generateReport();
  }

  /**
   * 获取所有指定扩展名的文件
   */
  getAllFiles(dir, extensions) {
    let results = [];
    const list = fs.readdirSync(dir);

    for (const file of list) {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);

      if (stat.isDirectory()) {
        // 跳过node_modules和build目录
        if (file !== 'node_modules' && file !== 'build' && file !== '.hvigor') {
          results = results.concat(this.getAllFiles(filePath, extensions));
        }
      } else {
        const ext = path.extname(file).toLowerCase();
        if (extensions.includes(ext)) {
          results.push(filePath);
        }
      }
    }

    return results;
  }

  /**
   * 处理单个文件
   */
  async processFile(filePath) {
    try {
      let content = fs.readFileSync(filePath, 'utf8');
      const originalContent = content;

      // 修复组件别名导入
      content = this.fixComponentImports(content);
      
      // 修复组件使用
      content = this.fixComponentUsage(content);
      
      // 修复ProgressBar属性
      content = this.fixProgressBarAttributes(content);
      
      // 修复其他属性语法
      content = this.fixPropertySyntax(content);

      if (content !== originalContent) {
        // 备份原文件
        const backupPath = filePath + '.backup';
        if (!fs.existsSync(backupPath)) {
          fs.writeFileSync(backupPath, originalContent);
        }
        
        // 写入修复后的内容
        fs.writeFileSync(filePath, content);
        this.stats.filesProcessed++;
        console.log(`✅ 修复文件: ${path.relative(process.cwd(), filePath)}`);
      }
    } catch (error) {
      console.error(`❌ 处理文件失败: ${filePath}`, error.message);
      this.stats.errors++;
    }
  }

  /**
   * 修复组件别名导入
   */
  fixComponentImports(content) {
    // 修复 ListItem as ListItemComponent
    const listItemImportRegex = /import\s*{\s*ListItem\s+as\s+ListItemComponent\s*}\s*from\s*['"]@arkui\/native['"]/g;
    if (listItemImportRegex.test(content)) {
      content = content.replace(listItemImportRegex, "import { ListItem } from '@arkui/native'");
      this.stats.importsFixed++;
    }

    // 修复其他组件别名
    const componentImportRegex = /import\s*{\s*(\w+)\s+as\s+(\w+Component)\s*}\s*from\s*['"]@arkui\/native['"]/g;
    const matches = content.match(componentImportRegex);
    if (matches) {
      content = content.replace(componentImportRegex, "import { $1 } from '@arkui/native'");
      this.stats.importsFixed += matches.length;
    }

    return content;
  }

  /**
   * 修复组件使用
   */
  fixComponentUsage(content) {
    // 修复 ListItemComponent -> ListItem
    const listItemUsageRegex = /<ListItemComponent(\s|>)/g;
    const listItemClosingRegex = /<\/ListItemComponent>/g;
    
    if (listItemUsageRegex.test(content) || listItemClosingRegex.test(content)) {
      content = content.replace(listItemUsageRegex, '<ListItem$1');
      content = content.replace(listItemClosingRegex, '</ListItem>');
      this.stats.componentsFixed++;
    }

    return content;
  }

  /**
   * 修复ProgressBar属性
   */
  fixProgressBarAttributes(content) {
    // 修复style对象为独立属性
    const progressBarStyleRegex = /<ProgressBar(\s+[^>]*)?\s+style=\{\s*{\s*strokeWidth:\s*(\d+),\s*color:\s*'([^']+)'\s*}\s*}([^>]*)?\s*\/?>/g;
    
    if (progressBarStyleRegex.test(content)) {
      content = content.replace(progressBarStyleRegex, '<ProgressBar$1 strokeWidth={$2} color="$3"$4>');
      this.stats.propertiesFixed++;
    }

    return content;
  }

  /**
   * 修复其他属性语法
   */
  fixPropertySyntax(content) {
    // 修复其他组件的style对象使用
    const styleObjectRegex = /<(\w+)(\s+[^>]*)?\s+style=\{\s*{\s*([^}]+)\s*}\s*}([^>]*)?\s*\/?>/g;
    
    const styleMatches = content.match(styleObjectRegex);
    if (styleMatches) {
      content = content.replace(styleObjectRegex, (match, tagName, attrs, styleContent, rest) => {
        // 将style对象转换为独立属性
        const styleProps = styleContent.split(',').map(prop => {
          const [key, value] = prop.split(':').map(s => s.trim());
          if (key && value) {
            return `${key}={${value}}`;
          }
          return '';
        }).filter(Boolean).join(' ');
        
        return `<${tagName}${attrs || ''} ${styleProps}${rest || ''}>`;
      });
      this.stats.propertiesFixed += styleMatches.length;
    }

    return content;
  }

  /**
   * 生成迁移报告
   */
  generateReport() {
    console.log('\n📊 迁移报告:');
    console.log('='.repeat(50));
    console.log(`📁 处理文件数: ${this.stats.filesProcessed}`);
    console.log(`🔧 修复导入问题: ${this.stats.importsFixed}`);
    console.log(`⚡ 修复组件使用: ${this.stats.componentsFixed}`);
    console.log(`🎨 修复属性语法: ${this.stats.propertiesFixed}`);
    console.log(`❌ 错误数量: ${this.stats.errors}`);
    console.log('='.repeat(50));

    if (this.stats.errors === 0) {
      console.log('🎉 迁移完成！所有问题已修复。');
    } else {
      console.log('⚠️ 迁移完成，但存在一些错误，请检查日志。');
    }
  }

  /**
   * 检查迁移状态
   */
  async checkMigrationStatus(srcDir = './src') {
    console.log('🔍 检查迁移状态...');
    
    const issues = {
      componentImports: [],
      componentUsage: [],
      propertySyntax: []
    };

    const files = this.getAllFiles(srcDir, ['.ets', '.ts']);
    
    for (const file of files) {
      const content = fs.readFileSync(file, 'utf8');
      const relativePath = path.relative(process.cwd(), file);

      // 检查组件别名导入
      const importIssues = content.match(/import\s*{\s*\w+\s+as\s+\w+Component\s*}\s*from\s*['"]@arkui\/native['"]/g);
      if (importIssues) {
        issues.componentImports.push({
          file: relativePath,
          issues: importIssues
        });
      }

      // 检查组件使用
      const usageIssues = content.match(/ListItemComponent/g);
      if (usageIssues) {
        issues.componentUsage.push({
          file: relativePath,
          issues: usageIssues
        });
      }

      // 检查属性语法
      const propertyIssues = content.match(/style=\{\s*{\s*[^}]+\s*}\s*}/g);
      if (propertyIssues) {
        issues.propertySyntax.push({
          file: relativePath,
          issues: propertyIssues
        });
      }
    }

    this.generateStatusReport(issues);
    return issues;
  }

  /**
   * 生成状态报告
   */
  generateStatusReport(issues) {
    console.log('\n📋 迁移状态报告:');
    console.log('='.repeat(50));
    
    const totalIssues = Object.values(issues).reduce((sum, category) => sum + category.length, 0);
    
    if (totalIssues === 0) {
      console.log('✅ 恭喜！项目已完全符合ArkTS规范。');
      return;
    }

    console.log(`❌ 发现 ${totalIssues} 个问题需要修复:`);
    
    if (issues.componentImports.length > 0) {
      console.log(`\n🔧 组件导入问题 (${issues.componentImports.length} 个文件):`);
      issues.componentImports.forEach(issue => {
        console.log(`   📄 ${issue.file}`);
      });
    }

    if (issues.componentUsage.length > 0) {
      console.log(`\n⚡ 组件使用问题 (${issues.componentUsage.length} 个文件):`);
      issues.componentUsage.forEach(issue => {
        console.log(`   📄 ${issue.file}`);
      });
    }

    if (issues.propertySyntax.length > 0) {
      console.log(`\n🎨 属性语法问题 (${issues.propertySyntax.length} 个文件):`);
      issues.propertySyntax.forEach(issue => {
        console.log(`   📄 ${issue.file}`);
      });
    }

    console.log('\n💡 建议运行迁移工具自动修复这些问题。');
    console.log('='.repeat(50));
  }
}

// CLI接口
async function main() {
  const tool = new ArkTSMigrationTool();
  const args = process.argv.slice(2);

  if (args.includes('--check') || args.includes('-c')) {
    await tool.checkMigrationStatus();
  } else if (args.includes('--help') || args.includes('-h')) {
    showHelp();
  } else {
    // 默认执行迁移
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout
    });

    console.log('🚀 ArkTS技术栈迁移工具');
    console.log('='.repeat(40));
    
    rl.question('是否确认执行迁移？(y/N): ', async (answer) => {
      if (answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes') {
        await tool.scanProject();
      } else {
        console.log('迁移已取消。');
      }
      rl.close();
    });
  }
}

function showHelp() {
  console.log(`
ArkTS技术栈迁移工具

用法:
  node migration-tool.js [选项]

选项:
  --check, -c    检查迁移状态，不执行实际迁移
  --help, -h     显示帮助信息
  
示例:
  node migration-tool.js          # 执行迁移
  node migration-tool.js --check # 检查状态
  `);
}

// 执行主函数
if (require.main === module) {
  main().catch(console.error);
}

module.exports = ArkTSMigrationTool;