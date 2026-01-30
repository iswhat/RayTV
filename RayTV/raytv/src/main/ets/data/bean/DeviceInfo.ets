/**
 * Device information data types | 设备信息数据类型
 * Define data structure for device basic information and capability description | 定义设备基本信息和能力描述的数据结构
 */

/**
 * Device type enum | 设备类型枚举
 */
export enum DeviceType {
  PHONE = 'phone',       // Phone | 手机
  TABLET = 'tablet',     // Tablet | 平板
  TV = 'tv',             // TV | 电视
  WEARABLE = 'wearable', // Wearable device | 可穿戴设备
  CAR = 'car',           // Car | 车载
  SMART_DISPLAY = 'smart_display', // Smart display | 智能显示屏
  PC = 'pc',             // PC | 电脑
  OTHER = 'other'        // Other device | 其他设备
}

/**
 * Device capability enum | 设备能力枚举
 */
export enum DeviceCapability {
  VIDEO_PLAYBACK = 'video_playback', // Video playback | 视频播放
  LIVE_STREAMING = 'live_streaming', // Live streaming | 直播流
  AUDIO_OUTPUT = 'audio_output',     // Audio output | 音频输出
  BIOMETRIC_AUTH = 'biometric_auth', // Biometric authentication | 生物识别
  MULTI_WINDOW = 'multi_window',     // Multi-window | 多窗口
  SCREEN_MIRRORING = 'screen_mirroring', // Screen mirroring | 屏幕镜像
  DEVICE_SHARING = 'device_sharing', // Device sharing | 设备共享
  SUPER_DEVICE = 'super_device',     // Super device | 超级终端
  HIGHER_RESOLUTION = 'higher_resolution', // Higher resolution | 高分辨率
  HDR_SUPPORT = 'hdr_support',       // HDR support | HDR支持
  DOLBY_ATMOS = 'dolby_atmos',       // Dolby Atmos | 杜比全景声
  GESTURE_INPUT = 'gesture_input',   // Gesture input | 手势输入
  VOICE_CONTROL = 'voice_control',   // Voice control | 语音控制
  REMOTE_CONTROL = 'remote_control', // Remote control support | 遥控器支持
  TOUCH_SCREEN = 'touch_screen',     // Touch screen | 触摸屏
  KEYBOARD_INPUT = 'keyboard_input', // Keyboard input | 键盘输入
  MOUSE_INPUT = 'mouse_input',       // Mouse input | 鼠标输入
  GAMEPAD = 'gamepad',               // Gamepad | 游戏手柄
  CAMERA = 'camera',                 // Camera | 摄像头
  NFC = 'nfc',                       // NFC
  IR_BLASTER = 'ir_blaster',         // IR blaster | 红外发射器
  BLUETOOTH = 'bluetooth',           // Bluetooth | 蓝牙
  WIFI_DISPLAY = 'wifi_display',     // WiFi display | WiFi显示
  WIFI_DIRECT = 'wifi_direct',       // WiFi direct | WiFi直连
  USB_TETHERING = 'usb_tethering',   // USB tethering | USB网络共享
  MOBILE_DATA = 'mobile_data',       // Mobile data | 移动数据
  BACKGROUND_RUNNING = 'background_running', // Background running | 后台运行
  FILE_SHARING = 'file_sharing',     // File sharing | 文件共享
  CLOUD_SYNC = 'cloud_sync',         // Cloud sync | 云同步
  OFFLINE_MODE = 'offline_mode',     // Offline mode | 离线模式
}

/**
 * Device status enum | 设备状态枚举
 */
export enum DeviceStatus {
  ONLINE = 'online',     // Online | 在线
  OFFLINE = 'offline',   // Offline | 离线
  CONNECTING = 'connecting', // Connecting | 连接中
  DISCONNECTED = 'disconnected', // Disconnected | 已断开
  ERROR = 'error'        // Error | 错误
}

/**
 * Device network information interface | 设备网络信息接口
 */
export interface DeviceNetworkInfo {
  type: 'wifi' | 'mobile' | 'ethernet' | 'none'; // Network type | 网络类型
  ssid?: string;         // WiFi name | WiFi名称
  signalStrength?: number; // Signal strength (-100+) | 信号强度 (-100+)
  ipAddress?: string;    // IP address | IP地址
  macAddress?: string;   // MAC address | MAC地址
  bandwidth?: number;    // Bandwidth (Mbps) | 带宽 (Mbps)
  latency?: number;      // Latency (ms) | 延迟 (ms)
  uploadSpeed?: number;  // Upload speed (Mbps) | 上传速度 (Mbps)
  downloadSpeed?: number; // Download speed (Mbps) | 下载速度 (Mbps)
  connectionTime?: number; // Connection time | 连接时间
}

/**
 * Device hardware information interface | 设备硬件信息接口
 */
export interface DeviceHardwareInfo {
  cpuModel?: string;     // CPU model | CPU型号
  cpuCores?: number;     // CPU cores | CPU核心数
  ramSize?: number;      // RAM size (GB) | RAM大小 (GB)
  storageSize?: number;  // Storage size (GB) | 存储大小 (GB)
  availableStorage?: number; // Available storage (GB) | 可用存储 (GB)
  batteryLevel?: number; // Battery level (0-100) | 电池电量 (0-100)
  batteryStatus?: 'charging' | 'discharging' | 'full' | 'unknown'; // Battery status | 电池状态
  temperature?: number;  // Device temperature | 设备温度
  manufacturer?: string; // Manufacturer | 制造商
  model?: string;        // Model | 型号
  deviceCode?: string;   // Device code | 设备码
  serialNumber?: string; // Serial number | 序列号
  hardwareId?: string;   // Hardware ID | 硬件ID
  chipset?: string;      // Chipset | 芯片组
  gpuModel?: string;     // GPU model | GPU型号
}

/**
 * Device display information interface | 设备显示信息接口
 */
export interface DeviceDisplayInfo {
  screenWidth: number;   // Screen width (pixels) | 屏幕宽度 (像素)
  screenHeight: number;  // Screen height (pixels) | 屏幕高度 (像素)
  densityDpi: number;    // Pixel density | 像素密度
  aspectRatio: string;   // Screen aspect ratio | 屏幕比例
  refreshRate: number;   // Refresh rate (Hz) | 刷新率 (Hz)
  isHdrSupported: boolean; // Whether HDR is supported | 是否支持HDR
  maxResolution: string; // Max resolution | 最大分辨率
  bitsPerPixel: number;  // Bits per pixel | 每像素位数
  displayName?: string;  // Display name | 显示器名称
  isPrimary: boolean;    // Whether primary display | 是否为主显示器
  supportsTouch: boolean; // Whether touch is supported | 是否支持触摸
  dpiX?: number;         // X-axis DPI | X轴DPI
  dpiY?: number;         // Y-axis DPI | Y轴DPI
}

/**
 * Device media capabilities interface | 设备媒体能力接口
 */
export interface DeviceMediaCapabilities {
  supportedCodecs: string[]; // Supported codecs | 支持的编解码器
  supportedFormats: string[]; // Supported formats | 支持的格式
  maxResolution: string;     // Max resolution | 最大分辨率
  maxFps: number;            // Max FPS | 最大帧率
  hdrFormats: string[];      // HDR formats | HDR格式
  audioChannels: number;     // Audio channels | 音频通道数
  audioFormats: string[];    // Audio formats | 音频格式
  dolbySupported: boolean;   // Whether Dolby is supported | 是否支持杜比
  dtsSupported: boolean;     // Whether DTS is supported | 是否支持DTS
  spatialAudioSupported: boolean; // Whether spatial audio is supported | 是否支持空间音频
  hardwareAcceleration: boolean; // Whether hardware acceleration is supported | 是否支持硬件加速
}

/**
 * Device permission information interface | 设备权限信息接口
 */
export interface DevicePermissionInfo {
  permissions: Map<string, boolean>; // Permission map | 权限映射
  hasPermission(permission: string): boolean; // Check if has permission | 检查是否有权限
  setPermission(permission: string, granted: boolean): void; // Set permission status | 设置权限状态
  getAllPermissions(): Map<string, boolean>; // Get all permissions | 获取所有权限
}

/**
 * Device permission information implementation class | 设备权限信息实现类
 */
export class DevicePermissionInfoImpl implements DevicePermissionInfo {
  permissions: Map<string, boolean> = new Map();
  
  hasPermission(permission: string): boolean {
    return this.permissions.get(permission) || false;
  }
  
  setPermission(permission: string, granted: boolean): void {
    this.permissions.set(permission, granted);
  }
  
  getAllPermissions(): Map<string, boolean> {
    return this.permissions;
  }
}

/**
 * Device account information interface | 设备账户信息接口
 */
export interface DeviceAccountInfo {
  accountType?: string;  // Account type | 账户类型
  username?: string;     // Username | 用户名
  avatarUrl?: string;    // Avatar URL | 头像URL
  isLoggedIn?: boolean;  // Whether logged in | 是否已登录
  lastLoginTime?: number; // Last login time | 最后登录时间
}

/**
 * Device location information interface | 设备位置信息接口
 */
export interface DeviceLocationInfo {
  country?: string;      // Country | 国家
  region?: string;       // Region | 地区
  city?: string;         // City | 城市
  latitude?: number;     // Latitude | 纬度
  longitude?: number;    // Longitude | 经度
  timezone?: string;     // Timezone | 时区
  languageCode?: string; // Language code | 语言码
  locale?: string;       // Locale | 区域设置
}

/**
 * Device app information interface | 设备应用信息接口
 */
export interface DeviceAppInfo {
  packageName: string;   // Package name | 包名
  versionName: string;   // Version name | 版本名称
  versionCode: number;   // Version code | 版本码
  buildType?: string;    // Build type | 构建类型
  minSdkVersion?: number; // Minimum SDK version | 最低SDK版本
  targetSdkVersion?: number; // Target SDK version | 目标SDK版本
  installationTime?: number; // Installation time | 安装时间
  lastUpdateTime?: number; // Last update time | 最后更新时间
  appSize?: number;      // App size (MB) | 应用大小 (MB)
  dataSize?: number;     // Data size (MB) | 数据大小 (MB)
  cacheSize?: number;    // Cache size (MB) | 缓存大小 (MB)
}

/**
 * Device connection information interface | 设备连接信息接口
 */
export interface DeviceConnectionInfo {
  connectionType: 'wifi' | 'bluetooth' | 'usb' | 'nfc' | 'other'; // Connection type | 连接类型
  signalStrength?: number; // Signal strength | 信号强度
  connectionTime?: number; // Connection time | 连接时间
  transferRate?: number;  // Transfer rate | 传输速率
  errorCount?: number;    // Error count | 错误计数
  lastErrorTime?: number; // Last error time | 最后错误时间
}

/**
 * Device information data type | 设备信息数据类型
 */
export interface DeviceInfo {
  deviceId: string;      // Device unique ID | 设备唯一标识
  deviceName: string;    // Device name | 设备名称
  deviceType: DeviceType; // Device type | 设备类型
  osVersion: string;     // OS version | 系统版本
  apiVersion: number;    // API version | API版本
  appVersion: string;    // App version | 应用版本
  deviceNetworkInfo: DeviceNetworkInfo; // Network information | 网络信息
  deviceHardwareInfo: DeviceHardwareInfo; // Hardware information | 硬件信息
  deviceDisplayInfo: DeviceDisplayInfo; // Display information | 显示信息
  deviceMediaCapabilities: DeviceMediaCapabilities; // Media capabilities | 媒体能力
  devicePermissionInfo: DevicePermissionInfo; // Permission information | 权限信息
  deviceAccountInfo?: DeviceAccountInfo; // Account information | 账户信息
  deviceLocationInfo?: DeviceLocationInfo; // Location information | 位置信息
  deviceAppInfo: DeviceAppInfo; // App information | 应用信息
  deviceConnectionInfo?: DeviceConnectionInfo; // Connection information | 连接信息
  status: DeviceStatus;  // Device status | 设备状态
  capabilities: DeviceCapability[]; // Supported capabilities list | 支持的功能列表
  isTvMode: boolean;     // Whether TV mode | 是否为TV模式
  isRemoteControlAvailable: boolean; // Whether remote control is available | 是否可用遥控器
  isMultiDeviceSupport: boolean; // Whether multi-device is supported | 是否支持多设备
  isPrimaryDevice: boolean; // Whether primary device | 是否为主设备
  pairedDevices?: string[]; // Paired devices list | 配对设备列表
  isVirtualDevice?: boolean; // Whether virtual device | 是否虚拟设备
  deviceIcon?: string;   // Device icon | 设备图标
  deviceDescription?: string; // Device description | 设备描述
  createdAt: number;     // Creation time | 创建时间
  updatedAt: number;     // Update time | 更新时间
  lastSeenAt?: number;   // Last seen time | 最后在线时间
  customProperties?: Map<string, string | number | boolean | null>; // Custom properties | 自定义属性
}

/**
 * Device pairing information interface | 设备配对信息接口
 */
export interface DevicePairInfo {
  deviceId: string;      // Device ID | 设备ID
  deviceName: string;    // Device name | 设备名称
  deviceType: DeviceType; // Device type | 设备类型
  pairTime: number;      // Pairing time | 配对时间
  lastConnectedTime?: number; // Last connected time | 最后连接时间
  connectionCount: number; // Connection count | 连接次数
  isTrusted: boolean;    // Whether trusted device | 是否可信设备
  capabilities: DeviceCapability[]; // Supported capabilities | 支持的功能
  connectionStatus: 'connected' | 'disconnected' | 'connecting'; // Connection status | 连接状态
  sharedResources?: string[]; // Shared resources list | 共享资源列表
}

/**
 * Device flow status interface | 设备流转状态接口
 */
export interface DeviceFlowStatus {
  sourceDeviceId: string; // Source device ID | 源设备ID
  targetDeviceId: string; // Target device ID | 目标设备ID
  flowType: 'video' | 'audio' | 'screen' | 'data'; // Flow type | 流转类型
  status: 'idle' | 'initiating' | 'transferring' | 'completed' | 'failed' | 'cancelled'; // Flow status | 流转状态
  progress: number;      // Flow progress (0-100) | 流转进度 (0-100)
  startTime?: number;    // Start time | 开始时间
  endTime?: number;      // End time | 结束时间
  errorMessage?: string; // Error message | 错误信息
  contentInfo?: DeviceFlowContentInfo; // Flow content information | 流转内容信息
}

/**
 * Device statistics information interface | 设备统计信息接口
 */
export interface DeviceStats {
  uptime?: number;       // Uptime | 运行时间
  appLaunchCount: number; // App launch count | 应用启动次数
  totalWatchTime: number; // Total watch time | 总观看时间
  batteryUsage?: number; // Battery usage | 电池使用量
  storageUsage?: number; // Storage usage | 存储使用量
  dataUsage?: DeviceDataUsage; // Data usage status | 数据使用情况
  errorCount?: number;   // Error count | 错误计数
  lastErrorTime?: number; // Last error time | 最后错误时间
  featureUsage?: Map<string, number>; // Feature usage statistics | 功能使用统计
}

/**
 * Device diagnostics result interface | 设备诊断结果接口
 */
export interface DeviceDiagnostics {
  overallStatus: 'good' | 'warning' | 'critical'; // Overall status | 整体状态
  cpuUsage?: number;     // CPU usage | CPU使用率
  memoryUsage?: number;  // Memory usage | 内存使用率
  storageUsage?: number; // Storage usage | 存储使用率
  batteryHealth?: 'excellent' | 'good' | 'fair' | 'poor'; // Battery health status | 电池健康状态
  networkStatus: 'excellent' | 'good' | 'fair' | 'poor'; // Network status | 网络状态
  issues?: DeviceIssue[]; // Device issues list | 设备问题列表
  recommendedActions?: string[]; // Recommended actions | 推荐操作
  diagnosticTime: number; // Diagnostic time | 诊断时间
}

/**
 * Device event interface | 设备事件接口
 */
export interface DeviceEvent {
  eventId: string;       // Event ID | 事件ID
  deviceId: string;      // Device ID | 设备ID
  eventType: string;     // Event type | 事件类型
  timestamp: number;     // Event time | 事件时间
  details?: string | number | boolean | null;         // Event details | 事件详情
  isProcessed: boolean;  // Whether processed | 是否已处理
  priority: 'low' | 'medium' | 'high'; // Priority | 优先级
}

/**
 * Device flow content information interface | 设备流转内容信息接口
 */
export interface DeviceFlowContentInfo {
  type: string;        // Content type | 内容类型
  id?: string;         // Content ID | 内容ID
  title?: string;      // Content title | 内容标题
  position?: number;   // Playback position | 播放位置
}

/**
 * Device data usage status interface | 设备数据使用情况接口
 */
export interface DeviceDataUsage {
  wifi: number;        // WiFi data usage | WiFi数据使用量
  mobile: number;      // Mobile data usage | 移动数据使用量
}

/**
 * Device issue interface | 设备问题接口
 */
export interface DeviceIssue {
  type: string;        // Issue type | 问题类型
  severity: 'low' | 'medium' | 'high'; // Severity | 严重程度
  description: string; // Issue description | 问题描述
  solution?: string;   // Solution | 解决方案
}
