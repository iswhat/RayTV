/**
 * 动画系统 | Animation System
 * 管理应用程序的动画效果和过渡效果
 * Manages application animations and transition effects
 */
import Logger from '../common/util/Logger';

// ==================== 动画类型定义 | Animation Type Definitions ====================

/**
 * 动画类型 | Animation Types
 */
export type AnimationType = 
  | 'fade'          // 淡入淡出
  | 'slide'         // 滑动
  | 'scale'         // 缩放
  | 'rotate'        // 旋转
  | 'bounce'        // 弹跳
  | 'shake'         // 摇晃
  | 'pulse'         // 脉冲
  | 'flip'          // 翻转
  | 'zoom'          // 缩放
  | 'custom';       // 自定义

/**
 * 动画方向 | Animation Directions
 */
export type AnimationDirection = 
  | 'in'            // 进入
  | 'out'           // 离开
  | 'left'          // 左侧
  | 'right'         // 右侧
  | 'up'            // 上方
  | 'down'          // 下方
  | 'center'        // 中心
  | 'top-left'      // 左上
  | 'top-right'     // 右上
  | 'bottom-left'   // 左下
  | 'bottom-right'; // 右下

/**
 * 缓动函数 | Easing Functions
 */
export type EasingFunction = 
  | 'linear'        // 线性
  | 'easeIn'        // 先慢后快
  | 'easeOut'       // 先快后慢
  | 'easeInOut'     // 先慢中快后慢
  | 'easeInQuad'    // 二次方缓入
  | 'easeOutQuad'   // 二次方缓出
  | 'easeInOutQuad' // 二次方缓入缓出
  | 'easeInCubic'   // 三次方缓入
  | 'easeOutCubic'  // 三次方缓出
  | 'easeInOutCubic'// 三次方缓入缓出
  | 'spring'        // 弹簧效果
  | 'bounce'        // 弹跳效果
  | 'elastic';      // 弹性效果

/**
 * 动画配置 | Animation Configuration
 */
export interface AnimationConfig {
  type: AnimationType;
  duration: number;           // 持续时间(ms)
  delay?: number;             // 延迟时间(ms)
  easing: EasingFunction;     // 缓动函数
  direction?: AnimationDirection; // 方向
  iterations?: number;        // 迭代次数 (Infinity表示无限循环)
  fillMode?: 'none' | 'forwards' | 'backwards' | 'both'; // 填充模式
  reverse?: boolean;          // 是否反向播放
}

/**
 * 关键帧动画配置 | Keyframe Animation Configuration
 */
export interface KeyframeAnimationConfig {
  keyframes: Keyframe[];
  duration: number;
  easing?: EasingFunction;
  iterations?: number;
  delay?: number;
  fillMode?: 'none' | 'forwards' | 'backwards' | 'both';
}

/**
 * 关键帧 | Keyframe
 */
export interface Keyframe {
  offset: number;             // 0-1之间的偏移量
  transform?: string;         // 变换属性
  opacity?: number;           // 透明度
  backgroundColor?: string;   // 背景色
  color?: string;             // 文字颜色
  boxShadow?: string;         // 阴影
  borderRadius?: string;      // 圆角
  [key: string]: any;         // 其他CSS属性
}

/**
 * 动画状态 | Animation State
 */
export interface AnimationState {
  id: string;
  element: HTMLElement | null;
  config: AnimationConfig | KeyframeAnimationConfig;
  startTime: number;
  currentTime: number;
  isPlaying: boolean;
  isPaused: boolean;
  progress: number;           // 0-1之间的进度
}

// ==================== 缓动函数实现 | Easing Function Implementations ====================

/**
 * 缓动函数映射 | Easing Function Map
 */
export const EasingFunctions: Record<EasingFunction, (t: number) => number> = {
  linear: (t: number) => t,
  
  easeIn: (t: number) => t * t,
  easeOut: (t: number) => t * (2 - t),
  easeInOut: (t: number) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t,
  
  easeInQuad: (t: number) => t * t,
  easeOutQuad: (t: number) => t * (2 - t),
  easeInOutQuad: (t: number) => t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t,
  
  easeInCubic: (t: number) => t * t * t,
  easeOutCubic: (t: number) => (--t) * t * t + 1,
  easeInOutCubic: (t: number) => t < 0.5 ? 4 * t * t * t : (t - 1) * (2 * t - 2) * (2 * t - 2) + 1,
  
  spring: (t: number) => 1 - Math.cos(t * 4.5 * Math.PI) * Math.exp(-6 * t),
  
  bounce: (t: number) => {
    if (t < 1 / 2.75) {
      return 7.5625 * t * t;
    } else if (t < 2 / 2.75) {
      return 7.5625 * (t -= 1.5 / 2.75) * t + 0.75;
    } else if (t < 2.5 / 2.75) {
      return 7.5625 * (t -= 2.25 / 2.75) * t + 0.9375;
    } else {
      return 7.5625 * (t -= 2.625 / 2.75) * t + 0.984375;
    }
  },
  
  elastic: (t: number) => {
    const amplitude = 1;
    const period = 0.3;
    if (t === 0 || t === 1) return t;
    const s = period / (2 * Math.PI) * Math.asin(1 / amplitude);
    return -(amplitude * Math.pow(2, 10 * (t -= 1)) * Math.sin((t - s) * (2 * Math.PI) / period));
  }
};

// ==================== 预设动画配置 | Preset Animation Configurations ====================

/**
 * 预设动画 | Preset Animations
 */
export const PresetAnimations: Record<string, AnimationConfig> = {
  fadeIn: {
    type: 'fade',
    duration: 300,
    easing: 'easeOut',
    direction: 'in'
  },
  
  fadeOut: {
    type: 'fade',
    duration: 300,
    easing: 'easeIn',
    direction: 'out'
  },
  
  slideInLeft: {
    type: 'slide',
    duration: 400,
    easing: 'easeOut',
    direction: 'left'
  },
  
  slideInRight: {
    type: 'slide',
    duration: 400,
    easing: 'easeOut',
    direction: 'right'
  },
  
  slideOutLeft: {
    type: 'slide',
    duration: 400,
    easing: 'easeIn',
    direction: 'left'
  },
  
  slideOutRight: {
    type: 'slide',
    duration: 400,
    easing: 'easeIn',
    direction: 'right'
  },
  
  scaleIn: {
    type: 'scale',
    duration: 300,
    easing: 'easeOut',
    direction: 'in'
  },
  
  scaleOut: {
    type: 'scale',
    duration: 300,
    easing: 'easeIn',
    direction: 'out'
  },
  
  pulse: {
    type: 'pulse',
    duration: 1000,
    easing: 'easeInOut',
    iterations: Infinity
  },
  
  bounce: {
    type: 'bounce',
    duration: 800,
    easing: 'bounce'
  }
};

// ==================== 动画系统核心类 | Animation System Core Class ====================

/**
 * 动画系统 | Animation System
 */
export class AnimationSystem {
  private static instance: AnimationSystem;
  private logger: Logger;
  private animations: Map<string, AnimationState> = new Map();
  private rafId: number | null = null;
  private isRunning: boolean = false;
  
  private constructor() {
    this.logger = new Logger('AnimationSystem');
    this.startAnimationLoop();
    this.logger.info('AnimationSystem initialized');
  }
  
  public static getInstance(): AnimationSystem {
    if (!AnimationSystem.instance) {
      AnimationSystem.instance = new AnimationSystem();
    }
    return AnimationSystem.instance;
  }
  
  /**
   * 开始动画循环 | Start animation loop
   */
  private startAnimationLoop(): void {
    if (this.isRunning) return;
    
    this.isRunning = true;
    const animate = (timestamp: number) => {
      this.updateAnimations(timestamp);
      if (this.isRunning) {
        this.rafId = requestAnimationFrame(animate);
      }
    };
    
    this.rafId = requestAnimationFrame(animate);
  }
  
  /**
   * 停止动画循环 | Stop animation loop
   */
  private stopAnimationLoop(): void {
    this.isRunning = false;
    if (this.rafId) {
      cancelAnimationFrame(this.rafId);
      this.rafId = null;
    }
  }
  
  /**
   * 更新动画 | Update animations
   */
  private updateAnimations(timestamp: number): void {
    for (const [id, state] of this.animations) {
      if (!state.isPlaying || !state.element) continue;
      
      const elapsed = timestamp - state.startTime - (state.config.delay || 0);
      const duration = state.config.duration;
      
      if (elapsed < 0) continue; // 还未开始
      
      if (elapsed >= duration) {
        // 动画结束
        this.finishAnimation(id, state);
      } else {
        // 更新动画进度
        const progress = elapsed / duration;
        state.progress = progress;
        state.currentTime = elapsed;
        this.applyAnimation(state);
      }
    }
    
    // 如果没有活动动画，停止循环
    if (this.animations.size === 0) {
      this.stopAnimationLoop();
    }
  }
  
  /**
   * 应用动画效果 | Apply animation effect
   */
  private applyAnimation(state: AnimationState): void {
    if (!state.element) return;
    
    const config = state.config;
    const progress = EasingFunctions[config.easing](state.progress);
    
    // 根据动画类型应用不同的变换
    let transform = '';
    let opacity = 1;
    
    switch (config.type) {
      case 'fade':
        opacity = config.direction === 'in' ? progress : 1 - progress;
        break;
        
      case 'slide':
        const translateValue = (1 - progress) * 100;
        switch (config.direction) {
          case 'left':
            transform = `translateX(-${translateValue}%)`;
            break;
          case 'right':
            transform = `translateX(${translateValue}%)`;
            break;
          case 'up':
            transform = `translateY(-${translateValue}%)`;
            break;
          case 'down':
            transform = `translateY(${translateValue}%)`;
            break;
        }
        break;
        
      case 'scale':
        const scaleValue = config.direction === 'in' ? progress : 1 - progress * 0.5;
        transform = `scale(${scaleValue})`;
        break;
        
      case 'pulse':
        const pulseScale = 1 + Math.sin(progress * Math.PI * 2) * 0.1;
        transform = `scale(${pulseScale})`;
        break;
        
      case 'bounce':
        const bounceProgress = EasingFunctions.bounce(progress);
        transform = `translateY(${(1 - bounceProgress) * 50}px)`;
        break;
    }
    
    // 应用样式
    state.element.style.transform = transform;
    state.element.style.opacity = opacity.toString();
  }
  
  /**
   * 完成动画 | Finish animation
   */
  private finishAnimation(id: string, state: AnimationState): void {
    if (state.element) {
      // 根据fillMode设置最终状态
      const fillMode = state.config.fillMode || 'none';
      if (fillMode === 'forwards' || fillMode === 'both') {
        // 保持最终状态
        state.element.style.transform = '';
        state.element.style.opacity = '1';
      } else {
        // 重置样式
        state.element.style.transform = '';
        state.element.style.opacity = '';
      }
    }
    
    // 移除动画状态
    this.animations.delete(id);
    this.logger.debug(`Animation ${id} finished`);
  }
  
  /**
   * 播放动画 | Play animation
   */
  public play(element: HTMLElement, config: AnimationConfig): string {
    const id = this.generateId();
    const state: AnimationState = {
      id,
      element,
      config,
      startTime: performance.now(),
      currentTime: 0,
      isPlaying: true,
      isPaused: false,
      progress: 0
    };
    
    this.animations.set(id, state);
    this.logger.debug(`Started animation ${id} on element`, element);
    
    // 如果动画循环未运行，启动它
    if (!this.isRunning) {
      this.startAnimationLoop();
    }
    
    return id;
  }
  
  /**
   * 播放关键帧动画 | Play keyframe animation
   */
  public playKeyframes(element: HTMLElement, config: KeyframeAnimationConfig): string {
    try {
      const animationId = `keyframe_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // 验证参数
      if (!element || !config) {
        this.logger.error('Invalid parameters for keyframe animation');
        return '';
      }
      
      // 处理默认值
      const duration = config.duration || 1000;
      const easing = config.easing || 'ease';
      const delay = config.delay || 0;
      const iterations = config.iterations || 1;
      const direction = config.direction || 'normal';
      const fillMode = config.fillMode || 'both';
      
      // 检查关键帧是否有效
      if (!config.keyframes || !Array.isArray(config.keyframes) || config.keyframes.length === 0) {
        this.logger.error('Invalid keyframes for animation');
        return '';
      }
      
      // 使用CSS动画实现关键帧动画
      const style = document.createElement('style');
      const keyframesName = `keyframes_${animationId}`;
      
      // 构建关键帧CSS
      let keyframesCSS = `@keyframes ${keyframesName} {`;
      config.keyframes.forEach((keyframe, index) => {
        const percentage = keyframe.offset !== undefined ? `${keyframe.offset * 100}%` : `${(index / (config.keyframes.length - 1)) * 100}%`;
        keyframesCSS += `${percentage} {`;
        
        // 添加关键帧属性
        if (keyframe.transform) {
          keyframesCSS += `transform: ${keyframe.transform};`;
        }
        if (keyframe.opacity !== undefined) {
          keyframesCSS += `opacity: ${keyframe.opacity};`;
        }
        if (keyframe.position) {
          keyframesCSS += `position: ${keyframe.position};`;
        }
        if (keyframe.left !== undefined) {
          keyframesCSS += `left: ${keyframe.left};`;
        }
        if (keyframe.top !== undefined) {
          keyframesCSS += `top: ${keyframe.top};`;
        }
        if (keyframe.width !== undefined) {
          keyframesCSS += `width: ${keyframe.width};`;
        }
        if (keyframe.height !== undefined) {
          keyframesCSS += `height: ${keyframe.height};`;
        }
        if (keyframe.backgroundColor) {
          keyframesCSS += `background-color: ${keyframe.backgroundColor};`;
        }
        
        keyframesCSS += `}`;
      });
      keyframesCSS += `}`;
      
      style.textContent = keyframesCSS;
      document.head.appendChild(style);
      
      // 应用动画到元素
      const animationStyle = {
        animationName: keyframesName,
        animationDuration: `${duration}ms`,
        animationTimingFunction: easing,
        animationDelay: `${delay}ms`,
        animationIterationCount: iterations,
        animationDirection: direction,
        animationFillMode: fillMode
      };
      
      // 保存原始样式以便后续清理
      const originalStyles = {
        animation: element.style.animation || '',
        transform: element.style.transform || '',
        opacity: element.style.opacity || '',
        position: element.style.position || '',
        left: element.style.left || '',
        top: element.style.top || '',
        width: element.style.width || '',
        height: element.style.height || '',
        backgroundColor: element.style.backgroundColor || ''
      };
      
      // 应用动画样式
      Object.assign(element.style, animationStyle);
      
      // 保存动画状态
      const animationState: AnimationState = {
        id: animationId,
        element: element,
        startTime: performance.now(),
        duration: duration,
        currentTime: 0,
        isPlaying: true,
        isPaused: false,
        config: config,
        originalStyles: originalStyles,
        cleanup: () => {
          // 移除样式标签
          if (style.parentNode) {
            style.parentNode.removeChild(style);
          }
          // 恢复原始样式
          Object.assign(element.style, originalStyles);
        }
      };
      
      this.animations.set(animationId, animationState);
      
      // 监听动画结束
      const handleAnimationEnd = () => {
        element.removeEventListener('animationend', handleAnimationEnd);
        this.finishAnimation(animationId, animationState);
      };
      
      element.addEventListener('animationend', handleAnimationEnd);
      
      // 启动动画循环
      if (!this.isRunning) {
        this.startAnimationLoop();
      }
      
      this.logger.debug(`Started keyframe animation ${animationId}`);
      return animationId;
    } catch (error) {
      this.logger.error(`Failed to play keyframe animation: ${error}`);
      return '';
    }
  }
  
  /**
   * 暂停动画 | Pause animation
   */
  public pause(animationId: string): void {
    const state = this.animations.get(animationId);
    if (state) {
      state.isPlaying = false;
      state.isPaused = true;
      this.logger.debug(`Paused animation ${animationId}`);
    }
  }
  
  /**
   * 恢复动画 | Resume animation
   */
  public resume(animationId: string): void {
    const state = this.animations.get(animationId);
    if (state) {
      state.isPlaying = true;
      state.isPaused = false;
      // 调整开始时间以补偿暂停时间
      state.startTime = performance.now() - state.currentTime;
      this.logger.debug(`Resumed animation ${animationId}`);
      
      if (!this.isRunning) {
        this.startAnimationLoop();
      }
    }
  }
  
  /**
   * 停止动画 | Stop animation
   */
  public stop(animationId: string): void {
    const state = this.animations.get(animationId);
    if (state) {
      this.finishAnimation(animationId, state);
      this.logger.debug(`Stopped animation ${animationId}`);
    }
  }
  
  /**
   * 停止元素上的所有动画 | Stop all animations on element
   */
  public stopAll(element: HTMLElement): void {
    for (const [id, state] of this.animations) {
      if (state.element === element) {
        this.stop(id);
      }
    }
  }
  
  /**
   * 获取动画状态 | Get animation state
   */
  public getAnimationState(animationId: string): AnimationState | undefined {
    return this.animations.get(animationId);
  }
  
  /**
   * 生成唯一ID | Generate unique ID
   */
  private generateId(): string {
    return `anim_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
  
  /**
   * 清理资源 | Cleanup resources
   */
  public destroy(): void {
    this.stopAnimationLoop();
    this.animations.clear();
    this.logger.info('AnimationSystem destroyed');
  }
  
  /**
   * 预设动画快捷方法 | Preset animation shortcuts
   */
  public fadeIn(element: HTMLElement, duration: number = 300): string {
    return this.play(element, { ...PresetAnimations.fadeIn, duration });
  }
  
  public fadeOut(element: HTMLElement, duration: number = 300): string {
    return this.play(element, { ...PresetAnimations.fadeOut, duration });
  }
  
  public slideInLeft(element: HTMLElement, duration: number = 400): string {
    return this.play(element, { ...PresetAnimations.slideInLeft, duration });
  }
  
  public slideInRight(element: HTMLElement, duration: number = 400): string {
    return this.play(element, { ...PresetAnimations.slideInRight, duration });
  }
  
  public pulse(element: HTMLElement, duration: number = 1000): string {
    return this.play(element, { ...PresetAnimations.pulse, duration });
  }
}

// ==================== 便捷导出 | Convenient Exports ====================

// 导出单例实例 | Export singleton instance
export const animationSystem = AnimationSystem.getInstance();

// 导出类型和常量 | Export types and constants
export type { 
  AnimationType, 
  AnimationDirection, 
  EasingFunction, 
  AnimationConfig, 
  KeyframeAnimationConfig, 
  Keyframe, 
  AnimationState 
};

export { EasingFunctions, PresetAnimations };