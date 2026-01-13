// LocalModel - 本地存储相关类型定义 | Local storage related type definitions
// 定义本地文件、存储等相关的数据类型 | Define data types related to local files and storage

/**
 * 本地存储类型枚举 | Local storage type enum
 */
export enum LocalStorageType {
  /**
   * 默认存储 | Default storage
   */
  DEFAULT = 'default',
  
  /**
   * 临时存储 | Temporary storage
   */
  TEMPORARY = 'temporary',
  
  /**
   * 安全存储 | Secure storage
   */
  SECURE = 'secure',
  
  /**
   * 持久化存储 | Persistent storage
   */
  PERSISTENT = 'persistent'
}

/**
 * 文件类型枚举 | File type enum
 */
export enum FileType {
  /**
   * 视频文件 | Video file
   */
  VIDEO = 'video',
  
  /**
   * 音频文件 | Audio file
   */
  AUDIO = 'audio',
  
  /**
   * 图片文件 | Image file
   */
  IMAGE = 'image',
  
  /**
   * 文本文件 | Text file
   */
  TEXT = 'text',
  
  /**
   * JSON文件 | JSON file
   */
  JSON = 'json',
  
  /**
   * 字幕文件 | Subtitle file
   */
  SUBTITLE = 'subtitle',
  
  /**
   * 压缩文件 | Archive file
   */
  ARCHIVE = 'archive',
  
  /**
   * 其他文件 | Other file
   */
  OTHER = 'other'
}

/**
 * 文件格式枚举 | File format enum
 */
export enum FileFormat {
  // 视频格式 | Video formats
  MP4 = 'mp4',
  MKV = 'mkv',
  AVI = 'avi',
  MOV = 'mov',
  FLV = 'flv',
  WMV = 'wmv',
  WEBM = 'webm',
  RMVB = 'rmvb',
  
  // 音频格式 | Audio formats
  MP3 = 'mp3',
  WAV = 'wav',
  FLAC = 'flac',
  AAC = 'aac',
  OGG = 'ogg',
  WMA = 'wma',
  
  // 图片格式 | Image formats
  JPG = 'jpg',
  JPEG = 'jpeg',
  PNG = 'png',
  GIF = 'gif',
  WEBP = 'webp',
  SVG = 'svg',
  BMP = 'bmp',
  
  // 文本格式 | Text formats
  TXT = 'txt',
  LOG = 'log',
  MD = 'md',
  HTML = 'html',
  XML = 'xml',
  
  // 字幕格式 | Subtitle formats
  SRT = 'srt',
  VTT = 'vtt',
  ASS = 'ass',
  SSA = 'ssa',
  SUB = 'sub',
  
  // 压缩格式 | Archive formats
  ZIP = 'zip',
  RAR = 'rar',
  SEVEN_Z = '7z',
  TAR = 'tar',
  GZ = 'gz',
  BZ2 = 'bz2',
  
  // 其他格式 | Other formats
  JSON = 'json',
  PDF = 'pdf',
  EXE = 'exe',
  APK = 'apk'
}

/**
 * 存储位置枚举 | Storage location enum
 */
export enum StorageLocation {
  /**
   * 应用内部存储 | App internal storage
   */
  INTERNAL = 'internal',
  
  /**
   * 应用外部存储 | App external storage
   */
  EXTERNAL = 'external',
  
  /**
   * SD卡存储 | SD card storage
   */
  SD_CARD = 'sd_card',
  
  /**
   * 临时存储 | Temporary storage
   */
  TEMP = 'temp',
  
  /**
   * 缓存目录 | Cache directory
   */
  CACHE = 'cache'
}

/**
 * 文件元数据接口 | File metadata interface
 */
export interface FileMetadata {
  /**
   * 文件路径 | File path
   */
  path: string;
  
  /**
   * 文件名 | File name
   */
  name: string;
  
  /**
   * 文件大小（字节） | File size (bytes)
   */
  size: number;
  
  /**
   * 修改时间（时间戳） | Modified time (timestamp)
   */
  modifiedAt: number;
  
  /**
   * 创建时间（时间戳） | Creation time (timestamp)
   */
  createdAt?: number;
  
  /**
   * 是否为目录 | Whether directory
   */
  isDirectory: boolean;
  
  /**
   * 文件类型 | File type
   */
  fileType?: FileType;
  
  /**
   * 文件格式 | File format
   */
  fileFormat?: FileFormat;
  
  /**
   * 文件扩展名 | File extension
   */
  extension?: string;
  
  /**
   * MIME类型 | MIME type
   */
  mimeType?: string;
  
  /**
   * 存储位置 | Storage location
   */
  storageLocation?: StorageLocation;
  
  /**
   * 文件权限 | File permissions
   */
  permissions?: string;
  
  /**
   * 校验和（MD5） | Checksum (MD5)
   */
  md5?: string;
}

/**
 * 目录信息接口 | Directory info interface
 */
export interface DirectoryInfo {
  /**
   * 目录路径 | Directory path
   */
  path: string;
  
  /**
   * 目录名称 | Directory name
   */
  name: string;
  
  /**
   * 子文件数量 | Subfile count
   */
  fileCount: number;
  
  /**
   * 子目录数量 | Subdirectory count
   */
  directoryCount: number;
  
  /**
   * 总大小（字节） | Total size (bytes)
   */
  totalSize: number;
  
  /**
   * 修改时间 | Modified time
   */
  modifiedAt: number;
  
  /**
   * 存储位置 | Storage location
   */
  storageLocation?: StorageLocation;
}

/**
 * 存储设备信息接口 | Storage device info interface
 */
export interface StorageDevice {
  /**
   * 设备ID | Device ID
   */
  id: string;
  
  /**
   * 设备名称 | Device name
   */
  name: string;
  
  /**
   * 挂载路径 | Mount path
   */
  mountPath: string;
  
  /**
   * 总空间（字节） | Total space (bytes)
   */
  totalSpace: number;
  
  /**
   * 可用空间（字节） | Available space (bytes)
   */
  availableSpace: number;
  
  /**
   * 设备类型 | Device type
   */
  type: StorageDeviceType;
  
  /**
   * 是否可移动 | Whether removable
   */
  removable: boolean;
  
  /**
   * 是否只读 | Whether read-only
   */
  readOnly: boolean;
  
  /**
   * 文件系统类型 | File system type
   */
  fileSystemType?: string;
}

/**
 * 存储设备类型枚举 | Storage device type enum
 */
export enum StorageDeviceType {
  /**
   * 内部存储 | Internal storage
   */
  INTERNAL = 'internal',
  
  /**
   * SD卡 | SD card
   */
  SD_CARD = 'sd_card',
  
  /**
   * USB存储 | USB storage
   */
  USB = 'usb',
  
  /**
   * 网络存储 | Network storage
   */
  NETWORK = 'network',
  
  /**
   * 其他存储 | Other storage
   */
  OTHER = 'other'
}

/**
 * 文件搜索参数接口 | File search params interface
 */
export interface FileSearchParams {
  /**
   * 搜索路径 | Search path
   */
  searchPath: string;
  
  /**
   * 搜索关键词 | Search keyword
   */
  keyword?: string;
  
  /**
   * 文件类型过滤 | File type filter
   */
  fileTypes?: FileType[];
  
  /**
   * 文件格式过滤 | File format filter
   */
  fileFormats?: FileFormat[];
  
  /**
   * 是否递归搜索子目录 | Whether recursive search subdirectories
   */
  recursive?: boolean;
  
  /**
   * 最小文件大小（字节） | Minimum file size (bytes)
   */
  minSize?: number;
  
  /**
   * 最大文件大小（字节） | Maximum file size (bytes)
   */
  maxSize?: number;
  
  /**
   * 修改时间范围（开始） | Modified time range (start)
   */
  modifiedAfter?: number;
  
  /**
   * 修改时间范围（结束） | Modified time range (end)
   */
  modifiedBefore?: number;
  
  /**
   * 排序字段 | Sort field
   */
  sortBy?: 'name' | 'size' | 'modifiedAt' | 'createdAt';
  
  /**
   * 排序方式 | Sort order
   */
  sortOrder?: 'asc' | 'desc';
  
  /**
   * 分页大小 | Page size
   */
  limit?: number;
  
  /**
   * 分页偏移 | Page offset
   */
  offset?: number;
}

/**
 * 文件搜索结果接口 | File search result interface
 */
export interface FileSearchResult {
  /**
   * 文件列表 | File list
   */
  files: FileMetadata[];
  
  /**
   * 目录列表 | Directory list
   */
  directories: DirectoryInfo[];
  
  /**
   * 总结果数 | Total count
   */
  totalCount: number;
  
  /**
   * 是否还有更多结果 | Whether has more results
   */
  hasMore: boolean;
}

/**
 * 文件操作类型枚举 | File operation type enum
 */
export enum FileOperationType {
  /**
   * 复制 | Copy
   */
  COPY = 'copy',
  
  /**
   * 移动 | Move
   */
  MOVE = 'move',
  
  /**
   * 删除 | Delete
   */
  DELETE = 'delete',
  
  /**
   * 重命名 | Rename
   */
  RENAME = 'rename',
  
  /**
   * 创建 | Create
   */
  CREATE = 'create',
  
  /**
   * 解压 | Extract
   */
  EXTRACT = 'extract',
  
  /**
   * 压缩 | Compress
   */
  COMPRESS = 'compress'
}

/**
 * 文件操作结果接口 | File operation result interface
 */
export interface FileOperationResult {
  /**
   * 是否成功 | Whether successful
   */
  success: boolean;
  
  /**
   * 操作类型 | Operation type
   */
  operationType: FileOperationType;
  
  /**
   * 源文件路径 | Source file path
   */
  sourcePath?: string;
  
  /**
   * 目标文件路径 | Target file path
   */
  targetPath?: string;
  
  /**
   * 错误信息 | Error message
   */
  errorMessage?: string;
  
  /**
   * 操作时间 | Operation time
   */
  timestamp: number;
}

/**
 * 文件监控事件类型枚举 | File monitor event type enum
 */
export enum FileMonitorEventType {
  /**
   * 文件创建 | File created
   */
  CREATED = 'created',
  
  /**
   * 文件修改 | File modified
   */
  MODIFIED = 'modified',
  
  /**
   * 文件删除 | File deleted
   */
  DELETED = 'deleted',
  
  /**
   * 文件移动 | File moved
   */
  MOVED = 'moved',
  
  /**
   * 目录创建 | Directory created
   */
  DIRECTORY_CREATED = 'directory_created',
  
  /**
   * 目录删除 | Directory deleted
   */
  DIRECTORY_DELETED = 'directory_deleted',
  
  /**
   * 目录移动 | Directory moved
   */
  DIRECTORY_MOVED = 'directory_moved'
}

/**
 * 文件监控事件接口 | File monitor event interface
 */
export interface FileMonitorEvent {
  /**
   * 事件类型 | Event type
   */
  type: FileMonitorEventType;
  
  /**
   * 文件路径 | File path
   */
  path: string;
  
  /**
   * 旧文件路径（用于移动事件） | Old file path (for move events)
   */
  oldPath?: string;
  
  /**
   * 事件时间戳 | Event timestamp
   */
  timestamp: number;
}

/**
 * 文件清理策略枚举 | File cleanup strategy enum
 */
export enum FileCleanupStrategy {
  /**
   * 按文件大小 | By file size
   */
  BY_SIZE = 'by_size',
  
  /**
   * 按文件时间 | By file time
   */
  BY_TIME = 'by_time',
  
  /**
   * 按文件类型 | By file type
   */
  BY_TYPE = 'by_type',
  
  /**
   * 全部清理 | All
   */
  ALL = 'all'
}

/**
 * 文件清理配置接口 | File cleanup config interface
 */
export interface FileCleanupConfig {
  /**
   * 清理策略 | Cleanup strategy
   */
  strategy: FileCleanupStrategy;
  
  /**
   * 目标目录 | Target directory
   */
  targetDir: string;
  
  /**
   * 最大文件大小（字节） | Maximum file size (bytes)
   */
  maxFileSize?: number;
  
  /**
   * 最老文件时间（时间戳） | Oldest file time (timestamp)
   */
  oldestFileTime?: number;
  
  /**
   * 要清理的文件类型 | File types to cleanup
   */
  fileTypes?: FileType[];
  
  /**
   * 保留最新的文件数量 | Keep latest file count
   */
  keepLatestCount?: number;
  
  /**
   * 是否递归清理子目录 | Whether recursive cleanup subdirectories
   */
  recursive: boolean;
  
  /**
   * 是否预览（不实际删除） | Whether preview only (not actually delete)
   */
  previewOnly: boolean;
}

/**
 * 文件清理结果接口 | File cleanup result interface
 */
export interface FileCleanupResult {
  /**
   * 已清理的文件数量 | Files cleaned count
   */
  filesCleaned: number;
  
  /**
   * 已清理的目录数量 | Directories cleaned count
   */
  directoriesCleaned: number;
  
  /**
   * 释放的空间（字节） | Space freed (bytes)
   */
  spaceFreed: number;
  
  /**
   * 清理失败的文件 | Failed to clean files
   */
  failedFiles: string[];
  
  /**
   * 清理时间（秒） | Cleanup time (seconds)
   */
  cleanupTime: number;
  
  /**
   * 是否预览模式 | Whether preview mode
   */
  isPreview: boolean;
}

/**
 * 本地存储配置接口 | Local storage config interface
 */
export interface LocalStorageConfig {
  /**
   * 缓存目录 | Cache directory
   */
  cacheDir: string;
  
  /**
   * 下载目录 | Download directory
   */
  downloadDir: string;
  
  /**
   * 字幕目录 | Subtitle directory
   */
  subtitleDir: string;
  
  /**
   * 用户数据目录 | User data directory
   */
  userDataDir: string;
  
  /**
   * 临时目录 | Temporary directory
   */
  tempDir: string;
  
  /**
   * 最大缓存大小（字节） | Maximum cache size (bytes)
   */
  maxCacheSize: number;
  
  /**
   * 自动清理缓存的时间间隔（小时） | Auto cleanup interval (hours)
   */
  autoCleanupInterval: number;
  
  /**
   * 是否启用文件监控 | Whether enable file monitoring
   */
  enableFileMonitoring: boolean;
}

/**
 * 本地文件图标接口 | Local file icon interface
 */
export interface FileIcon {
  /**
   * 文件类型 | File type
   */
  fileType: FileType;
  /**
   * 文件格式 | File format
   */
  fileFormat?: FileFormat;
  /**
   * 图标资源ID | Icon resource ID
   */
  iconResourceId: string;
  /**
   * 自定义图标路径 | Custom icon path
   */
  customIconPath?: string;
}

/**
 * MIME类型映射接口 | MIME type mapping interface
 */
export interface MimeTypeMap {
  /**
   * 文件格式 | File format
   */
  format: FileFormat;
  /**
   * MIME类型 | MIME type
   */
  mimeType: string;
  /**
   * 描述 | Description
   */
  description: string;
}



