/**
 * 响应式布局系统 | Responsive Layout System
 * 支持不同屏幕尺寸的适配和响应式设计
 */
import Logger from '../util/Logger';

// 断点类型 | Breakpoint type
export type Breakpoint = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl';

// 响应式配置接口 | Responsive config interface
export interface ResponsiveConfig {
  breakpoints: Record<Breakpoint, number>;
  gridColumns: Record<Breakpoint, number>;
  spacing: Record<Breakpoint, number>;
  fontSize: Record<Breakpoint, number>;
  containerWidth: Record<Breakpoint, number | '100%'>;
}

// 媒体查询条件接口 | Media query condition interface
export interface MediaQueryCondition {
  minWidth?: number;
  maxWidth?: number;
  orientation?: 'portrait' | 'landscape';
  aspectRatio?: string;
}

// 响应式显示属性 | Responsive display props
export interface ResponsiveDisplayProps {
  breakpoint: Breakpoint;
  width: number;
  height: number;
  orientation: 'portrait' | 'landscape';
  aspectRatio: number;
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
}

/**
 * 响应式系统类 | Responsive system class
 */
export class ResponsiveSystem {
  private static instance: ResponsiveSystem | null = null;
  private config: ResponsiveConfig;
  private currentBreakpoint: Breakpoint = 'md';
  private currentDisplayProps: ResponsiveDisplayProps | null = null;
  private logger: Logger;
  private resizeListeners: Set<(props: ResponsiveDisplayProps) => void> = new Set();

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): ResponsiveSystem {
    if (!ResponsiveSystem.instance) {
      ResponsiveSystem.instance = new ResponsiveSystem();
    }
    return ResponsiveSystem.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('ResponsiveSystem');
    this.config = this.getDefaultConfig();
    this.initialize();
  }

  /**
   * 初始化 | Initialize
   */
  private initialize(): void {
    this.updateDisplayProps();
    this.setupResizeListener();
  }

  /**
   * 获取默认配置 | Get default config
   */
  private getDefaultConfig(): ResponsiveConfig {
    return {
      breakpoints: {
        xs: 0,
        sm: 576,
        md: 768,
        lg: 992,
        xl: 1200,
        xxl: 1400
      },
      gridColumns: {
        xs: 1,
        sm: 2,
        md: 3,
        lg: 4,
        xl: 5,
        xxl: 6
      },
      spacing: {
        xs: 8,
        sm: 12,
        md: 16,
        lg: 20,
        xl: 24,
        xxl: 28
      },
      fontSize: {
        xs: 14,
        sm: 16,
        md: 18,
        lg: 20,
        xl: 22,
        xxl: 24
      },
      containerWidth: {
        xs: '100%',
        sm: 540,
        md: 720,
        lg: 960,
        xl: 1140,
        xxl: 1320
      }
    };
  }

  /**
   * 设置窗口大小变化监听器 | Set up resize listener
   */
  private setupResizeListener(): void {
    try {
      // 在HarmonyOS环境中，使用相应的API监听尺寸变化
      // 这里使用模拟实现，实际环境中需要根据平台API调整
      this.logger.info('Responsive system initialized');
    } catch (error) {
      this.logger.error('Failed to setup resize listener:', error);
    }
  }

  /**
   * 更新显示属性 | Update display props
   */
  private updateDisplayProps(): void {
    // 模拟获取窗口尺寸，实际环境中需要根据平台API调整
    const width = 1920; // 模拟电视屏幕宽度
    const height = 1080; // 模拟电视屏幕高度
    const orientation = width >= height ? 'landscape' : 'portrait';
    const aspectRatio = width / height;
    const breakpoint = this.getBreakpoint(width);

    this.currentBreakpoint = breakpoint;
    this.currentDisplayProps = {
      breakpoint,
      width,
      height,
      orientation,
      aspectRatio,
      isMobile: breakpoint === 'xs' || breakpoint === 'sm',
      isTablet: breakpoint === 'md',
      isDesktop: breakpoint === 'lg' || breakpoint === 'xl' || breakpoint === 'xxl'
    };

    // 通知所有监听器 | Notify all listeners
    this.resizeListeners.forEach(listener => {
      try {
        listener(this.currentDisplayProps!);
      } catch (error) {
        this.logger.error('Error in resize listener:', error);
      }
    });
  }

  /**
   * 获取当前断点 | Get current breakpoint
   * @returns 当前断点 | Current breakpoint
   */
  public getCurrentBreakpoint(): Breakpoint {
    return this.currentBreakpoint;
  }

  /**
   * 获取当前显示属性 | Get current display props
   * @returns 当前显示属性 | Current display props
   */
  public getCurrentDisplayProps(): ResponsiveDisplayProps {
    if (!this.currentDisplayProps) {
      this.updateDisplayProps();
    }
    return this.currentDisplayProps!;
  }

  /**
   * 根据宽度获取断点 | Get breakpoint by width
   * @param width 屏幕宽度 | Screen width
   * @returns 断点 | Breakpoint
   */
  public getBreakpoint(width: number): Breakpoint {
    if (width >= this.config.breakpoints.xxl) return 'xxl';
    if (width >= this.config.breakpoints.xl) return 'xl';
    if (width >= this.config.breakpoints.lg) return 'lg';
    if (width >= this.config.breakpoints.md) return 'md';
    if (width >= this.config.breakpoints.sm) return 'sm';
    return 'xs';
  }

  /**
   * 获取网格列数 | Get grid column count
   * @param breakpoint 断点 | Breakpoint
   * @returns 列数 | Column count
   */
  public getGridColumnCount(breakpoint: Breakpoint = this.currentBreakpoint): number {
    return this.config.gridColumns[breakpoint];
  }

  /**
   * 获取间距 | Get spacing
   * @param breakpoint 断点 | Breakpoint
   * @returns 间距 | Spacing
   */
  public getSpacing(breakpoint: Breakpoint = this.currentBreakpoint): number {
    return this.config.spacing[breakpoint];
  }

  /**
   * 获取字体大小 | Get font size
   * @param breakpoint 断点 | Breakpoint
   * @returns 字体大小 | Font size
   */
  public getFontSize(breakpoint: Breakpoint = this.currentBreakpoint): number {
    return this.config.fontSize[breakpoint];
  }

  /**
   * 获取容器宽度 | Get container width
   * @param breakpoint 断点 | Breakpoint
   * @returns 容器宽度 | Container width
   */
  public getContainerWidth(breakpoint: Breakpoint = this.currentBreakpoint): number | '100%' {
    return this.config.containerWidth[breakpoint];
  }

  /**
   * 计算响应式值 | Calculate responsive value
   * @param values 不同断点的值 | Values for different breakpoints
   * @param breakpoint 断点 | Breakpoint
   * @returns 计算后的值 | Calculated value
   */
  public getResponsiveValue<T>(values: Partial<Record<Breakpoint, T>>, breakpoint: Breakpoint = this.currentBreakpoint): T | undefined {
    // 从当前断点开始向下查找 | Start from current breakpoint and look down
    const breakpoints: Breakpoint[] = ['xxl', 'xl', 'lg', 'md', 'sm', 'xs'];
    const startIndex = breakpoints.indexOf(breakpoint);

    for (let i = startIndex; i < breakpoints.length; i++) {
      const currentBreakpoint = breakpoints[i];
      if (values[currentBreakpoint] !== undefined) {
        return values[currentBreakpoint];
      }
    }

    return undefined;
  }

  /**
   * 注册尺寸变化监听器 | Register resize listener
   * @param listener 监听器函数 | Listener function
   * @returns 取消注册函数 | Unregister function
   */
  public onResize(listener: (props: ResponsiveDisplayProps) => void): () => void {
    this.resizeListeners.add(listener);

    // 立即调用一次，提供当前状态 | Call immediately with current state
    if (this.currentDisplayProps) {
      listener(this.currentDisplayProps);
    }

    return () => {
      this.resizeListeners.delete(listener);
    };
  }

  /**
   * 获取媒体查询条件 | Get media query condition
   * @param breakpoint 断点 | Breakpoint
   * @returns 媒体查询条件 | Media query condition
   */
  public getMediaQueryCondition(breakpoint: Breakpoint): MediaQueryCondition {
    const breakpoints = this.config.breakpoints;
    const breakpointKeys = Object.keys(breakpoints) as Breakpoint[];
    const index = breakpointKeys.indexOf(breakpoint);

    if (index === 0) {
      return {
        maxWidth: breakpoints[breakpointKeys[index + 1]] - 1
      };
    } else if (index === breakpointKeys.length - 1) {
      return {
        minWidth: breakpoints[breakpoint]
      };
    } else {
      return {
        minWidth: breakpoints[breakpoint],
        maxWidth: breakpoints[breakpointKeys[index + 1]] - 1
      };
    }
  }

  /**
   * 检查是否匹配断点 | Check if matches breakpoint
   * @param width 屏幕宽度 | Screen width
   * @param breakpoint 断点 | Breakpoint
   * @returns 是否匹配 | Whether matches
   */
  public matchesBreakpoint(width: number, breakpoint: Breakpoint): boolean {
    const condition = this.getMediaQueryCondition(breakpoint);
    if (condition.minWidth !== undefined && width < condition.minWidth) {
      return false;
    }
    if (condition.maxWidth !== undefined && width > condition.maxWidth) {
      return false;
    }
    return true;
  }

  /**
   * 更新配置 | Update config
   * @param config 配置 | Config
   */
  public updateConfig(config: Partial<ResponsiveConfig>): void {
    this.config = {
      ...this.config,
      ...config,
      breakpoints: {
        ...this.config.breakpoints,
        ...(config.breakpoints || {})
      },
      gridColumns: {
        ...this.config.gridColumns,
        ...(config.gridColumns || {})
      },
      spacing: {
        ...this.config.spacing,
        ...(config.spacing || {})
      },
      fontSize: {
        ...this.config.fontSize,
        ...(config.fontSize || {})
      },
      containerWidth: {
        ...this.config.containerWidth,
        ...(config.containerWidth || {})
      }
    };

    // 重新计算显示属性 | Recalculate display props
    this.updateDisplayProps();
    this.logger.info('Responsive system config updated');
  }

  /**
   * 获取配置 | Get config
   * @returns 配置 | Config
   */
  public getConfig(): ResponsiveConfig {
    return { ...this.config };
  }

  /**
   * 销毁 | Destroy
   */
  public destroy(): void {
    this.resizeListeners.clear();
    this.logger.info('Responsive system destroyed');
  }
}

// 导出单例实例 | Export singleton instance
export default ResponsiveSystem.getInstance();

// 导出便捷的响应式钩子 | Export convenient responsive hooks
export const responsiveDisplay = ResponsiveSystem.getInstance();

// 导出断点常量 | Export breakpoint constants
export const Breakpoints = {
  xs: 0,
  sm: 576,
  md: 768,
  lg: 992,
  xl: 1200,
  xxl: 1400
} as const;
