/**
 * RemoteKeyConstant - Remote control key constant definitions | 遥控器按键常量定义
 * Define remote control key values and function mappings | 定义遥控器按键的键值和功能映射
 */
export class RemoteKeyConstant {
  // Direction keys | 方向键
  public static readonly KEY_UP: number = 19;      // Up key | 上键
  public static readonly KEY_DOWN: number = 20;    // Down key | 下键
  public static readonly KEY_LEFT: number = 21;    // Left key | 左键
  public static readonly KEY_RIGHT: number = 22;   // Right key | 右键

  // Function keys | 功能键
  public static readonly KEY_OK: number = 23;      // OK key | 确认键
  public static readonly KEY_BACK: number = 4;     // Back key | 返回键
  public static readonly KEY_HOME: number = 3;     // Home key | 主页键
  public static readonly KEY_MENU: number = 82;    // Menu key | 菜单键
  public static readonly KEY_SETTINGS: number = 176; // Settings key | 设置键

  // Number keys | 数字键
  public static readonly KEY_0: number = 7;        // Number 0 | 数字0
  public static readonly KEY_1: number = 8;        // Number 1 | 数字1
  public static readonly KEY_2: number = 9;        // Number 2 | 数字2
  public static readonly KEY_3: number = 10;       // Number 3 | 数字3
  public static readonly KEY_4: number = 11;       // Number 4 | 数字4
  public static readonly KEY_5: number = 12;       // Number 5 | 数字5
  public static readonly KEY_6: number = 13;       // Number 6 | 数字6
  public static readonly KEY_7: number = 14;       // Number 7 | 数字7
  public static readonly KEY_8: number = 15;       // Number 8 | 数字8
  public static readonly KEY_9: number = 16;       // Number 9 | 数字9

  // Media control keys | 媒体控制键
  public static readonly KEY_PLAY_PAUSE: number = 85;  // Play/Pause | 播放/暂停
  public static readonly KEY_PLAY: number = 126;       // Play key | 播放键
  public static readonly KEY_PAUSE: number = 127;      // Pause key | 暂停键
  public static readonly KEY_STOP: number = 86;        // Stop key | 停止键
  public static readonly KEY_NEXT: number = 87;        // Next key | 下一曲键
  public static readonly KEY_PREVIOUS: number = 88;    // Previous key | 上一曲键
  public static readonly KEY_FAST_FORWARD: number = 90; // Fast forward key | 快进键
  public static readonly KEY_REWIND: number = 89;      // Rewind key | 快退键
  public static readonly KEY_VOLUME_UP: number = 24;   // Volume up key | 音量加键
  public static readonly KEY_VOLUME_DOWN: number = 25; // Volume down key | 音量减键
  public static readonly KEY_MUTE: number = 164;       // Mute key | 静音键

  // Other common keys | 其他常用键
  public static readonly KEY_SEARCH: number = 84;      // Search key | 搜索键
  public static readonly KEY_INFO: number = 45;        // Info key | 信息键
  public static readonly KEY_SUBTITLE: number = 177;   // Subtitle key | 字幕键
  public static readonly KEY_AUDIO: number = 178;      // Audio key | 音频键
  public static readonly KEY_CHANNEL_UP: number = 166; // Channel up key | 频道加键
  public static readonly KEY_CHANNEL_DOWN: number = 167; // Channel down key | 频道减键
  public static readonly KEY_PAGE_UP: number = 92;     // Page up key | 上一页键
  public static readonly KEY_PAGE_DOWN: number = 93;   // Page down key | 下一页键

  // HarmonyOS specific keys | HarmonyOS特有键
  public static readonly KEY_ASSISTANT: number = 179;  // Voice assistant key | 语音助手键
  public static readonly KEY_SCREEN_CAST: number = 180; // Screen cast key | 投屏键
  public static readonly KEY_SMART_INTERACTION: number = 181; // Smart interaction key | 智能交互键

  /**
   * Check if it's a direction key | 判断是否为方向键
   * @param keyCode Key code | 按键代码
   * @returns Whether it's a direction key | 是否为方向键
   */
  public static isDirectionKey(keyCode: number): boolean {
    return [this.KEY_UP, this.KEY_DOWN, this.KEY_LEFT, this.KEY_RIGHT].includes(keyCode);
  }

  /**
   * Check if it's a media control key | 判断是否为媒体控制键
   * @param keyCode Key code | 按键代码
   * @returns Whether it's a media control key | 是否为媒体控制键
   */
  public static isMediaKey(keyCode: number): boolean {
    return [
      this.KEY_PLAY_PAUSE, this.KEY_PLAY, this.KEY_PAUSE, this.KEY_STOP,
      this.KEY_NEXT, this.KEY_PREVIOUS, this.KEY_FAST_FORWARD, this.KEY_REWIND
    ].includes(keyCode);
  }

  /**
   * Check if it's a volume control key | 判断是否为音量控制键
   * @param keyCode Key code | 按键代码
   * @returns Whether it's a volume control key | 是否为音量控制键
   */
  public static isVolumeKey(keyCode: number): boolean {
    return [this.KEY_VOLUME_UP, this.KEY_VOLUME_DOWN, this.KEY_MUTE].includes(keyCode);
  }

  /**
   * Check if it's a number key | 判断是否为数字键
   * @param keyCode Key code | 按键代码
   * @returns Whether it's a number key | 是否为数字键
   */
  public static isNumberKey(keyCode: number): boolean {
    return keyCode >= this.KEY_0 && keyCode <= this.KEY_9;
  }

  /**
   * Get text description of key | 获取按键的文本描述
   * @param keyCode Key code | 按键代码
   * @returns Key description text | 按键描述文本
   */
  public static getKeyText(keyCode: number): string {
    const keyMap: Record<number, string> = {
      [this.KEY_UP]: '上',
      [this.KEY_DOWN]: '下',
      [this.KEY_LEFT]: '左',
      [this.KEY_RIGHT]: '右',
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
      [this.KEY_AUDIO]: '音频',
      [this.KEY_ASSISTANT]: '语音助手',
      [this.KEY_SCREEN_CAST]: '投屏'
    };

    // 添加数字键 // Add number keys
    for (let i = 0; i <= 9; i++) {
      keyMap[this.KEY_0 + i] = String(i);
    }

    return keyMap[keyCode] || `未知键(${keyCode})`;
  }
}
