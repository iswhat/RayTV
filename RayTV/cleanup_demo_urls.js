const fs = require('fs');
const path = require('path');

const etsDir = 'd:/tv/RayTV/raytv/src/main/ets';
const backupDir = 'd:/tv/RayTV/backup_urls';

// 需要清理的URL模式
const URL_PATTERNS = {
  // 占位符图片 - 替换为本地默认图片
  placeholderImages: {
    pattern: /https?:\/\/via\.placeholder\.com\/[^\s'"]+/g,
    replacement: '',
    description: '占位符图片URL'
  },
  
  // 测试API端点 - 需要手动配置
  testApiEndpoints: {
    pattern: /https?:\/\/api\.raytv\.example\.com/g,
    replacement: 'TODO_CONFIGURE_REAL_API',
    description: '测试API端点'
  },
  
  // 测试视频URL - 移除或标记
  testVideoUrls: {
    pattern: /https?:\/\/example\.com\/(episode\d+|test-movie|related\d+)/g,
    replacement: '',
    description: '测试视频URL'
  },
  
  // 测试直播流URL - 移除或标记
  testLiveStreams: {
    pattern: /https?:\/\/example\.com\/live\/[^\s'"]+/g,
    replacement: '',
    description: '测试直播流URL'
  }
};

// 创建备份目录
if (!fs.existsSync(backupDir)) {
  fs.mkdirSync(backupDir, { recursive: true });
}

// 递归查找所有.ets文件
function findEtsFiles(dir) {
  const files = [];
  
  function scan(directory) {
    const items = fs.readdirSync(directory);
    for (const item of items) {
      const fullPath = path.join(directory, item);
      const stat = fs.statSync(fullPath);
      
      if (stat.isDirectory() && !item.startsWith('.') && item !== 'node_modules') {
        scan(fullPath);
      } else if (item.endsWith('.ets')) {
        files.push(fullPath);
      }
    }
  }
  
  scan(dir);
  return files;
}

// 处理单个文件
function processFile(filePath, dryRun = false) {
  const content = fs.readFileSync(filePath, 'utf8');
  let modified = false;
  let newContent = content;
  const changes = [];

  // 处理每种URL模式
  for (const [key, rule] of Object.entries(URL_PATTERNS)) {
    const matches = content.match(rule.pattern);
    if (matches) {
      matches.forEach(match => {
        if (rule.replacement !== '') {
          newContent = newContent.replace(rule.pattern, rule.replacement);
        } else {
          // 对于空替换,需要特殊处理以避免误删
          newContent = newContent.replace(match, '/* REMOVED: ' + match + ' */');
        }
        changes.push({
          type: rule.description,
          original: match,
          replacement: rule.replacement || '/* REMOVED */'
        });
        modified = true;
      });
    }
  }

  if (modified && !dryRun) {
    // 备份原文件
    const backupPath = path.join(backupDir, path.relative(etsDir, filePath));
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

  console.log('🔍 开始扫描URL清理...\n');
  console.log(`模式: ${dryRun ? '✅ 预演模式 (不会修改文件)' : '⚠️  实际修改模式'}\n`);

  const files = findEtsFiles(etsDir);
  console.log(`📁 找到 ${files.length} 个 .ets 文件\n`);

  let totalFiles = 0;
  let totalChanges = 0;
  const fileChanges = [];

  for (const file of files) {
    const relativePath = path.relative(etsDir, file);
    const result = processFile(file, dryRun);

    if (result.modified) {
      totalFiles++;
      totalChanges += result.changes.length;
      
      if (verbose) {
        console.log(`📝 ${relativePath}`);
        result.changes.forEach(change => {
          console.log(`   └─ [${change.type}]`);
          console.log(`      原始: ${change.original}`);
          console.log(`      替换: ${change.replacement}\n`);
        });
      } else {
        fileChanges.push({
          file: relativePath,
          changes: result.changes
        });
      }
    }
  }

  if (!verbose && fileChanges.length > 0) {
    console.log(`\n📋 修改文件列表:\n`);
    fileChanges.forEach(item => {
      console.log(`📝 ${item.file} (${item.changes.length} 处修改)`);
      item.changes.forEach(change => {
        console.log(`   ├─ [${change.type}]`);
      });
    });
  }

  console.log(`\n${dryRun ? '📊 预演结果:' : '✅ 完成结果:'}`);
  console.log(`   修改文件: ${totalFiles}`);
  console.log(`   总计修改: ${totalChanges} 处`);
  
  if (dryRun && totalChanges > 0) {
    console.log(`\n💡 提示: 使用不带 --dry-run 参数执行实际修改`);
    console.log(`   备份文件将保存到: ${backupDir}`);
  } else if (totalChanges > 0) {
    console.log(`\n💾 备份已保存到: ${backupDir}`);
  } else {
    console.log(`\n✨ 没有发现需要清理的URL`);
  }
}

// 显示帮助信息
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
用法: node cleanup_demo_urls.js [选项]

选项:
  --dry-run, -n    预演模式,不实际修改文件 (默认: false)
  --verbose, -v   显示详细修改信息 (默认: false)
  --help, -h       显示此帮助信息

示例:
  node cleanup_demo_urls.js              # 实际修改
  node cleanup_demo_urls.js --dry-run     # 预演查看
  node cleanup_demo_urls.js -v            # 显示详细信息
  node cleanup_demo_urls.js -n -v         # 预演+详细信息
`);
  process.exit(0);
}

// 运行
main();
