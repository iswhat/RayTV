/**
 * FactoryBase - Factory base class | 工厂基类
 * Abstract common logic for ServiceFactory and RepositoryFactory to reduce code duplication | 抽象ServiceFactory和RepositoryFactory的共同逻辑，减少代码重复
 */
import Logger from '../util/Logger';

/**
 * Closable object interface | 可关闭对象接口
 */
export interface Closable {
  close?: () => Promise<void>;
}

/**
 * Factory base class | 工厂基类
 * @template T Type key | 类型键
 * @template I Instance type | 实例类型
 */
export abstract class FactoryBase<T, I> {
  private static instance: FactoryBase<string, Record<string, object>> | null = null;
  protected instanceMap: Map<T, I> = new Map();
  protected isInitialized: boolean = false;
  /**
   * Logger tag | 日志标签
   */
  protected abstract readonly TAG: string;
  
  /**
   * Constructor (protected, prevent direct instantiation) | 构造函数（保护，防止直接实例化）
   */
  protected constructor() {}
  /**
   * Get singleton instance | 获取单例实例
   * @returns Factory instance | 工厂实例
   */
  public static getInstance(): FactoryBase<string, Record<string, object>> | null {
    if (!FactoryBase.instance) {
      // 由于ArkTS限制，静态方法中无法创建实例，需要子类实现具体逻辑
      return null;
    }
    return FactoryBase.instance;
  }
  
  /**
   * Initialize all instances | 初始化所有实例
   * @returns Whether initialization succeeded | 是否初始化成功
   */
  public abstract initialize(): Promise<boolean>;
  
  /**
   * Get instance of specified type | 获取指定类型的实例
   * @param type Instance type | 实例类型
   * @returns Instance | 实例
   */
  protected getInstance(type: T): I {
    const instance = this.instanceMap.get(type);
    if (!instance) {
      throw new Error(`Instance of type ${type} not initialized. Call initialize() first.`);
    }
    return instance;
  }
  
  /**
   * Set custom instance | 设置自定义实例
   * @param type Instance type | 实例类型
   * @param instance Instance | 实例
   */
  public setInstance(type: T, instance: I): void {
    this.instanceMap.set(type, instance);
    Logger.info(this.TAG, `Custom instance set for type: ${type}`);
  }
  
  /**
   * Check if instance is initialized | 检查实例是否初始化
   * @param type Instance type | 实例类型
   * @returns Whether initialized | 是否初始化
   */
  public isInstanceInitialized(type: T): boolean {
    return this.instanceMap.has(type);
  }
  
  /**
   * Close all resources | 关闭所有资源
   */
  public async close(): Promise<void> {
    try {
      Logger.info(this.TAG, 'Closing resources...');
      // 关闭所有可关闭的实例 | Close all closable instances
      for (const entry of this.instanceMap.entries()) {
        const type = entry[0];
        const instance = entry[1];
        // 使用类型检查代替类型断言
        if (instance && typeof instance === 'object') {
          // 直接检查close属性
          const closableInstance = instance as Closable;
          if (closableInstance.close && typeof closableInstance.close === 'function') {
            await closableInstance.close();
            Logger.info(this.TAG, String(type) + ' instance closed');
          }
        }
      }
      
      // 清理实例映射 | Clear instance map
      this.instanceMap.clear();
      this.isInitialized = false;
      
      Logger.info(this.TAG, 'All resources closed successfully');
    } catch (error) {
      let errorMsg: string = 'Unknown error';
      if (error instanceof Error) {
        errorMsg = error.message;
      }
      Logger.error(this.TAG, 'Failed to close resources: ' + errorMsg);
    }
  }
  /**
   * Reset factory (mainly for testing) | 重置工厂（主要用于测试）
   */
  public static reset(): void {
    const TAG = 'FactoryBase';
    // 由于ArkTS限制，静态方法中无法访问实例，需要子类实现具体重置逻辑
    Logger.info(TAG, 'Factory reset method called - subclasses should implement specific reset logic');
  }
}

