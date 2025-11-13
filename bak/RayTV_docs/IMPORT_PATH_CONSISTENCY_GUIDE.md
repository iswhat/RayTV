# 导入路径一致性规范指南

## 概述

本文档定义了RayTV项目中导入路径的使用规范，确保代码库中所有相对路径导入的一致性和正确性。

## 问题发现与修复总结

在本次系统性检查中，发现了service目录中存在的导入路径错误：

### 问题描述
- **错误路径**: `../../data/repository/`
- **正确路径**: `../data/repository/`
- **影响范围**: service目录下的所有文件

### 修复文件列表
- `service/device/DeviceService.ets`
- `service/media/MediaService.ets`
- `service/AppService.ets`
- `service/config/ConfigService.ets`
- `service/playback/PlaybackService.ets`
- `service/live/LiveStreamService.ets`
- `service/media/MovieService.ets`
- `service/user/UserService.ets`
- `service/collection/CollectionService.ets`
- `service/ServiceFactory.ets`
- `service/search/SearchService.ets`
- `service/parser/ParserService.ets`
- `service/download/DownloadService.ets`

## 导入路径规范

### 1. 基本规则

#### 1.1 相对路径计算
- 始终从当前文件所在目录开始计算相对路径
- 使用正确的相对路径层级（`../` 表示上一级目录）

#### 1.2 路径验证
- 在编写导入语句前，验证目标文件的实际位置
- 使用IDE的路径自动补全功能

### 2. 目录结构映射

以下是项目中主要目录之间的正确相对路径映射：

#### 2.1 从 service/ 目录导入
```typescript
// 正确路径
import X from '../data/repository/X';  // 到 data/repository
import Y from '../../common/util/Y';  // 到 common/util
import Z from './subdir/Z';           // 到 service/subdir
```

#### 2.2 从 domain/usecase/ 目录导入
```typescript
// 正确路径
import X from '../../data/repository/X';  // 到 data/repository
import Y from '../../common/util/Y';      // 到 common/util
```

#### 2.3 从 data/repository/ 目录导入
```typescript
// 正确路径
import X from '../../common/util/X';      // 到 common/util
import Y from '../bean/Y';               // 到 data/bean
import Z from '../db/Z';                 // 到 data/db
```

#### 2.4 从 service/spider/loader/ 目录导入
```typescript
// 正确路径（三层相对路径）
import X from '../../../common/util/X';      // 到 common/util
import Y from '../../../task/pool/Y';        // 到 task/pool
```

### 3. 常见错误模式

#### 3.1 错误的路径层级
```typescript
// 错误示例（service目录中）
import X from '../../data/repository/X';  // 多了一层 ../

// 正确写法
import X from '../data/repository/X';
```

#### 3.2 路径方向错误
```typescript
// 错误示例
import X from './../../data/repository/X';  // 不必要的 ./ 前缀

// 正确写法
import X from '../data/repository/X';
```

### 4. 验证方法

#### 4.1 手动验证
1. 确定当前文件位置
2. 确定目标文件位置
3. 计算正确的相对路径

#### 4.2 工具验证
- 使用构建命令验证：`npm run build`
- 使用IDE的路径检查功能
- 运行代码检查工具

#### 4.3 自动化检查
建议在CI/CD流程中添加导入路径检查：
```bash
# 检查错误的导入路径模式
grep -r "import.*from.*\.\./\.\./data/repository" src/main/ets/service/
```

### 5. 最佳实践

#### 5.1 代码组织
- 保持目录结构的扁平化
- 避免过深的嵌套目录
- 相关文件尽量放在相邻目录中

#### 5.2 导入语句管理
- 按模块分组导入语句
- 外部依赖在前，内部模块在后
- 使用清晰的空行分隔不同类别的导入

#### 5.3 重构指导
当移动文件时：
1. 更新所有导入该文件的路径
2. 更新该文件中的所有导出路径
3. 运行构建验证

### 6. 示例代码

#### 6.1 service目录中的正确导入
```typescript
// service/media/MediaService.ets
import Logger from '../../common/util/Logger';
import ConfigService from '../config/ConfigService';
import VodRepository from '../data/repository/VodRepository';  // 正确路径
import LiveRepository from '../data/repository/LiveRepository'; // 正确路径
```

#### 6.2 domain/usecase目录中的正确导入
```typescript
// domain/usecase/PlayVodUseCase.ets
import Logger from '../../common/util/Logger';
import VodRepository from '../../data/repository/VodRepository';  // 正确路径
import HistoryRepository from '../../data/repository/HistoryRepository'; // 正确路径
```

### 7. 维护责任

- **开发人员**: 负责编写正确的导入路径
- **代码审查者**: 负责验证导入路径的正确性
- **架构师**: 负责设计合理的目录结构

## 总结

通过遵循本规范，可以确保：
1. 代码的可维护性
2. 构建的稳定性
3. 团队协作的效率
4. 代码质量的一致性

**最后验证**: 所有修复后的导入路径已通过构建验证，构建成功完成。

---

*文档版本: 1.0*  
*创建日期: 2024年*  
*维护者: 开发团队*