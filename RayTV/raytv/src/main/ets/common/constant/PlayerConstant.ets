/**
 * PlayerConstant - Player related constant definitions | 播放器相关常量定义
 * Define player related constant values, including playback states, error codes, etc. | 定义播放器相关的常量值，包括播放状态、错误码等
 */
export class PlayerConstant {
  // Playback states | 播放状态
  public static readonly STATE_IDLE: number = 0; // Idle state | 空闲状态
  public static readonly STATE_PREPARING: number = 1; // Preparing state | 准备中状态
  public static readonly STATE_PREPARED: number = 2; // Prepared state | 准备完成状态
  public static readonly STATE_PLAYING: number = 3; // Playing state | 播放中状态
  public static readonly STATE_PAUSED: number = 4; // Paused state | 暂停状态
  public static readonly STATE_STOPPED: number = 5; // Stopped state | 停止状态
  public static readonly STATE_COMPLETED: number = 6; // Completed state | 播放完成状态
  public static readonly STATE_ERROR: number = 7; // Error state | 错误状态
  public static readonly STATE_BUFFERING: number = 8; // Buffering state | 缓冲状态

  // Error codes | 错误码
  public static readonly ERROR_UNKNOWN: number = -1; // Unknown error | 未知错误
  public static readonly ERROR_NETWORK: number = -100; // Network error | 网络错误
  public static readonly ERROR_DECODE: number = -200; // Decode error | 解码错误
  public static readonly ERROR_PERMISSION: number = -300; // Permission error | 权限错误
  public static readonly ERROR_FORMAT: number = -400; // Format error | 格式错误
  public static readonly ERROR_TIMEOUT: number = -500; // Timeout error | 超时错误
  public static readonly ERROR_RESOURCE: number = -600; // Resource error | 资源错误

  // Playback speed options | 播放速度选项
  public static readonly PLAYBACK_SPEEDS: number[] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]; // Playback speed list | 播放速度列表
  public static readonly DEFAULT_PLAYBACK_SPEED: number = 1.0; // Default playback speed | 默认播放速度

  // Video quality options | 画质选项
  public static readonly VIDEO_QUALITY_AUTO: string = 'auto'; // Auto quality | 自动画质
  public static readonly VIDEO_QUALITY_SD: string = 'sd'; // Standard definition | 标清
  public static readonly VIDEO_QUALITY_HD: string = 'hd'; // High definition | 高清
  public static readonly VIDEO_QUALITY_FHD: string = 'fhd'; // Full high definition | 全高清
  public static readonly VIDEO_QUALITY_4K: string = '4k'; // 4K resolution | 4K分辨率

  // Screen scale | 屏幕比例
  public static readonly SCREEN_SCALE_DEFAULT: number = 0; // Default scale | 默认比例
  public static readonly SCREEN_SCALE_16_9: number = 1; // 16:9 scale | 16:9比例
  public static readonly SCREEN_SCALE_4_3: number = 2; // 4:3 scale | 4:3比例
  public static readonly SCREEN_SCALE_FIT: number = 3; // Fit screen | 适应屏幕
  public static readonly SCREEN_SCALE_FILL: number = 4; // Fill screen | 充满屏幕
  public static readonly SCREEN_SCALE_ORIGINAL: number = 5; // Original size | 原始大小

  // Gesture operation types | 手势操作类型
  public static readonly GESTURE_TYPE_NONE: number = 0; // No gesture | 无手势
  public static readonly GESTURE_TYPE_PROGRESS: number = 1; // Progress gesture | 进度手势
  public static readonly GESTURE_TYPE_VOLUME: number = 2; // Volume gesture | 音量手势
  public static readonly GESTURE_TYPE_BRIGHTNESS: number = 3; // Brightness gesture | 亮度手势

  // Playback mode | 播放模式
  public static readonly PLAY_MODE_SINGLE: number = 0; // Single play | 单曲播放
  public static readonly PLAY_MODE_LIST_LOOP: number = 1; // List loop | 列表循环
  public static readonly PLAY_MODE_RANDOM: number = 2; // Random play | 随机播放

  // Other constants | 其他常量
  public static readonly MAX_VOLUME: number = 100; // Maximum volume | 最大音量
  public static readonly MAX_BRIGHTNESS: number = 100; // Maximum brightness | 最大亮度
  public static readonly SEEK_STEP: number = 10000; // 10 seconds | 10秒
  public static readonly FAST_FORWARD_STEP: number = 30000; // 30 seconds | 30秒
  public static readonly MAX_SUBTITLE_TRACKS: number = 10; // Maximum subtitle tracks | 最大字幕轨道数
  public static readonly MAX_AUDIO_TRACKS: number = 5; // Maximum audio tracks | 最大音轨数
  public static readonly AUTO_HIDE_CONTROLS_DELAY: number = 3000; // 3 seconds | 3秒
  public static readonly BUFFER_PROGRESS_UPDATE_INTERVAL: number = 500; // 500ms | 500毫秒
  public static readonly MIN_BUFFER_DURATION: number = 2000; // 2 seconds | 2秒
  public static readonly MAX_BUFFER_DURATION: number = 30000; // 30 seconds | 30秒

  /**
   * Get text description of playback state | 获取播放状态的文本描述
   * @param state Playback state code | 播放状态码
   * @returns State description text | 状态描述文本
   */
  public static getStateText(state: number): string {
    switch (state) {
      case this.STATE_IDLE:
        return '空闲';
      case this.STATE_PREPARING:
        return '准备中';
      case this.STATE_PREPARED:
        return '准备完成';
      case this.STATE_PLAYING:
        return '播放中';
      case this.STATE_PAUSED:
        return '暂停';
      case this.STATE_STOPPED:
        return '停止';
      case this.STATE_COMPLETED:
        return '播放完成';
      case this.STATE_ERROR:
        return '播放错误';
      case this.STATE_BUFFERING:
        return '缓冲中';
      default:
        return '未知状态';
    }
  }

  /**
   * Get text description of error code | 获取错误码的文本描述
   * @param errorCode Error code | 错误码
   * @returns Error description text | 错误描述文本
   */
  public static getErrorText(errorCode: number): string {
    switch (errorCode) {
      case this.ERROR_UNKNOWN:
        return '未知错误';
      case this.ERROR_NETWORK:
        return '网络错误';
      case this.ERROR_DECODE:
        return '解码错误';
      case this.ERROR_PERMISSION:
        return '权限错误';
      case this.ERROR_FORMAT:
        return '格式不支持';
      case this.ERROR_TIMEOUT:
        return '请求超时';
      case this.ERROR_RESOURCE:
        return '资源不可用';
      default:
        return `错误码: ${errorCode}`;
    }
  }
}
