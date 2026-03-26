# RayTV API 文档

## 1. 概述

本API文档详细描述了RayTV应用的公共接口和类，包括核心服务、工具类和数据模型。文档按照功能模块组织，提供了每个接口的参数、返回值和使用示例，旨在帮助开发者理解和使用RayTV的API。

## 2. 核心服务

### 2.1 ConfigService

**服务描述**：配置服务，负责管理应用的各种设置参数，包括安全存储敏感信息。

**公共接口**：

#### getInstance()

```typescript
public static getInstance(): ConfigService
```

**描述**：获取ConfigService的单例实例。

**返回值**：ConfigService实例。

#### getFullConfig()

```typescript
public async getFullConfig(): Promise<Config>
```

**描述**：获取完整的应用配置。

**返回值**：Config对象，包含所有配置项。

#### updateFullConfig(customConfig)

```typescript
public async updateFullConfig(customConfig: Partial<Config>): Promise<ApiResponse<Config>>
```

**描述**：更新完整的应用配置。

**参数**：
- customConfig: 要更新的配置部分。

**返回值**：ApiResponse<Config>，包含更新后的配置。

#### getPartialConfig(key)

```typescript
public async getPartialConfig(key: keyof Config): Promise<PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig>
```

**描述**：获取部分配置。

**参数**：
- key: 配置部分的键。

**返回值**：对应配置部分的对象。

#### updatePartialConfig(key, sectionConfig)

```typescript
public async updatePartialConfig(key: keyof Config, sectionConfig: ConfigUpdate): Promise<ApiResponse<PlayerConfig | DisplayConfig | NetworkConfig | StorageConfig | GeneralConfig | SecurityConfig | NotificationConfig | AccessibilityConfig | LiveConfig | VodConfig>>
```

**描述**：更新部分配置。

**参数**：
- key: 配置部分的键。
- sectionConfig: 要更新的配置内容。

**返回值**：ApiResponse<ConfigSection>，包含更新后的配置部分。

#### getSecureConfig(key)

```typescript
public async getSecureConfig(key: string): Promise<string | null>
```

**描述**：从安全存储中获取配置。

**参数**：
- key: 配置键。

**返回值**：配置值，如果不存在则返回null。

#### setSecureConfig(key, value)

```typescript
public async setSecureConfig(key: string, value: string): Promise<boolean>
```

**描述**：将配置保存到安全存储。

**参数**：
- key: 配置键。
- value: 配置值。

**返回值**：是否保存成功。

#### removeSecureConfig(key)

```typescript
public async removeSecureConfig(key: string): Promise<boolean>
```

**描述**：从安全存储中移除配置。

**参数**：
- key: 配置键。

**返回值**：是否移除成功。

#### clearAllSecureConfig()

```typescript
public async clearAllSecureConfig(): Promise<boolean>
```

**描述**：清除所有安全存储的配置。

**返回值**：是否清除成功。

### 2.2 HttpService

**服务描述**：网络服务，负责处理网络请求，提供安全的HTTP通信。

**公共接口**：

#### getInstance()

```typescript
public static getInstance(): HttpService
```

**描述**：获取HttpService的单例实例。

**返回值**：HttpService实例。

#### setContext(ctx)

```typescript
public setContext(ctx: common.Context): void
```

**描述**：设置应用上下文。

**参数**：
- ctx: 应用上下文。

#### initialize()

```typescript
public async initialize(): Promise<void>
```

**描述**：初始化HTTP服务。

#### get(url, options)

```typescript
public async get<T>(url: string, options?: HttpOptions): Promise<HttpResponse<T>>
```

**描述**：发送GET请求。

**参数**：
- url: 请求URL。
- options: 请求选项。

**返回值**：HttpResponse<T>，包含响应数据。

#### post(url, data, options)

```typescript
public async post<T>(url: string, data?: Record<string, string | number | boolean | null> | string, options?: HttpOptions): Promise<HttpResponse<T>>
```

**描述**：发送POST请求。

**参数**：
- url: 请求URL。
- data: 请求数据。
- options: 请求选项。

**返回值**：HttpResponse<T>，包含响应数据。

#### request(url, options)

```typescript
public async request<T>(url: string, options: HttpRequestOptions): Promise<HttpResponse<T>>
```

**描述**：发送网络请求。

**参数**：
- url: 请求URL。
- options: 请求选项。

**返回值**：HttpResponse<T>，包含响应数据。

#### mergeRequest(url, options)

```typescript
public async mergeRequest<T>(url: string, options?: HttpRequestOptions): Promise<HttpResponse<T>>
```

**描述**：合并请求，避免短时间内发送相同的请求。

**参数**：
- url: 请求URL。
- options: 请求选项。

**返回值**：HttpResponse<T>，包含响应数据。

#### batchRequests(requests)

```typescript
public async batchRequests(requests: Array<{ url: string, options?: HttpRequestOptions }>): Promise<Array<HttpResponse<any>>>
```

**描述**：批量执行请求，提高网络请求效率。

**参数**：
- requests: 请求列表。

**返回值**：HttpResponse<any>数组，包含所有请求的响应数据。

#### getConcurrentRequestCount()

```typescript
public getConcurrentRequestCount(): number
```

**描述**：获取当前并发请求数。

**返回值**：当前并发请求数。

#### cleanExpiredRequestCache()

```typescript
public cleanExpiredRequestCache(): void
```

**描述**：清理过期的请求缓存。

### 2.3 MediaService

**服务描述**：媒体服务，负责管理媒体资源，包括播放历史、收藏和推荐内容。

**公共接口**：

#### getInstance()

```typescript
public static getInstance(): MediaService
```

**描述**：获取MediaService的单例实例。

**返回值**：MediaService实例。

#### updatePlaybackRecord(record)

```typescript
public async updatePlaybackRecord(record: PlaybackRecord): Promise<boolean>
```

**描述**：更新播放记录。

**参数**：
- record: 播放记录。

**返回值**：是否更新成功。

#### getPlaybackHistory()

```typescript
public async getPlaybackHistory(): Promise<PlaybackRecord[]>
```

**描述**：获取播放历史。

**返回值**：播放记录数组。

#### clearPlaybackHistory()

```typescript
public async clearPlaybackHistory(): Promise<boolean>
```

**描述**：清除播放历史。

**返回值**：是否清除成功。

#### addFavorite(media)

```typescript
public async addFavorite(media: MediaInfo): Promise<boolean>
```

**描述**：添加收藏。

**参数**：
- media: 媒体信息。

**返回值**：是否添加成功。

#### getFavorites()

```typescript
public async getFavorites(): Promise<MediaInfo[]>
```

**描述**：获取收藏列表。

**返回值**：媒体信息数组。

#### removeFavorite(mediaId)

```typescript
public async removeFavorite(mediaId: string): Promise<boolean>
```

**描述**：移除收藏。

**参数**：
- mediaId: 媒体ID。

**返回值**：是否移除成功。

#### getRecommendedContent(limit)

```typescript
public async getRecommendedContent(limit: number): Promise<RecommendedContent[]>
```

**描述**：获取推荐内容。

**参数**：
- limit: 返回数量限制。

**返回值**：推荐内容数组。

#### getPopularContent(limit)

```typescript
public async getPopularContent(limit: number): Promise<MediaInfo[]>
```

**描述**：获取热门内容。

**参数**：
- limit: 返回数量限制。

**返回值**：媒体信息数组。

#### getNewContent(limit)

```typescript
public async getNewContent(limit: number): Promise<MediaInfo[]>
```

**描述**：获取最新内容。

**参数**：
- limit: 返回数量限制。

**返回值**：媒体信息数组。

## 3. 工具类

### 3.1 StorageUtil

**类描述**：存储工具类，提供统一的存储管理功能，包括加密存储敏感信息。

**公共接口**：

#### initialize(context)

```typescript
public static async initialize(context: common.Context): Promise<boolean>
```

**描述**：初始化存储服务。

**参数**：
- context: 应用上下文。

**返回值**：是否初始化成功。

#### putString(key, value)

```typescript
public static async putString(key: string, value: string): Promise<void>
```

**描述**：存储字符串值。

**参数**：
- key: 键。
- value: 值。

#### getString(key, defaultValue)

```typescript
public static async getString(key: string, defaultValue: string = '', storageType: StorageType = StorageType.PREFERENCES): Promise<string>
```

**描述**：获取字符串值。

**参数**：
- key: 键。
- defaultValue: 默认值。
- storageType: 存储类型。

**返回值**：存储的字符串值。

#### putNumber(key, value)

```typescript
public static async putNumber(key: string, value: number): Promise<void>
```

**描述**：存储数值。

**参数**：
- key: 键。
- value: 值。

#### getNumber(key, defaultValue)

```typescript
public static async getNumber(key: string, defaultValue: number = 0): Promise<number>
```

**描述**：获取数值。

**参数**：
- key: 键。
- defaultValue: 默认值。

**返回值**：存储的数值。

#### putBoolean(key, value)

```typescript
public static async putBoolean(key: string, value: boolean): Promise<void>
```

**描述**：存储布尔值。

**参数**：
- key: 键。
- value: 值。

#### getBoolean(key, defaultValue)

```typescript
public static async getBoolean(key: string, defaultValue: boolean = false): Promise<boolean>
```

**描述**：获取布尔值。

**参数**：
- key: 键。
- defaultValue: 默认值。

**返回值**：存储的布尔值。

#### set(key, value)

```typescript
public static async set(key: string, value: string | number | boolean): Promise<void>
```

**描述**：自动类型检测存储值。

**参数**：
- key: 键。
- value: 值。

#### remove(key)

```typescript
public static async remove(key: string): Promise<void>
```

**描述**：移除存储项。

**参数**：
- key: 键。

#### contains(key)

```typescript
public static async contains(key: string): Promise<boolean>
```

**描述**：检查存储项是否存在。

**参数**：
- key: 键。

**返回值**：是否存在。

#### clear()

```typescript
public static async clear(): Promise<void>
```

**描述**：清除所有存储项。

### 3.2 URLValidator

**类描述**：URL安全验证工具，防止开放重定向和SSRF攻击。

**公共接口**：

#### validateURL(url)

```typescript
public static validateURL(url: string): void
```

**描述**：验证URL是否安全。

**参数**：
- url: 要验证的URL。

**异常**：如果URL不安全，抛出Error。

#### isAbsoluteURL(url)

```typescript
public static isAbsoluteURL(url: string): boolean
```

**描述**：验证URL是否是绝对URL。

**参数**：
- url: URL字符串。

**返回值**：是否是绝对URL。

#### normalizeURL(url)

```typescript
public static normalizeURL(url: string): string
```

**描述**：规范化URL。

**参数**：
- url: URL字符串。

**返回值**：规范化后的URL。

#### getDomain(url)

```typescript
public static getDomain(url: string): string
```

**描述**：从URL中提取域名。

**参数**：
- url: URL字符串。

**返回值**：域名。

## 4. 数据模型

### 4.1 Config

**描述**：完整的应用配置接口。

**属性**：
- player: PlayerConfig，播放器配置。
- display: DisplayConfig，显示配置。
- network: NetworkConfig，网络配置。
- storage: StorageConfig，存储配置。
- general: GeneralConfig，通用配置。
- security: SecurityConfig，安全配置。
- notification: NotificationConfig，通知配置。
- accessibility: AccessibilityConfig，无障碍配置。
- live: LiveConfig，直播配置。
- vod: VodConfig，VOD配置。

### 4.2 PlayerConfig

**描述**：播放器配置接口。

**属性**：
- defaultPlayer: string，默认播放器。
- autoPlay: boolean，自动播放。
- rememberPosition: boolean，记住播放位置。
- maxBufferSize: number，最大缓冲区大小。
- minBufferSize: number，最小缓冲区大小。
- preloadSeconds: number，预加载秒数。
- enableHardwareDecoding: boolean，启用硬件解码。
- enableHDR: boolean，启用HDR。
- subtitleSize: number，字幕大小。
- subtitleColor: string，字幕颜色。
- subtitleBackgroundColor: string，字幕背景颜色。
- audioTrack: string，音轨。
- videoTrack: string，视频轨。

### 4.3 MediaInfo

**描述**：媒体信息接口。

**属性**：
- id: string，媒体ID。
- title: string，标题。
- type: string，类型。
- coverUrl: string，封面URL。
- rating: number，评分。
- year: number，年份。
- duration: number，时长。
- description: string，描述。
- genre: string[]， genre。
- cast: string[]，演员。
- director: string[]，导演。
- releaseDate: string，发布日期。
- url: string，播放URL。

### 4.4 PlaybackRecord

**描述**：播放记录接口。

**属性**：
- mediaId: string，媒体ID。
- title: string，标题。
- type: string，类型。
- duration: number，时长。
- currentPosition: number，当前位置。
- lastWatchedAt: number，最后观看时间。
- isFinished: boolean，是否完成。

### 4.5 ApiResponse

**描述**：API响应接口。

**属性**：
- code: number，响应代码。
- message: string，响应消息。
- data: T，响应数据。

**方法**：
- isSuccess(): boolean，是否成功。
- isError(): boolean，是否错误。

## 5. 枚举类型

### 5.1 StorageType

**描述**：存储类型枚举。

**值**：
- PREFERENCES: 'preferences'，偏好设置存储。
- TEMPORARY: 'temporary'，临时存储。
- PERMANENT: 'permanent'，永久存储。

## 6. 错误处理

### 6.1 异常类型

- **Error**: 通用错误。
- **ConfigError**: 配置相关错误。
- **NetworkError**: 网络相关错误。
- **MediaError**: 媒体相关错误。

### 6.2 错误处理最佳实践

1. 使用try-catch捕获异常。
2. 记录错误日志。
3. 向用户显示友好的错误信息。
4. 对于网络错误，实现重试机制。
5. 对于配置错误，提供默认值。

## 7. 使用示例

### 7.1 配置服务示例

```typescript
// 获取配置服务实例
const configService = ConfigService.getInstance();

// 获取完整配置
const fullConfig = await configService.getFullConfig();
console.log('播放器配置:', fullConfig.player);

// 更新配置
const updateResult = await configService.updateFullConfig({
  player: {
    autoPlay: true
  }
});

if (updateResult.isSuccess()) {
  console.log('配置更新成功:', updateResult.data);
} else {
  console.error('配置更新失败:', updateResult.message);
}

// 安全存储敏感信息
await configService.setSecureConfig('apiKey', 'your-api-key');

// 获取安全存储的信息
const apiKey = await configService.getSecureConfig('apiKey');
console.log('API Key:', apiKey);
```

### 7.2 网络服务示例

```typescript
// 获取网络服务实例
const httpService = HttpService.getInstance();

// 发送GET请求
const response = await httpService.get('https://api.github.com/users/octocat');
console.log('响应状态:', response.status);
console.log('响应数据:', response.data);

// 发送POST请求
const postResponse = await httpService.post('https://api.example.com/login', {
  username: 'user',
  password: 'pass'
});
console.log('POST响应:', postResponse.data);
```

### 7.3 媒体服务示例

```typescript
// 获取媒体服务实例
const mediaService = MediaService.getInstance();

// 更新播放记录
await mediaService.updatePlaybackRecord({
  mediaId: 'movie-123',
  title: '测试电影',
  type: 'movie',
  duration: 3600,
  currentPosition: 60,
  lastWatchedAt: Date.now(),
  isFinished: false
});

// 获取播放历史
const history = await mediaService.getPlaybackHistory();
console.log('播放历史:', history);

// 添加收藏
await mediaService.addFavorite({
  id: 'movie-123',
  title: '测试电影',
  type: 'movie',
  coverUrl: 'https://example.com/cover.jpg',
  rating: 8.5,
  year: 2023
});

// 获取推荐内容
const recommended = await mediaService.getRecommendedContent(10);
console.log('推荐内容:', recommended);
```

## 8. 版本历史

| 版本 | 日期 | 变更描述 |
|------|------|----------|
| 1.0.0 | 2024-01-01 | 初始版本 |
| 1.1.0 | 2024-02-10 | 添加安全存储功能 |
| 1.2.0 | 2024-03-15 | 增强网络安全配置 |
| 1.3.0 | 2024-04-20 | 添加媒体服务功能 |
| 1.4.0 | 2024-10-01 | 优化网络请求，添加请求合并和批量操作功能 |

## 9. 贡献指南

### 9.1 代码规范

- 遵循TypeScript/ArkTS代码规范。
- 使用JSDoc注释文档化公共接口。
- 为新功能添加单元测试。

### 9.2 提交规范

- 使用语义化提交消息。
- 提交前运行测试。
- 提交前运行lint检查。

## 10. 联系方式

如有问题或建议，请联系：

- 邮箱：dev@raytv.com
- GitHub：https://github.com/raytv/raytv

---

**文档更新时间**：2024-10-01
**文档版本**：1.4.0
