#!/usr/bin/env node

/**
 * ArkTS静态代码检查工具
 * 基于code-linter.json5配置执行代码质量检查
 */

const fs = require('fs');
const path = require('path');

class ArkTSCodeLinter {
  constructor() {
    this.config = this.loadConfig();
    this.results = {
      filesScanned: 0,
      issuesFound: 0,
      errors: [],
      warnings: [],
      details: {}
    };
  }

  /**
   * 加载配置文件
   */
  loadConfig() {
    const configPath = path.join(process.cwd(), 'code-linter.json5');
    
    if (!fs.existsSync(configPath)) {
      console.warn('⚠️ 未找到code-linter.json5配置文件，使用默认配置');
      return this.getDefaultConfig();
    }

    try {
      const configContent = fs.readFileSync(configPath, 'utf8');
      // 简化JSON5解析（实际项目中应使用json5库）
      return JSON.parse(configContent.replace(/\/\/.*$/gm, ''));
    } catch (error) {
      console.error('❌ 配置文件解析失败，使用默认配置:', error.message);
      return this.getDefaultConfig();
    }
  }

  /**
   * 获取默认配置
   */
  getDefaultConfig() {
    return {
      rules: {
        "arkts-component-import": {
          level: "error",
          pattern: "import.*as.*Component",
          message: "请使用标准组件导入方式，避免别名导入"
        },
        "arkts-property-syntax": {
          level: "error",
          pattern: "style={{.*}}",
          message: "请将style对象拆分为独立属性设置"
        },
        "consistent-component-usage": {
          level: "warning",
          pattern: "ListItemComponent",
          message: "请使用标准ListItem组件名称"
        }
      },
      include: ["src/**/*.ets", "src/**/*.ts"],
      exclude: ["node_modules", "build", "dist", ".hvigor"]
    };
  }

  /**
   * 执行代码检查
   */
  async runLint(srcDir = './src') {
    console.log('🔍 开始ArkTS代码检查...');
    console.log('='.repeat(60));

    if (!fs.existsSync(srcDir)) {
      this.results.errors.push(`源目录不存在: ${srcDir}`);
      return this.results;
    }

    const files = this.getAllFiles(srcDir);
    console.log(`📁 扫描 ${files.length} 个文件`);

    for (const file of files) {
      await this.checkFile(file);
    }

    this.generateReport();
    return this.results;
  }

  /**
   * 获取所有需要检查的文件
   */
  getAllFiles(dir) {
    let results = [];
    
    try {
      const list = fs.readdirSync(dir);

      for (const file of list) {
        const filePath = path.join(dir, file);
        const stat = fs.statSync(filePath);

        if (stat.isDirectory()) {
          // 检查是否在排除列表中
          const shouldExclude = this.config.exclude.some(pattern => 
            filePath.includes(pattern.replace('*', ''))
          );
          
          if (!shouldExclude) {
            results = results.concat(this.getAllFiles(filePath));
          }
        } else {
          // 检查文件扩展名是否符合包含规则
          const ext = path.extname(file).toLowerCase();
          const shouldInclude = this.config.include.some(pattern => {
            const patternExt = pattern.split('.').pop();
            return ext === `.${patternExt}` || pattern.includes('*');
          });
          
          if (shouldInclude) {
            results.push(filePath);
          }
        }
      }
    } catch (error) {
      console.error(`扫描目录失败: ${dir}`, error.message);
    }

    return results;
  }

  /**
   * 检查单个文件
   */
  async checkFile(filePath) {
    try {
      const content = fs.readFileSync(filePath, 'utf8');
      const relativePath = path.relative(process.cwd(), filePath);
      
      this.results.filesScanned++;
      this.results.details[relativePath] = [];

      // 应用所有规则
      for (const [ruleName, ruleConfig] of Object.entries(this.config.rules)) {
        await this.applyRule(filePath, content, ruleName, ruleConfig);
      }

    } catch (error) {
      this.results.errors.push(`检查文件失败: ${filePath} - ${error.message}`);
    }
  }

  /**
   * 应用单个规则
   */
  async applyRule(filePath, content, ruleName, ruleConfig) {
    const relativePath = path.relative(process.cwd(), filePath);
    const pattern = new RegExp(ruleConfig.pattern, 'g');
    const matches = content.match(pattern);

    if (matches) {
      matches.forEach((match, index) => {
        const issue = {
          rule: ruleName,
          level: ruleConfig.level,
          message: ruleConfig.message,
          match: match,
          line: this.getLineNumber(content, match, index),
          character: this.getCharacterPosition(content, match, index)
        };

        this.results.issuesFound++;
        this.results.details[relativePath].push(issue);

        if (ruleConfig.level === 'error') {
          this.results.errors.push(issue);
        } else {
          this.results.warnings.push(issue);
        }
      });
    }
  }

  /**
   * 获取匹配内容所在行号
   */
  getLineNumber(content, match, matchIndex) {
    const lines = content.split('\n');
    let currentPos = 0;
    
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineStart = currentPos;
      const lineEnd = currentPos + line.length;
      
      // 查找匹配位置
      const matchPos = content.indexOf(match, matchIndex > 0 ? content.indexOf(match) + 1 : 0);
      
      if (matchPos >= lineStart && matchPos <= lineEnd) {
        return i + 1; // 转换为1-based行号
      }
      
      currentPos = lineEnd + 1; // +1 for newline character
    }
    
    return 1; // 默认返回第1行
  }

  /**
   * 获取字符位置
   */
  getCharacterPosition(content, match, matchIndex) {
    const matchPos = content.indexOf(match, matchIndex > 0 ? content.indexOf(match) + 1 : 0);
    const lineStart = content.lastIndexOf('\n', matchPos) + 1;
    return matchPos - lineStart + 1; // 转换为1-based字符位置
  }

  /**
   * 生成检查报告
   */
  generateReport() {
    console.log('\n📊 ArkTS代码检查报告');
    console.log('='.repeat(60));
    
    console.log(`📁 扫描文件数: ${this.results.filesScanned}`);
    console.log(`❌ 发现问题数: ${this.results.issuesFound}`);
    console.log(`🚫 错误数量: ${this.results.errors.length}`);
    console.log(`⚠️ 警告数量: ${this.results.warnings.length}`);

    // 按文件显示详细问题
    if (this.results.issuesFound > 0) {
      console.log('\n📋 详细问题报告:');
      console.log('-'.repeat(40));
      
      Object.entries(this.results.details).forEach(([filePath, issues]) => {
        if (issues.length > 0) {
          console.log(`\n📄 ${filePath}:`);
          issues.forEach(issue => {
            const levelIcon = issue.level === 'error' ? '❌' : '⚠️';
            console.log(`   ${levelIcon} 行 ${issue.line}:${issue.character} - ${issue.message}`);
            console.log(`       匹配: ${issue.match.substring(0, 50)}...`);
          });
        }
      });
    }

    // 显示错误和警告摘要
    if (this.results.errors.length > 0) {
      console.log('\n🚫 错误摘要:');
      this.results.errors.slice(0, 5).forEach(error => {
        console.log(`   ❌ ${error.message}`);
      });
      if (this.results.errors.length > 5) {
        console.log(`   ... 还有 ${this.results.errors.length - 5} 个错误`);
      }
    }

    if (this.results.warnings.length > 0) {
      console.log('\n⚠️ 警告摘要:');
      this.results.warnings.slice(0, 5).forEach(warning => {
        console.log(`   ⚠️ ${warning.message}`);
      });
      if (this.results.warnings.length > 5) {
        console.log(`   ... 还有 ${this.results.warnings.length - 5} 个警告`);
      }
    }

    // 生成通过/失败状态
    const hasErrors = this.results.errors.length > 0;
    const status = hasErrors ? '❌ 检查失败' : '✅ 检查通过';
    
    console.log('\n' + '='.repeat(60));
    console.log(`检查结果: ${status}`);
    
    if (!hasErrors && this.results.warnings.length === 0) {
      console.log('🎉 恭喜！代码完全符合ArkTS规范。');
    } else if (!hasErrors) {
      console.log('💡 代码通过检查，但存在一些警告建议修复。');
    } else {
      console.log('🔧 发现错误，请修复后重新检查。');
      process.exit(1); // 退出码非0表示检查失败
    }
  }

  /**
   * 生成IDE友好的报告格式
   */
  generateIDEFormat() {
    const output = [];
    
    Object.entries(this.results.details).forEach(([filePath, issues]) => {
      issues.forEach(issue => {
        output.push({
          file: filePath,
          line: issue.line,
          column: issue.character,
          severity: issue.level,
          message: issue.message,
          source: issue.match
        });
      });
    });

    return output;
  }
}

// CLI接口
async function main() {
  const linter = new ArkTSCodeLinter();
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    showHelp();
    return;
  }

  if (args.includes('--json') || args.includes('-j')) {
    const results = await linter.runLint();
    console.log(JSON.stringify(linter.generateIDEFormat(), null, 2));
  } else {
    await linter.runLint();
  }
}

function showHelp() {
  console.log(`
ArkTS静态代码检查工具

用法:
  node code-linter.js [选项]

选项:
  --json, -j    输出JSON格式的报告（用于IDE集成）
  --help, -h    显示帮助信息

配置文件:
  工具会自动加载项目根目录下的 code-linter.json5 文件
  
退出码:
  0 - 检查通过
  1 - 检查失败（存在错误）
  `);
}

// 执行主函数
if (require.main === module) {
  main().catch(error => {
    console.error('检查过程出错:', error);
    process.exit(1);
  });
}

module.exports = ArkTSCodeLinter;