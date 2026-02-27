/**
 * AppError.ets - 应用错误类型定义
 * 定义项目中使用的各种自定义错误类型，提供更详细的错误信息
 */

/**
 * 错误详情接口 | Error details interface
 */
export interface ErrorDetails {
  name?: string;
  message?: string;
  code?: string;
  stack?: string;
  timestamp?: number;
  originalError?: string;
  sql?: string;
  configKey?: string;
  siteKey?: string;
  mediaId?: string;
  status?: string;
  cacheKey?: string;
  source?: string;
  url?: string;
  statusCode?: number;
}

/**
 * 应用错误对象接口 | App error object interface
 */
export interface AppErrorObject {
  name: string;
  message: string;
  code: string;
  details?: ErrorDetails;
  timestamp: number;
  stack?: string;
}

/**
 * 应用错误基础类 | App error base class
 */
export class AppError extends Error {
  /**
   * 错误代码 | Error code
   */
  public code: string;

  /**
   * 错误详情 | Error details
   */
  public details?: ErrorDetails;

  /**
   * 错误时间戳 | Error timestamp
   */
  public timestamp: number;

  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string, details?: ErrorDetails) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.details = details;
    this.timestamp = Date.now();
  }

  /**
   * 转换为字符串 | Convert to string
   * @returns 错误字符串 | Error string
   */
  public toString(): string {
    return `[${this.code}] ${this.message}${this.details ? ` - ${JSON.stringify(this.details)}` : ''}`;
  }

  /**
   * 转换为对象 | Convert to object
   * @returns 错误对象 | Error object
   */
  public toObject(): AppErrorObject {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      details: this.details,
      timestamp: this.timestamp,
      stack: this.stack
    };
  }
}

/**
 * 网络错误 | Network error
 */
export class NetworkError extends AppError {
  /**
   * HTTP状态码 | HTTP status code
   */
  public statusCode?: number;
  
  /**
   * 请求URL | Request URL
   */
  public url?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param statusCode HTTP状态码 | HTTP status code
   * @param url 请求URL | Request URL
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'NETWORK_ERROR', statusCode?: number, url?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'NetworkError';
    this.statusCode = statusCode;
    this.url = url;
  }
}

/**
 * 数据库错误 | Database error
 */
export class DatabaseError extends AppError {
  /**
   * SQL语句 | SQL statement
   */
  public sql?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param sql SQL语句 | SQL statement
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'DATABASE_ERROR', sql?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'DatabaseError';
    this.sql = sql;
  }
}

/**
 * 配置错误 | Configuration error
 */
export class ConfigError extends AppError {
  /**
   * 配置键 | Configuration key
   */
  public configKey?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param configKey 配置键 | Configuration key
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'CONFIG_ERROR', configKey?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'ConfigError';
    this.configKey = configKey;
  }
}

/**
 * 站点错误 | Site error
 */
export class SiteError extends AppError {
  /**
   * 站点key | Site key
   */
  public siteKey?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param siteKey 站点key | Site key
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'SITE_ERROR', siteKey?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'SiteError';
    this.siteKey = siteKey;
  }
}

/**
 * 播放错误 | Playback error
 */
export class PlaybackError extends AppError {
  /**
   * 媒体ID | Media ID
   */
  public mediaId?: string;
  
  /**
   * 播放状态 | Playback status
   */
  public status?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param mediaId 媒体ID | Media ID
   * @param status 播放状态 | Playback status
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'PLAYBACK_ERROR', mediaId?: string, status?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'PlaybackError';
    this.mediaId = mediaId;
    this.status = status;
  }
}

/**
 * 缓存错误 | Cache error
 */
export class CacheError extends AppError {
  /**
   * 缓存键 | Cache key
   */
  public cacheKey?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param cacheKey 缓存键 | Cache key
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'CACHE_ERROR', cacheKey?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'CacheError';
    this.cacheKey = cacheKey;
  }
}

/**
 * 解析错误 | Parser error
 */
export class ParserError extends AppError {
  /**
   * 解析源 | Parser source
   */
  public source?: string;
  
  /**
   * 构造函数 | Constructor
   * @param message 错误消息 | Error message
   * @param code 错误代码 | Error code
   * @param source 解析源 | Parser source
   * @param details 错误详情 | Error details
   */
  constructor(message: string, code: string = 'PARSER_ERROR', source?: string, details?: ErrorDetails) {
    super(message, code, details);
    this.name = 'ParserError';
    this.source = source;
  }
}

/**
 * 工具函数：创建网络错误 | Utility function: Create network error
 * @param message 错误消息 | Error message
 * @param statusCode HTTP状态码 | HTTP status code
 * @param url 请求URL | Request URL
 * @param details 错误详情 | Error details
 * @returns 网络错误实例 | Network error instance
 */
export function createNetworkError(message: string, statusCode?: number, url?: string, details?: ErrorDetails): NetworkError {
  return new NetworkError(message, 'NETWORK_ERROR', statusCode, url, details);
}

/**
 * 工具函数：创建数据库错误 | Utility function: Create database error
 * @param message 错误消息 | Error message
 * @param sql SQL语句 | SQL statement
 * @param details 错误详情 | Error details
 * @returns 数据库错误实例 | Database error instance
 */
export function createDatabaseError(message: string, sql?: string, details?: ErrorDetails): DatabaseError {
  return new DatabaseError(message, 'DATABASE_ERROR', sql, details);
}

/**
 * 工具函数：创建配置错误 | Utility function: Create configuration error
 * @param message 错误消息 | Error message
 * @param configKey 配置键 | Configuration key
 * @param details 错误详情 | Error details
 * @returns 配置错误实例 | Configuration error instance
 */
export function createConfigError(message: string, configKey?: string, details?: ErrorDetails): ConfigError {
  return new ConfigError(message, 'CONFIG_ERROR', configKey, details);
}

/**
 * 工具函数：创建站点错误 | Utility function: Create site error
 * @param message 错误消息 | Error message
 * @param siteKey 站点key | Site key
 * @param details 错误详情 | Error details
 * @returns 站点错误实例 | Site error instance
 */
export function createSiteError(message: string, siteKey?: string, details?: ErrorDetails): SiteError {
  return new SiteError(message, 'SITE_ERROR', siteKey, details);
}

/**
 * 工具函数：创建播放错误 | Utility function: Create playback error
 * @param message 错误消息 | Error message
 * @param mediaId 媒体ID | Media ID
 * @param status 播放状态 | Playback status
 * @param details 错误详情 | Error details
 * @returns 播放错误实例 | Playback error instance
 */
export function createPlaybackError(message: string, mediaId?: string, status?: string, details?: ErrorDetails): PlaybackError {
  return new PlaybackError(message, 'PLAYBACK_ERROR', mediaId, status, details);
}

/**
 * 工具函数：创建缓存错误 | Utility function: Create cache error
 * @param message 错误消息 | Error message
 * @param cacheKey 缓存键 | Cache key
 * @param details 错误详情 | Error details
 * @returns 缓存错误实例 | Cache error instance
 */
export function createCacheError(message: string, cacheKey?: string, details?: ErrorDetails): CacheError {
  return new CacheError(message, 'CACHE_ERROR', cacheKey, details);
}

/**
 * 工具函数：创建解析错误 | Utility function: Create parser error
 * @param message 错误消息 | Error message
 * @param source 解析源 | Parser source
 * @param details 错误详情 | Error details
 * @returns 解析错误实例 | Parser error instance
 */
export function createParserError(message: string, source?: string, details?: ErrorDetails): ParserError {
  return new ParserError(message, 'PARSER_ERROR', source, details);
}

/**
 * 工具函数：处理错误 | Utility function: Handle error
 * @param error 错误对象 | Error object
 * @param defaultMessage 默认错误消息 | Default error message
 * @returns 标准化的错误对象 | Standardized error object
 */
export function handleError(error: Error | string | number | object | null | undefined, defaultMessage: string = 'Unknown error'): AppError {
  if (error instanceof AppError) {
    return error;
  }

  if (error instanceof Error) {
    const details: ErrorDetails = {
      name: error.name,
      message: error.message,
      stack: error.stack
    };
    return new AppError(error.message || defaultMessage, 'UNKNOWN_ERROR', details);
  }

  const errorStr = String(error || defaultMessage);
  const details: ErrorDetails = {
    message: errorStr
  };
  return new AppError(errorStr, 'UNKNOWN_ERROR', details);
}
