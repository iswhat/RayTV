/**
 * 视觉反馈管理器
 * 提供统一的用户交互反馈机制
 */
export class FeedbackManager {
  private static instance: FeedbackManager;
  private vibrationEnabled: boolean = true;
  private soundEnabled: boolean = true;
  private visualEnabled: boolean = true;

  private constructor() {}

  static getInstance(): FeedbackManager {
    if (!FeedbackManager.instance) {
      FeedbackManager.instance = new FeedbackManager();
    }
    return FeedbackManager.instance;
  }

  /**
   * 触摸反馈
   */
  touchFeedback(type: TouchFeedbackType = TouchFeedbackType.LIGHT): void {
    if (this.vibrationEnabled) {
      this.triggerVibration(type);
    }
    
    if (this.soundEnabled) {
      this.playSound(SoundType.CLICK);
    }
    
    if (this.visualEnabled) {
      this.showVisualFeedback(type);
    }
  }

  /**
   * 成功反馈
   */
  successFeedback(): void {
    if (this.vibrationEnabled) {
      this.triggerVibration(TouchFeedbackType.SUCCESS);
    }
    
    if (this.soundEnabled) {
      this.playSound(SoundType.SUCCESS);
    }
    
    if (this.visualEnabled) {
      this.showVisualFeedback(TouchFeedbackType.SUCCESS);
    }
  }

  /**
   * 错误反馈
   */
  errorFeedback(): void {
    if (this.vibrationEnabled) {
      this.triggerVibration(TouchFeedbackType.ERROR);
    }
    
    if (this.soundEnabled) {
      this.playSound(SoundType.ERROR);
    }
    
    if (this.visualEnabled) {
      this.showVisualFeedback(TouchFeedbackType.ERROR);
    }
  }

  /**
   * 警告反馈
   */
  warningFeedback(): void {
    if (this.vibrationEnabled) {
      this.triggerVibration(TouchFeedbackType.WARNING);
    }
    
    if (this.soundEnabled) {
      this.playSound(SoundType.WARNING);
    }
    
    if (this.visualEnabled) {
      this.showVisualFeedback(TouchFeedbackType.WARNING);
    }
  }

  /**
   * 加载反馈
   */
  loadingFeedback(): void {
    if (this.visualEnabled) {
      this.showLoadingIndicator();
    }
  }

  /**
   * 进度反馈
   */
  progressFeedback(progress: number): void {
    if (this.visualEnabled) {
      this.updateProgressIndicator(progress);
    }
  }

  /**
   * 触发震动反馈
   */
  private triggerVibration(type: TouchFeedbackType): void {
    try {
      // 模拟震动反馈实现
      console.log(`Vibration triggered: ${type}`);
      // 在实际应用中调用系统震动API
    } catch (error) {
      console.warn('Vibration not available:', error);
    }
  }

  /**
   * 播放声音反馈
   */
  private playSound(type: SoundType): void {
    try {
      // 模拟声音播放实现
      console.log(`Sound played: ${type}`);
      // 在实际应用中调用音频播放API
    } catch (error) {
      console.warn('Sound playback not available:', error);
    }
  }

  /**
   * 显示视觉反馈
   */
  private showVisualFeedback(type: TouchFeedbackType): void {
    // 这里可以集成到UI组件中显示视觉反馈
    console.log(`Visual feedback shown: ${type}`);
  }

  /**
   * 显示加载指示器
   */
  private showLoadingIndicator(): void {
    console.log('Loading indicator shown');
  }

  /**
   * 更新进度指示器
   */
  private updateProgressIndicator(progress: number): void {
    console.log(`Progress updated: ${progress}%`);
  }

  /**
   * 设置反馈选项
   */
  setFeedbackOptions(options: FeedbackOptions): void {
    if (options.vibration !== undefined) {
      this.vibrationEnabled = options.vibration;
    }
    
    if (options.sound !== undefined) {
      this.soundEnabled = options.sound;
    }
    
    if (options.visual !== undefined) {
      this.visualEnabled = options.visual;
    }
  }

  /**
   * 获取当前反馈设置
   */
  getFeedbackOptions(): FeedbackOptions {
    return {
      vibration: this.vibrationEnabled,
      sound: this.soundEnabled,
      visual: this.visualEnabled
    };
  }

  /**
   * 预定义反馈组合
   */
  getPresets(): FeedbackPresets {
    return {
      buttonPress: () => this.touchFeedback(TouchFeedbackType.LIGHT),
      formSubmit: () => this.successFeedback(),
      validationError: () => this.errorFeedback(),
      warning: () => this.warningFeedback(),
      pageLoad: () => this.loadingFeedback()
    };
  }
}

/**
 * 触摸反馈类型枚举
 */
enum TouchFeedbackType {
  /** 轻触 */
  LIGHT = 'light',
  
  /** 中等 */
  MEDIUM = 'medium',
  
  /** 重触 */
  HEAVY = 'heavy',
  
  /** 成功 */
  SUCCESS = 'success',
  
  /** 错误 */
  ERROR = 'error',
  
  /** 警告 */
  WARNING = 'warning',
  
  /** 选择 */
  SELECTION = 'selection'
}

/**
 * 声音类型枚举
 */
enum SoundType {
  /** 点击声 */
  CLICK = 'click',
  
  /** 成功声 */
  SUCCESS = 'success',
  
  /** 错误声 */
  ERROR = 'error',
  
  /** 警告声 */
  WARNING = 'warning',
  
  /** 提示声 */
  NOTIFICATION = 'notification'
}

/**
 * 反馈选项接口
 */
interface FeedbackOptions {
  /** 是否启用震动 */
  vibration?: boolean;
  
  /** 是否启用声音 */
  sound?: boolean;
  
  /** 是否启用视觉反馈 */
  visual?: boolean;
}

/**
 * 预定义反馈组合
 */
interface FeedbackPresets {
  /** 按钮按下 */
  buttonPress: () => void;
  
  /** 表单提交 */
  formSubmit: () => void;
  
  /** 验证错误 */
  validationError: () => void;
  
  /** 警告提示 */
  warning: () => void;
  
  /** 页面加载 */
  pageLoad: () => void;
}