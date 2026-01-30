/**
 * Image Component | 图片组件
 * Provides unified image loading, placeholder and error handling functionality | 提供统一的图片加载、占位符和错误处理功能
 */
import { Component, Prop, State, EventHub, Event, Stack, Image, Text, Alignment } from '@ohos/arkui';
import Logger from '../common/util/Logger';

export interface ImageComponentOptions {
  /** Image URL | 图片URL */
  src?: string;
  /** Placeholder URL | 占位图URL */
  placeholder?: string;
  /** Error Image URL | 错误图URL */
  errorImage?: string;
  /** Image Width | 图片宽度 */
  width?: number | string;
  /** Image Height | 图片高度 */
  height?: number | string;
  /** Image Mode | 图片模式 */
  mode?: ImageMode;
  /** Whether to enable lazy loading | 是否启用懒加载 */
  lazyLoad?: boolean;
  /** Whether to show loading state | 是否显示加载状态 */
  showLoading?: boolean;
  /** Custom Style | 自定义样式 */
  style?: Record<string, string | number | boolean>;
}

/**
 * Image Mode Enum | 图片模式枚举
 */
export enum ImageMode {
  /** Auto Fit | 自动适配 */
  ASPECT_FIT = 'aspectFit',
  /** Fill | 填充 */
  ASPECT_FILL = 'aspectFill',
  /** Stretch | 拉伸 */
  FILL = 'fill',
  /** Center Crop | 居中裁剪 */
  CENTER_CROP = 'centerCrop',
  /** Top Left | 左上角 */
  TOP_LEFT = 'topLeft',
  /** Top Right | 右上角 */
  TOP_RIGHT = 'topRight',
  /** Bottom Left | 左下角 */
  BOTTOM_LEFT = 'bottomLeft',
  /** Bottom Right | 右下角 */
  BOTTOM_RIGHT = 'bottomRight',
  /** Center | 居中 */
  CENTER = 'center'
}

/**
 * Image Component | 图片组件
 */
@Component
@Entry
export struct ImageComponent {
  /** Logger tag | 日志标签 */
  private readonly TAG: string = 'ImageComponent';
  
  @Prop private src?: string;
  @Prop private placeholder?: string = '/common/images/placeholder.png';
  @Prop private errorImage?: string = '/common/images/error.png';
  @Prop private width?: number | string = '100%';
  @Prop private height?: number | string = '100%';
  @Prop private mode?: ImageMode = ImageMode.ASPECT_FIT;
  @Prop private lazyLoad?: boolean = true;
  @Prop private showLoading?: boolean = true;
  @Prop private style?: Record<string, string | number | boolean> = {};

  /**
   * Component State | 组件状态
   */
  @State private isLoading: boolean = true;
  @State private loadFailed: boolean = false;
  @State private currentImage: string = '';

  /**
   * Lazy Loading Related | 懒加载相关
   */
  private observer?: IntersectionObserver;
  private isInViewport: boolean = false;

  /**
   * Component Lifecycle - Component Mounted | 组件生命周期 - 组件挂载完成
   */
  aboutToAppear() {
    this.currentImage = this.placeholder || '';
    
    if (this.lazyLoad) {
      this.setupLazyLoadObserver();
    } else {
      this.loadImage();
    }
  }

  /**
   * Component Lifecycle - Before Component Unmount | 组件生命周期 - 组件卸载前
   */
  aboutToDisappear() {
    // Clean up observer | 清理观察器
    if (this.observer) {
      this.observer.disconnect();
      this.observer = undefined;
    }
  }

  /**
   * Set up intersection observer | 设置交叉观察器
   */
  private setupLazyLoadObserver() {
    try {
      // Implementation of intersection observer | 交叉观察器实现
      const element = this.$element();
      if (element) {
        // Setup real intersection observer | 设置真实交叉观察器
        this.observer = new IntersectionObserver(entries => {
          for (const entry of entries) {
            if (entry.isIntersecting) {
              this.isInViewport = true;
              this.loadImage();
              // Stop observing after loading is complete | 加载完成后可以停止观察
              if (this.observer) {
                this.observer.disconnect();
                this.observer = undefined;
              }
            } else {
              this.isInViewport = false;
            }
          }
        });
        
        // Observe current element | 观察当前元素
        this.observer.observe(element);
      } else {
        // Load image directly on failure | 失败时直接加载图片
        this.loadImage();
      }
    } catch (error) {
      Logger.error(this.TAG, 'Failed to setup lazy load observer', error instanceof Error ? error : new Error(String(error)));
      this.loadImage();
    }
  }

  /**
   * Load Image | 加载图片
   */
  private loadImage() {
    if (!this.src) {
      Logger.warn(this.TAG, 'No image source provided');
      this.loadFailed = true;
      this.isLoading = false;
      this.currentImage = this.errorImage || '';
      return;
    }

    Logger.debug(this.TAG, `Loading image: ${this.src}`);
    this.isLoading = true;
    this.loadFailed = false;

    // Real image loading implementation | 真实图片加载实现
    try {
      // Setup loading timeout | 设置加载超时
      const timeoutId = setTimeout(() => {
        if (this.isLoading) {
          Logger.warn(this.TAG, `Image loading timeout: ${this.src}`);
          this.isLoading = false;
          this.loadFailed = true;
          this.currentImage = this.errorImage || '';
        }
      }, 10000); // 10 seconds timeout | 10秒超时
      
      // Use Image object to load image | 使用Image对象加载图片
      const image = new Image();
      
      // Set image source | 设置图片源
      image.src = this.src;
      
      // Handle image load success | 处理图片加载成功
      image.onload = () => {
        clearTimeout(timeoutId);
        this.isLoading = false;
        this.loadFailed = false;
        this.currentImage = this.src || '';
      };
      
      // Handle image load error | 处理图片加载失败
      image.onerror = (error) => {
        clearTimeout(timeoutId);
        Logger.error(this.TAG, `Failed to load image: ${this.src}`, error instanceof Error ? error : new Error(String(error)));
        this.isLoading = false;
        this.loadFailed = true;
        this.currentImage = this.errorImage || '';
      };
      
      // Set crossOrigin if needed | 根据需要设置crossOrigin
      if (this.crossOrigin) {
        image.crossOrigin = this.crossOrigin;
      }
      
    } catch (error) {
      Logger.error(this.TAG, `Failed to load image: ${this.src}`, error instanceof Error ? error : new Error(String(error)));
      this.isLoading = false;
      this.loadFailed = true;
      this.currentImage = this.errorImage || '';
    }
  }

  /**
   * Reset Loading State | 重置加载状态
   */
  private resetLoadingState() {
    this.isLoading = true;
    this.loadFailed = false;
    this.currentImage = this.placeholder || '';
  }

  /**
   * Retry Loading | 重试加载
   */
  private retryLoad() {
    this.resetLoadingState();
    this.loadImage();
  }

  /**
   * Clear Loading Timer | 清除加载定时器
   */
  private clearLoadingTimer() {
    // Clear timer logic | 清除定时器逻辑
  }

  build() {
    // Image container | 图片容器
    Stack({
      alignContent: Alignment.Center
    })
    .width(this.width)
    .height(this.height)
    .onClick(() => {
      if (this.loadFailed) {
        this.retryLoad();
      }
    })
    {
      // Display current image | 显示当前图片
      Image(this.currentImage)
        .width('100%')
        .height('100%')
        .objectFit(this.mode)
      
      // Display loading state | 加载状态显示
      if (this.isLoading && this.showLoading) {
        this.renderLoadingIndicator();
      }
      
      // Display error state | 错误状态显示
      if (this.loadFailed) {
        this.renderErrorIndicator();
      }
    }
  }

  /**
   * Render Loading Indicator | 渲染加载指示器
   */
  @Builder
  private renderLoadingIndicator() {
    Stack({
      alignContent: Alignment.Center
    })
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.3)')
    {
      // Can use platform-provided loading component here | 这里可以使用平台提供的加载组件
      Text('加载中.. Loading..')
        .fontSize(14)
        .fontColor('#FFFFFF')
    }
  }
  
  /**
   * Render Error Indicator | 渲染错误指示器
   */
  @Builder
  private renderErrorIndicator() {
    Stack({
      alignContent: Alignment.Center
    })
    .width('100%')
    .height('100%')
    .backgroundColor('rgba(0, 0, 0, 0.3)')
    {
      // Can use platform-provided error component here | 这里可以使用平台提供的错误组件
      Text('加载失败，点击重试 Failed to load, click to retry')
        .fontSize(14)
        .fontColor('#FFFFFF')
    }
  }
}
