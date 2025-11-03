// TableSchema.ts - 数据库表结构定义
// 定义所有数据库表的结构、字段和创建SQL语句

/**
 * 站点表结构
 */
export const SITE_TABLE = {
  TABLE_NAME: 'site',
  COLUMNS: {
    KEY: 'key',               // 站点唯一标识
    NAME: 'name',             // 站点名称
    TYPE: 'type',             // 站点类型（jar/js/py）
    API: 'api',               // 站点API地址
    SEARCHABLE: 'searchable', // 是否支持搜索
    FILTERABLE: 'filterable', // 是否支持筛选
    HEADERS: 'headers',       // 请求头（JSON字符串）
    COOKIE: 'cookie',         // Cookie
    EXT: 'ext',               // 扩展信息（JSON字符串）
    ENABLED: 'enabled',       // 是否启用
    ORDER: 'order_num',       // 排序
    CREATED_AT: 'created_at', // 创建时间
    UPDATED_AT: 'updated_at'  // 更新时间
  },
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS site (
      key TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      api TEXT NOT NULL,
      searchable INTEGER DEFAULT 1,
      filterable INTEGER DEFAULT 1,
      headers TEXT,
      cookie TEXT,
      ext TEXT,
      enabled INTEGER DEFAULT 1,
      order_num INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  `
};

/**
 * 历史记录表结构
 */
export const HISTORY_TABLE = {
  TABLE_NAME: 'history',
  COLUMNS: {
    ID: 'id',                 // 历史记录ID
    CONTENT_ID: 'content_id', // 内容ID
    CONTENT_NAME: 'content_name', // 内容名称
    TYPE: 'type',             // 内容类型（vod/live）
    COVER: 'cover',           // 封面URL
    EPISODE_NAME: 'episode_name', // 剧集名称
    SOURCE_KEY: 'source_key', // 数据源标识
    POSITION: 'position',     // 播放位置（毫秒）
    DURATION: 'duration',     // 总时长（毫秒）
    LAST_PLAYED_AT: 'last_played_at', // 最后播放时间
    CREATED_AT: 'created_at'  // 创建时间
  },
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS history (
      id TEXT PRIMARY KEY,
      content_id TEXT NOT NULL,
      content_name TEXT NOT NULL,
      type TEXT NOT NULL,
      cover TEXT,
      episode_name TEXT,
      source_key TEXT NOT NULL,
      position INTEGER DEFAULT 0,
      duration INTEGER DEFAULT 0,
      last_played_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL
    );
  `
};

/**
 * 收藏表结构
 */
export const FAVORITE_TABLE = {
  TABLE_NAME: 'favorite',
  COLUMNS: {
    ID: 'id',                 // 收藏ID
    CONTENT_ID: 'content_id', // 内容ID
    CONTENT_NAME: 'content_name', // 内容名称
    TYPE: 'type',             // 内容类型（vod/live）
    COVER: 'cover',           // 封面URL
    SOURCE_KEY: 'source_key', // 数据源标识
    URL: 'url',               // 内容URL
    CREATED_AT: 'created_at'  // 收藏时间
  },
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS favorite (
      id TEXT PRIMARY KEY,
      content_id TEXT NOT NULL,
      content_name TEXT NOT NULL,
      type TEXT NOT NULL,
      cover TEXT,
      source_key TEXT NOT NULL,
      url TEXT NOT NULL,
      created_at INTEGER NOT NULL
    );
  `
};

/**
 * 配置表结构
 */
export const CONFIG_TABLE = {
  TABLE_NAME: 'config',
  COLUMNS: {
    KEY: 'key',               // 配置键
    VALUE: 'value',           // 配置值（JSON字符串）
    TYPE: 'type',             // 配置类型
    DESCRIPTION: 'description', // 配置描述
    UPDATED_AT: 'updated_at'  // 更新时间
  },
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS config (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      type TEXT DEFAULT 'general',
      description TEXT,
      updated_at INTEGER NOT NULL
    );
  `
};

/**
 * 缓存表结构
 */
export const CACHE_TABLE = {
  TABLE_NAME: 'cache',
  COLUMNS: {
    KEY: 'key',               // 缓存键
    VALUE: 'value',           // 缓存值（JSON字符串）
    EXPIRES_AT: 'expires_at', // 过期时间
    CREATED_AT: 'created_at'  // 创建时间
  },
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS cache (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      expires_at INTEGER,
      created_at INTEGER NOT NULL
    );
  `
};

/**
 * 索引定义
 */
export const INDEXES = {
  HISTORY_CONTENT_INDEX: `
    CREATE INDEX IF NOT EXISTS idx_history_content 
    ON history(content_id, source_key);
  `,
  HISTORY_TIME_INDEX: `
    CREATE INDEX IF NOT EXISTS idx_history_time 
    ON history(last_played_at);
  `,
  FAVORITE_CONTENT_INDEX: `
    CREATE INDEX IF NOT EXISTS idx_favorite_content 
    ON favorite(content_id, source_key);
  `,
  SITE_ENABLED_INDEX: `
    CREATE INDEX IF NOT EXISTS idx_site_enabled 
    ON site(enabled, order_num);
  `,
  SITE_TYPE_INDEX: `
    CREATE INDEX IF NOT EXISTS idx_site_type 
    ON site(type, enabled, order_num);
  `,
  CACHE_EXPIRES_INDEX: `
    CREATE INDEX IF NOT EXISTS idx_cache_expires 
    ON cache(expires_at);
  `
};

/**
 * 获取所有表的创建SQL语句
 * @returns string[] 所有表的创建SQL语句数组
 */
export function getAllTables(): string[] {
  return [
    SITE_TABLE.CREATE_SQL,
    HISTORY_TABLE.CREATE_SQL,
    FAVORITE_TABLE.CREATE_SQL,
    CONFIG_TABLE.CREATE_SQL,
    CACHE_TABLE.CREATE_SQL,
    INDEXES.HISTORY_CONTENT_INDEX,
    INDEXES.HISTORY_TIME_INDEX,
    INDEXES.FAVORITE_CONTENT_INDEX,
    INDEXES.SITE_ENABLED_INDEX,
    INDEXES.SITE_TYPE_INDEX,
    INDEXES.CACHE_EXPIRES_INDEX
  ];
}

/**
 * 数据库版本信息
 */
export const DATABASE_VERSION = 1;
export const DATABASE_NAME = 'raytv.db';

/**
 * 表迁移信息
 */
export const MIGRATIONS: Record<number, string[]> = {
  1: getAllTables() // 初始版本
};

/**
 * 获取表名常量
 * @returns string[] 所有表名数组
 */
export function getAllTableNames(): string[] {
  return [
    SITE_TABLE.TABLE_NAME,
    HISTORY_TABLE.TABLE_NAME,
    FAVORITE_TABLE.TABLE_NAME,
    CONFIG_TABLE.TABLE_NAME,
    CACHE_TABLE.TABLE_NAME
  ];
}