// DatabaseModel - 数据库相关模型定�?// 定义数据库表结构、查询条件等数据模型

/**
 * 数据库配置接�? */
export interface DatabaseConfig {
  /**
   * 数据库名�?   */
  name: string;
  
  /**
   * 数据库版�?   */
  version: number;
  
  /**
   * 数据库描�?   */
  description?: string;
  
  /**
   * 数据库大小限制（字节�?   */
  size?: number;
}

/**
 * 数据库列定义接口
 */
/**
 * 数据库支持的值类�? */
export type DatabaseValueType = string | number | boolean | null;

export interface DatabaseColumn {
  /**
   * 列名
   */
  name: string;
  
  /**
   * 数据类型
   */
  type: string;
  
  /**
   * 是否为主�?   */
  primaryKey?: boolean;
  
  /**
   * 是否自增
   */
  autoIncrement?: boolean;
  
  /**
   * 是否唯一
   */
  unique?: boolean;
  
  /**
   * 是否非空
   */
  notNull?: boolean;
  
  /**
   * 默认�?   */
  defaultValue?: DatabaseValueType;
  
  /**
   * 注释
   */
  comment?: string;
}

/**
 * 数据库表定义接口
 */
export interface DatabaseTable {
  /**
   * 表名
   */
  name: string;
  
  /**
   * 列定�?   */
  columns: DatabaseColumn[];
  
  /**
   * 索引定义
   */
  indexes?: DatabaseIndex[];
  
  /**
   * 外键定义
   */
  foreignKeys?: DatabaseForeignKey[];
  
  /**
   * 表注�?   */
  comment?: string;
}

/**
 * 数据库索引定义接�? */
export interface DatabaseIndex {
  /**
   * 索引名称
   */
  name: string;
  /**
   * 索引字段
   */
  columns: string[];
  /**
   * 是否唯一索引
   */
  unique?: boolean;
}

/**
 * 数据库外键定义接�? */
export interface DatabaseForeignKey {
  /**
   * 外键名称
   */
  name: string;
  /**
   * 源表字段
   */
  sourceColumns: string[];
  /**
   * 目标表名
   */
  targetTable: string;
  /**
   * 目标表字�?   */
  targetColumns: string[];
  /**
   * 删除时行�?   */
  onDelete?: ForeignKeyAction;
  /**
   * 更新时行�?   */
  onUpdate?: ForeignKeyAction;
}

/**
 * 外键动作枚举
 */
export enum ForeignKeyAction {
  /**
   * 级联删除/更新
   */
  CASCADE = 'CASCADE',
  /**
   * 设置为空
   */
  SET_NULL = 'SET NULL',
  /**
   * 设置默认�?   */
  SET_DEFAULT = 'SET DEFAULT',
  /**
   * 限制操作
   */
  RESTRICT = 'RESTRICT',
  /**
   * 无操�?   */
  NO_ACTION = 'NO ACTION'
}

/**
 * 查询操作符枚�? */
export enum QueryOperator {
  /**
   * 等于
   */
  EQUAL = '=',
  /**
   * 不等�?   */
  NOT_EQUAL = '!=',
  /**
   * 大于
   */
  GREATER_THAN = '>',
  /**
   * 大于等于
   */
  GREATER_THAN_OR_EQUAL = '>=',
  /**
   * 小于
   */
  LESS_THAN = '<',
  /**
   * 小于等于
   */
  LESS_THAN_OR_EQUAL = '<=',
  /**
   * 包含
   */
  LIKE = 'LIKE',
  /**
   * 不包�?   */
  NOT_LIKE = 'NOT LIKE',
  /**
   * 为空
   */
  IS_NULL = 'IS NULL',
  /**
   * 不为�?   */
  IS_NOT_NULL = 'IS NOT NULL',
  /**
   * 在范围内
   */
  IN = 'IN',
  /**
   * 不在范围�?   */
  NOT_IN = 'NOT IN',
  /**
   * 介于
   */
  BETWEEN = 'BETWEEN'
}

/**
 * 查询条件接口
 */
export interface QueryCondition {
  /**
   * 字段�?   */
  field: string;
  /**
   * 操作�?   */
  operator: QueryOperator | string;
  /**
   * �?   */
  value?: DatabaseValueType | string[] | number[];
  /**
   * �?（用于BETWEEN等操作符�?   */
  value2?: DatabaseValueType;
  /**
   * 是否忽略大小�?   */
  ignoreCase?: boolean;
}

/**
 * 排序方式枚举
 */
export enum SortOrder {
  /**
   * 升序
   */
  ASC = 'ASC',
  /**
   * 降序
   */
  DESC = 'DESC'
}

/**
 * 排序定义接口
 */
export interface SortDefinition {
  /**
   * 排序字段
   */
  field: string;
  /**
   * 排序方式
   */
  order: SortOrder;
}

/**
 * 分页参数接口
 */
export interface PaginationParams {
  /**
   * 页码（从1开始）
   */
  page: number;
  /**
   * 每页大小
   */
  pageSize: number;
}

/**
 * 分页结果接口
 */
export interface PaginationResult<T> {
  /**
   * 数据列表
   */
  list: T[];
  /**
   * 总条�?   */
  total: number;
  /**
   * 页码
   */
  page: number;
  /**
   * 每页大小
   */
  pageSize: number;
  /**
   * 总页�?   */
  totalPages: number;
}

/**
 * 批量操作结果接口
 */
export interface BatchOperationResult {
  /**
   * 成功数量
   */
  successCount: number;
  /**
   * 失败数量
   */
  failedCount: number;
  /**
   * 失败项索�?   */
  failedIndexes: number[];
  /**
   * 失败原因
   */
  failedReasons?: string[];
}

/**
 * 数据库迁移定义接�? */
export interface Migration {
  /**
   * 源版�?   */
  fromVersion: number;
  /**
   * 目标版本
   */
  toVersion: number;
  /**
   * 迁移操作
   */
  migrate: () => Promise<void>;
}

/**
 * 数据库事务类型枚�? */
export enum TransactionType {
  /**
   * 只读事务
   */
  READ_ONLY = 'READ_ONLY',
  /**
   * 读写事务
   */
  READ_WRITE = 'READ_WRITE'
}

/**
 * 数据库事务接�? */
export interface Transaction {
  /**
   * 执行SQL语句
   * @param sql SQL语句
   * @param params 参数
   * @returns 执行结果
   */
  executeSql(sql: string, params?: (DatabaseValueType)[]): Promise<Object>;
  /**
   * 提交事务
   */
  commit(): Promise<void>;
  /**
   * 回滚事务
   */
  rollback(): Promise<void>;
}

/**
 * 数据模型接口（所有实体模型的基类�? */
export interface BaseModel {
  /**
   * 唯一标识
   */
  id?: number;
  /**
   * 创建时间
   */
  createdAt?: number;
  /**
   * 更新时间
   */
  updatedAt?: number;
}

/**
 * 用户模型接口
 */
export interface UserModel extends BaseModel {
  /**
   * 用户�?   */
  username: string;
  /**
   * 邮箱
   */
  email?: string;
  /**
   * 头像
   */
  avatar?: string;
  /**
   * 最后登录时�?   */
  lastLoginAt?: number;
  /**
   * 用户状�?   */
  status?: UserStatus;
}

/**
 * 用户状态枚�? */
export enum UserStatus {
  /**
   * 活跃
   */
  ACTIVE = 'ACTIVE',
  /**
   * 禁用
   */
  DISABLED = 'DISABLED',
  /**
   * 待验�?   */
  PENDING = 'PENDING'
}

/**
 * 历史记录模型接口
 */
export interface HistoryModel extends BaseModel {
  /**
   * 媒体ID
   */
  mediaId: string;
  /**
   * 标题
   */
  title: string;
  /**
   * 海报
   */
  poster?: string;
  /**
   * 进度
   */
  progress: number;
  /**
   * 总时�?   */
  duration: number;
  /**
   * 媒体类型
   */
  mediaType: MediaType;
  /**
   * 剧集信息
   */
  episode?: string;
  /**
   * 用户ID
   */
  userId?: number;
}

/**
 * 媒体类型枚举
 */
export enum MediaType {
  /**
   * 电影
   */
  MOVIE = 'MOVIE',
  /**
   * 电视�?   */
  TV_SERIES = 'TV_SERIES',
  /**
   * 综艺
   */
  VARIETY = 'VARIETY',
  /**
   * 动漫
   */
  ANIME = 'ANIME',
  /**
   * 纪录�?   */
  DOCUMENTARY = 'DOCUMENTARY',
  /**
   * 直播
   */
  LIVE = 'LIVE',
  /**
   * 其他
   */
  OTHER = 'OTHER'
}

/**
 * 收藏模型接口
 */
export interface CollectionModel extends BaseModel {
  /**
   * 媒体ID
   */
  mediaId: string;
  /**
   * 标题
   */
  title: string;
  /**
   * 海报
   */
  poster?: string;
  /**
   * 分类
   */
  category?: string;
  /**
   * 评分
   */
  rating?: number;
  /**
   * 媒体类型
   */
  mediaType: MediaType;
  /**
   * 备注
   */
  note?: string;
  /**
   * 用户ID
   */
  userId?: number;
}

/**
 * 下载任务模型接口
 */
export interface DownloadTaskModel extends BaseModel {
  /**
   * 任务ID
   */
  taskId: string;
  /**
   * 标题
   */
  title: string;
  /**
   * 下载URL
   */
  url: string;
  /**
   * 保存路径
   */
  savePath: string;
  /**
   * 总大�?   */
  totalSize: number;
  /**
   * 已下载大�?   */
  downloadedSize: number;
  /**
   * 状�?   */
  status: DownloadStatus;
  /**
   * 错误信息
   */
  errorMessage?: string;
  /**
   * 媒体类型
   */
  mediaType?: MediaType;
  /**
   * 优先�?   */
  priority: number;
}

/**
 * 下载状态枚�? */
export enum DownloadStatus {
  /**
   * 等待�?   */
  WAITING = 'WAITING',
  /**
   * 下载�?   */
  DOWNLOADING = 'DOWNLOADING',
  /**
   * 暂停
   */
  PAUSED = 'PAUSED',
  /**
   * 完成
   */
  COMPLETED = 'COMPLETED',
  /**
   * 失败
   */
  FAILED = 'FAILED',
  /**
   * 取消
   */
  CANCELLED = 'CANCELLED'
}

/**
 * 直播频道模型接口
 */
export interface LiveChannelModel extends BaseModel {
  /**
   * 频道ID
   */
  channelId: string;
  /**
   * 频道名称
   */
  name: string;
  /**
   * 频道Logo
   */
  logo?: string;
  /**
   * 播放URL
   */
  url: string;
  /**
   * 分类
   */
  category: string;
  /**
   * 是否收藏
   */
  isFavorite: boolean;
  /**
   * 排序
   */
  sortOrder: number;
  /**
   * 国家/地区
   */
  country?: string;
  /**
   * 语言
   */
  language?: string;
}

/**
 * 配置项模型接�? */
export interface ConfigItemModel extends BaseModel {
  /**
   * 配置�?   */
  key: string;
  /**
   * 配置�?   */
  value: string;
  /**
   * 值类�?   */
  type: string;
  /**
   * 分类
   */
  category: string;
  /**
   * 描述
   */
  description?: string;
}
