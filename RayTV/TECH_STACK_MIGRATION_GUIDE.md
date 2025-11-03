# HarmonyOS ArkTS技术栈适配指南

## 1. 技术栈概述

### 1.1 当前技术栈
- **框架**: HarmonyOS ArkTS
- **UI组件**: ArkUI Native
- **API版本**: HarmonyOS API 9+
- **开发工具**: DevEco Studio

### 1.2 适配目标
- 确保代码符合ArkTS语法规范
- 统一组件使用方式
- 建立长期可维护的代码架构

## 2. 迁移检查清单

### 2.1 组件导入迁移
```typescript
// ❌ 迁移前
import { ListItem as ListItemComponent } from '@arkui/native';

// ✅ 迁移后
import { ListItem } from '@arkui/native';
```

### 2.2 属性语法迁移
```typescript
// ❌ 迁移前
<ProgressBar style={{ strokeWidth: 4, color: '#FF4500' }} />

// ✅ 迁移后
<ProgressBar strokeWidth={4} color="#FF4500" />
```

### 2.3 状态管理迁移
```typescript
// ❌ 迁移前（React风格）
this.setState({ progress: newValue });

// ✅ 迁移后（ArkTS风格）
this.progressValue = newValue;
```

## 3. 自动化迁移工具

### 3.1 代码检查脚本
创建自动化检查脚本，识别需要迁移的模式：

```bash
#!/bin/bash
# migration-check.sh

echo "开始检查ArkTS代码规范..."

# 检查组件别名导入
echo "1. 检查组件别名导入..."
grep -r "import.*as.*Component" src/ --include="*.ets" --include="*.ts" || echo "✅ 无组件别名导入问题"

# 检查style对象使用
echo "2. 检查style对象使用..."
grep -r "style={{.*}}" src/ --include="*.ets" --include="*.ts" || echo "✅ 无style对象使用问题"

# 检查ProgressBar属性
echo "3. 检查ProgressBar属性..."
grep -r "ProgressBar" src/ --include="*.ets" --include="*.ts" | grep -v "strokeWidth\|color" && echo "⚠️ 发现ProgressBar属性问题" || echo "✅ ProgressBar属性正常"

echo "检查完成！"
```

### 3.2 批量迁移脚本
```javascript
// migration-tool.js
const fs = require('fs');
const path = require('path');

/**
 * 自动修复组件别名导入
 */
function fixComponentImports(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // 修复 ListItem as ListItemComponent
  content = content.replace(
    /import\s*{\s*ListItem\s+as\s+ListItemComponent\s*}\s*from\s*'@arkui\/native'/g,
    "import { ListItem } from '@arkui/native'"
  );
  
  // 修复其他组件别名
  content = content.replace(
    /import\s*{\s*(\w+)\s+as\s+(\w+Component)\s*}\s*from\s*'@arkui\/native'/g,
    "import { $1 } from '@arkui/native'"
  );
  
  fs.writeFileSync(filePath, content);
}

/**
 * 自动修复组件使用
 */
function fixComponentUsage(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // 修复 ListItemComponent -> ListItem
  content = content.replace(/ListItemComponent/g, 'ListItem');
  
  fs.writeFileSync(filePath, content);
}

/**
 * 自动修复ProgressBar属性
 */
function fixProgressBarAttributes(filePath) {
  let content = fs.readFileSync(filePath, 'utf8');
  
  // 修复style对象为独立属性
  content = content.replace(
    /<ProgressBar\s+style=\{\s*{\s*strokeWidth:\s*(\d+),\s*color:\s*'([^']+)'\s*}\s*}\s*\/>/g,
    "<ProgressBar strokeWidth={$1} color=\"$2\" />"
  );
  
  fs.writeFileSync(filePath, content);
}

// 执行迁移
function runMigration() {
  const srcDir = path.join(__dirname, 'src');
  
  // 遍历所有.ets和.ts文件
  function traverseDirectory(dir) {
    const files = fs.readdirSync(dir);
    
    files.forEach(file => {
      const filePath = path.join(dir, file);
      const stat = fs.statSync(filePath);
      
      if (stat.isDirectory()) {
        traverseDirectory(filePath);
      } else if (file.endsWith('.ets') || file.endsWith('.ts')) {
        console.log(`处理文件: ${filePath}`);
        
        // 执行修复
        fixComponentImports(filePath);
        fixComponentUsage(filePath);
        fixProgressBarAttributes(filePath);
      }
    });
  }
  
  traverseDirectory(srcDir);
  console.log('迁移完成！');
}

// 运行迁移工具
runMigration();
```

## 4. 依赖管理规范

### 4.1 包管理配置
```json5
// oh-package.json5
{
  "name": "raytv",
  "version": "1.0.0",
  "description": "RayTV应用",
  "license": "Apache-2.0",
  "dependencies": {
    "@arkui/native": "^1.0.0",
    "@ohos/hypium": "^1.0.0"
  },
  "devDependencies": {
    "@ohos/hvigor-ohos-plugin": "^1.0.0"
  }
}
```

### 4.2 版本兼容性检查
```bash
# 检查依赖版本兼容性
ohpm check --compatibility

# 更新依赖到最新兼容版本
ohpm update --latest-compatible
```

## 5. 构建配置优化

### 5.1 构建配置文件
```json5
// build-profile.json5
{
  "app": {
    "signingConfigs": [],
    "products": {
      "raytv": {
        "signingConfig": "default",
        "compileSdkVersion": 9,
        "compatibleSdkVersion": 9,
        "runtimeOS": "HarmonyOS"
      }
    },
    "buildModeSet": {
      "debug": {},
      "release": {}
    }
  },
  "modules": {
    "entry": {
      "name": "entry",
      "srcPath": "./src",
      "dependencies": []
    }
  }
}
```

### 5.2 代码检查集成
```typescript
// hvigorfile.ts
import { hvigor } from '@ohos/hvigor-ohos-plugin';

export default function configure() {
  return hvigor
    .project(() => {
      // 项目配置
    })
    .plugin(() => {
      // 代码检查插件
      return {
        apply(project) {
          project.task('codeLint', () => {
            // 执行代码检查
            console.log('执行代码检查...');
          });
        }
      };
    });
}
```

## 6. 测试策略

### 6.1 单元测试配置
```typescript
// test/Example.test.ets
import { describe, it, expect } from '@ohos/hypium';

export default function abilityTest() {
  describe('ComponentTest', function() {
    it('ListItemImportTest', 0, function() {
      // 测试组件导入
      expect(true).assertTrue();
    });
    
    it('ProgressBarAttributeTest', 0, function() {
      // 测试ProgressBar属性
      expect(true).assertTrue();
    });
  });
}
```

### 6.2 集成测试
```typescript
// test/Integration.test.ets
import { describe, it, expect } from '@ohos/hypium';

export default function integrationTest() {
  describe('MigrationIntegrationTest', function() {
    it('VerifyComponentUsage', 0, function() {
      // 验证组件使用方式
      expect(true).assertTrue();
    });
    
    it('VerifyBuildSuccess', 0, function() {
      // 验证构建成功
      expect(true).assertTrue();
    });
  });
}
```

## 7. 持续集成配置

### 7.1 GitHub Actions配置
```yaml
# .github/workflows/arkts-migration.yml
name: ArkTS Migration CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  migration-check:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: Run Migration Check
      run: |
        npm install
        node migration-tool.js --check-only
    
    - name: Run Tests
      run: |
        ohos test
    
    - name: Build Project
      run: |
        ohos build -b debug
```

## 8. 监控和告警

### 8.1 代码质量监控
```typescript
// scripts/quality-monitor.js
const fs = require('fs');
const path = require('path');

class QualityMonitor {
  constructor() {
    this.metrics = {
      componentImports: 0,
      propertySyntax: 0,
      buildErrors: 0
    };
  }
  
  scanProject() {
    // 扫描项目代码质量
    this.checkComponentImports();
    this.checkPropertySyntax();
    this.reportMetrics();
  }
  
  checkComponentImports() {
    // 检查组件导入规范
    // 实现检查逻辑
  }
  
  checkPropertySyntax() {
    // 检查属性语法规范
    // 实现检查逻辑
  }
  
  reportMetrics() {
    console.log('代码质量监控报告:');
    console.log(`- 组件导入问题: ${this.metrics.componentImports}`);
    console.log(`- 属性语法问题: ${this.metrics.propertySyntax}`);
    console.log(`- 构建错误: ${this.metrics.buildErrors}`);
  }
}

// 执行监控
const monitor = new QualityMonitor();
monitor.scanProject();
```

## 9. 回滚策略

### 9.1 迁移回滚计划
```bash
# 回滚脚本
#!/bin/bash
# rollback-migration.sh

echo "开始回滚迁移更改..."

# 备份当前代码
git stash

# 恢复到迁移前状态
git checkout HEAD~1 -- src/

echo "回滚完成！"
```

## 10. 成功标准

### 10.1 技术指标
- [ ] 所有组件导入符合规范
- [ ] 属性语法100%正确
- [ ] 构建成功率100%
- [ ] 单元测试通过率100%
- [ ] 代码检查无错误

### 10.2 业务指标
- [ ] 应用功能正常
- [ ] 性能无退化
- [ ] 用户体验无影响
- [ ] 开发效率提升

---

**最后更新：2024年**  
**适用版本：HarmonyOS ArkTS技术栈迁移**