/**
 * 懒加载工具
 * 提供组件和资源的懒加载功能
 */
export class LazyLoader {
  private static instance: LazyLoader
  private loadedModules: Map<string, any> = new Map()
  private loadingPromises: Map<string, Promise<any>> = new Map()
  
  private constructor() {}
  
  public static getInstance(): LazyLoader {
    if (!LazyLoader.instance) {
      LazyLoader.instance = new LazyLoader()
    }
    return LazyLoader.instance
  }
  
  /**
   * 懒加载模块
   */
  public async loadModule<T>(modulePath: string, loader: () => Promise<T>): Promise<T> {
    // 如果已经加载过，直接返回
    if (this.loadedModules.has(modulePath)) {
      return this.loadedModules.get(modulePath)
    }
    
    // 如果正在加载中，返回相同的Promise
    if (this.loadingPromises.has(modulePath)) {
      return this.loadingPromises.get(modulePath)!
    }
    
    // 开始加载
    const loadPromise = loader().then((module) => {
      this.loadedModules.set(modulePath, module)
      this.loadingPromises.delete(modulePath)
      return module
    }).catch((error) => {
      this.loadingPromises.delete(modulePath)
      throw error
    })
    
    this.loadingPromises.set(modulePath, loadPromise)
    return loadPromise
  }
  
  /**
   * 预加载模块
   */
  public preloadModule<T>(modulePath: string, loader: () => Promise<T>): void {
    if (!this.loadedModules.has(modulePath) && !this.loadingPromises.has(modulePath)) {
      this.loadModule(modulePath, loader).catch((error) => {
        console.warn(`[LazyLoader] 预加载模块失败 ${modulePath}:`, error)
      })
    }
  }
  
  /**
   * 懒加载图片
   */
  public loadImage(src: string): Promise<HTMLImageElement> {
    return new Promise((resolve, reject) => {
      const img = new Image()
      img.onload = () => resolve(img)
      img.onerror = reject
      img.src = src
    })
  }
  
  /**
   * 懒加载组件
   */
  public async loadComponent<T>(componentName: string, loader: () => Promise<{ default: T }>): Promise<T> {
    const module = await this.loadModule(componentName, loader)
    return module.default
  }
  
  /**
   * 清理已加载的模块
   */
  public clearModule(modulePath: string): void {
    this.loadedModules.delete(modulePath)
    this.loadingPromises.delete(modulePath)
  }
  
  /**
   * 清理所有已加载的模块
   */
  public clearAll(): void {
    this.loadedModules.clear()
    this.loadingPromises.clear()
  }
  
  /**
   * 获取加载统计信息
   */
  public getLoadStats(): any {
    return {
      loadedModules: this.loadedModules.size,
      loadingPromises: this.loadingPromises.size,
      modules: Array.from(this.loadedModules.keys())
    }
  }
}

// 懒加载装饰器
export function LazyLoad(modulePath: string) {
  return function(target: any, propertyKey: string) {
    const loader = new LazyLoader()
    
    Object.defineProperty(target, propertyKey, {
      get: function() {
        // 这里应该返回一个代理对象，实际加载在使用时进行
        return {
          load: (actualLoader: () => Promise<any>) => {
            return loader.loadModule(modulePath, actualLoader)
          }
        }
      },
      enumerable: true,
      configurable: true
    })
  }
}

// 组件懒加载高阶组件
export function withLazyLoading<T>(WrappedComponent: T, loader: () => Promise<any>): T {
  // 这里应该返回一个包装组件，实际实现取决于具体框架
  return WrappedComponent
}