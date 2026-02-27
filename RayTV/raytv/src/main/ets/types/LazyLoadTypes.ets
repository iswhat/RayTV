/**
 * 懒加载策略枚举
 */
export enum LazyLoadStrategy {
  /** 交叉观察器策略 - 当元素进入视口时加载 */
  INTERSECTION = 'intersection',
  
  /** 滚动监听策略 - 监听滚动事件触发加载 */
  SCROLL = 'scroll',
  
  /** 立即加载策略 - 组件初始化时立即加载 */
  VISIBLE = 'visible',
  
  /** 延迟加载策略 - 延迟一段时间后加载 */
  DELAYED = 'delayed'
}

/**
 * 懒加载配置接口
 */
export interface LazyLoadConfig {
  /** 加载策略 */
  strategy: LazyLoadStrategy;
  
  /** 交叉观察器阈值 (0-1) */
  threshold?: number;
  
  /** 根边距 */
  rootMargin?: string;
  
  /** 是否启用缓存 */
  enableCache?: boolean;
  
  /** 最大重试次数 */
  maxRetries?: number;
  
  /** 重试延迟(ms) */
  retryDelay?: number;
  
  /** 预加载数量 */
  preloadCount?: number;
}

/**
 * 图片加载状态
 */
export enum ImageLoadStatus {
  /** 未开始加载 */
  IDLE = 'idle',
  
  /** 正在加载 */
  LOADING = 'loading',
  
  /** 加载成功 */
  LOADED = 'loaded',
  
  /** 加载失败 */
  ERROR = 'error'
}

/**
 * 懒加载事件接口
 */
export interface LazyLoadEvents {
  /** 开始加载 */
  onLoadStart?: () => void;
  
  /** 加载成功 */
  onLoadSuccess?: (src: string) => void;
  
  /** 加载失败 */
  onLoadError?: (error: any) => void;
  
  /** 重试 */
  onRetry?: (attempt: number) => void;
}