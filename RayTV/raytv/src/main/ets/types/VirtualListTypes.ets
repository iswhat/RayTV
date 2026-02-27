/**
 * 虚拟列表相关类型定义
 */

/**
 * 虚拟列表项接口
 */
export interface VirtualListItem {
  /** 唯一标识符 */
  id: string;
  
  /** 项目索引 */
  index: number;
  
  /** 项目数据 */
  data: any;
  
  /** 项目顶部位置 */
  top: number;
  
  /** 项目高度 */
  height?: number;
  
  /** 是否可见 */
  visible?: boolean;
}

/**
 * 虚拟列表配置接口
 */
export interface VirtualListConfig {
  /** 估算的项目高度 */
  estimatedItemHeight: number;
  
  /** 缓冲区大小 */
  bufferSize: number;
  
  /** 滚动节流时间(ms) */
  throttleTime: number;
  
  /** 是否启用回收机制 */
  enableRecycling: boolean;
  
  /** 回收阈值 */
  recycleThreshold: number;
}

/**
 * 虚拟列表状态接口
 */
export interface VirtualListState {
  /** 容器高度 */
  containerHeight: number;
  
  /** 滚动位置 */
  scrollTop: number;
  
  /** 可见项目范围 */
  visibleRange: {
    start: number;
    end: number;
  };
  
  /** 总项目数 */
  totalItems: number;
  
  /** 已渲染项目数 */
  renderedItems: number;
}

/**
 * 虚拟列表事件接口
 */
export interface VirtualListEvents {
  /** 滚动事件 */
  onScroll?: (state: VirtualListState) => void;
  
  /** 可见项目变化事件 */
  onVisibleItemsChange?: (items: VirtualListItem[]) => void;
  
  /** 项目即将进入视口 */
  onItemWillEnterView?: (item: VirtualListItem) => void;
  
  /** 项目离开视口 */
  onItemDidLeaveView?: (item: VirtualListItem) => void;
}