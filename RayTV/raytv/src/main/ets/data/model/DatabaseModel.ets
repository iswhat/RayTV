// DatabaseModel - 数据库相关类型定义 | Database-related type definitions
// 定义数据库表结构、查询条件等数据类型 | Define data types for database table structures, query conditions, etc.

/**
 * 数据库配置接口 | Database configuration interface
 */
export interface DatabaseConfig {
  /**
   * 数据库名称 | Database name
   */
  name: string;
  
  /**
   * 数据库版本 | Database version
   */
  version: number;
  
  /**
   * 数据库描述 | Database description
   */
  description?: string;
  
  /**
   * 数据库大小限制（字节） | Database size limit (bytes)
   */
  size?: number;
}

/**
 * 数据库支持的值类型 | Database supported value types
 */
export type DatabaseValueType = string | number | boolean | null;

/**
 * 数据库列定义接口 | Database column definition interface
 */
export interface DatabaseColumn {
  /**
   * 列名 | Column name
   */
  name: string;
  
  /**
   * 数据类型 | Data type
   */
  type: string;
  
  /**
   * 是否为主键 | Whether primary key
   */
  primaryKey?: boolean;
  
  /**
   * 是否自增 | Whether auto increment
   */
  autoIncrement?: boolean;
  
  /**
   * 是否唯一 | Whether unique
   */
  unique?: boolean;
  
  /**
   * 是否非空 | Whether not null
   */
  notNull?: boolean;
  
  /**
   * 默认值 | Default value
   */
  defaultValue?: DatabaseValueType;
  
  /**
   * 备注 | Comment
   */
  comment?: string;
}

/**
 * 数据库表定义接口 | Database table definition interface
 */
export interface DatabaseTable {
  /**
   * 表名 | Table name
   */
  name: string;
  
  /**
   * 列定义 | Column definitions
   */
  columns: DatabaseColumn[];
  
  /**
   * 索引定义 | Index definitions
   */
  indexes?: DatabaseIndex[];
  
  /**
   * 外键定义 | Foreign key definitions
   */
  foreignKeys?: DatabaseForeignKey[];
  
  /**
   * 表注释 | Table comment
   */
  comment?: string;
}

/**
 * 数据库索引定义接口 | Database index definition interface
 */
export interface DatabaseIndex {
  /**
   * 索引名称 | Index name
   */
  name: string;
  /**
   * 索引列 | Index columns
   */
  columns: string[];
  /**
   * 是否唯一索引 | Whether unique index
   */
  unique?: boolean;
}

/**
 * 数据库外键定义接口 | Database foreign key definition interface
 */
export interface DatabaseForeignKey {
  /**
   * 外键名称 | Foreign key name
   */
  name: string;
  /**
   * 源表列 | Source table columns
   */
  sourceColumns: string[];
  /**
   * 目标表名 | Target table name
   */
  targetTable: string;
  /**
   * 目标表列 | Target table columns
   */
  targetColumns: string[];
  /**
   * 删除时行为 | On delete action
   */
  onDelete?: ForeignKeyAction;
  /**
   * 更新时行为 | On update action
   */
  onUpdate?: ForeignKeyAction;
}

/**
 * 外键行为枚举 | Foreign key action enum
 */
export enum ForeignKeyAction {
  /**
   * 级联删除/更新 | Cascade delete/update
   */
  CASCADE = 'CASCADE',
  /**
   * 设置为空 | Set null
   */
  SET_NULL = 'SET NULL',
  /**
   * 设置默认值 | Set default
   */
  SET_DEFAULT = 'SET DEFAULT',
  /**
   * 限制操作 | Restrict operation
   */
  RESTRICT = 'RESTRICT',
  /**
   * 无操作 | No action
   */
  NO_ACTION = 'NO ACTION'
}

/**
 * 查询操作符枚举 | Query operator enum
 */
export enum QueryOperator {
  /**
   * 等于 | Equal
   */
  EQUAL = '=',
  /**
   * 不等于 | Not equal
   */
  NOT_EQUAL = '!=',
  /**
   * 大于 | Greater than
   */
  GREATER_THAN = '>',
  /**
   * 大于等于 | Greater than or equal
   */
  GREATER_THAN_OR_EQUAL = '>=',
  /**
   * 小于 | Less than
   */
  LESS_THAN = '<',
  /**
   * 小于等于 | Less than or equal
   */
  LESS_THAN_OR_EQUAL = '<=',
  /**
   * 包含 | Like
   */
  LIKE = 'LIKE',
  /**
   * 不包含 | Not like
   */
  NOT_LIKE = 'NOT LIKE',
  /**
   * 为空 | Is null
   */
  IS_NULL = 'IS NULL',
  /**
   * 不为空 | Is not null
   */
  IS_NOT_NULL = 'IS NOT NULL',
  /**
   * 在范围内 | In
   */
  IN = 'IN',
  /**
   * 不在范围内 | Not in
   */
  NOT_IN = 'NOT IN',
  /**
   * 介于 | Between
   */
  BETWEEN = 'BETWEEN'
}

/**
 * 查询条件接口 | Query condition interface
 */
export interface QueryCondition {
  /**
   * 字段名 | Field name
   */
  field: string;
  /**
   * 操作符 | Operator
   */
  operator: QueryOperator | string;
  /**
   * 值 | Value
   */
  value?: DatabaseValueType | string[] | number[];
  /**
   * 值2（用于BETWEEN等操作符） | Value 2 (for BETWEEN and other operators)
   */
  value2?: DatabaseValueType;
  /**
   * 是否忽略大小写 | Whether ignore case
   */
  ignoreCase?: boolean;
}

/**
 * 排序方式枚举 | Sort order enum
 */
export enum SortOrder {
  /**
   * 升序 | Ascending
   */
  ASC = 'ASC',
  /**
   * 降序 | Descending
   */
  DESC = 'DESC'
}

/**
 * 排序定义接口 | Sort definition interface
 */
export interface SortDefinition {
  /**
   * 排序字段 | Sort field
   */
  field: string;
  /**
   * 排序方式 | Sort order
   */
  order: SortOrder;
}

/**
 * 分页参数接口 | Pagination params interface
 */
export interface PaginationParams {
  /**
   * 页码（从1开始） | Page number (starting from 1)
   */
  page: number;
  /**
   * 每页大小 | Page size
   */
  pageSize: number;
}

/**
 * 分页结果接口 | Pagination result interface
 */
export interface PaginationResult<T> {
  /**
   * 数据列表 | Data list
   */
  list: T[];
  /**
   * 总条数 | Total count
   */
  total: number;
  /**
   * 页码 | Page number
   */
  page: number;
  /**
   * 每页大小 | Page size
   */
  pageSize: number;
  /**
   * 总页数 | Total pages
   */
  totalPages: number;
}

/**
 * 批量操作结果接口 | Batch operation result interface
 */
export interface BatchOperationResult {
  /**
   * 成功数量 | Success count
   */
  successCount: number;
  /**
   * 失败数量 | Failed count
   */
  failedCount: number;
  /**
   * 失败索引 | Failed indexes
   */
  failedIndexes: number[];
  /**
   * 失败原因 | Failed reasons
   */
  failedReasons?: string[];
}

/**
 * 数据库迁移定义接口 | Database migration definition interface
 */
export interface Migration {
  /**
   * 源版本 | Source version
   */
  fromVersion: number;
  /**
   * 目标版本 | Target version
   */
  toVersion: number;
  /**
   * 迁移操作 | Migration operation
   */
  migrate: () => Promise<void>;
}

/**
 * 数据库事务类型枚举 | Database transaction type enum
 */
export enum TransactionType {
  /**
   * 只读事务 | Read-only transaction
   */
  READ_ONLY = 'READ_ONLY',
  /**
   * 读写事务 | Read-write transaction
   */
  READ_WRITE = 'READ_WRITE'
}

/**
 * 数据库事务接口 | Database transaction interface
 */
export interface Transaction {
  /**
   * 执行SQL语句 | Execute SQL statement
   * @param sql SQL语句 | SQL statement
   * @param params 参数 | Parameters
   * @returns 执行结果 | Execution result
   */
  executeSql(sql: string, params?: (DatabaseValueType)[]): Promise<Object>;
  /**
   * 提交事务 | Commit transaction
   */
  commit(): Promise<void>;
  /**
   * 回滚事务 | Rollback transaction
   */
  rollback(): Promise<void>;
}

/**
 * 数据模型接口（所有具体类型的父类） | Data model interface (parent of all specific types)
 */
export interface BaseModel {
  /**
   * 唯一标识 | Unique identifier
   */
  id?: number;
  /**
   * 创建时间 | Creation time
   */
  createdAt?: number;
  /**
   * 更新时间 | Update time
   */
  updatedAt?: number;
}

/**
 * 用户模型接口 | User model interface
 */
export interface UserModel extends BaseModel {
  /**
   * 用户名 | Username
   */
  username: string;
  /**
   * 邮箱 | Email
   */
  email?: string;
  /**
   * 头像 | Avatar
   */
  avatar?: string;
  /**
   * 最后登录时间 | Last login time
   */
  lastLoginAt?: number;
  /**
   * 用户状态 | User status
   */
  status?: UserStatus;
}

/**
 * 用户状态枚举 | User status enum
 */
export enum UserStatus {
  /**
   * 活跃 | Active
   */
  ACTIVE = 'ACTIVE',
  /**
   * 禁用 | Disabled
   */
  DISABLED = 'DISABLED',
  /**
   * 待验证 | Pending
   */
  PENDING = 'PENDING'
}

/**
 * 历史记录模型接口 | History model interface
 */
export interface HistoryModel extends BaseModel {
  /**
   * 媒体ID | Media ID
   */
  mediaId: string;
  /**
   * 标题 | Title
   */
  title: string;
  /**
   * 海报 | Poster
   */
  poster?: string;
  /**
   * 进度 | Progress
   */
  progress: number;
  /**
   * 总时长 | Duration
   */
  duration: number;
  /**
   * 媒体类型 | Media type
   */
  mediaType: MediaType;
  /**
   * 剧集信息 | Episode info
   */
  episode?: string;
  /**
   * 用户ID | User ID
   */
  userId?: number;
}

/**
 * 媒体类型枚举 | Media type enum
 */
export enum MediaType {
  /**
   * 电影 | Movie
   */
  MOVIE = 'MOVIE',
  /**
   * 电视剧 | TV series
   */
  TV_SERIES = 'TV_SERIES',
  /**
   * 综艺 | Variety show
   */
  VARIETY = 'VARIETY',
  /**
   * 动漫 | Anime
   */
  ANIME = 'ANIME',
  /**
   * 纪录片 | Documentary
   */
  DOCUMENTARY = 'DOCUMENTARY',
  /**
   * 直播 | Live
   */
  LIVE = 'LIVE',
  /**
   * 其他 | Other
   */
  OTHER = 'OTHER'
}

/**
 * 收藏模型接口 | Collection model interface
 */
export interface CollectionModel extends BaseModel {
  /**
   * 媒体ID | Media ID
   */
  mediaId: string;
  /**
   * 标题 | Title
   */
  title: string;
  /**
   * 海报 | Poster
   */
  poster?: string;
  /**
   * 分类 | Category
   */
  category?: string;
  /**
   * 评分 | Rating
   */
  rating?: number;
  /**
   * 媒体类型 | Media type
   */
  mediaType: MediaType;
  /**
   * 备注 | Note
   */
  note?: string;
  /**
   * 用户ID | User ID
   */
  userId?: number;
}

/**
 * 下载任务模型接口 | Download task model interface
 */
export interface DownloadTaskModel extends BaseModel {
  /**
   * 任务ID | Task ID
   */
  taskId: string;
  /**
   * 标题 | Title
   */
  title: string;
  /**
   * 下载URL | Download URL
   */
  url: string;
  /**
   * 保存路径 | Save path
   */
  savePath: string;
  /**
   * 总大小 | Total size
   */
  totalSize: number;
  /**
   * 已下载大小 | Downloaded size
   */
  downloadedSize: number;
  /**
   * 状态 | Status
   */
  status: DownloadStatus;
  /**
   * 错误信息 | Error message
   */
  errorMessage?: string;
  /**
   * 媒体类型 | Media type
   */
  mediaType?: MediaType;
  /**
   * 优先级 | Priority
   */
  priority: number;
}

/**
 * 下载状态枚举 | Download status enum
 */
export enum DownloadStatus {
  /**
   * 等待中 | Waiting
   */
  WAITING = 'WAITING',
  /**
   * 下载中 | Downloading
   */
  DOWNLOADING = 'DOWNLOADING',
  /**
   * 暂停 | Paused
   */
  PAUSED = 'PAUSED',
  /**
   * 完成 | Completed
   */
  COMPLETED = 'COMPLETED',
  /**
   * 失败 | Failed
   */
  FAILED = 'FAILED',
  /**
   * 取消 | Cancelled
   */
  CANCELLED = 'CANCELLED'
}

/**
 * 直播频道模型接口 | Live channel model interface
 */
export interface LiveChannelModel extends BaseModel {
  /**
   * 频道ID | Channel ID
   */
  channelId: string;
  /**
   * 频道名称 | Channel name
   */
  name: string;
  /**
   * 频道Logo | Channel logo
   */
  logo?: string;
  /**
   * 播放URL | Playback URL
   */
  url: string;
  /**
   * 分类 | Category
   */
  category: string;
  /**
   * 是否收藏 | Whether favorite
   */
  isFavorite: boolean;
  /**
   * 排序 | Sort order
   */
  sortOrder: number;
  /**
   * 国家/地区 | Country/Region
   */
  country?: string;
  /**
   * 语言 | Language
   */
  language?: string;
}

/**
 * 配置项模型接口 | Config item model interface
 */
export interface ConfigItemModel extends BaseModel {
  /**
   * 配置键 | Config key
   */
  key: string;
  /**
   * 配置值 | Config value
   */
  value: string;
  /**
   * 值类型 | Value type
   */
  type: string;
  /**
   * 分类 | Category
   */
  category: string;
  /**
   * 描述 | Description
   */
  description?: string;
}
