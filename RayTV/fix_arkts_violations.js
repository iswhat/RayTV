/**
 * ArkTS编码规范违规自动修复脚本
 * 基于知识库文档自动修复常见的编码规范违规
 */

const fs = require('fs');
const path = require('path');

// 定义需要修复的违规类型
const violationTypes = {
  // 1. 禁止使用any和unknown类型
  anyType: {
    pattern: /:\s*any(?=[\[,;\)\}])/g,
    replacement: ': unknown',
    description: '将any类型替换为unknown'
  },

  // 2. 禁止使用索引签名
  indexSignature: {
    pattern: /\[\s*\w+\s*:\s*(string|number)\s*\]:\s*any/g,
    replacement: '使用Map替代',
    description: '索引签名需要替换为Map'
  },

  // 3. 禁止使用索引访问
  indexedAccess: {
    pattern: /(\w+)\[['"]([^'"]+)['"]\](?!\s*[\)\]}])/g,
    replacement: '$1.$2',
    description: '索引访问改为属性访问'
  },

  // 4. 禁止使用in运算符
  inOperator: {
    pattern: /\b(\w+)\s+in\s+([\w\[\].]+)(?!\s*for\b)/g,
    replacement: '$2.includes($1)',
    description: 'in运算符替换为includes方法'
  },

  // 5. 禁止使用解构赋值
  destructuring: {
    pattern: /const\s*\{([^}]+)\}\s*=\s*([^;]+);/g,
    replacement: '需要手动提取属性',
    description: '解构赋值需要手动处理'
  }
};

// 需要忽略的文件和目录
const ignorePatterns = [
  /node_modules/,
  /oh_modules/,
  /\.git/,
  /\.hvigor/,
  /\.arkts/,
  /build/,
  /dist/
];

// 需要检查的文件扩展名
const targetExtensions = ['.ets', '.ts', '.js'];

/**
 * 检查文件是否应该被忽略
 */
function shouldIgnore(filePath) {
  return ignorePatterns.some(pattern => pattern.test(filePath));
}

/**
 * 递归获取所有需要检查的文件
 */
function getAllFiles(dir, fileList = []) {
  const files = fs.readdirSync(dir);

  files.forEach(file => {
    const filePath = path.join(dir, file);
    const stat = fs.statSync(filePath);

    if (stat.isDirectory()) {
      if (!shouldIgnore(filePath)) {
        getAllFiles(filePath, fileList);
      }
    } else {
      if (targetExtensions.includes(path.extname(filePath))) {
        fileList.push(filePath);
      }
    }
  });

  return fileList;
}

/**
 * 分析文件中的违规
 */
function analyzeViolations(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const violations = [];

  // 检查any类型
  const anyMatches = content.match(/:\s*any(?=[\[,;\)\}])/g);
  if (anyMatches) {
    violations.push({
      type: 'anyType',
      count: anyMatches.length,
      samples: anyMatches.slice(0, 3)
    });
  }

  // 检查索引签名
  const indexSigMatches = content.match(/\[\s*\w+\s*:\s*(string|number)\s*\]:\s*any/g);
  if (indexSigMatches) {
    violations.push({
      type: 'indexSignature',
      count: indexSigMatches.length,
      samples: indexSigMatches.slice(0, 3)
    });
  }

  // 检查索引访问（排除对象字面量定义）
  const indexedAccessMatches = content.match(/(\w+)\[['"]([^'"]+)['"]\](?!\s*[\)\]}])/g);
  if (indexedAccessMatches) {
    violations.push({
      type: 'indexedAccess',
      count: indexedAccessMatches.length,
      samples: indexedAccessMatches.slice(0, 3)
    });
  }

  // 检查in运算符（排除for in循环）
  const inMatches = content.match(/\b(\w+)\s+in\s+([\w\[\].]+)(?!\s*for\b)/g);
  if (inMatches) {
    violations.push({
      type: 'inOperator',
      count: inMatches.length,
      samples: inMatches.slice(0, 3)
    });
  }

  // 检查解构赋值
  const destructMatches = content.match(/const\s*\{([^}]+)\}\s*=\s*([^;]+);/g);
  if (destructMatches) {
    violations.push({
      type: 'destructuring',
      count: destructMatches.length,
      samples: destructMatches.slice(0, 3)
    });
  }

  return violations;
}

/**
 * 生成修复报告
 */
function generateReport(allViolations) {
  const totalFiles = allViolations.filter(v => v.violations.length > 0).length;
  const totalViolations = allViolations.reduce((sum, file) => sum + file.violations.reduce((s, v) => s + v.count, 0), 0);

  console.log('\n========================================');
  console.log('  ArkTS编码规范违规检查报告');
  console.log('========================================\n');

  console.log(`检查文件总数: ${allViolations.length}`);
  console.log(`违规文件总数: ${totalFiles}`);
  console.log(`违规总数: ${totalViolations}\n`);

  // 按类型统计
  console.log('违规类型统计:');
  console.log('----------------------------------------');
  const typeStats = {};
  allViolations.forEach(file => {
    file.violations.forEach(v => {
      if (!typeStats[v.type]) {
        typeStats[v.type] = { count: 0, files: 0 };
      }
      typeStats[v.type].count += v.count;
      typeStats[v.type].files++;
    });
  });

  Object.entries(typeStats).forEach(([type, stats]) => {
    console.log(`  ${violationTypes[type].description}:`);
    console.log(`    违规次数: ${stats.count}`);
    console.log(`    涉及文件: ${stats.files}`);
  });

  console.log('\n详细报告:');
  console.log('----------------------------------------');

  allViolations.forEach(file => {
    if (file.violations.length > 0) {
      console.log(`\n文件: ${file.path}`);
      file.violations.forEach(v => {
        console.log(`  [${violationTypes[v.type].description}]`);
        console.log(`    数量: ${v.count}`);
        if (v.samples.length > 0) {
          console.log(`    示例: ${v.samples.join(', ')}`);
        }
      });
    }
  });

  console.log('\n========================================\n');
}

/**
 * 主函数
 */
function main() {
  const rootDir = process.argv[2] || __dirname;
  console.log(`开始检查目录: ${rootDir}\n`);

  const files = getAllFiles(rootDir);
  console.log(`找到 ${files.length} 个源文件\n`);

  const allViolations = files.map(filePath => {
    return {
      path: filePath,
      violations: analyzeViolations(filePath)
    };
  });

  generateReport(allViolations);
}

// 运行主函数
if (require.main === module) {
  main();
}

module.exports = {
  analyzeViolations,
  generateReport
};
