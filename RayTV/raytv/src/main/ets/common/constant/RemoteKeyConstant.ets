// RemoteKeyConstant - 遥控器按键常量定�?
/**
 * 遥控器按键常量类
 * 定义遥控器按键的键值和功能映射
 */
export class RemoteKeyConstant {
  // 方向�?  public static readonly KEY_UP: number = 19;
  public static readonly KEY_DOWN: number = 20;
  public static readonly KEY_LEFT: number = 21;
  public static readonly KEY_RIGHT: number = 22;

  // 功能�?  public static readonly KEY_OK: number = 23;      // 确认�?  public static readonly KEY_BACK: number = 4;     // 返回�?  public static readonly KEY_HOME: number = 3;
  public static readonly KEY_MENU: number = 82;    // 菜单�?  public static readonly KEY_SETTINGS: number = 176; // 设置�?
  // 数字�?  public static readonly KEY_0: number = 7;
  public static readonly KEY_1: number = 8;
  public static readonly KEY_2: number = 9;
  public static readonly KEY_3: number = 10;
  public static readonly KEY_4: number = 11;
  public static readonly KEY_5: number = 12;
  public static readonly KEY_6: number = 13;
  public static readonly KEY_7: number = 14;
  public static readonly KEY_8: number = 15;
  public static readonly KEY_9: number = 16;

  // 媒体控制�?  public static readonly KEY_PLAY_PAUSE: number = 85;  // 播放/暂停
  public static readonly KEY_PLAY: number = 126;
  public static readonly KEY_PAUSE: number = 127;
  public static readonly KEY_STOP: number = 86;
  public static readonly KEY_NEXT: number = 87;
  public static readonly KEY_PREVIOUS: number = 88;
  public static readonly KEY_FAST_FORWARD: number = 90;
  public static readonly KEY_REWIND: number = 89;
  public static readonly KEY_VOLUME_UP: number = 24;
  public static readonly KEY_VOLUME_DOWN: number = 25;
  public static readonly KEY_MUTE: number = 164;

  // 其他常用�?  public static readonly KEY_SEARCH: number = 84;
  public static readonly KEY_INFO: number = 45;
  public static readonly KEY_SUBTITLE: number = 177;
  public static readonly KEY_AUDIO: number = 178;
  public static readonly KEY_CHANNEL_UP: number = 166;
  public static readonly KEY_CHANNEL_DOWN: number = 167;
  public static readonly KEY_PAGE_UP: number = 92;
  public static readonly KEY_PAGE_DOWN: number = 93;

  // HarmonyOS特殊�?  public static readonly KEY_ASSISTANT: number = 179;  // 语音助手�?  public static readonly KEY_SCREEN_CAST: number = 180; // 投屏�?  public static readonly KEY_SMART_INTERACTION: number = 181; // 智慧交互�?
  /**
   * 判断是否为方向键
   * @param keyCode 按键代码
   * @returns 是否为方向键
   */
  public static isDirectionKey(keyCode: number): boolean {
    return [this.KEY_UP, this.KEY_DOWN, this.KEY_LEFT, this.KEY_RIGHT].includes(keyCode);
  }

  /**
   * 判断是否为媒体控制键
   * @param keyCode 按键代码
   * @returns 是否为媒体控制键
   */
  public static isMediaKey(keyCode: number): boolean {
    return [
      this.KEY_PLAY_PAUSE, this.KEY_PLAY, this.KEY_PAUSE, this.KEY_STOP,
      this.KEY_NEXT, this.KEY_PREVIOUS, this.KEY_FAST_FORWARD, this.KEY_REWIND
    ].includes(keyCode);
  }

  /**
   * 判断是否为音量控制键
   * @param keyCode 按键代码
   * @returns 是否为音量控制键
   */
  public static isVolumeKey(keyCode: number): boolean {
    return [this.KEY_VOLUME_UP, this.KEY_VOLUME_DOWN, this.KEY_MUTE].includes(keyCode);
  }

  /**
   * 判断是否为数字键
   * @param keyCode 按键代码
   * @returns 是否为数字键
   */
  public static isNumberKey(keyCode: number): boolean {
    return keyCode >= this.KEY_0 && keyCode <= this.KEY_9;
  }

  /**
   * 获取按键的文本描�?   * @param keyCode 按键代码
   * @returns 按键描述文本
   */
  public static getKeyText(keyCode: number): string {
    const keyMap: Record<number, string> = {
      [this.KEY_UP]: '�?,
      [this.KEY_DOWN]: '�?,
      [this.KEY_LEFT]: '�?,
      [this.KEY_RIGHT]: '�?,
      [this.KEY_OK]: '确认',
      [this.KEY_BACK]: '返回',
      [this.KEY_HOME]: '主页',
      [this.KEY_MENU]: '菜单',
      [this.KEY_SETTINGS]: '设置',
      [this.KEY_PLAY_PAUSE]: '播放/暂停',
      [this.KEY_VOLUME_UP]: '音量+',
      [this.KEY_VOLUME_DOWN]: '音量-',
      [this.KEY_MUTE]: '静音',
      [this.KEY_SEARCH]: '搜索',
      [this.KEY_INFO]: '信息',
      [this.KEY_SUBTITLE]: '字幕',
      [this.KEY_AUDIO]: '音轨',
      [this.KEY_ASSISTANT]: '语音助手',
      [this.KEY_SCREEN_CAST]: '投屏'
    };

    // 添加数字�?    for (let i = 0; i <= 9; i++) {
      keyMap[this.KEY_0 + i] = String(i);
    }

    return keyMap[keyCode] || `未知�?${keyCode})`;
  }
}
