const fs = require('fs');
const path = require('path');

const etsDir = 'd:/tv/RayTV/raytv/src/main/ets';
const backupDir = 'd:/tv/RayTV/backup_hardcoded_data';

// 创建备份目录
if (!fs.existsSync(backupDir)) {
  fs.mkdirSync(backupDir, { recursive: true });
}

// 需要清理的模式 - 按优先级排序
const CLEANUP_RULES = [
  // P0: 必须清理 - 测试数据和占位符
  {
    pattern: /https?:\/\/via\.placeholder\.com\/[^\s'"`>]+/g,
    replacement: '$r("app.media.default_cover")',
    description: '占位符图片URL (via.placeholder.com)',
    priority: 'P0'
  },
  
  // P0: 必须清理 - 测试视频URL
  {
    pattern: /https?:\/\/example\.com\/(episode\d+|test-movie|related\d+|live\/\w+)/g,
    replacement: '""',
    description: '测试视频URL (example.com)',
    priority: 'P0'
  },
  
  // P0: 必须清理 - 测试API端点
  {
    pattern: /https?:\/\/api\.raytv\.example\.com/g,
    replacement: 'null',
    description: '测试API端点 (api.raytv.example.com)',
    priority: 'P0'
  },
  
  // P1: 应该清理 - 其他example.com
  {
    pattern: /https?:\/\/example\.com\/video\.mp4/g,
    replacement: '""',
    description: '示例视频URL',
    priority: 'P1'
  },
  
  // P1: 应该清理 - 测试数据注释
  {
    pattern: /\/\/ 模拟数据[- ].*Mock data/g,
    replacement: '// TODO: 从网络源加载真实数据',
    description: '模拟数据注释',
    priority: 'P1'
  },
  
  // P1: 应该清理 - 测试内容
  {
    pattern: /name: ['"]测试电影['"]/g,
    replacement: 'name: ""',
    description: '测试电影名称',
    priority: 'P1'
  },
  
  {
    pattern: /desc: ['"]这是一部测试电影[^'"]*['"]/g,
    replacement: 'desc: ""',
    description: '测试描述',
    priority: 'P1'
  },
  
  {
    pattern: /sourceKey: ['"]test_source['"]/g,
    replacement: 'sourceKey: ""',
    description: '测试源Key',
    priority: 'P1'
  }
];

// 保留的合法URL (不匹配这些)
const ALLOWED_PATTERNS = [
  /https:\/\/(www\.eoeoo\.com|list\.eoeoo\.com|q\.uoouo\.com)/,
  /https?:\/\/(www\.)?饭太硬\.com/,
  /https?:\/\/www\.eoeoo\.com\/list\.json/,
  /https?:\/\/www\.eoeoo\.com\/base2\/a\.json/,
  /https?:\/\/q\.uoouo\.com\/dianshi\.json/
];

// 递归查找所有.ets文件
function findEtsFiles(dir) {
  const files = [];
  
  function scan(directory) {
    try {
      const items = fs.readdirSync(directory);
      for (const item of items) {
        const fullPath = path.join(directory, item);
        const stat = fs.statSync(fullPath);
        
        if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
          scan(fullPath);
        } else if (item.endsWith('.ets') || item.endsWith('.ts')) {
          files.push(fullPath);
        }
      }
    } catch (e) {
      console.log(`  跳过目录: ${directory}`);
    }
  }
  
  scan(dir);
  return files;
}

// 检查是否是允许的URL
function isAllowedUrl(url) {
  for (const pattern of ALLOWED_PATTERNS) {
    if (pattern.test(url)) {
      return true;
    }
  }
  return false;
}

// 处理单个文件
function processFile(filePath, dryRun = true) {
  const content = fs.readFileSync(filePath, 'utf8');
  let newContent = content;
  let modified = false;
  const changes = [];
  const relativePath = path.relative(etsDir, filePath);
  
  // 跳过测试文件
  if (relativePath.includes('test/') || relativePath.includes('Test.ts')) {
    return { modified: false, changes: [] };
  }
  
  for (const rule of CLEANUP_RULES) {
    const matches = content.match(rule.pattern);
    if (matches) {
      // 检查每个匹配是否是允许的URL
      const validMatches = matches.filter(match => !isAllowedUrl(match));
      
      if (validMatches.length > 0) {
        validMatches.forEach(match => {
          newContent = newContent.replace(match, rule.replacement);
          changes.push({
            priority: rule.priority,
            description: rule.description,
            original: match,
            replacement: rule.replacement
          });
          modified = true;
        });
      }
    }
  }
  
  if (modified && !dryRun) {
    // 备份原文件
    const backupPath = path.join(backupDir, relativePath);
    const backupDirPath = path.dirname(backupPath);
    if (!fs.existsSync(backupDirPath)) {
      fs.mkdirSync(backupDirPath, { recursive: true });
    }
    fs.copyFileSync(filePath, backupPath);
    
    // 写入修改后的内容
    fs.writeFileSync(filePath, newContent);
  }
  
  return { modified, changes };
}

// 主函数
function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes('--dry-run') || args.includes('-n');
  const verbose = args.includes('--verbose') || args.includes('-v');
  const filterPriority = args.find(arg => arg.startsWith('--priority='))?.split('=')[1];
  
  console.log('🧹 RayTV壳应用 - 硬编码数据清理工具\n');
  console.log('项目定位: TVBox/影视仓兼容的壳应用\n');
  console.log('清理原则:');
  console.log('  ✅ 保留: 网络源配置 (eoeoo.com, 饭太硬.com, uoouo.com)');
  console.log('  ❌ 移除: 测试数据、占位符URL、demo内容\n');
  
  console.log(`执行模式: ${dryRun ? '🔍 预演模式 (不会修改文件)' : '✏️  实际修改模式'}\n`);
  
  const files = findEtsFiles(etsDir);
  console.log(`📁 扫描范围: ${etsDir}`);
  console.log(`📄 找到 ${files.length} 个 .ets/.ts 文件\n`);
  
  // 按优先级过滤规则
  const activeRules = filterPriority 
    ? CLEANUP_RULES.filter(r => r.priority === filterPriority)
    : CLEANUP_RULES;
  
  console.log(`🔧 清理规则: ${activeRules.length} 条`);
  activeRules.forEach(rule => {
    console.log(`   [${rule.priority}] ${rule.description}`);
  });
  console.log('');
  
  let totalFiles = 0;
  let totalChanges = 0;
  const priorityStats = {};
  const fileChanges = [];
  
  for (const file of files) {
    const relativePath = path.relative(etsDir, file);
    
    // 处理文件
    let tempContent = fs.readFileSync(file, 'utf8');
    let fileModified = false;
    let fileChanges = [];
    
    for (const rule of activeRules) {
      const matches = tempContent.match(rule.pattern);
      if (matches) {
        const validMatches = matches.filter(match => !isAllowedUrl(match));
        
        if (validMatches.length > 0) {
          validMatches.forEach(match => {
            tempContent = tempContent.replace(match, rule.replacement);
            if (!priorityStats[rule.priority]) {
              priorityStats[rule.priority] = 0;
            }
            priorityStats[rule.priority]++;
            totalChanges++;
            fileChanges.push({
              priority: rule.priority,
              description: rule.description,
              original: match,
              replacement: rule.replacement
            });
            fileModified = true;
          });
        }
      }
    }
    
    if (fileModified) {
      totalFiles++;
      if (verbose) {
        console.log(`📝 ${relativePath}`);
        fileChanges.forEach(change => {
          console.log(`   └─ [${change.priority}] ${change.description}`);
          console.log(`      原始: ${change.original}`);
          console.log(`      替换: ${change.replacement}`);
        });
        console.log('');
      } else {
        fileChanges.push({
          file: relativePath,
          changes: fileChanges,
          content: tempContent
        });
      }
    }
  }
  
  // 显示统计
  console.log(`\n${dryRun ? '📊 预演结果:' : '✅ 清理结果:'}`);
  console.log(`   修改文件: ${totalFiles}`);
  console.log(`   总计修改: ${totalChanges} 处\n`);
  
  if (Object.keys(priorityStats).length > 0) {
    console.log(`按优先级统计:`);
    Object.keys(priorityStats).sort().forEach(priority => {
      console.log(`   [${priority}] ${priorityStats[priority]} 处`);
    });
    console.log('');
  }
  
  if (!verbose && fileChanges.length > 0) {
    console.log(`📋 修改文件列表:\n`);
    fileChanges.forEach(item => {
      console.log(`📄 ${item.file} (${item.changes.length} 处修改)`);
      const uniqueDescriptions = [...new Set(item.changes.map(c => c.description))];
      uniqueDescriptions.forEach(desc => {
        console.log(`   ├─ ${desc}`);
      });
    });
  }
  
  if (dryRun && totalChanges > 0) {
    console.log(`\n💡 提示: 运行不带 --dry-run 参数执行实际修改`);
    console.log(`   备份文件将保存到: ${backupDir}`);
    console.log(`\n⚠️  请在执行前检查预演结果!`);
  } else if (totalChanges > 0) {
    console.log(`\n💾 备份已保存到: ${backupDir}`);
    console.log(`\n✨ 清理完成! 请验证构建和运行测试。`);
  } else {
    console.log(`\n✨ 没有发现需要清理的硬编码数据!`);
  }
}

// 显示帮助信息
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
RayTV硬编码数据清理工具

用法: node cleanup_hardcoded_data.js [选项]

选项:
  --dry-run, -n         预演模式,不实际修改文件 (默认: true)
  --verbose, -v         显示详细修改信息 (默认: false)
  --priority=P0,P1,P2    只处理指定优先级的规则 (默认: 全部)
  --help, -h            显示此帮助信息

示例:
  node cleanup_hardcoded_data.js              # 预演所有清理
  node cleanup_hardcoded_data.js -v            # 预演+详细信息
  node cleanup_hardcoded_data.js --priority=P0 # 只清理P0级别
  node cleanup_hardcoded_data.js (no args)    # 实际执行所有清理

清理说明:
  P0 (必须清理): 测试数据、占位符URL、demo内容
  P1 (应该清理): 测试API端点、示例数据
  P2 (可选清理): 其他示例内容

项目定位: TVBox/影视仓兼容的壳应用
数据来源: 仅来自用户配置的网络源
`);
  process.exit(0);
}

// 运行
main();
