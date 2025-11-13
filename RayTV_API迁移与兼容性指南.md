# RayTV API迁移与兼容性指南

## 1. HarmonyOS API迁移概述

### 1.1 迁移背景
本项目从Android平台迁移到HarmonyOS平台，需要将Android API替换为HarmonyOS原生API。迁移过程遵循"功能参考而非代码参考"原则，Android版Fongmi仅作为需求实现的逻辑参考，不作为代码实现的参考。

### 1.2 迁移目标
- 实现Android功能的1:1复刻，但基于HarmonyOS原生API重新实现
- 充分利用HarmonyOS系统特性，提升应用性能和用户体验
- 确保应用在HarmonyOS 5和HarmonyOS 6平台上的兼容性

## 2. 核心API迁移映射

### 2.1 基础框架迁移

| Android API | HarmonyOS API | 说明 |
|-------------|---------------|------|
| Application | App.ets | 应用入口点，继承自Application类 |
| Activity | Ability | 应用能力，处理UI初始化和窗口管理 |
| Fragment | Page | 页面组件，实现界面展示 |
| Context | AbilityContext | 上下文环境，提供系统服务访问 |

### 2.2 数据存储迁移

| Android API | HarmonyOS API | 说明 |
|-------------|---------------|------|
| Room | RelationalStore | 关系型数据库，支持SQLite操作 |
| SharedPreferences | Preferences | 轻量级数据存储，支持键值对 |
| File | File | 文件操作，支持本地文件读写 |
| ContentProvider | DataAbility | 数据共享能力，支持跨应用数据访问 |

### 2.3 网络请求迁移

| Android API | HarmonyOS API | 说明 |
|-------------|---------------|------|
| OkHttp | @ohos.net.http | 高级网络请求库，支持HTTP/HTTPS |
| Retrofit | Fetch API | RESTful API调用，支持异步请求 |
| Gson | JSON API | JSON数据解析，支持序列化/反序列化 |

### 2.4 多媒体迁移

| Android API | HarmonyOS API | 说明 |
|-------------|---------------|------|
| ExoPlayer | AVPlayer | 媒体播放器，支持音视频播放 |
| MediaPlayer | MediaPlayer | 基础媒体播放，支持音频播放 |
| SurfaceView | XComponent | 视频渲染组件，支持硬件加速 |
| TextureView | XComponent | 纹理视图，支持视频渲染 |

## 3. 技术栈迁移检查清单

### 3.1 开发语言迁移
- [ ] 将Java代码迁移为ArkTS代码
- [ ] 确保类型系统符合ArkTS规范
- [ ] 移除any和unknown类型的使用
- [ ] 实现静态类型检查

### 3.2 UI框架迁移
- [ ] 将XML布局迁移为ArkUI声明式UI
- [ ] 实现响应式数据绑定
- [ ] 适配多设备屏幕尺寸
- [ ] 优化动画和过渡效果

### 3.3 数据库迁移
- [ ] 设计RelationalStore数据库结构
- [ ] 实现数据迁移脚本
- [ ] 测试数据库操作性能
- [ ] 验证分布式数据同步

### 3.4 网络层迁移
- [ ] 实现@ohos.net.http网络请求
- [ ] 配置网络安全策略
- [ ] 优化网络缓存机制
- [ ] 测试网络异常处理

## 4. 已修复的迁移问题

### 4.1 类型系统问题
- **问题**：使用any和unknown类型导致编译错误
- **解决方案**：使用具体的基础类型（boolean、number、string）或自定义类/接口
- **示例**：将`any`类型替换为具体的对象类型或联合类型

### 4.2 类实例化问题
- **问题**：类被当作对象使用，出现"Classes cannot be used as objects"警告
- **解决方案**：使用局部变量避免直接类名引用
- **示例**：
```typescript
// 错误用法
ParserService.instance = new ParserService();

// 正确用法
const instance = new ParserService();
ParserService.instance = instance;
```

### 4.3 装饰器使用问题
- **问题**：@State装饰器变量未初始化或类型不一致
- **解决方案**：确保装饰器变量正确初始化，类型与初始化值一致
- **示例**：
```typescript
// 错误用法
@State private user: User;

// 正确用法
@State private user: User = new User();
```

### 4.4 权限配置问题
- **问题**：权限配置格式不符合HarmonyOS规范
- **解决方案**：使用正确的权限声明格式，包含usedScene字段
- **示例**：
```json
{
  "name": "ohos.permission.DISTRIBUTED_DATASYNC",
  "reason": "$string:distributed_data_sync_reason",
  "usedScene": {
    "abilities": ["RaytvAbility"],
    "when": "inuse"
  }
}
```

## 5. 配置文件格式规范

### 5.1 JSON/JSON5格式要求
- 所有配置文件必须严格遵守JSON/JSON5语法规范
- 确保格式正确，避免语法错误
- 使用合适的缩进和格式，提高可读性

### 5.2 字符串资源引用规范
- 配置文件中的文本内容必须使用字符串资源引用格式（`$string:resource_name`）
- 权限配置中的reason字段必须引用字符串资源
- 确保资源引用名称与资源文件中的定义名称完全匹配

### 5.3 权限配置规范

#### 5.3.1 requestPermissions配置
- 所有user_grant类型的权限必须添加usedScene字段
- usedScene.abilities字段必须明确指定使用该权限的Ability名称
- usedScene.when字段必须设置为"inuse"

#### 5.3.2 definePermissions配置
- 对于非SDK预定义的自定义权限，必须在module.json5的definePermissions部分进行明确定义
- 必须包含name、grantMode、availableLevel、label和description字段
- grantMode根据权限性质设置为"user_grant"或"system_grant"
- availableLevel必须是"system_core"、"system_basic"或"normal"之一

### 5.4 资源引用完整性检查

#### 5.4.1 定义完整性要求
- 所有配置文件中的资源引用（`$string:`、`$media:`、`$color:`等）必须在对应的资源文件中正确定义
- 资源引用名称必须与资源文件中的定义名称完全匹配，包括大小写

#### 5.4.2 权限字符串完整性
- definePermissions中的label和description引用必须在string.json中定义对应的字符串资源
- 应用级资源引用必须在AppScope/app.json5中定义
- 模块级资源引用必须在raytv/src/main/resources/base/element/string.json中定义

#### 5.4.3 构建前验证
- 在构建前必须验证所有资源引用的完整性
- 构建失败时优先检查资源引用是否正确定义
- 特别是权限相关的字符串资源必须完整定义

## 6. 兼容性测试策略

### 6.1 多设备兼容性测试
- **测试设备类型**：直板手机、折叠屏手机、三折叠屏手机、阔折叠屏手机、平板、电视
- **测试重点**：UI适配、交互方式、性能表现
- **测试工具**：DevEco Studio模拟器、真机测试

### 6.2 系统版本兼容性测试
- **测试版本**：HarmonyOS 5.1.1(19)、HarmonyOS 6.0.0(20)
- **测试重点**：API兼容性、功能完整性、性能稳定性
- **测试方法**：版本间功能对比、性能基准测试

### 6.3 功能兼容性测试
- **核心功能**：视频播放、配置加载、爬虫执行、数据存储
- **鸿蒙特有功能**：语音助手、设备流转、手势操作
- **测试标准**：功能完整性、性能指标、用户体验

## 7. 迁移最佳实践

### 7.1 渐进式迁移策略
- 采用模块化迁移方式，逐个模块进行迁移
- 保持Android版本和HarmonyOS版本的并行开发
- 建立迁移验证机制，确保功能一致性

### 7.2 代码重构原则
- 遵循单一职责原则，拆分复杂功能模块
- 使用依赖注入，降低模块间耦合度
- 实现接口隔离，提高代码可维护性

### 7.3 性能优化建议
- 利用HarmonyOS的并发处理能力，优化任务调度
- 使用内存管理API，优化大内存使用场景
- 实现智能预加载策略，提升用户体验

### 7.4 安全开发规范
- 实现应用沙箱管理，确保代码执行安全
- 开发权限控制和验证机制，保护用户数据
- 添加网络访问安全监控，防止安全威胁

## 8. 常见问题与解决方案

### 8.1 编译错误处理
- **问题类型**：类型错误、语法错误、资源引用错误
- **排查方法**：检查错误信息、验证代码规范、测试资源完整性
- **解决方案**：修正代码规范、完善资源定义、更新配置格式

### 8.2 运行时异常处理
- **问题类型**：空指针异常、类型转换异常、权限异常
- **排查方法**：日志分析、调试跟踪、异常捕获
- **解决方案**：添加空值检查、类型保护、权限验证

### 8.3 性能问题优化
- **问题类型**：内存泄漏、CPU占用过高、响应延迟
- **排查方法**：性能分析、内存监控、代码审查
- **解决方案**：优化资源管理、改进算法、使用缓存机制

## 9. 迁移验收标准

### 9.1 功能完整性
- [ ] 所有Android版本功能在HarmonyOS版本中完整实现
- [ ] 鸿蒙特有功能正常集成和运行
- [ ] 多设备适配效果符合设计要求

### 9.2 性能指标
- [ ] 应用启动时间符合性能要求
- [ ] 视频播放流畅，无卡顿现象
- [ ] 内存使用合理，无内存泄漏

### 9.3 兼容性验证
- [ ] 在目标系统版本上正常运行
- [ ] 在不同设备类型上适配良好
- [ ] 功能在不同场景下稳定可靠

### 9.4 用户体验
- [ ] 界面交互流畅自然
- [ ] 功能操作符合用户习惯
- [ ] 错误提示清晰明确