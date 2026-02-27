/**
 * 动画管理器
 * 统一管理和协调应用中的动画效果
 */
export class AnimationManager {
  private static instance: AnimationManager;
  private activeAnimations: Map<string, Animator> = new Map();
  private globalSettings: AnimationSettings = {
    defaultDuration: 300,
    defaultEasing: Curve.EaseInOut,
    isEnabled: true
  };

  private constructor() {}

  static getInstance(): AnimationManager {
    if (!AnimationManager.instance) {
      AnimationManager.instance = new AnimationManager();
    }
    return AnimationManager.instance;
  }

  /**
   * 创建动画控制器
   */
  createAnimator(config: AnimationConfig): Animator {
    const animator = Animator.create({
      duration: config.duration ?? this.globalSettings.defaultDuration,
      easing: config.easing ?? this.globalSettings.defaultEasing,
      delay: config.delay ?? 0,
      iterations: config.iterations ?? 1,
      fill: config.fill ?? FillMode.Forwards
    });

    if (config.id) {
      this.activeAnimations.set(config.id, animator);
    }

    return animator;
  }

  /**
   * 运行动画序列
   */
  async runSequence(animations: AnimationStep[]): Promise<void> {
    for (const step of animations) {
      await this.runAnimation(step);
    }
  }

  /**
   * 并行动画
   */
  async runParallel(animations: AnimationStep[]): Promise<void> {
    const promises = animations.map(step => this.runAnimation(step));
    await Promise.all(promises);
  }

  /**
   * 运行动画步骤
   */
  private runAnimation(step: AnimationStep): Promise<void> {
    return new Promise((resolve) => {
      const animator = this.createAnimator(step.config);
      
      animator.onFinish = () => {
        if (step.config.id) {
          this.activeAnimations.delete(step.config.id);
        }
        resolve();
      };

      if (step.onUpdate) {
        animator.onUpdate = step.onUpdate;
      }

      animator.play();
    });
  }

  /**
   * 停止指定动画
   */
  stopAnimation(id: string): boolean {
    const animator = this.activeAnimations.get(id);
    if (animator) {
      animator.stop();
      this.activeAnimations.delete(id);
      return true;
    }
    return false;
  }

  /**
   * 停止所有动画
   */
  stopAllAnimations(): void {
    for (const [id, animator] of this.activeAnimations.entries()) {
      animator.stop();
    }
    this.activeAnimations.clear();
  }

  /**
   * 暂停动画
   */
  pauseAnimation(id: string): boolean {
    const animator = this.activeAnimations.get(id);
    if (animator) {
      animator.pause();
      return true;
    }
    return false;
  }

  /**
   * 恢复动画
   */
  resumeAnimation(id: string): boolean {
    const animator = this.activeAnimations.get(id);
    if (animator) {
      animator.resume();
      return true;
    }
    return false;
  }

  /**
   * 获取动画状态
   */
  getAnimationState(id: string): AnimationState | null {
    const animator = this.activeAnimations.get(id);
    if (animator) {
      return {
        isRunning: animator.state === AnimatorState.Running,
        isPaused: animator.state === AnimatorState.Paused,
        progress: animator.progress
      };
    }
    return null;
  }

  /**
   * 设置全局动画设置
   */
  setGlobalSettings(settings: Partial<AnimationSettings>): void {
    this.globalSettings = { ...this.globalSettings, ...settings };
  }

  /**
   * 获取全局动画设置
   */
  getGlobalSettings(): AnimationSettings {
    return { ...this.globalSettings };
  }

  /**
   * 预定义动画效果
   */
  getPresets(): AnimationPresets {
    return {
      fadeIn: {
        config: {
          duration: 200,
          easing: Curve.EaseIn
        },
        onUpdate: (progress: number) => ({ opacity: progress })
      },
      fadeOut: {
        config: {
          duration: 200,
          easing: Curve.EaseOut
        },
        onUpdate: (progress: number) => ({ opacity: 1 - progress })
      },
      slideInLeft: {
        config: {
          duration: 300,
          easing: Curve.EaseInOut
        },
        onUpdate: (progress: number) => ({ transform: `translateX(${(1 - progress) * 100}%)` })
      },
      slideInRight: {
        config: {
          duration: 300,
          easing: Curve.EaseInOut
        },
        onUpdate: (progress: number) => ({ transform: `translateX(${-(1 - progress) * 100}%)` })
      },
      zoomIn: {
        config: {
          duration: 300,
          easing: Curve.EaseOut
        },
        onUpdate: (progress: number) => ({ transform: `scale(${0.8 + 0.2 * progress})` })
      },
      bounce: {
        config: {
          duration: 600,
          easing: Curve.ElasticOut,
          iterations: 2
        },
        onUpdate: (progress: number) => ({ transform: `scale(${1 + 0.2 * Math.sin(progress * Math.PI * 4)})` })
      }
    };
  }
}

/**
 * 动画配置接口
 */
interface AnimationConfig {
  /** 动画ID */
  id?: string;
  
  /** 持续时间(ms) */
  duration?: number;
  
  /** 缓动函数 */
  easing?: Curve;
  
  /** 延迟时间(ms) */
  delay?: number;
  
  /** 循环次数 */
  iterations?: number;
  
  /** 填充模式 */
  fill?: FillMode;
}

/**
 * 动画步骤接口
 */
interface AnimationStep {
  /** 动画配置 */
  config: AnimationConfig;
  
  /** 更新回调 */
  onUpdate?: (progress: number) => void;
}

/**
 * 动画状态接口
 */
interface AnimationState {
  /** 是否正在运行 */
  isRunning: boolean;
  
  /** 是否已暂停 */
  isPaused: boolean;
  
  /** 动画进度 */
  progress: number;
}

/**
 * 全局动画设置接口
 */
interface AnimationSettings {
  /** 默认持续时间 */
  defaultDuration: number;
  
  /** 默认缓动函数 */
  defaultEasing: Curve;
  
  /** 是否启用动画 */
  isEnabled: boolean;
}

/**
 * 预定义动画集合
 */
interface AnimationPresets {
  fadeIn: AnimationStep;
  fadeOut: AnimationStep;
  slideInLeft: AnimationStep;
  slideInRight: AnimationStep;
  zoomIn: AnimationStep;
  bounce: AnimationStep;
}