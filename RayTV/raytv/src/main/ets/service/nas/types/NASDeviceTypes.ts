// NASDeviceTypes.ts - NAS设备相关类型定义

/**
 * NAS设备能力接口
 */
export interface NASCapabilities {
  smb: boolean;     // SMB/CIFS协议支持
  dlna: boolean;    // DLNA/UPnP协议支持
  webdav: boolean;  // WebDAV协议支持
  http: boolean;     // HTTP协议支持
}

/**
 * NAS设备认证配置接口
 */
export interface NASAuthConfig {
  username: string;  // 用户名
  password: string;  // 密码
  enableAuth: boolean; // 是否启用认证
}

/**
 * NAS设备接口
 */
export interface NASDevice {
  id: string;                // 设备唯一标识
  name: string;              // 设备名称
  ip: string;                // IP地址
  port: number;              // 端口号
  protocol: 'smb' | 'dlna' | 'webdav' | 'http' | 'huawei'; // 协议类型
  manufacturer: string;       // 制造商
  model: string;              // 型号
  isOnline: boolean;          // 是否在线
  lastSeen: number;           // 最后seen时间
  capabilities: NASCapabilities; // 设备能力
  authConfig?: NASAuthConfig; // 认证配置
  priority?: number;          // 设备优先级 (1-10)
  discoverySource?: string;   // 发现来源
  type?: string;              // 设备类型
  status?: string;            // 设备状态
  config?: Record<string, any>; // 设备配置
}

/**
 * NAS文件项接口
 */
export interface NASFileItem {
  id: string;          // 文件唯一标识
  name: string;        // 文件名
  path: string;        // 文件路径
  type: 'file' | 'directory'; // 文件类型
  size?: number;       // 文件大小（字节）
  modifiedTime: number; // 修改时间
  mimeType?: string;   // MIME类型
  thumbnailUrl?: string; // 缩略图URL
  duration?: number;   // 视频时长（秒）
  resolution?: string; // 视频分辨率
  isVideo: boolean;    // 是否为视频文件
  isAudio: boolean;    // 是否为音频文件
  isImage: boolean;    // 是否为图片文件
}

/**
 * NAS视频索引接口
 */
export interface NASVideoIndex {
  deviceId: string;     // 设备ID
  fileId: string;       // 文件ID
  filePath: string;     // 文件路径
  fileName: string;     // 文件名
  fileSize: number;     // 文件大小
  duration?: number;    // 视频时长
  resolution?: string;  // 视频分辨率
  codec?: string;       // 视频编码
  bitrate?: number;     // 比特率
  thumbnailPath?: string; // 缩略图路径
  metadata: VideoMetadata; // 视频元数据
  indexedAt: number;    // 索引时间
  lastModified: number; // 最后修改时间
}

/**
 * 视频元数据接口
 */
export interface VideoMetadata {
  title?: string;       // 标题
  year?: number;        // 年份
  genre?: string[];     // 类型
  actors?: string[];    // 演员
  director?: string;    // 导演
  description?: string; // 描述
  poster?: string;      // 海报
  backdrop?: string;    // 背景图
}

/**
 * NAS目录分类接口
 */
export interface NASDirectoryCategory {
  id: string;           // 分类ID
  deviceId: string;     // 设备ID
  sourceId: string;     // 网络源ID
  name: string;         // 分类名称
  path: string;         // 目录路径
  type: 'root' | 'category' | 'subcategory'; // 分类类型
  parentId?: string;    // 父分类ID
  itemCount: number;    // 项目数量
  icon?: string;        // 图标
  isBrowsable: boolean; // 是否可浏览
}

/**
 * NAS视频项接口
 */
export interface NASVideoItem {
  id: string;                 // 视频唯一标识
  deviceId: string;           // 设备ID
  sourceId: string;           // 网络源ID
  categoryId: string;          // 分类ID
  fileItem: NASFileItem;       // 文件项
  watchedProgress?: number;    // 观看进度
  lastWatched?: number;        // 最后观看时间
  isFavorite: boolean;         // 是否收藏
}

/**
 * NAS内容统计接口
 */
export interface NASContentStats {
  totalVideos: number;         // 总视频数
  totalDirectories: number;     // 总目录数
  totalSize: number;           // 总大小
  videoFormats: Record<string, number>; // 视频格式统计
  lastIndexed: number;         // 最后索引时间
}

/**
 * NAS配置接口
 */
export interface NASConfig {
  deviceId: string;           // 设备ID
  deviceName: string;         // 设备名称
  protocol: 'smb' | 'dlna' | 'webdav' | 'http' | 'huawei'; // 协议类型
  ipAddress: string;          // IP地址
  port: number;               // 端口号
  sharePath?: string;         // SMB共享路径
  username?: string;          // 用户名
  password?: string;          // 密码
  enableAuth: boolean;        // 是否启用认证
  huaweiConfig?: HuaweiSpecificConfig; // 华为特定配置
}

/**
 * 华为存储特定配置接口
 */
export interface HuaweiSpecificConfig {
  deviceModel: string;        // 设备型号
  firmwareVersion: string;    // 固件版本
  familyMembers?: string[];   // 家庭成员
  sharedFolders?: string[];   // 共享文件夹
}

/**
 * 目录树节点接口
 */
export interface DirectoryTreeNode {
  name: string;              // 节点名称
  path: string;              // 节点路径
  type: 'directory';         // 节点类型
  children: DirectoryTreeNode[]; // 子节点
}
