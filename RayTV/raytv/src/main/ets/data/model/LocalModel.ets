// LocalModel - 本地存储相关模型定义
// 定义本地文件、存储等相关的数据模�?
/**
 * 本地存储类型枚举
 */
export enum LocalStorageType {
  /**
   * 默认存储
   */
  DEFAULT = 'default',
  
  /**
   * 临时存储
   */
  TEMPORARY = 'temporary',
  
  /**
   * 安全存储
   */
  SECURE = 'secure',
  
  /**
   * 持久化存�?   */
  PERSISTENT = 'persistent'
}

/**
 * 文件类型枚举
 */
export enum FileType {
  /**
   * 视频文件
   */
  VIDEO = 'video',
  
  /**
   * 音频文件
   */
  AUDIO = 'audio',
  
  /**
   * 图片文件
   */
  IMAGE = 'image',
  
  /**
   * 文本文件
   */
  TEXT = 'text',
  
  /**
   * JSON文件
   */
  JSON = 'json',
  
  /**
   * 字幕文件
   */
  SUBTITLE = 'subtitle',
  
  /**
   * 压缩文件
   */
  ARCHIVE = 'archive',
  
  /**
   * 其他文件
   */
  OTHER = 'other'
}

/**
 * 文件格式枚举
 */
export enum FileFormat {
  // 视频格式
  MP4 = 'mp4',
  MKV = 'mkv',
  AVI = 'avi',
  MOV = 'mov',
  FLV = 'flv',
  WMV = 'wmv',
  WEBM = 'webm',
  RMVB = 'rmvb',
  
  // 音频格式
  MP3 = 'mp3',
  WAV = 'wav',
  FLAC = 'flac',
  AAC = 'aac',
  OGG = 'ogg',
  WMA = 'wma',
  
  // 图片格式
  JPG = 'jpg',
  JPEG = 'jpeg',
  PNG = 'png',
  GIF = 'gif',
  WEBP = 'webp',
  SVG = 'svg',
  BMP = 'bmp',
  
  // 文本格式
  TXT = 'txt',
  LOG = 'log',
  MD = 'md',
  HTML = 'html',
  XML = 'xml',
  
  // 字幕格式
  SRT = 'srt',
  VTT = 'vtt',
  ASS = 'ass',
  SSA = 'ssa',
  SUB = 'sub',
  
  // 压缩格式
  ZIP = 'zip',
  RAR = 'rar',
  7Z = '7z',
  TAR = 'tar',
  GZ = 'gz',
  BZ2 = 'bz2',
  
  // 其他格式
  JSON = 'json',
  PDF = 'pdf',
  EXE = 'exe',
  APK = 'apk'
}

/**
 * 存储位置枚举
 */
export enum StorageLocation {
  /**
   * 应用内部存储
   */
  INTERNAL = 'internal',
  
  /**
   * 应用外部存储
   */
  EXTERNAL = 'external',
  
  /**
   * SD卡存�?   */
  SD_CARD = 'sd_card',
  
  /**
   * 临时存储
   */
  TEMP = 'temp',
  
  /**
   * 缓存目录
   */
  CACHE = 'cache'
}

/**
 * 文件元数据接�? */
export interface FileMetadata {
  /**
   * 文件路径
   */
  path: string;
  
  /**
   * 文件�?   */
  name: string;
  
  /**
   * 文件大小（字节）
   */
  size: number;
  
  /**
   * 修改时间（时间戳�?   */
  modifiedAt: number;
  
  /**
   * 创建时间（时间戳�?   */
  createdAt?: number;
  
  /**
   * 是否为目�?   */
  isDirectory: boolean;
  
  /**
   * 文件类型
   */
  fileType?: FileType;
  
  /**
   * 文件格式
   */
  fileFormat?: FileFormat;
  
  /**
   * 文件扩展�?   */
  extension?: string;
  
  /**
   * MIME类型
   */
  mimeType?: string;
  
  /**
   * 存储位置
   */
  storageLocation?: StorageLocation;
  
  /**
   * 文件权限
   */
  permissions?: string;
  
  /**
   * 校验和（MD5�?   */
  md5?: string;
}

/**
 * 目录信息接口
 */
export interface DirectoryInfo {
  /**
   * 目录路径
   */
  path: string;
  
  /**
   * 目录名称
   */
  name: string;
  
  /**
   * 子文件数�?   */
  fileCount: number;
  
  /**
   * 子目录数�?   */
  directoryCount: number;
  
  /**
   * 总大小（字节�?   */
  totalSize: number;
  
  /**
   * 修改时间
   */
  modifiedAt: number;
  
  /**
   * 存储位置
   */
  storageLocation?: StorageLocation;
}

/**
 * 存储设备信息接口
 */
export interface StorageDevice {
  /**
   * 设备ID
   */
  id: string;
  
  /**
   * 设备名称
   */
  name: string;
  
  /**
   * 挂载路径
   */
  mountPath: string;
  
  /**
   * 总空间（字节�?   */
  totalSpace: number;
  
  /**
   * 可用空间（字节）
   */
  availableSpace: number;
  
  /**
   * 设备类型
   */
  type: StorageDeviceType;
  
  /**
   * 是否可移�?   */
  removable: boolean;
  
  /**
   * 是否只读
   */
  readOnly: boolean;
  
  /**
   * 文件系统类型
   */
  fileSystemType?: string;
}

/**
 * 存储设备类型枚举
 */
export enum StorageDeviceType {
  /**
   * 内部存储
   */
  INTERNAL = 'internal',
  
  /**
   * SD�?   */
  SD_CARD = 'sd_card',
  
  /**
   * USB存储
   */
  USB = 'usb',
  
  /**
   * 网络存储
   */
  NETWORK = 'network',
  
  /**
   * 其他存储
   */
  OTHER = 'other'
}

/**
 * 文件搜索参数接口
 */
export interface FileSearchParams {
  /**
   * 搜索路径
   */
  searchPath: string;
  
  /**
   * 搜索关键�?   */
  keyword?: string;
  
  /**
   * 文件类型过滤
   */
  fileTypes?: FileType[];
  
  /**
   * 文件格式过滤
   */
  fileFormats?: FileFormat[];
  
  /**
   * 是否递归搜索子目�?   */
  recursive?: boolean;
  
  /**
   * 最小文件大小（字节�?   */
  minSize?: number;
  
  /**
   * 最大文件大小（字节�?   */
  maxSize?: number;
  
  /**
   * 修改时间范围（开始）
   */
  modifiedAfter?: number;
  
  /**
   * 修改时间范围（结束）
   */
  modifiedBefore?: number;
  
  /**
   * 排序字段
   */
  sortBy?: 'name' | 'size' | 'modifiedAt' | 'createdAt';
  
  /**
   * 排序方式
   */
  sortOrder?: 'asc' | 'desc';
  
  /**
   * 分页大小
   */
  limit?: number;
  
  /**
   * 分页偏移
   */
  offset?: number;
}

/**
 * 文件搜索结果接口
 */
export interface FileSearchResult {
  /**
   * 文件列表
   */
  files: FileMetadata[];
  
  /**
   * 目录列表
   */
  directories: DirectoryInfo[];
  
  /**
   * 总结果数
   */
  totalCount: number;
  
  /**
   * 是否还有更多结果
   */
  hasMore: boolean;
}

/**
 * 文件操作类型枚举
 */
export enum FileOperationType {
  /**
   * 复制
   */
  COPY = 'copy',
  
  /**
   * 移动
   */
  MOVE = 'move',
  
  /**
   * 删除
   */
  DELETE = 'delete',
  
  /**
   * 重命�?   */
  RENAME = 'rename',
  
  /**
   * 创建
   */
  CREATE = 'create',
  
  /**
   * 解压
   */
  EXTRACT = 'extract',
  
  /**
   * 压缩
   */
  COMPRESS = 'compress'
}

/**
 * 文件操作结果接口
 */
export interface FileOperationResult {
  /**
   * 是否成功
   */
  success: boolean;
  
  /**
   * 操作类型
   */
  operationType: FileOperationType;
  
  /**
   * 源文件路�?   */
  sourcePath?: string;
  
  /**
   * 目标文件路径
   */
  targetPath?: string;
  
  /**
   * 错误信息
   */
  errorMessage?: string;
  
  /**
   * 操作时间
   */
  timestamp: number;
}

/**
 * 文件监控事件类型枚举
 */
export enum FileMonitorEventType {
  /**
   * 文件创建
   */
  CREATED = 'created',
  
  /**
   * 文件修改
   */
  MODIFIED = 'modified',
  
  /**
   * 文件删除
   */
  DELETED = 'deleted',
  
  /**
   * 文件移动
   */
  MOVED = 'moved',
  
  /**
   * 目录创建
   */
  DIRECTORY_CREATED = 'directory_created',
  
  /**
   * 目录删除
   */
  DIRECTORY_DELETED = 'directory_deleted',
  
  /**
   * 目录移动
   */
  DIRECTORY_MOVED = 'directory_moved'
}

/**
 * 文件监控事件接口
 */
export interface FileMonitorEvent {
  /**
   * 事件类型
   */
  type: FileMonitorEventType;
  
  /**
   * 文件路径
   */
  path: string;
  
  /**
   * 旧文件路径（用于移动事件�?   */
  oldPath?: string;
  
  /**
   * 事件时间�?   */
  timestamp: number;
}

/**
 * 文件清理策略枚举
 */
export enum FileCleanupStrategy {
  /**
   * 按文件大�?   */
  BY_SIZE = 'by_size',
  
  /**
   * 按文件时�?   */
  BY_TIME = 'by_time',
  
  /**
   * 按文件类�?   */
  BY_TYPE = 'by_type',
  
  /**
   * 全部清理
   */
  ALL = 'all'
}

/**
 * 文件清理配置接口
 */
export interface FileCleanupConfig {
  /**
   * 清理策略
   */
  strategy: FileCleanupStrategy;
  
  /**
   * 目标目录
   */
  targetDir: string;
  
  /**
   * 最大文件大小（字节�?   */
  maxFileSize?: number;
  
  /**
   * 最旧文件时间（时间戳）
   */
  oldestFileTime?: number;
  
  /**
   * 要清理的文件类型
   */
  fileTypes?: FileType[];
  
  /**
   * 保留最新的文件数量
   */
  keepLatestCount?: number;
  
  /**
   * 是否递归清理子目�?   */
  recursive: boolean;
  
  /**
   * 是否预览（不实际删除�?   */
  previewOnly: boolean;
}

/**
 * 文件清理结果接口
 */
export interface FileCleanupResult {
  /**
   * 已清理的文件数量
   */
  filesCleaned: number;
  
  /**
   * 已清理的目录数量
   */
  directoriesCleaned: number;
  
  /**
   * 释放的空间（字节�?   */
  spaceFreed: number;
  
  /**
   * 清理失败的文�?   */
  failedFiles: string[];
  
  /**
   * 清理时间（毫秒）
   */
  cleanupTime: number;
  
  /**
   * 是否预览模式
   */
  isPreview: boolean;
}

/**
 * 本地存储配置接口
 */
export interface LocalStorageConfig {
  /**
   * 缓存目录
   */
  cacheDir: string;
  
  /**
   * 下载目录
   */
  downloadDir: string;
  
  /**
   * 字幕目录
   */
  subtitleDir: string;
  
  /**
   * 用户数据目录
   */
  userDataDir: string;
  
  /**
   * 临时目录
   */
  tempDir: string;
  
  /**
   * 最大缓存大小（字节�?   */
  maxCacheSize: number;
  
  /**
   * 自动清理缓存的时间间隔（毫秒�?   */
  autoCleanupInterval: number;
  
  /**
   * 是否启用文件监控
   */
  enableFileMonitoring: boolean;
}

/**
 * 本地文件图标接口
 */
export interface FileIcon {
  /**
   * 文件类型
   */
  fileType: FileType;
  /**
   * 文件格式
   */
  fileFormat?: FileFormat;
  /**
   * 图标资源ID
   */
  iconResourceId: string;
  /**
   * 自定义图标路�?   */
  customIconPath?: string;
}

/**
 * MIME类型映射接口
 */
export interface MimeTypeMap {
  /**
   * 文件格式
   */
  format: FileFormat;
  /**
   * MIME类型
   */
  mimeType: string;
  /**
   * 描述
   */
  description: string;
}
