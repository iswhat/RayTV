/**
 * 动画类型定义
 */

/**
 * 过渡效果枚举
 */
export enum TransitionEffect {
  /** 淡入淡出 */
  FADE = 'fade',
  
  /** 从左滑入 */
  SLIDE_LEFT = 'slide-left',
  
  /** 从右滑入 */
  SLIDE_RIGHT = 'slide-right',
  
  /** 从上滑入 */
  SLIDE_UP = 'slide-up',
  
  /** 从下滑入 */
  SLIDE_DOWN = 'slide-down',
  
  /** 放大进入 */
  ZOOM_IN = 'zoom-in',
  
  /** 缩小退出 */
  ZOOM_OUT = 'zoom-out',
  
  /** 旋转 */
  ROTATE = 'rotate',
  
  /** 弹跳 */
  BOUNCE = 'bounce',
  
  /** 翻转 */
  FLIP = 'flip'
}

/**
 * 动画触发时机
 */
export enum AnimationTrigger {
  /** 组件挂载时 */
  MOUNT = 'mount',
  
  /** 组件卸载时 */
  UNMOUNT = 'unmount',
  
  /** 属性变化时 */
  PROP_CHANGE = 'prop-change',
  
  /** 状态变化时 */
  STATE_CHANGE = 'state-change',
  
  /** 用户交互时 */
  USER_INTERACTION = 'user-interaction',
  
  /** 数据更新时 */
  DATA_UPDATE = 'data-update'
}

/**
 * 动画方向
 */
export enum AnimationDirection {
  /** 正向 */
  FORWARD = 'forward',
  
  /** 反向 */
  REVERSE = 'reverse',
  
  /** 交替 */
  ALTERNATE = 'alternate'
}

/**
 * 动画填充模式
 */
export enum AnimationFillMode {
  /** 不保持最终状态 */
  NONE = 'none',
  
  /** 保持最终状态 */
  FORWARDS = 'forwards',
  
  /** 保持初始状态 */
  BACKWARDS = 'backwards',
  
  /** 保持初始和最终状态 */
  BOTH = 'both'
}

/**
 * 动画状态
 */
export enum AnimationState {
  /** 空闲 */
  IDLE = 'idle',
  
  /** 运行中 */
  RUNNING = 'running',
  
  /** 暂停 */
  PAUSED = 'paused',
  
  /** 完成 */
  FINISHED = 'finished',
  
  /** 取消 */
  CANCELLED = 'cancelled'
}

/**
 * 动画配置接口
 */
export interface AnimationOptions {
  /** 动画类型 */
  effect: TransitionEffect;
  
  /** 持续时间(ms) */
  duration: number;
  
  /** 延迟时间(ms) */
  delay: number;
  
  /** 缓动函数 */
  easing: Curve;
  
  /** 触发时机 */
  trigger: AnimationTrigger;
  
  /** 方向 */
  direction: AnimationDirection;
  
  /** 是否循环 */
  loop: boolean;
  
  /** 循环次数 */
  iterations: number;
}

/**
 * 关键帧动画接口
 */
export interface KeyframeAnimation {
  /** 关键帧 */
  keyframes: Keyframe[];
  
  /** 持续时间 */
  duration: number;
  
  /** 延迟 */
  delay: number;
  
  /** 缓动函数 */
  easing: Curve;
  
  /** 循环次数 */
  iterations: number;
}

/**
 * 关键帧接口
 */
export interface Keyframe {
  /** 时间点(0-1) */
  offset: number;
  
  /** 样式属性 */
  styles: AnimationStyles;
  
  /** 缓动函数 */
  easing?: Curve;
}

/**
 * 动画样式接口
 */
export interface AnimationStyles {
  /** 透明度 */
  opacity?: number;
  
  /** 变换矩阵 */
  transform?: string;
  
  /** 背景色 */
  backgroundColor?: string;
  
  /** 边框颜色 */
  borderColor?: string;
  
  /** 尺寸 */
  scale?: number;
  
  /** 旋转角度 */
  rotate?: number;
  
  /** 平移X */
  translateX?: number;
  
  /** 平移Y */
  translateY?: number;
}