// DeviceInfo.ets - 设备信息数据模型
// 定义设备基本信息和能力描述的数据结构

/**
 * 设备类型枚举
 */
export enum DeviceType {
  PHONE = 'phone',       // 手机
  TABLET = 'tablet',     // 平板
  TV = 'tv',             // 电视
  WEARABLE = 'wearable', // 可穿戴设备
  CAR = 'car',           // 车机
  SMART_DISPLAY = 'smart_display', // 智能显示屏
  PC = 'pc',             // 电脑
  OTHER = 'other'        // 其他设备
}

/**
 * 设备能力枚举
 */
export enum DeviceCapability {
  VIDEO_PLAYBACK = 'video_playback', // 视频播放
  LIVE_STREAMING = 'live_streaming', // 直播流
  AUDIO_OUTPUT = 'audio_output',     // 音频输出
  BIOMETRIC_AUTH = 'biometric_auth', // 生物识别
  MULTI_WINDOW = 'multi_window',     // 多窗口
  SCREEN_MIRRORING = 'screen_mirroring', // 屏幕镜像
  DEVICE_SHARING = 'device_sharing', // 设备共享
  SUPER_DEVICE = 'super_device',     // 超级终端
  HIGHER_RESOLUTION = 'higher_resolution', // 高分辨率
  HDR_SUPPORT = 'hdr_support',       // HDR支持
  DOLBY_ATMOS = 'dolby_atmos',       // 杜比全景声
  GESTURE_INPUT = 'gesture_input',   // 手势输入
  VOICE_CONTROL = 'voice_control',   // 语音控制
  REMOTE_CONTROL = 'remote_control', // 遥控器支持
  TOUCH_SCREEN = 'touch_screen',     // 触摸屏
  KEYBOARD_INPUT = 'keyboard_input', // 键盘输入
  MOUSE_INPUT = 'mouse_input',       // 鼠标输入
  GAMEPAD = 'gamepad',               // 游戏手柄
  CAMERA = 'camera',                 // 摄像头
  NFC = 'nfc',                       // NFC
  IR_BLASTER = 'ir_blaster',         // 红外发射器
  BLUETOOTH = 'bluetooth',           // 蓝牙
  WIFI_DISPLAY = 'wifi_display',     // WiFi显示
  WIFI_DIRECT = 'wifi_direct',       // WiFi直连
  USB_TETHERING = 'usb_tethering',   // USB网络共享
  MOBILE_DATA = 'mobile_data',       // 移动数据
  BACKGROUND_RUNNING = 'background_running', // 后台运行
  FILE_SHARING = 'file_sharing',     // 文件共享
  CLOUD_SYNC = 'cloud_sync',         // 云同步
  OFFLINE_MODE = 'offline_mode',     // 离线模式
}

/**
 * 设备状态枚举
 */
export enum DeviceStatus {
  ONLINE = 'online',     // 在线
  OFFLINE = 'offline',   // 离线
  CONNECTING = 'connecting', // 连接中
  DISCONNECTED = 'disconnected', // 已断开
  ERROR = 'error'        // 错误
}

/**
 * 设备网络信息接口
 */
export interface DeviceNetworkInfo {
  type: 'wifi' | 'mobile' | 'ethernet' | 'none'; // 网络类型
  ssid?: string;         // WiFi名称
  signalStrength?: number; // 信号强度（0-100）
  ipAddress?: string;    // IP地址
  macAddress?: string;   // MAC地址
  bandwidth?: number;    // 带宽（Mbps）
  latency?: number;      // 延迟（ms）
  uploadSpeed?: number;  // 上传速度（Mbps）
  downloadSpeed?: number; // 下载速度（Mbps）
  connectionTime?: number; // 连接时间
}

/**
 * 设备硬件信息接口
 */
export interface DeviceHardwareInfo {
  cpuModel?: string;     // CPU型号
  cpuCores?: number;     // CPU核心数
  ramSize?: number;      // RAM大小（GB）
  storageSize?: number;  // 存储大小（GB）
  availableStorage?: number; // 可用存储（GB）
  batteryLevel?: number; // 电池电量（0-100）
  batteryStatus?: 'charging' | 'discharging' | 'full' | 'unknown'; // 电池状态
  temperature?: number;  // 设备温度
  manufacturer?: string; // 制造商
  model?: string;        // 型号
  deviceCode?: string;   // 设备代码
  serialNumber?: string; // 序列号
  hardwareId?: string;   // 硬件ID
  chipset?: string;      // 芯片组
  gpuModel?: string;     // GPU型号
}

/**
 * 设备显示信息接口
 */
export interface DeviceDisplayInfo {
  screenWidth: number;   // 屏幕宽度（像素）
  screenHeight: number;  // 屏幕高度（像素）
  densityDpi: number;    // 像素密度
  aspectRatio: string;   // 屏幕比例
  refreshRate: number;   // 刷新率（Hz）
  isHdrSupported: boolean; // 是否支持HDR
  maxResolution: string; // 最大分辨率
  bitsPerPixel: number;  // 每像素位数
  displayName?: string;  // 显示器名称
  isPrimary: boolean;    // 是否主显示器
  supportsTouch: boolean; // 是否支持触摸
  dpiX?: number;         // X轴DPI
  dpiY?: number;         // Y轴DPI
}

/**
 * 设备媒体能力接口
 */
export interface DeviceMediaCapabilities {
  supportedCodecs: string[]; // 支持的编解码器
  supportedFormats: string[]; // 支持的格式
  maxResolution: string;     // 最大分辨率
  maxFps: number;            // 最大帧率
  hdrFormats: string[];      // HDR格式
  audioChannels: number;     // 音频通道数
  audioFormats: string[];    // 音频格式
  dolbySupported: boolean;   // 是否支持杜比
  dtsSupported: boolean;     // 是否支持DTS
  spatialAudioSupported: boolean; // 是否支持空间音频
  hardwareAcceleration: boolean; // 是否支持硬件加速
}

/**
 * 设备权限信息接口
 */
export interface DevicePermissionInfo {
  [permission: string]: boolean; // 权限名称和状态
}

/**
 * 设备账户信息接口
 */
export interface DeviceAccountInfo {
  accountType?: string;  // 账户类型
  username?: string;     // 用户名
  avatarUrl?: string;    // 头像URL
  isLoggedIn?: boolean;  // 是否已登录
  lastLoginTime?: number; // 最后登录时间
}

/**
 * 设备位置信息接口
 */
export interface DeviceLocationInfo {
  country?: string;      // 国家
  region?: string;       // 地区
  city?: string;         // 城市
  latitude?: number;     // 纬度
  longitude?: number;    // 经度
  timezone?: string;     // 时区
  languageCode?: string; // 语言代码
  locale?: string;       // 区域设置
}

/**
 * 设备应用信息接口
 */
export interface DeviceAppInfo {
  packageName: string;   // 包名
  versionName: string;   // 版本名称
  versionCode: number;   // 版本代码
  buildType?: string;    // 构建类型
  minSdkVersion?: number; // 最低SDK版本
  targetSdkVersion?: number; // 目标SDK版本
  installationTime?: number; // 安装时间
  lastUpdateTime?: number; // 最后更新时间
  appSize?: number;      // 应用大小（MB）
  dataSize?: number;     // 数据大小（MB）
  cacheSize?: number;    // 缓存大小（MB）
}

/**
 * 设备连接信息接口
 */
export interface DeviceConnectionInfo {
  connectionType: 'wifi' | 'bluetooth' | 'usb' | 'nfc' | 'other'; // 连接类型
  signalStrength?: number; // 信号强度
  connectionTime?: number; // 连接时间
  transferRate?: number;  // 传输速率
  errorCount?: number;    // 错误计数
  lastErrorTime?: number; // 最后错误时间
}

/**
 * 设备信息数据模型
 */
export interface DeviceInfo {
  deviceId: string;      // 设备唯一标识
  deviceName: string;    // 设备名称
  deviceType: DeviceType; // 设备类型
  osVersion: string;     // 系统版本
  apiVersion: number;    // API版本
  appVersion: string;    // 应用版本
  deviceNetworkInfo: DeviceNetworkInfo; // 网络信息
  deviceHardwareInfo: DeviceHardwareInfo; // 硬件信息
  deviceDisplayInfo: DeviceDisplayInfo; // 显示信息
  deviceMediaCapabilities: DeviceMediaCapabilities; // 媒体能力
  devicePermissionInfo: DevicePermissionInfo; // 权限信息
  deviceAccountInfo?: DeviceAccountInfo; // 账户信息
  deviceLocationInfo?: DeviceLocationInfo; // 位置信息
  deviceAppInfo: DeviceAppInfo; // 应用信息
  deviceConnectionInfo?: DeviceConnectionInfo; // 连接信息
  status: DeviceStatus;  // 设备状态
  capabilities: DeviceCapability[]; // 支持的功能列表
  isTvMode: boolean;     // 是否为TV模式
  isRemoteControlAvailable: boolean; // 是否可用遥控器
  isMultiDeviceSupport: boolean; // 是否支持多设备
  isPrimaryDevice: boolean; // 是否为主设备
  pairedDevices?: string[]; // 配对设备列表
  isVirtualDevice?: boolean; // 是否虚拟设备
  deviceIcon?: string;   // 设备图标
  deviceDescription?: string; // 设备描述
  createdAt: number;     // 创建时间
  updatedAt: number;     // 更新时间
  lastSeenAt?: number;   // 最后在线时间
  customProperties?: Map<string, string | number | boolean | null>; // 自定义属性
}

/**
 * 设备配对信息接口
 */
export interface DevicePairInfo {
  deviceId: string;      // 设备ID
  deviceName: string;    // 设备名称
  deviceType: DeviceType; // 设备类型
  pairTime: number;      // 配对时间
  lastConnectedTime?: number; // 最后连接时间
  connectionCount: number; // 连接次数
  isTrusted: boolean;    // 是否可信设备
  capabilities: DeviceCapability[]; // 支持的功能
  connectionStatus: 'connected' | 'disconnected' | 'connecting'; // 连接状态
  sharedResources?: string[]; // 共享资源列表
}

/**
 * 设备流转状态接口
 */
export interface DeviceFlowStatus {
  sourceDeviceId: string; // 源设备ID
  targetDeviceId: string; // 目标设备ID
  flowType: 'video' | 'audio' | 'screen' | 'data'; // 流转类型
  status: 'idle' | 'initiating' | 'transferring' | 'completed' | 'failed' | 'cancelled'; // 流转状态
  progress: number;      // 流转进度（0-100）
  startTime?: number;    // 开始时间
  endTime?: number;      // 结束时间
  errorMessage?: string; // 错误信息
  contentInfo?: DeviceFlowContentInfo; // 流转内容信息
}

/**
 * 设备统计信息接口
 */
export interface DeviceStats {
  uptime?: number;       // 运行时间
  appLaunchCount: number; // 应用启动次数
  totalWatchTime: number; // 总观看时长
  batteryUsage?: number; // 电池使用量
  storageUsage?: number; // 存储使用量
  dataUsage?: DeviceDataUsage; // 数据使用情况
  errorCount?: number;   // 错误计数
  lastErrorTime?: number; // 最后错误时间
  featureUsage?: Map<string, number>; // 功能使用统计
}

/**
 * 设备诊断结果接口
 */
export interface DeviceDiagnostics {
  overallStatus: 'good' | 'warning' | 'critical'; // 总体状态
  cpuUsage?: number;     // CPU使用率
  memoryUsage?: number;  // 内存使用率
  storageUsage?: number; // 存储使用率
  batteryHealth?: 'excellent' | 'good' | 'fair' | 'poor'; // 电池健康状态
  networkStatus: 'excellent' | 'good' | 'fair' | 'poor'; // 网络状态
  issues?: DeviceIssue[]; // 设备问题列表
  recommendedActions?: string[]; // 推荐操作
  diagnosticTime: number; // 诊断时间
}

/**
 * 设备事件接口
 */
export interface DeviceEvent {
  eventId: string;       // 事件ID
  deviceId: string;      // 设备ID
  eventType: string;     // 事件类型
  timestamp: number;     // 事件时间
  details?: string | number | boolean | null;         // 事件详情
  isProcessed: boolean;  // 是否已处理
  priority: 'low' | 'medium' | 'high'; // 优先级
}

/**
 * 设备流转内容信息接口
 */
export interface DeviceFlowContentInfo {
  type: string;        // 内容类型
  id?: string;         // 内容ID
  title?: string;      // 内容标题
  position?: number;   // 播放位置
}

/**
 * 设备数据使用情况接口
 */
export interface DeviceDataUsage {
  wifi: number;        // WiFi数据使用量
  mobile: number;      // 移动数据使用量
}

/**
 * 设备问题接口
 */
export interface DeviceIssue {
  type: string;        // 问题类型
  severity: 'low' | 'medium' | 'high'; // 严重程度
  description: string; // 问题描述
  solution?: string;   // 解决方案
}