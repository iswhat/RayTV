/**
 * 动画系统 - Animation System
 *
 * 提供统一的动画配置和工具方法
 */

/**
 * 动画类型
 */
export enum AnimationType {
  FADE = 'fade',
  SLIDE = 'slide',
  SCALE = 'scale',
  ROTATE = 'rotate',
  BOUNCE = 'bounce',
  FLIP = 'flip',
  PULSE = 'pulse',
  SHAKE = 'shake'
}

/**
 * 动画方向
 */
export enum AnimationDirection {
  IN = 'in',
  OUT = 'out',
  UP = 'up',
  DOWN = 'down',
  LEFT = 'left',
  RIGHT = 'right'
}

/**
 * 缓动函数
 */
export enum EasingFunction {
  LINEAR = 'linear',
  EASE = 'ease',
  EASE_IN = 'ease-in',
  EASE_OUT = 'ease-out',
  EASE_IN_OUT = 'ease-in-out',
  BOUNCE = 'cubic-bezier(0.68, -0.55, 0.265, 1.55)',
  ELASTIC = 'cubic-bezier(0.68, -0.6, 0.32, 1.6)',
  BACK = 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
}

/**
 * 动画配置
 */
export interface AnimationConfig {
  type: AnimationType;
  direction?: AnimationDirection;
  duration: number;
  delay: number;
  easing: EasingFunction;
  iterations: number;
  fillMode: string; // 'none' | 'forwards' | 'backwards' | 'both'
}

/**
 * 关键帧
 */
export interface Keyframe {
  offset: number;
  properties: Record<string, Object>;
}

/**
 * 关键帧动画配置
 */
export interface KeyframeAnimationConfig {
  keyframes: Keyframe[];
  duration: number;
  delay: number;
  easing: EasingFunction;
  iterations: number;
  fillMode: string;
}

/**
 * 动画状态
 */
export interface AnimationState {
  isAnimating: boolean;
  animationId: string;
  startTime: number;
  endTime: number;
}

/**
 * 动画系统
 */
export class AnimationSystem {
  // 预设动画配置
  public static readonly PresetAnimations: Record<string, AnimationConfig> = {
    fadeIn: {
      type: AnimationType.FADE,
      direction: AnimationDirection.IN,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE,
      iterations: 1,
      fillMode: 'forwards'
    },
    fadeOut: {
      type: AnimationType.FADE,
      direction: AnimationDirection.OUT,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE,
      iterations: 1,
      fillMode: 'forwards'
    },
    slideInLeft: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.LEFT,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    },
    slideInRight: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.RIGHT,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    },
    slideInUp: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.UP,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    },
    slideInDown: {
      type: AnimationType.SLIDE,
      direction: AnimationDirection.DOWN,
      duration: 500,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    },
    scaleIn: {
      type: AnimationType.SCALE,
      direction: AnimationDirection.IN,
      duration: 300,
      delay: 0,
      easing: EasingFunction.EASE_OUT,
      iterations: 1,
      fillMode: 'forwards'
    },
    scaleOut: {
      type: AnimationType.SCALE,
      direction: AnimationDirection.OUT,
      duration: 300,
      delay: 0,
      easing: EasingFunction.EASE_IN,
      iterations: 1,
      fillMode: 'forwards'
    },
    bounce: {
      type: AnimationType.BOUNCE,
      duration: 1000,
      delay: 0,
      easing: EasingFunction.BOUNCE,
      iterations: 1,
      fillMode: 'forwards'
    },
    pulse: {
      type: AnimationType.PULSE,
      duration: 1000,
      delay: 0,
      easing: EasingFunction.EASE_IN_OUT,
      iterations: -1,
      fillMode: 'both'
    }
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
    fillMode: string = 'forwards'
  ): KeyframeAnimationConfig {
    return { keyframes, duration, delay, easing, iterations, fillMode };
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
   * 创建脉冲动画（无限循环）
   */
  public static createPulseAnimation(duration: number = 1000, delay: number = 0): AnimationConfig {
    return {
      type: AnimationType.PULSE,
      duration,
      delay,
      easing: EasingFunction.EASE_IN_OUT,
      iterations: -1,
      fillMode: 'both'
    };
  }

  /**
   * 生成唯一的动画 ID
   */
  public static generateAnimationId(): string {
    return `animation_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }

  /**
   * 计算动画结束时间戳
   */
  public static calculateEndTime(config: AnimationConfig | KeyframeAnimationConfig): number {
    return Date.now() + config.duration + config.delay;
  }

  /**
   * 检查动画是否仍在进行中
   */
  public static isAnimationActive(state: AnimationState | null): boolean {
    if (!state) {
      return false;
    }
    return state.isAnimating && Date.now() < state.endTime;
  }

  /**
   * 创建交错动画配置列表
   */
  public static createStaggeredAnimations(
    count: number,
    baseConfig: AnimationConfig,
    staggerDelay: number = 100
  ): AnimationConfig[] {
    const animations: AnimationConfig[] = [];
    for (let i = 0; i < count; i++) {
      animations.push({
        type: baseConfig.type,
        direction: baseConfig.direction,
        duration: baseConfig.duration,
        delay: baseConfig.delay + i * staggerDelay,
        easing: baseConfig.easing,
        iterations: baseConfig.iterations,
        fillMode: baseConfig.fillMode
      });
    }
    return animations;
  }
}

export default AnimationSystem;
