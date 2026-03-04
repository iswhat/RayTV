/**
 * 动画系统 - Animation System
 * 
 * 提供统一的动画配置和工具方法
 */

/**
 * 动画类型
 */
export enum AnimationType {
  FADE = 'fade',          // 淡入淡出
  SLIDE = 'slide',        // 滑动
  SCALE = 'scale',        // 缩放
  ROTATE = 'rotate',      // 旋转
  BOUNCE = 'bounce',      // 弹跳
  FLIP = 'flip',          // 翻转
  PULSE = 'pulse',        // 脉冲
  SHAKE = 'shake'         // 摇晃
}

/**
 * 动画方向
 */
export enum AnimationDirection {
  IN = 'in',              // 进入
  OUT = 'out',            // 退出
  UP = 'up',              // 向上
  DOWN = 'down',          // 向下
  LEFT = 'left',          // 向左
  RIGHT = 'right'         // 向右
}

/**
 * 缓动函数
 */
export enum EasingFunction {
  LINEAR = 'linear',                  // 线性
  EASE = 'ease',                      // 缓动
  EASE_IN = 'ease-in',                // 缓入
  EASE_OUT = 'ease-out',              // 缓出
  EASE_IN_OUT = 'ease-in-out',        // 缓入缓出
  BOUNCE = 'cubic-bezier(0.68, -0.55, 0.265, 1.55)', // 弹跳
  ELASTIC = 'cubic-bezier(0.68, -0.6, 0.32, 1.6)',   // 弹性
  BACK = 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'    // 回退
}

/**
 * 动画配置
 */
export interface AnimationConfig {
  type: AnimationType;             // 动画类型
  direction?: AnimationDirection;  // 动画方向
  duration: number;                // 动画持续时间（毫秒）
  delay: number;                   // 动画延迟（毫秒）
  easing: EasingFunction;          // 缓动函数
  iterations: number;              // 动画重复次数
  fillMode: 'none' | 'forwards' | 'backwards' | 'both'; // 填充模式
}

/**
 * 关键帧
 */
export interface Keyframe {
  offset: number;      // 关键帧偏移（0-1）
  properties: Record<string, any>; // 关键帧属性
}

/**
 * 关键帧动画配置
 */
export interface KeyframeAnimationConfig {
  keyframes: Keyframe[];           // 关键帧数组
  duration: number;                // 动画持续时间（毫秒）
  delay: number;                   // 动画延迟（毫秒）
  easing: EasingFunction;          // 缓动函数
  iterations: number;              // 动画重复次数
  fillMode: 'none' | 'forwards' | 'backwards' | 'both'; // 填充模式
}

/**
 * 动画状态
 */
export interface AnimationState {
  isAnimating: boolean;   // 是否正在动画中
  animationId: string;    // 动画ID
  startTime: number;      // 动画开始时间
  endTime: number;        // 动画结束时间
}

/**
 * 动画系统
 */
export class AnimationSystem {
  // 预设动画配置
  public static readonly PresetAnimations = {
    // 淡入淡出
    fadeIn: {
      type: AnimationType.FADE,
      direction: AnimationDirection.IN,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    fadeOut: {
      type: AnimationType.FADE,
      direction: AnimationDirection.OUT,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    // 滑动
    slideInLeft: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.LEFT,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    slideInRight: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.RIGHT,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    slideInUp: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.UP,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    slideInDown: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.DOWN,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    // 缩放
    scaleIn: {
      type: AnimationType.SCALE,
      direction: AnimationDirection.IN,
      duration: 300,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    scaleOut: {
      type: AnimationType.SCALE,
      direction: AnimationDirection.OUT,
      duration: 300,
      delay: 0,
      easing: EasingFunction.EASE_IN,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    // 弹跳
    bounce: {
      type: AnimationType.BOUNCE,
      duration: 1000,
      delay: 0,
      easing: EasingFunction.BOUNCE,
      iterations: 1,
      fillMode: 'forwards'
    } as AnimationConfig,
    
    // 脉冲
    pulse: {
      type: AnimationType.PULSE,
      duration: 1000,
      delay: 0,
      easing: EasingFunction.EASE_IN_OUT,
      iterations: -1, // 无限循环
      fillMode: 'both'
    } as AnimationConfig
  };

  // 缓动函数映射
  public static readonly EasingFunctions = {
    [EasingFunction.LINEAR]: 'linear',
    [EasingFunction.EASE]: 'ease',
    [EasingFunction.EASE_IN]: 'ease-in',
    [EasingFunction.EASE_OUT]: 'ease-out',
    [EasingFunction.EASE_IN_OUT]: 'ease-in-out',
    [EasingFunction.BOUNCE]: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
    [EasingFunction.ELASTIC]: 'cubic-bezier(0.68, -0.6, 0.32, 1.6)',
    [EasingFunction.BACK]: 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
  };

  /**
   * 创建淡入动画
   */
  public static createFadeInAnimation(duration: number = 500, delay: number = 0): AnimationConfig {
    return {
      type: AnimationType.FADE,
      direction: AnimationDirection.IN,
      duration,
      delay,
      easing: EasingFunction.EASE,
      iterations: 1,
      fillMode: 'forwards'
    };
  }

  /**
   * 创建淡出动画
   */
  public static createFadeOutAnimation(duration: number = 500, delay: number = 0): AnimationConfig {
    return {
      type: AnimationType.FADE,
      direction: AnimationDirection.OUT,
      duration,
      delay,
      easing: EasingFunction.EASE,
      iterations: 1,
      fillMode: 'forwards'
    };
  }

  /**
   * 创建滑动动画
   */
  public static createSlideAnimation(
    direction: AnimationDirection,
    duration: number = 500,
    delay: number = 0
  ): AnimationConfig {
    return {
      type: AnimationType.SLIDE,
      direction,
      duration,
      delay,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    };
  }

  /**
   * 创建缩放动画
   */
  public static createScaleAnimation(
    direction: AnimationDirection,
    duration: number = 300,
    delay: number = 0
  ): AnimationConfig {
    return {
      type: AnimationType.SCALE,
      direction,
      duration,
      delay,
      easing: direction === AnimationDirection.IN ? EasingFunction.EASE_OUT : EasingFunction.EASE_IN,
      iterations: 1,
      fillMode: 'forwards'
    };
  }

  /**
   * 创建关键帧动画
   */
  public static createKeyframeAnimation(
    keyframes: Keyframe[],
    duration: number = 1000,
    delay: number = 0,
    easing: EasingFunction = EasingFunction.EASE,
    iterations: number = 1,
    fillMode: 'none' | 'forwards' | 'backwards' | 'both' = 'forwards'
  ): KeyframeAnimationConfig {
    return {
      keyframes,
      duration,
      delay,
      easing,
      iterations,
      fillMode
    };
  }

  /**
   * 创建弹跳动画
   */
  public static createBounceAnimation(duration: number = 1000, delay: number = 0): AnimationConfig {
    return {
      type: AnimationType.BOUNCE,
      duration,
      delay,
      easing: EasingFunction.BOUNCE,
      iterations: 1,
      fillMode: 'forwards'
    };
  }

  /**
   * 创建脉冲动画
   */
  public static createPulseAnimation(duration: number = 1000, delay: number = 0): AnimationConfig {
    return {
      type: AnimationType.PULSE,
      duration,
      delay,
      easing: EasingFunction.EASE_IN_OUT,
      iterations: -1, // 无限循环
      fillMode: 'both'
    };
  }

  /**
   * 生成唯一的动画ID
   */
  public static generateAnimationId(): string {
    return `animation_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }

  /**
   * 计算动画结束时间
   */
  public static calculateEndTime(config: AnimationConfig | KeyframeAnimationConfig): number {
    return Date.now() + config.duration + config.delay;
  }

  /**
   * 检查动画是否正在进行中
   */
  public static isAnimationActive(state: AnimationState | null): boolean {
    if (!state) return false;
    return state.isAnimating && Date.now() < state.endTime;
  }

  /**
   * 创建交错动画配置
   */
  public static createStaggeredAnimations(
    count: number,
    baseConfig: AnimationConfig,
    staggerDelay: number = 100
  ): AnimationConfig[] {
    const animations: AnimationConfig[] = [];
    
    for (let i = 0; i < count; i++) {
      animations.push({
        ...baseConfig,
        delay: baseConfig.delay + (i * staggerDelay)
      });
    }
    
    return animations;
  }
}

// 导出默认实例
export default AnimationSystem;