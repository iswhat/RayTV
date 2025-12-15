// Site.ets - 站点数据模型
// 定义爬虫站点的基本信息和配置结构

/**
 * 站点类型枚举
 */
export enum SiteType {
  VOD = 'vod',          // 点播站点
  LIVE = 'live',        // 直播站点
  MIXED = 'mixed'       // 混合站点（同时支持点播和直播）
}

/**
 * 站点加载器类型枚举
 */
export enum LoaderType {
  JAR = 'jar',          // Java JAR包
  JS = 'js',            // JavaScript脚本
  PY = 'py',            // Python脚本
  DART = 'dart',        // Dart脚本
  WASM = 'wasm'         // WebAssembly
}

/**
 * 站点认证信息接口
 */
export interface SiteAuth {
  username?: string;    // 用户名
  password?: string;    // 密码（加密存储）
  cookie?: string;      // Cookie信息
  token?: string;       // 认证令牌
  expiresAt?: number;   // 过期时间
}

/**
 * 站点配置项接口
 */
export interface SiteConfigItem {
  key: string;          // 配置键
  value: string | number | boolean; // 配置值
  type: 'string' | 'number' | 'boolean' | 'select' | 'password'; // 配置类型
  label?: string;       // 显示标签
  description?: string; // 描述
  options?: string[];   // 选项列表（用于select类型）
  placeholder?: string; // 占位符
  min?: number;         // 最小值（用于number类型）
  max?: number;         // 最大值（用于number类型）
  required?: boolean;   // 是否必填
  default?: string | number | boolean;        // 默认值
}

/**
 * 站点请求头配置接口
 */
export interface SiteHeaders {
  headers?: Record<string, string>; // 键值对形式的请求头，使用Record替代Map
}

/**
 * 站点搜索配置接口
 */
export interface SiteSearchConfig {
  enabled: boolean;     // 是否支持搜索
  searchDelay?: number; // 搜索延迟（毫秒）
  searchLimit?: number; // 搜索结果限制
  supportAdvancedSearch?: boolean; // 是否支持高级搜索
  searchFilters?: string[]; // 搜索筛选条件
  searchCategories?: string[]; // 搜索分类
}

/**
 * 站点筛选配置接口
 */
export interface SiteFilterConfig {
  enabled: boolean;     // 是否支持筛选
  filterOptions?: Record<string, string[]>; // 筛选选项（键为筛选名称，值为选项列表），使用Record替代Map
  sortOptions?: string[]; // 排序选项
}

/**
 * 站点性能配置接口
 */
export interface SitePerformanceConfig {
  timeout?: number;     // 超时时间（毫秒）
  retryCount?: number;  // 重试次数
  cacheEnabled?: boolean; // 是否启用缓存
  cacheDuration?: number; // 缓存时长（分钟）
  concurrency?: number; // 并发请求数
}

/**
 * 站点版本信息接口
 */
export interface SiteVersion {
  version: string;      // 版本号
  buildTime: number;    // 构建时间
  author?: string;      // 作者
  changelog?: string;   // 更新日志
  updateUrl?: string;   // 更新地址
  compatibleVersion?: string; // 兼容版本
}

/**
 * 站点统计信息接口
 */
export interface SiteStats {
  queryCount: number;   // 查询次数
  errorCount: number;   // 错误次数
  avgResponseTime: number; // 平均响应时间（毫秒）
  lastQueryTime?: number; // 最后查询时间
  lastErrorTime?: number; // 最后错误时间
  lastErrorMessage?: string; // 最后错误信息
}

/**
 * 站点生命周期状态接口
 */
export interface SiteLifecycle {
  initialized: boolean; // 是否已初始化
  loading: boolean;     // 是否加载中
  error: boolean;       // 是否出错
  errorMessage?: string; // 错误信息
  initializedAt?: number; // 初始化时间
  lastActivityAt?: number; // 最后活动时间
}

/**
 * 站点数据模型
 */
export interface Site {
  key: string;          // 站点唯一标识
  name: string;         // 站点名称
  type: SiteType;       // 站点类型
  loaderType: LoaderType; // 加载器类型
  api: string;          // 站点API地址或脚本路径
  logo?: string;        // 站点Logo URL
  description?: string; // 站点描述
  siteAuth?: SiteAuth;  // 认证信息
  headers?: SiteHeaders; // 请求头配置
  config?: Record<string, string | number | boolean>; // 站点配置，使用Record替代Map
  configItems?: SiteConfigItem[]; // 可配置项定义
  searchConfig: SiteSearchConfig; // 搜索配置
  filterConfig: SiteFilterConfig; // 筛选配置
  performanceConfig: SitePerformanceConfig; // 性能配置
  version?: SiteVersion; // 版本信息
  stats: SiteStats;     // 统计信息
  lifecycle: SiteLifecycle; // 生命周期状态
  enabled: boolean;     // 是否启用
  order: number;        // 排序权重
  group?: string;       // 所属分组
  tags?: string[];      // 标签
  customCode?: string;  // 自定义代码
  sandboxEnabled?: boolean; // 是否启用沙箱
  allowThirdParty?: boolean; // 是否允许第三方调用
  createdAt: number;    // 创建时间
  updatedAt: number;    // 更新时间
  lastUsedAt?: number;  // 最后使用时间
  userAgent?: string;   // 自定义User-Agent
  referer?: string;     // 自定义Referer
  proxy?: string;       // 代理配置
  encoding?: string;    // 编码格式
  charset?: string;     // 字符集
  certificate?: string; // 证书配置
}

/**
 * 站点分组接口
 */
export interface SiteGroup {
  id: string;           // 分组ID
  name: string;         // 分组名称
  siteKeys: string[];   // 站点标识列表
  icon?: string;        // 分组图标
  color?: string;       // 分组颜色
  description?: string; // 分组描述
  order: number;        // 排序权重
  createdAt: number;    // 创建时间
  updatedAt: number;    // 更新时间
}

/**
 * 站点列表响应接口
 */
export interface SiteListResponse {
  sites: Site[];        // 站点列表
  groups?: SiteGroup[]; // 分组列表
  total: number;        // 总数
  enabledCount: number; // 启用的站点数量
  disabledCount: number; // 禁用的站点数量
}

/**
 * 站点测试结果接口
 */
export interface SiteTestResult {
  siteKey: string;      // 站点标识
  status: 'success' | 'failed' | 'timeout'; // 测试状态
  responseTime: number; // 响应时间（毫秒）
  errorMessage?: string; // 错误信息
  testTime: number;     // 测试时间
  details?: string | number | boolean | null;        // 测试详情
}

/**
 * 站点更新信息接口
 */
export interface SiteUpdateInfo {
  siteKey: string;      // 站点标识
  currentVersion: string; // 当前版本
  latestVersion: string; // 最新版本
  updateUrl: string;    // 更新地址
  changelog: string;    // 更新日志
  isAvailable: boolean; // 是否有更新
  size?: number;        // 更新包大小
  buildTime?: number;   // 构建时间
  author?: string;      // 作者
}

/**
 * 站点搜索请求接口
 */
export interface SiteSearchRequest {
  keyword: string;      // 搜索关键词
  siteKey?: string;     // 站点标识
  page?: number;        // 页码
  pageSize?: number;    // 每页数量
  filters?: Record<string, string>; // 筛选条件，使用Record替代Map
  sortBy?: string;      // 排序字段
  sortOrder?: 'asc' | 'desc'; // 排序顺序
  type?: 'all' | 'movie' | 'tv' | 'anime' | 'variety'; // 内容类型
}

/**
 * 站点错误报告接口
 */
export interface SiteErrorReport {
  siteKey: string;      // 站点标识
  errorType: string;    // 错误类型
  errorMessage: string; // 错误信息
  stackTrace?: string;  // 堆栈跟踪
  requestInfo?: string | number | boolean | null;    // 请求信息
  timestamp: number;    // 发生时间
  deviceInfo?: string;  // 设备信息
  appVersion?: string;  // 应用版本
}

/**
 * 站点导入导出配置接口
 */
export interface SiteImportExportConfig {
  includeCredentials?: boolean; // 是否包含凭证信息
  includeStats?: boolean;      // 是否包含统计信息
  includeCustomConfig?: boolean; // 是否包含自定义配置
  format?: 'json' | 'zip' | 'raytv'; // 导出格式
  password?: string;           // 加密密码
  description?: string;        // 描述信息
}

/**
 * 站点模板接口
 */
export interface SiteTemplate {
  id: string;           // 模板ID
  name: string;         // 模板名称
  loaderType: LoaderType; // 加载器类型
  configTemplate: string | number | boolean | null;  // 配置模板
  description?: string; // 描述
  tags?: string[];      // 标签
  author?: string;      // 作者
  version?: string;     // 版本号
}