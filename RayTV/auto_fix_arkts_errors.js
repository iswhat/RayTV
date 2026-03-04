#!/usr/bin/env node

/**
 * ArkTS错误批量修复脚本
 * 自动修复常见的ArkTS编译错误模式
 */

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// 错误统计
const stats = {
  totalFiles: 0,
  modifiedFiles: 0,
  totalErrorsFixed: 0,
  errorsByType: {}
};

/**
 * 修复console.log为Logger
 */
function fixConsoleToLogger(content, filePath) {
  let fixedCount = 0;
  const patterns = [
    { regex: /console\.info\(/g, replacement: 'Logger.info(', desc: 'console.info' },
    { regex: /console\.error\(/g, replacement: 'Logger.error(', desc: 'console.error' },
    { regex: /console\.warn\(/g, replacement: 'Logger.warn(', desc: 'console.warn' },
    { regex: /console\.debug\(/g, replacement: 'Logger.debug(', desc: 'console.debug' },
    { regex: /console\.log\(/g, replacement: 'Logger.info(', desc: 'console.log' }
  ];

  patterns.forEach(pattern => {
    const matches = content.match(pattern.regex);
    if (matches) {
      fixedCount += matches.length;
      content = content.replace(pattern.regex, pattern.replacement);
      logFix(pattern.desc, filePath, matches.length);
    }
  });

  return { content, fixedCount };
}

/**
 * 修复数组解构赋值
 */
function fixArrayDestructuring(content, filePath) {
  let fixedCount = 0;

  // 匹配: const [a, b, c] = await Promise.all([...])
  const destructuringRegex = /const\s+\[([^\]]+)\]\s*=\s*await\s+Promise\.all\(([^)]+)\)/g;

  content = content.replace(destructuringRegex, (match, vars, promiseAll) => {
    fixedCount++;
    const varNames = vars.split(',').map(v => v.trim());
    const newCode = `const allResults = await Promise.all(${promiseAll});\n`;
    const assignments = varNames.map((v, i) => `    const ${v} = allResults[${i}];`).join('\n');
    logFix('Array destructuring', filePath, 1);
    return newCode + assignments;
  });

  return { content, fixedCount };
}

/**
 * 修复动态import导致的classes as objects警告
 */
function fixDynamicImport(content, filePath) {
  let fixedCount = 0;

  // 匹配: const X = (await import('...')).X;
  const dynamicImportRegex = /const\s+(\w+)\s*=\s*\(await\s+import\(['"]([^'"]+)['"]\)\)\.\1;/g;

  content = content.replace(dynamicImportRegex, (match, name, importPath) => {
    fixedCount++;
    // 检查是否已经有顶层import
    const importStatement = `import { ${name} } from '${importPath}';`;
    if (!content.includes(importStatement)) {
      // 添加import到文件开头
      content = content + '\n' + importStatement;
    }
    logFix('Dynamic import', filePath, 1);
    return '';
  });

  return { content, fixedCount };
}

/**
 * 修复Progress组件使用
 */
function fixProgressComponent(content, filePath) {
  let fixedCount = 0;

  // 匹配: Progress().type(ProgressType.Circular)
  const progressRegex = /Progress\(\)\.type\(ProgressType\.Circular\)/g;

  content = content.replace(progressRegex, () => {
    fixedCount++;
    logFix('Progress component', filePath, 1);
    return "Progress({ value: 50, type: ProgressType.Ring })";
  });

  return { content, fixedCount };
}

/**
 * 添加缺失的返回类型
 */
function addExplicitReturnTypes(content, filePath) {
  let fixedCount = 0;

  // 匹配没有返回类型的函数: function foo() { 或 const foo = () => {
  const functionRegex = /(?:function\s+(\w+)\s*\(|const\s+(\w+)\s*=\s*(?:async\s*)?\([^)]*\)\s*=>)\s*\{/g;

  // 注意: 这只是一个简单的实现,实际应用中需要更精确的匹配
  // 这里只记录,不实际修改,因为自动添加返回类型需要更复杂的类型推断

  return { content, fixedCount };
}

/**
 * 记录修复信息
 */
function logFix(type, filePath, count) {
  if (!stats.errorsByType[type]) {
    stats.errorsByType[type] = 0;
  }
  stats.errorsByType[type] += count;
  stats.totalErrorsFixed += count;
  console.log(`  [FIX] ${type}: ${count} fixes in ${path.basename(filePath)}`);
}

/**
 * 处理单个文件
 */
async function processFile(filePath) {
  stats.totalFiles++;

  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    let modifiedContent = content;
    let totalFixed = 0;

    // 应用所有修复规则
    const fixes = [
      fixConsoleToLogger,
      fixArrayDestructuring,
      fixDynamicImport,
      fixProgressComponent,
      addExplicitReturnTypes
    ];

    for (const fix of fixes) {
      const result = fix(modifiedContent, filePath);
      modifiedContent = result.content;
      totalFixed += result.fixedCount;
    }

    // 如果文件有修改,写回文件
    if (modifiedContent !== content && totalFixed > 0) {
      fs.writeFileSync(filePath, modifiedContent, 'utf-8');
      stats.modifiedFiles++;
      console.log(`✓ Processed: ${filePath} (${totalFixed} fixes)`);
    }

  } catch (error) {
    console.error(`✗ Error processing ${filePath}:`, error.message);
  }
}

/**
 * 递归查找所有.ets文件
 */
function findEtsFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);

  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      // 跳过node_modules和oh_modules
      if (!['node_modules', 'oh_modules', '.hvigor', '.git'].includes(file)) {
        findEtsFiles(filePath, fileList);
      }
    } else if (file.endsWith('.ets')) {
      fileList.push(filePath);
    }
  });

  return fileList;
}

/**
 * 主函数
 */
async function main() {
  console.log('========================================');
  console.log('  ArkTS批量错误修复工具');
  console.log('========================================\n');

  const projectRoot = process.argv[2] || path.join(__dirname, 'raytv');
  console.log(`项目根目录: ${projectRoot}\n`);

  console.log('正在扫描.ets文件...');
  const etsFiles = findEtsFiles(projectRoot);
  console.log(`找到 ${etsFiles.length} 个.ets文件\n`);

  console.log('开始修复...\n');

  for (const file of etsFiles) {
    await processFile(file);
  }

  console.log('\n========================================');
  console.log('修复完成');
  console.log('========================================\n');
  console.log(`总计处理文件: ${stats.totalFiles}`);
  console.log(`修改文件数: ${stats.modifiedFiles}`);
  console.log(`修复错误总数: ${stats.totalErrorsFixed}\n`);

  console.log('按类型统计:');
  Object.entries(stats.errorsByType).forEach(([type, count]) => {
    console.log(`  ${type}: ${count}`);
  });

  console.log('\n注意:');
  console.log('- 此脚本仅修复常见的错误模式');
  console.log('- 部分复杂的错误仍需要手动修复');
  console.log('- 建议在修复后重新编译以验证结果');
  console.log('- 建议使用版本控制系统以便回退\n');
}

// 运行主函数
main().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
