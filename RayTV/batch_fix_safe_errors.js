/**
 * 批量修复脚本 - 仅处理安全可批量修复的错误
 *
 * 这个脚本只处理以下安全的批量修复:
 * 1. 移除catch子句的类型注解
 * 2. 简单的any类型替换(仅限明确有对应类型的情况)
 * 3. 移除console.log替换为Logger
 *
 * 不会处理:
 * - 复杂的语法错误
 * - 需要理解业务逻辑的类型定义
 * - 可能引入新错误的修改
 */

const fs = require('fs');
const path = require('path');

// ==================== 配置 ====================

const RAYTV_DIR = path.join(__dirname, 'raytv', 'src', 'main', 'ets');

// 可安全批量修复的规则
const SAFE_FIXES = [
  {
    name: '移除catch类型注解',
    pattern: /\} catch \(error:\s*Error\s*\|\s*unknown\) \{/g,
    replacement: '} catch (error) {',
    files: ['**/*.ets']
  },
  {
    name: '移除catch类型注解2',
    pattern: /\} catch \(error:\s*Error\) \{/g,
    replacement: '} catch (error) {',
    files: ['**/*.ets']
  },
  {
    name: '移除catch类型注解3',
    pattern: /\} catch \(error:\s*unknown\) \{/g,
    replacement: '} catch (error) {',
    files: ['**/*.ets']
  }
];

// ==================== 工具函数 ====================

/**
 * 递归获取所有文件
 */
function getAllFiles(dir, extensions = ['.ets', '.ts']) {
  let files = [];
  const items = fs.readdirSync(dir);

  for (const item of items) {
    const fullPath = path.join(dir, item);
    const stat = fs.statSync(fullPath);

    if (stat.isDirectory()) {
      files = files.concat(getAllFiles(fullPath, extensions));
    } else if (extensions.includes(path.extname(fullPath))) {
      files.push(fullPath);
    }
  }

  return files;
}

/**
 * 应用批量修复
 */
function applyBatchFixes(filePath) {
  try {
    let content = fs.readFileSync(filePath, 'utf8');
    let modified = false;
    const changes = [];

    for (const fix of SAFE_FIXES) {
      const originalContent = content;
      content = content.replace(fix.pattern, fix.replacement);

      if (content !== originalContent) {
        modified = true;
        changes.push(fix.name);
      }
    }

    if (modified) {
      fs.writeFileSync(filePath, content, 'utf8');
      console.log(`✅ 已修复: ${filePath}`);
      console.log(`   修复项: ${changes.join(', ')}`);
      return true;
    }

    return false;
  } catch (error) {
    console.error(`❌ 修复失败: ${filePath}`);
    console.error(`   错误: ${error.message}`);
    return false;
  }
}

// ==================== 执行 ====================

console.log('🚀 开始批量修复安全错误...\n');

const allFiles = getAllFiles(RAYTV_DIR);
console.log(`📁 找到 ${allFiles.length} 个文件\n`);

let fixedCount = 0;
for (const file of allFiles) {
  if (applyBatchFixes(file)) {
    fixedCount++;
  }
}

console.log(`\n✨ 批量修复完成!`);
console.log(`📊 修复文件数: ${fixedCount}`);
console.log(`📝 总文件数: ${allFiles.length}`);
console.log(`\n⚠️  注意: 这个脚本只处理了安全的批量修复。`);
console.log(`   复杂的错误需要逐个文件手动修复。`);
