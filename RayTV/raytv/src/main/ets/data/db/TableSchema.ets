// TableSchema.ets - 数据库表结构定义
// 定义RayTV应用的所有数据库表结构和字段常量

/**
 * 站点表定�? */
export const SITE_TABLE = {
  NAME: 'site',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS site (
      key TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      loader_type TEXT NOT NULL,
      api TEXT NOT NULL,
      logo TEXT,
      description TEXT,
      site_auth TEXT,
      headers TEXT,
      config TEXT,
      config_items TEXT,
      search_config TEXT NOT NULL,
      filter_config TEXT NOT NULL,
      performance_config TEXT NOT NULL,
      version TEXT,
      stats TEXT NOT NULL,
      lifecycle TEXT NOT NULL,
      enabled INTEGER NOT NULL DEFAULT 1,
      "order" INTEGER NOT NULL DEFAULT 0,
      "group" TEXT,
      tags TEXT,
      custom_code TEXT,
      sandbox_enabled INTEGER DEFAULT 1,
      allow_third_party INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      last_used_at INTEGER,
      user_agent TEXT,
      referer TEXT,
      proxy TEXT,
      encoding TEXT,
      charset TEXT,
      certificate TEXT
    );
  `,
  COLUMNS: {
    KEY: 'key',
    NAME: 'name',
    TYPE: 'type',
    LOADER_TYPE: 'loader_type',
    API: 'api',
    LOGO: 'logo',
    DESCRIPTION: 'description',
    SITE_AUTH: 'site_auth',
    HEADERS: 'headers',
    CONFIG: 'config',
    CONFIG_ITEMS: 'config_items',
    SEARCH_CONFIG: 'search_config',
    FILTER_CONFIG: 'filter_config',
    PERFORMANCE_CONFIG: 'performance_config',
    VERSION: 'version',
    STATS: 'stats',
    LIFECYCLE: 'lifecycle',
    ENABLED: 'enabled',
    ORDER: 'order',
    GROUP: 'group',
    TAGS: 'tags',
    CUSTOM_CODE: 'custom_code',
    SANDBOX_ENABLED: 'sandbox_enabled',
    ALLOW_THIRD_PARTY: 'allow_third_party',
    CREATED_AT: 'created_at',
    UPDATED_AT: 'updated_at',
    LAST_USED_AT: 'last_used_at',
    USER_AGENT: 'user_agent',
    REFERER: 'referer',
    PROXY: 'proxy',
    ENCODING: 'encoding',
    CHARSET: 'charset',
    CERTIFICATE: 'certificate'
  }
};

/**
 * 历史记录表定�? */
export const HISTORY_TABLE = {
  NAME: 'history',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS history (
      id TEXT PRIMARY KEY,
      content_id TEXT NOT NULL,
      content_name TEXT NOT NULL,
      "type" TEXT NOT NULL,
      content_type TEXT NOT NULL,
      source_key TEXT NOT NULL,
      cover TEXT NOT NULL,
      poster TEXT,
      backdrop TEXT,
      position INTEGER NOT NULL DEFAULT 0,
      duration INTEGER NOT NULL DEFAULT 0,
      progress REAL NOT NULL DEFAULT 0,
      playback_status TEXT NOT NULL,
      episode_name TEXT,
      episode_id TEXT,
      season_name TEXT,
      season_id TEXT,
      source_name TEXT,
      source_url TEXT,
      play_count INTEGER NOT NULL DEFAULT 1,
      total_watch_time INTEGER NOT NULL DEFAULT 0,
      last_played_at INTEGER NOT NULL,
      first_played_at INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      device_id TEXT,
      device_name TEXT,
      user_agent TEXT,
      resolution TEXT,
      bitrate INTEGER,
      language TEXT,
      subtitles TEXT,
      audio_tracks TEXT,
      selected_audio_track TEXT,
      selected_subtitle TEXT,
      playback_speed REAL,
      volume REAL,
      brightness REAL,
      contrast REAL,
      saturation REAL,
      hue REAL,
      playback_notes TEXT,
      watch_time_list TEXT,
      UNIQUE(content_id, content_type, source_key)
    );
  `,
  COLUMNS: {
    ID: 'id',
    CONTENT_ID: 'content_id',
    CONTENT_NAME: 'content_name',
    TYPE: 'type',
    CONTENT_TYPE: 'content_type',
    SOURCE_KEY: 'source_key',
    COVER: 'cover',
    POSTER: 'poster',
    BACKDROP: 'backdrop',
    POSITION: 'position',
    DURATION: 'duration',
    PROGRESS: 'progress',
    PLAYBACK_STATUS: 'playback_status',
    EPISODE_NAME: 'episode_name',
    EPISODE_ID: 'episode_id',
    SEASON_NAME: 'season_name',
    SEASON_ID: 'season_id',
    SOURCE_NAME: 'source_name',
    SOURCE_URL: 'source_url',
    PLAY_COUNT: 'play_count',
    TOTAL_WATCH_TIME: 'total_watch_time',
    LAST_PLAYED_AT: 'last_played_at',
    FIRST_PLAYED_AT: 'first_played_at',
    CREATED_AT: 'created_at',
    UPDATED_AT: 'updated_at',
    DEVICE_ID: 'device_id',
    DEVICE_NAME: 'device_name',
    USER_AGENT: 'user_agent',
    RESOLUTION: 'resolution',
    BITRATE: 'bitrate',
    LANGUAGE: 'language',
    SUBTITLES: 'subtitles',
    AUDIO_TRACKS: 'audio_tracks',
    SELECTED_AUDIO_TRACK: 'selected_audio_track',
    SELECTED_SUBTITLE: 'selected_subtitle',
    PLAYBACK_SPEED: 'playback_speed',
    VOLUME: 'volume',
    BRIGHTNESS: 'brightness',
    CONTRAST: 'contrast',
    SATURATION: 'saturation',
    HUE: 'hue',
    PLAYBACK_NOTES: 'playback_notes',
    WATCH_TIME_LIST: 'watch_time_list'
  }
};

/**
 * 收藏表定�? */
export const KEEP_TABLE = {
  NAME: 'keep',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS keep (
      id TEXT PRIMARY KEY,
      content_id TEXT NOT NULL,
      content_name TEXT NOT NULL,
      "type" TEXT NOT NULL,
      content_type TEXT NOT NULL,
      source_key TEXT NOT NULL,
      cover TEXT NOT NULL,
      poster TEXT,
      backdrop TEXT,
      description TEXT,
      episode_name TEXT,
      season_name TEXT,
      add_time INTEGER NOT NULL,
      last_update_time INTEGER NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0,
      folder_id TEXT,
      rating REAL,
      tags TEXT,
      notes TEXT,
      progress REAL DEFAULT 0,
      UNIQUE(content_id, content_type, source_key)
    );
  `,
  COLUMNS: {
    ID: 'id',
    CONTENT_ID: 'content_id',
    CONTENT_NAME: 'content_name',
    TYPE: 'type',
    CONTENT_TYPE: 'content_type',
    SOURCE_KEY: 'source_key',
    COVER: 'cover',
    POSTER: 'poster',
    BACKDROP: 'backdrop',
    DESCRIPTION: 'description',
    EPISODE_NAME: 'episode_name',
    SEASON_NAME: 'season_name',
    ADD_TIME: 'add_time',
    LAST_UPDATE_TIME: 'last_update_time',
    SORT_ORDER: 'sort_order',
    FOLDER_ID: 'folder_id',
    RATING: 'rating',
    TAGS: 'tags',
    NOTES: 'notes',
    PROGRESS: 'progress'
  }
};

/**
 * 配置表定�? */
export const CONFIG_TABLE = {
  NAME: 'config',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS config (
      id TEXT PRIMARY KEY,
      player_config TEXT NOT NULL,
      display_config TEXT NOT NULL,
      network_config TEXT NOT NULL,
      security_config TEXT NOT NULL,
      ad_block_config TEXT NOT NULL,
      harmony_config TEXT NOT NULL,
      search_config TEXT NOT NULL,
      download_config TEXT NOT NULL,
      sync_config TEXT NOT NULL,
      log_config TEXT NOT NULL,
      "version" TEXT NOT NULL,
      last_updated INTEGER NOT NULL,
      migration_version TEXT,
      custom_settings TEXT,
      is_default INTEGER DEFAULT 0
    );
  `,
  COLUMNS: {
    ID: 'id',
    PLAYER_CONFIG: 'player_config',
    DISPLAY_CONFIG: 'display_config',
    NETWORK_CONFIG: 'network_config',
    SECURITY_CONFIG: 'security_config',
    AD_BLOCK_CONFIG: 'ad_block_config',
    HARMONY_CONFIG: 'harmony_config',
    SEARCH_CONFIG: 'search_config',
    DOWNLOAD_CONFIG: 'download_config',
    SYNC_CONFIG: 'sync_config',
    LOG_CONFIG: 'log_config',
    VERSION: 'version',
    LAST_UPDATED: 'last_updated',
    MIGRATION_VERSION: 'migration_version',
    CUSTOM_SETTINGS: 'custom_settings',
    IS_DEFAULT: 'is_default'
  }
};

/**
 * 收藏文件夹表定义
 */
export const KEEP_FOLDER_TABLE = {
  NAME: 'keep_folder',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS keep_folder (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      icon TEXT,
      color TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      item_count INTEGER NOT NULL DEFAULT 0,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_default INTEGER DEFAULT 0
    );
  `,
  COLUMNS: {
    ID: 'id',
    NAME: 'name',
    DESCRIPTION: 'description',
    ICON: 'icon',
    COLOR: 'color',
    CREATED_AT: 'created_at',
    UPDATED_AT: 'updated_at',
    ITEM_COUNT: 'item_count',
    SORT_ORDER: 'sort_order',
    IS_DEFAULT: 'is_default'
  }
};

/**
 * 搜索历史表定�? */
export const SEARCH_HISTORY_TABLE = {
  NAME: 'search_history',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS search_history (
      id TEXT PRIMARY KEY,
      keyword TEXT NOT NULL,
      search_type TEXT,
      source_key TEXT,
      search_time INTEGER NOT NULL,
      result_count INTEGER DEFAULT 0,
      is_favorite INTEGER DEFAULT 0
    );
  `,
  COLUMNS: {
    ID: 'id',
    KEYWORD: 'keyword',
    SEARCH_TYPE: 'search_type',
    SOURCE_KEY: 'source_key',
    SEARCH_TIME: 'search_time',
    RESULT_COUNT: 'result_count',
    IS_FAVORITE: 'is_favorite'
  }
};

/**
 * 线路表定�? */
export const LINE_TABLE = {
  NAME: 'line',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS line (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      description TEXT,
      type TEXT DEFAULT 'all',
      update_time INTEGER NOT NULL,
      create_time INTEGER NOT NULL,
      source_count INTEGER DEFAULT 0,
      enabled INTEGER DEFAULT 1,
      current INTEGER DEFAULT 0,
      cache_time INTEGER DEFAULT 24,
      response_time INTEGER DEFAULT 0
    );
  `,
  COLUMNS: {
    ID: 'id',
    NAME: 'name',
    URL: 'url',
    DESCRIPTION: 'description',
    TYPE: 'type',
    UPDATE_TIME: 'update_time',
    CREATE_TIME: 'create_time',
    SOURCE_COUNT: 'source_count',
    ENABLED: 'enabled',
    CURRENT: 'current',
    CACHE_TIME: 'cache_time',
    RESPONSE_TIME: 'response_time'
  }
};

/**
 * 订阅表定�? */
export const SUBSCRIPTION_TABLE = {
  NAME: 'subscription',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS subscription (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      url TEXT NOT NULL,
      description TEXT,
      update_time INTEGER NOT NULL,
      create_time INTEGER NOT NULL,
      site_count INTEGER NOT NULL DEFAULT 0,
      enabled INTEGER NOT NULL DEFAULT 1,
      current INTEGER NOT NULL DEFAULT 0
    );
  `,
  COLUMNS: {
    ID: 'id',
    NAME: 'name',
    URL: 'url',
    DESCRIPTION: 'description',
    UPDATE_TIME: 'update_time',
    CREATE_TIME: 'create_time',
    SITE_COUNT: 'site_count',
    ENABLED: 'enabled',
    CURRENT: 'current'
  }
};

/**
 * 直播频道表定�? */
export const LIVE_CHANNEL_TABLE = {
  NAME: 'live_channel',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS live_channel (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      group_id TEXT NOT NULL,
      logo TEXT,
      epg_id TEXT,
      streams TEXT NOT NULL,
      "order" INTEGER NOT NULL DEFAULT 0,
      is_favorite INTEGER DEFAULT 0,
      is_locked INTEGER DEFAULT 0,
      password TEXT,
      play_count INTEGER DEFAULT 0,
      last_play_time INTEGER,
      last_check_time INTEGER,
      "status" TEXT DEFAULT 'unknown',
      country TEXT,
      language TEXT,
      category TEXT,
      description TEXT,
      current_epg TEXT,
      next_epg TEXT,
      source_key TEXT NOT NULL,
      custom_url TEXT,
      tags TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      user_config TEXT
    );
  `,
  COLUMNS: {
    ID: 'id',
    NAME: 'name',
    GROUP_ID: 'group_id',
    LOGO: 'logo',
    EPG_ID: 'epg_id',
    STREAMS: 'streams',
    ORDER: 'order',
    IS_FAVORITE: 'is_favorite',
    IS_LOCKED: 'is_locked',
    PASSWORD: 'password',
    PLAY_COUNT: 'play_count',
    LAST_PLAY_TIME: 'last_play_time',
    LAST_CHECK_TIME: 'last_check_time',
    STATUS: 'status',
    COUNTRY: 'country',
    LANGUAGE: 'language',
    CATEGORY: 'category',
    DESCRIPTION: 'description',
    CURRENT_EPG: 'current_epg',
    NEXT_EPG: 'next_epg',
    SOURCE_KEY: 'source_key',
    CUSTOM_URL: 'custom_url',
    TAGS: 'tags',
    CREATED_AT: 'created_at',
    UPDATED_AT: 'updated_at',
    USER_CONFIG: 'user_config'
  }
};

/**
 * 直播分组表定�? */
export const LIVE_GROUP_TABLE = {
  NAME: 'live_group',
  CREATE_SQL: `
    CREATE TABLE IF NOT EXISTS live_group (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      "order" INTEGER NOT NULL DEFAULT 0,
      icon TEXT,
      channel_count INTEGER DEFAULT 0,
      is_expanded INTEGER DEFAULT 1,
      is_default INTEGER DEFAULT 0,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  `,
  COLUMNS: {
    ID: 'id',
    NAME: 'name',
    ORDER: 'order',
    ICON: 'icon',
    CHANNEL_COUNT: 'channel_count',
    IS_EXPANDED: 'is_expanded',
    IS_DEFAULT: 'is_default',
    CREATED_AT: 'created_at',
    UPDATED_AT: 'updated_at'
  }
};

/**
 * 获取所有表的创建SQL语句
 */
export function getAllTables(): string[] {
  return [
    SITE_TABLE.CREATE_SQL,
    HISTORY_TABLE.CREATE_SQL,
    KEEP_TABLE.CREATE_SQL,
    CONFIG_TABLE.CREATE_SQL,
    KEEP_FOLDER_TABLE.CREATE_SQL,
    SEARCH_HISTORY_TABLE.CREATE_SQL,
    LINE_TABLE.CREATE_SQL,
    SUBSCRIPTION_TABLE.CREATE_SQL,
    LIVE_CHANNEL_TABLE.CREATE_SQL,
    LIVE_GROUP_TABLE.CREATE_SQL
  ];
}

/**
 * 获取所有表�? */
export function getAllTableNames(): string[] {
  return [
    SITE_TABLE.NAME,
    SITE_GROUP_TABLE.NAME,
    HISTORY_TABLE.NAME,
    KEEP_TABLE.NAME,
    CONFIG_TABLE.NAME,
    KEEP_FOLDER_TABLE.NAME,
    SEARCH_HISTORY_TABLE.NAME,
    LINE_TABLE.NAME,
    SUBSCRIPTION_TABLE.NAME,
    LIVE_CHANNEL_TABLE.NAME,
    LIVE_GROUP_TABLE.NAME,
    LIVE_PLAY_HISTORY_TABLE.NAME,
    EPG_TABLE.NAME
  ];
}

/**
 * 索引创建SQL语句
 */
export const INDEXES: Record<string, string | number | boolean | null> = { ... };

/**
 * 数据库版本信�? */
export const DATABASE_INFO: Record<string, string | number | boolean | null> = { ... };
