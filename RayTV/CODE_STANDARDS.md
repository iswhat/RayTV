# RayTV 项目代码规范

## 概述

本文档定义了RayTV项目的编码标准、最佳实践和代码质量要求，确保代码的一致性和可维护性。

## 文件组织规范

### 目录结构
```
src/main/ets/
├── ability/           # Ability相关代码
├── components/        # 自定义组件
├── model/            # 数据模型
├── pages/            # 页面组件
├── service/          # 服务层
│   ├── database/     # 数据库服务
│   ├── network/      # 网络服务
│   └── sync/         # 数据同步服务
├── utils/            # 工具类
└── MainAbility.ts    # 应用入口
```

### 文件命名
- **TypeScript文件**: 使用PascalCase，如`HttpService.ets`
- **组件文件**: 使用PascalCase，如`VideoPlayer.ets`
- **工具类文件**: 使用PascalCase，如`NetworkUtil.ets`

## 代码风格规范

### 缩进和格式
- 使用2个空格进行缩进
- 每行代码不超过120个字符
- 使用分号结束语句

### 命名约定

#### 变量和函数
- **变量**: camelCase，如`videoList`, `currentIndex`
- **常量**: UPPER_SNAKE_CASE，如`MAX_RETRY_COUNT`, `DEFAULT_TIMEOUT`
- **函数**: camelCase，如`fetchVideoData()`, `handlePlaybackError()`

#### 类和接口
- **类**: PascalCase，如`VideoPlayer`, `HttpService`
- **接口**: PascalCase，以`I`开头，如`IVideoItem`, `IPlaybackConfig`

### 导入规范
```typescript
// 系统模块导入
import http from '@ohos.net.http';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';

// 项目模块导入
import ConfigService from '../service/ConfigService';
import AdBlockManager from '../service/AdBlockManager';

// 类型导入
import type { VideoItem } from '../model/VideoModel';
```

## 类型系统规范

### 类型注解
- 所有函数参数和返回值必须明确类型
- 避免使用`any`类型，优先使用具体类型或泛型
- 使用接口定义复杂数据结构

**示例**:
```typescript
interface VideoItem {
  id: string;
  title: string;
  duration: number;
  thumbnail: string;
}

class VideoService {
  public async getVideoList(category: string): Promise<VideoItem[]> {
    // 实现逻辑
  }
}
```

### 空值处理
- 使用可选链操作符`?.`
- 使用空值合并操作符`??`
- 明确标注可为空的类型

## 异步编程规范

### Promise使用
- 优先使用`async/await`语法
- 正确处理Promise拒绝
- 使用`try/catch`处理异步错误

**示例**:
```typescript
class HttpService {
  public async request<T>(url: string, options?: RequestOptions): Promise<T> {
    try {
      const response = await http.request(url, options);
      return this.processResponse<T>(response);
    } catch (error) {
      console.error('HTTP request failed:', error);
      throw new Error(`Request failed: ${error.message}`);
    }
  }
}
```

### 错误处理
- 使用自定义错误类
- 提供有意义的错误信息
- 记录错误日志

## 服务类规范

### 上下文管理
所有服务类必须实现上下文管理：

```typescript
class BaseService {
  protected context: common.Context | null = null;

  public setContext(ctx: common.Context): void {
    this.context = ctx;
  }

  protected getContext(): common.Context {
    if (!this.context) {
      throw new Error('Context not initialized. Call setContext() first.');
    }
    return this.context;
  }
}
```

### 权限管理
需要权限的服务方法必须检查权限：

```typescript
class NetworkService extends BaseService {
  public async fetchData(url: string): Promise<any> {
    await this.checkNetworkPermission();
    // 执行网络请求
  }

  private async checkNetworkPermission(): Promise<void> {
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const context = this.getContext();
      
      await atManager.requestPermissionsFromUser(context, [
        'ohos.permission.INTERNET'
      ]);
    } catch (error) {
      console.error('Permission request failed:', error);
      throw error;
    }
  }
}
```

## 组件开发规范

### 组件结构
```typescript
@Component
struct VideoPlayer {
  @State currentTime: number = 0;
  @Prop videoUrl: string;
  @Link isPlaying: boolean;

  aboutToAppear(): void {
    // 初始化逻辑
  }

  build() {
    Column() {
      // 组件内容
    }
  }

  private handlePlaybackEnd(): void {
    // 事件处理
  }
}
```

### 状态管理
- 使用`@State`管理组件内部状态
- 使用`@Prop`接收父组件传递的数据
- 使用`@Link`实现双向数据绑定
- 避免在build方法中执行复杂逻辑

## 数据库操作规范

### 数据访问层
```typescript
class DatabaseService {
  private rdbStore: relationalStore.RdbStore | null = null;

  public async initialize(): Promise<void> {
    // 数据库初始化
  }

  public async query<T>(sql: string, params: any[] = []): Promise<T[]> {
    if (!this.rdbStore) {
      throw new Error('Database not initialized');
    }
    
    const resultSet = await this.rdbStore.query(sql, params);
    return this.processResultSet<T>(resultSet);
  }

  private processResultSet<T>(resultSet: relationalStore.ResultSet): T[] {
    // 结果集处理逻辑
  }
}
```

## 网络请求规范

### 请求封装
```typescript
class ApiService {
  private readonly baseUrl: string = 'https://api.example.com';
  private readonly timeout: number = 10000;

  public async get<T>(endpoint: string): Promise<T> {
    return this.request<T>('GET', endpoint);
  }

  public async post<T>(endpoint: string, data: any): Promise<T> {
    return this.request<T>('POST', endpoint, data);
  }

  private async request<T>(method: string, endpoint: string, data?: any): Promise<T> {
    const url = `${this.baseUrl}${endpoint}`;
    const options: http.HttpRequestOptions = {
      method: method,
      readTimeout: this.timeout,
      connectTimeout: this.timeout
    };

    if (data) {
      options.extraData = JSON.stringify(data);
    }

    return await http.request(url, options);
  }
}
```

## 日志和调试规范

### 日志级别
- 使用`console.log`记录一般信息
- 使用`console.warn`记录警告信息
- 使用`console.error`记录错误信息

### 调试信息
```typescript
class DebugUtil {
  private static readonly DEBUG_MODE: boolean = true;

  public static log(message: string, ...args: any[]): void {
    if (this.DEBUG_MODE) {
      console.log(`[DEBUG] ${message}`, ...args);
    }
  }

  public static error(message: string, error?: Error): void {
    console.error(`[ERROR] ${message}`, error);
  }
}
```

## 性能优化规范

### 内存管理
- 及时释放不再使用的资源
- 避免内存泄漏
- 使用弱引用处理循环引用

### 渲染优化
- 避免不必要的重新渲染
- 使用`@Reusable`装饰器优化组件复用
- 合理使用`@State`和`@Prop`

## 测试规范

### 单元测试
- 为所有公共方法编写单元测试
- 测试覆盖率不低于80%
- 使用Mock对象隔离依赖

### 集成测试
- 测试组件间的交互
- 测试服务集成
- 验证端到端功能

## 代码审查清单

### 提交前检查
- [ ] 代码符合命名规范
- [ ] 类型注解完整
- [ ] 错误处理完善
- [ ] 异步操作正确处理
- [ ] 权限检查完备
- [ ] 日志记录适当
- [ ] 性能考虑充分

### 审查要点
- 代码可读性
- 功能完整性
- 错误处理健壮性
- 性能影响评估
- 安全性考虑

## 版本控制规范

### 提交信息格式
```
类型(范围): 描述

详细说明（可选）

关联Issue: #123
```

**类型**: feat, fix, docs, style, refactor, test, chore

**示例**:
```
feat(video): 添加视频播放进度保存功能

- 实现播放进度自动保存
- 添加进度恢复功能
- 优化用户体验

关联Issue: #45
```

---

*文档版本: 1.0*  
*最后更新: 2024年*  
*维护者: RayTV开发团队*