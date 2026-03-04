import { ImageCacheManager } from '../utils/ImageCacheManager';
import { LazyLoadStrategy } from '../types/LazyLoadTypes';

/**
 * 图片懒加载组件
 * 支持多种加载策略和缓存机制
 */
@Component
struct ImageLazyLoader {
  @State private isLoading: boolean = false;
  @State private isError: boolean = false;
  @State private isLoaded: boolean = false;
  @State private currentSrc: string = '';
  
  private cacheManager: ImageCacheManager = ImageCacheManager.getInstance();
  private observer: IntersectionObserver | null = null;
  private retryCount: number = 0;
  private maxRetries: number = 3;

  // 组件属性
  @Prop src: string = '';
  @Prop placeholder: string = '';
  @Prop errorPlaceholder: string = '';
  @Prop lazyStrategy: LazyLoadStrategy = LazyLoadStrategy.INTERSECTION;
  @Prop threshold: number = 0.1;
  @Prop rootMargin: string = '50px';
  @Prop enableCache: boolean = true;
  @Prop cacheKey: string = '';
  @Prop width: number | string = '100%';
  @Prop height: number | string = 'auto';
  @Prop borderRadius: number | string = 0;
  @Prop onLoad?: (src: string) => void;
  @Prop onError?: (error: Error) => void;

  aboutToAppear(): void {
    this.initializeLazyLoading();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  private initializeLazyLoading(): void {
    if (!this.src) return;

    const cacheKey = this.cacheKey || this.src;
    
    // 检查缓存
    if (this.enableCache && this.cacheManager.has(cacheKey)) {
      const cachedData = this.cacheManager.get(cacheKey);
      if (cachedData && !cachedData.error) {
        this.currentSrc = cachedData.data;
        this.isLoaded = true;
        this.onLoad?.(this.currentSrc);
        return;
      }
    }

    switch (this.lazyStrategy) {
      case LazyLoadStrategy.INTERSECTION:
        this.setupIntersectionObserver();
        break;
      case LazyLoadStrategy.SCROLL:
        this.setupScrollListener();
        break;
      case LazyLoadStrategy.VISIBLE:
        this.loadImmediately();
        break;
      case LazyLoadStrategy.DELAYED:
        this.loadWithDelay();
        break;
    }
  }

  private setupIntersectionObserver(): void {
    // 模拟交叉观察器实现
    // 在实际HarmonyOS环境中需要使用原生API
    setTimeout(() => {
      if (Math.random() > 0.3) { // 模拟元素进入视口
        this.loadImage();
      }
    }, 1000 + Math.random() * 2000);
  }

  private setupScrollListener(): void {
    // 监听滚动事件
    // 这里简化实现，在实际应用中需要监听具体的滚动容器
    setTimeout(() => {
      this.loadImage();
    }, 500);
  }

  private loadImmediately(): void {
    this.loadImage();
  }

  private loadWithDelay(): void {
    setTimeout(() => {
      this.loadImage();
    }, 1000);
  }

  private async loadImage(): Promise<void> {
    if (this.isLoading || this.isLoaded) return;

    this.isLoading = true;
    this.isError = false;

    try {
      const cacheKey = this.cacheKey || this.src;
      
      // 先检查缓存
      if (this.enableCache && this.cacheManager.has(cacheKey)) {
        const cachedData = this.cacheManager.get(cacheKey);
        if (cachedData && !cachedData.error) {
          this.currentSrc = cachedData.data;
          this.isLoaded = true;
          this.isLoading = false;
          this.onLoad?.(this.currentSrc);
          return;
        }
      }

      // 网络加载
      const imageData = await this.fetchImage(this.src);
      
      // 缓存图片数据
      if (this.enableCache) {
        this.cacheManager.set(cacheKey, imageData);
      }

      this.currentSrc = imageData;
      this.isLoaded = true;
      this.onLoad?.(imageData);

    } catch (error) {
      console.error('Image loading failed:', error);
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  private async fetchImage(url: string): Promise<string> {
    return new Promise((resolve, reject) => {
      // 模拟网络请求
      setTimeout(() => {
        if (Math.random() > 0.1) { // 90%成功率
          // 模拟返回图片数据
          resolve(`data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/${btoa(url)}`);
        } else {
          reject(new Error('Network error'));
        }
      }, 200 + Math.random() * 800);
    });
  }

  private handleError(error: Error): void {
    this.isError = true;
    this.onError?.(error);

    // 自动重试机制
    if (this.retryCount < this.maxRetries) {
      this.retryCount++;
      setTimeout(() => {
        this.loadImage();
      }, 1000 * this.retryCount);
    }
  }

  private cleanup(): void {
    if (this.observer) {
      this.observer.disconnect();
      this.observer = null;
    }
  }

  build() {
    Column() {
      if (this.isError && this.errorPlaceholder) {
        Image(this.errorPlaceholder)
          .width(this.width)
          .height(this.height)
          .borderRadius(this.borderRadius)
          .onTouch(() => {
            this.retryCount = 0;
            this.loadImage();
          })
      } else if (this.isLoading && this.placeholder) {
        Image(this.placeholder)
          .width(this.width)
          .height(this.height)
          .borderRadius(this.borderRadius)
      } else if (this.isLoaded && this.currentSrc) {
        Image(this.currentSrc)
          .width(this.width)
          .height(this.height)
          .borderRadius(this.borderRadius)
          .onComplete(() => {
            console.log('Image loaded successfully');
          })
          .onError(() => {
            this.isError = true;
          })
      } else {
        // 默认占位符
        Row()
          .width(this.width)
          .height(this.height)
          .borderRadius(this.borderRadius)
          .backgroundColor('#f0f0f0')
          .justifyContent(FlexAlign.Center)
          .alignItems(VerticalAlign.Center)
          .children([
            Text('🖼️')
              .fontSize(24)
          ])
      }
    }
  }
}