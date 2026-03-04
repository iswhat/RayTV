const fs = require('fs');
const path = require('path');

const etsDir = 'd:/tv/RayTV/raytv/src/main/ets';

// 替换规则
const replacements = [
  {
    pattern: /https:\/\/api\.raytv\.example\.com/g,
    replacement: 'TODO_CONFIGURE_REAL_API',
    description: '测试API端点'
  },
  {
    pattern: /https?:\/\/via\.placeholder\.com\/[^\s'"`>]+/g,
    replacement: 'DEFAULT_IMAGE_PLACEHOLDER',
    description: '占位符图片'
  },
  {
    pattern: /https?:\/\/example\.com\/(episode\d+|test-movie|related\d+)/g,
    replacement: '',
    description: '测试视频URL'
  },
  {
    pattern: /https?:\/\/example\.com\/live\/[^\s'"`>]+/g,
    replacement: '',
    description: '测试直播流'
  }
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
        } else if (item.endsWith('.ets')) {
          files.push(fullPath);
        }
      }
    } catch (e) {
      console.log(`无法访问目录: ${directory}`);
    }
  }
  
  scan(dir);
  return files;
}

// 处理单个文件
function processFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    let newContent = content;
    let modified = false;
    
    for (const rule of replacements) {
      const matches = content.match(rule.pattern);
      if (matches) {
        newContent = newContent.replace(rule.pattern, rule.replacement);
        modified = true;
        console.log(`✓ ${path.relative(etsDir, filePath)} - ${rule.description} (${matches.length} 处)`);
      }
    }
    
    if (modified) {
      fs.writeFileSync(filePath, newContent);
      return true;
    }
    return false;
  } catch (e) {
    console.log(`✗ 处理文件失败: ${filePath} - ${e.message}`);
    return false;
  }
}

// 主函数
function main() {
  console.log('🔍 开始批量替换Demo URL...\n');
  
  const files = findEtsFiles(etsDir);
  console.log(`📁 找到 ${files.length} 个 .ets 文件\n`);
  
  let modifiedCount = 0;
  for (const file of files) {
    if (processFile(file)) {
      modifiedCount++;
    }
  }
  
  console.log(`\n✅ 完成! 共修改 ${modifiedCount} 个文件`);
}

main();
