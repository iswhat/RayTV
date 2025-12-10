// PlayerConstant - 播放器相关常量定�?
/**
 * 播放器常量类
 * 定义播放器相关的常量值，包括播放状态、错误码�? */
export class PlayerConstant {
  // 播放状�?  public static readonly STATE_IDLE: number = 0;
  public static readonly STATE_PREPARING: number = 1;
  public static readonly STATE_PREPARED: number = 2;
  public static readonly STATE_PLAYING: number = 3;
  public static readonly STATE_PAUSED: number = 4;
  public static readonly STATE_STOPPED: number = 5;
  public static readonly STATE_COMPLETED: number = 6;
  public static readonly STATE_ERROR: number = 7;
  public static readonly STATE_BUFFERING: number = 8;

  // 错误�?  public static readonly ERROR_UNKNOWN: number = -1;
  public static readonly ERROR_NETWORK: number = -100;
  public static readonly ERROR_DECODE: number = -200;
  public static readonly ERROR_PERMISSION: number = -300;
  public static readonly ERROR_FORMAT: number = -400;
  public static readonly ERROR_TIMEOUT: number = -500;
  public static readonly ERROR_RESOURCE: number = -600;

  // 播放速度选项
  public static readonly PLAYBACK_SPEEDS: number[] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  public static readonly DEFAULT_PLAYBACK_SPEED: number = 1.0;

  // 画质选项
  public static readonly VIDEO_QUALITY_AUTO: string = 'auto';
  public static readonly VIDEO_QUALITY_SD: string = 'sd'; // 标清
  public static readonly VIDEO_QUALITY_HD: string = 'hd'; // 高清
  public static readonly VIDEO_QUALITY_FHD: string = 'fhd'; // 全高�?  public static readonly VIDEO_QUALITY_4K: string = '4k'; // 4K

  // 屏幕比例
  public static readonly SCREEN_SCALE_DEFAULT: number = 0; // 默认
  public static readonly SCREEN_SCALE_16_9: number = 1;
  public static readonly SCREEN_SCALE_4_3: number = 2;
  public static readonly SCREEN_SCALE_FIT: number = 3;
  public static readonly SCREEN_SCALE_FILL: number = 4;
  public static readonly SCREEN_SCALE_ORIGINAL: number = 5;

  // 手势操作类型
  public static readonly GESTURE_TYPE_NONE: number = 0;
  public static readonly GESTURE_TYPE_PROGRESS: number = 1;
  public static readonly GESTURE_TYPE_VOLUME: number = 2;
  public static readonly GESTURE_TYPE_BRIGHTNESS: number = 3;

  // 播放模式
  public static readonly PLAY_MODE_SINGLE: number = 0;
  public static readonly PLAY_MODE_LIST_LOOP: number = 1;
  public static readonly PLAY_MODE_RANDOM: number = 2;

  // 其他常量
  public static readonly MAX_VOLUME: number = 100;
  public static readonly MAX_BRIGHTNESS: number = 100;
  public static readonly SEEK_STEP: number = 10000; // 10�?  public static readonly FAST_FORWARD_STEP: number = 30000; // 30�?  public static readonly MAX_SUBTITLE_TRACKS: number = 10;
  public static readonly MAX_AUDIO_TRACKS: number = 5;
  public static readonly AUTO_HIDE_CONTROLS_DELAY: number = 3000; // 3�?  public static readonly BUFFER_PROGRESS_UPDATE_INTERVAL: number = 500; // 500ms
  public static readonly MIN_BUFFER_DURATION: number = 2000; // 2�?  public static readonly MAX_BUFFER_DURATION: number = 30000; // 30�?
  /**
   * 获取播放状态的文本描述
   * @param state 播放状态码
   * @returns 状态描述文�?   */
  public static getStateText(state: number): string {
    switch (state) {
      case this.STATE_IDLE:
        return '空闲';
      case this.STATE_PREPARING:
        return '准备�?;
      case this.STATE_PREPARED:
        return '准备完成';
      case this.STATE_PLAYING:
        return '播放�?;
      case this.STATE_PAUSED:
        return '暂停';
      case this.STATE_STOPPED:
        return '停止';
      case this.STATE_COMPLETED:
        return '播放完成';
      case this.STATE_ERROR:
        return '播放错误';
      case this.STATE_BUFFERING:
        return '缓冲�?;
      default:
        return '未知状�?;
    }
  }

  /**
   * 获取错误码的文本描述
   * @param errorCode 错误�?   * @returns 错误描述文本
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
        return '格式不支�?;
      case this.ERROR_TIMEOUT:
        return '请求超时';
      case this.ERROR_RESOURCE:
        return '资源不可�?;
      default:
        return `错误�? ${errorCode}`;
    }
  }
}
