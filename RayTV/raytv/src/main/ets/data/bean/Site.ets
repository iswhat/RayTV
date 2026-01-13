/**
 * Site data types | 站点数据类型
 * Define basic information and configuration structures for crawler sites | 定义爬虫站点的基本信息和配置结构
 */

/**
 * Site type enumeration | 站点类型枚举
 */
export enum SiteType {
  VOD = 'vod',          // VOD site | 点播站点
  LIVE = 'live',        // Live site | 直播站点
  MIXED = 'mixed'       // Mixed site (supports both VOD and live) | 混合站点(同时支持点播和直播)
}

/**
 * Site loader type enumeration | 站点加载器类型枚举
 */
export enum LoaderType {
  JAR = 'jar',          // Java JAR package | Java JAR包
  JS = 'js',            // JavaScript script | JavaScript脚本
  PY = 'py',            // Python script | Python脚本
  DART = 'dart',        // Dart script | Dart脚本
  WASM = 'wasm'         // WebAssembly
}

/**
 * Site authentication information interface | 站点认证信息接口
 */
export interface SiteAuth {
  username?: string;    // Username | 用户名
  password?: string;    // Password (encrypted storage) | 密码(加密存储)
  cookie?: string;      // Cookie information | Cookie信息
  token?: string;       // Authentication token | 认证令牌
  expiresAt?: number;   // Expiration time | 过期时间
}

/**
 * Site configuration item interface | 站点配置项接口
 */
export interface SiteConfigItem {
  key: string;          // Configuration key | 配置键
  value: string | number | boolean; // Configuration value | 配置值
  type: 'string' | 'number' | 'boolean' | 'select' | 'password'; // Configuration type | 配置类型
  label?: string;       // Display label | 显示标签
  description?: string; // Description | 描述
  options?: string[];   // Option list (for select type) | 选项列表(用于select类型)
  placeholder?: string; // Placeholder | 占位符
  min?: number;         // Minimum value (for number type) | 最小值(用于number类型)
  max?: number;         // Maximum value (for number type) | 最大值(用于number类型)
  required?: boolean;   // Whether required | 是否必填
  default?: string | number | boolean;        // Default value | 默认值
}

/**
 * Site request header configuration interface | 站点请求头配置接口
 */
export interface SiteHeaders {
  headers?: Record<string, string>; // Request headers in key-value form, using Record instead of Map | 键值对形式的请求头，使用Record替换Map
}

/**
 * Site search configuration interface | 站点搜索配置接口
 */
export interface SiteSearchConfig {
  enabled: boolean;     // Whether search is supported | 是否支持搜索
  searchDelay?: number; // Search delay (milliseconds) | 搜索延迟(毫秒)
  searchLimit?: number; // Search result limit | 搜索结果限制
  supportAdvancedSearch?: boolean; // Whether advanced search is supported | 是否支持高级搜索
  searchFilters?: string[]; // Search filter conditions | 搜索筛选条件
  searchCategories?: string[]; // Search categories | 搜索分类
}

/**
 * Site filter configuration interface | 站点筛选配置接口
 */
export interface SiteFilterConfig {
  enabled: boolean;     // Whether filtering is supported | 是否支持筛选
  filterOptions?: Record<string, string[]>; // Filter options (key is filter name, value is option list), using Record instead of Map | 筛选选项(键为筛选名称，值为选项列表)，使用Record替换Map
  sortOptions?: string[]; // Sort options | 排序选项
}

/**
 * Site performance configuration interface | 站点性能配置接口
 */
export interface SitePerformanceConfig {
  timeout?: number;     // Timeout time (milliseconds) | 超时时间(毫秒)
  retryCount?: number;  // Retry count | 重试次数
  cacheEnabled?: boolean; // Whether cache is enabled | 是否启用缓存
  cacheDuration?: number; // Cache duration (minutes) | 缓存时长(分钟)
  concurrency?: number; // Concurrent request count | 并发请求数
}

/**
 * Site version information interface | 站点版本信息接口
 */
export interface SiteVersion {
  version: string;      // Version number | 版本号
  buildTime: number;    // Build time | 构建时间
  author?: string;      // Author | 作者
  changelog?: string;   // Update log | 更新日志
  updateUrl?: string;   // Update URL | 更新地址
  compatibleVersion?: string; // Compatible version | 兼容版本
}

/**
 * Site statistics interface | 站点统计信息接口
 */
export interface SiteStats {
  queryCount: number;   // Query count | 查询次数
  errorCount: number;   // Error count | 错误次数
  avgResponseTime: number; // Average response time (milliseconds) | 平均响应时间(毫秒)
  lastQueryTime?: number; // Last query time | 最后查询时间
  lastErrorTime?: number; // Last error time | 最后错误时间
  lastErrorMessage?: string; // Last error message | 最后错误信息
}

/**
 * Site lifecycle status interface | 站点生命周期状态接口
 */
export interface SiteLifecycle {
  initialized: boolean; // Whether initialized | 是否已初始化
  loading: boolean;     // Whether loading | 是否加载中
  error: boolean;       // Whether error | 是否出错
  errorMessage?: string; // Error message | 错误信息
  initializedAt?: number; // Initialization time | 初始化时间
  lastActivityAt?: number; // Last activity time | 最后活动时间
}

/**
 * Site data type | 站点数据类型
 */
export interface Site {
  key: string;          // Site unique identifier | 站点唯一标识
  name: string;         // Site name | 站点名称
  type: SiteType;       // Site type | 站点类型
  loaderType: LoaderType; // Loader type | 加载器类型
  api: string;          // Site API address or local path | 站点API地址或本地路径
  logo?: string;        // Site Logo URL | 站点Logo URL
  description?: string; // Site description | 站点描述
  siteAuth?: SiteAuth;  // Authentication information | 认证信息
  headers?: SiteHeaders; // Request header configuration | 请求头配置
  config?: Record<string, string | number | boolean>; // Site configuration, using Record instead of Map | 站点配置，使用Record替换Map
  configItems?: SiteConfigItem[]; // Configurable item definitions | 可配置项定义
  searchConfig: SiteSearchConfig; // Search configuration | 搜索配置
  filterConfig: SiteFilterConfig; // Filter configuration | 筛选配置
  performanceConfig: SitePerformanceConfig; // Performance configuration | 性能配置
  version?: SiteVersion; // Version information | 版本信息
  stats: SiteStats;     // Statistics | 统计信息
  lifecycle: SiteLifecycle; // Lifecycle status | 生命周期状态
  enabled: boolean;     // Whether enabled | 是否启用
  order: number;        // Sorting weight | 排序权重
  group?: string;       // Belonging group | 所属分组
  tags?: string[];      // Tags | 标签
  customCode?: string;  // Custom code | 自定义代码
  sandboxEnabled?: boolean; // Whether sandbox is enabled | 是否启用沙箱
  allowThirdParty?: boolean; // Whether third-party calls are allowed | 是否允许第三方调用
  createdAt: number;    // Creation time | 创建时间
  updatedAt: number;    // Update time | 更新时间
  lastUsedAt?: number;  // Last used time | 最后使用时间
  userAgent?: string;   // Custom User-Agent | 自定义User-Agent
  referer?: string;     // Custom Referer | 自定义Referer
  proxy?: string;       // Proxy configuration | 代理配置
  encoding?: string;    // Encoding format | 编码格式
  charset?: string;     // Character set | 字符集
  certificate?: string; // Certificate configuration | 证书配置
}

/**
 * Site group interface | 站点分组接口
 */
export interface SiteGroup {
  id: string;           // Group ID | 分组ID
  name: string;         // Group name | 分组名称
  siteKeys: string[];   // Site identifier list | 站点标识列表
  icon?: string;        // Group icon | 分组图标
  color?: string;       // Group color | 分组颜色
  description?: string; // Group description | 分组描述
  order: number;        // Sorting weight | 排序权重
  createdAt: number;    // Creation time | 创建时间
  updatedAt: number;    // Update time | 更新时间
}

/**
 * Site list response interface | 站点列表响应接口
 */
export interface SiteListResponse {
  sites: Site[];        // Site list | 站点列表
  groups?: SiteGroup[]; // Group list | 分组列表
  total: number;        // Total count | 总数
  enabledCount: number; // Enabled site count | 启用的站点数量
  disabledCount: number; // Disabled site count | 禁用的站点数量
}

/**
 * Site test result interface | 站点测试结果接口
 */
export interface SiteTestResult {
  siteKey: string;      // Site identifier | 站点标识
  status: 'success' | 'failed' | 'timeout'; // Test status | 测试状态
  responseTime: number; // Response time (milliseconds) | 响应时间(毫秒)
  errorMessage?: string; // Error message | 错误信息
  testTime: number;     // Test time | 测试时间
  details?: string | number | boolean | null;        // Test details | 测试详情
}

/**
 * Site update information interface | 站点更新信息接口
 */
export interface SiteUpdateInfo {
  siteKey: string;      // Site identifier | 站点标识
  currentVersion: string; // Current version | 当前版本
  latestVersion: string; // Latest version | 最新版本
  updateUrl: string;    // Update URL | 更新地址
  changelog: string;    // Update log | 更新日志
  isAvailable: boolean; // Whether update is available | 是否有更新
  size?: number;        // Update package size | 更新包大小
  buildTime?: number;   // Build time | 构建时间
  author?: string;      // Author | 作者
}

/**
 * Site search request interface | 站点搜索请求接口
 */
export interface SiteSearchRequest {
  keyword: string;      // Search keyword | 搜索关键词
  siteKey?: string;     // Site identifier | 站点标识
  page?: number;        // Page number | 页码
  pageSize?: number;    // Page size | 每页数量
  filters?: Record<string, string>; // Filter conditions, using Record instead of Map | 筛选条件，使用Record替换Map
  sortBy?: string;      // Sort field | 排序字段
  sortOrder?: 'asc' | 'desc'; // Sort order | 排序顺序
  type?: 'all' | 'movie' | 'tv' | 'anime' | 'variety'; // Content type | 内容类型
}

/**
 * Site error report interface | 站点错误报告接口
 */
export interface SiteErrorReport {
  siteKey: string;      // Site identifier | 站点标识
  errorType: string;    // Error type | 错误类型
  errorMessage: string; // Error message | 错误信息
  stackTrace?: string;  // Stack trace | 堆栈跟踪
  requestInfo?: string | number | boolean | null;    // Request information | 请求信息
  timestamp: number;    // Occurrence time | 发生时间
  deviceInfo?: string;  // Device information | 设备信息
  appVersion?: string;  // App version | 应用版本
}

/**
 * Site import/export configuration interface | 站点导入导出配置接口
 */
export interface SiteImportExportConfig {
  includeCredentials?: boolean; // Whether to include credential information | 是否包含凭证信息
  includeStats?: boolean;      // Whether to include statistics | 是否包含统计信息
  includeCustomConfig?: boolean; // Whether to include custom configuration | 是否包含自定义配置
  format?: 'json' | 'zip' | 'raytv'; // Export format | 导出格式
  password?: string;           // Encryption password | 加密密码
  description?: string;        // Description information | 描述信息
}

/**
 * Site template interface | 站点模板接口
 */
export interface SiteTemplate {
  id: string;           // Template ID | 模板ID
  name: string;         // Template name | 模板名称
  loaderType: LoaderType; // Loader type | 加载器类型
  configTemplate: string | number | boolean | null;  // Configuration template | 配置模板
  description?: string; // Description | 描述
  tags?: string[];      // Tags | 标签
  author?: string;      // Author | 作者
  version?: string;     // Version number | 版本号
}
