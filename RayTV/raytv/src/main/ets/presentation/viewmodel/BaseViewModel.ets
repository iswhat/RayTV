/**
 * ViewModel基类 | Base ViewModel Class
 * 提供事件订阅、发布和依赖注入功能
 */
import EventBus, { EventCallback } from '../../common/event/EventBus';
import DIContainer from '../../common/di/Container';
import Logger from '../../common/util/Logger';

/**
 * ViewModel基类 | Base ViewModel class
 */
export abstract class BaseViewModel {
  protected eventBus: EventBus;
  protected diContainer: DIContainer;
  protected disposables: Array<() => void> = [];
  protected logger: Logger;

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    this.eventBus = EventBus.getInstance();
    this.diContainer = DIContainer.getInstance();
    this.logger = new Logger(this.constructor.name);
    this.setupSubscriptions();
  }

  /**
   * 设置事件订阅 | Set up event subscriptions
   * 子类应重写此方法来设置事件订阅
   */
  protected abstract setupSubscriptions(): void;

  /**
   * 订阅事件 | Subscribe to event
   * @param eventName 事件名称 | Event name
   * @param callback 回调函数 | Callback function
   */
  protected subscribe<T = any>(eventName: string, callback: EventCallback<T>): void {
    const subscriptionId = this.eventBus.subscribe(eventName, callback);
    this.disposables.push(() => this.eventBus.unsubscribe(eventName, subscriptionId));
    this.logger.info(`Subscribed to event: ${eventName}`);
  }

  /**
   * 订阅一次性事件 | Subscribe to one-time event
   * @param eventName 事件名称 | Event name
   * @param callback 回调函数 | Callback function
   */
  protected subscribeOnce<T = any>(eventName: string, callback: EventCallback<T>): void {
    const subscriptionId = this.eventBus.once(eventName, callback);
    this.disposables.push(() => this.eventBus.unsubscribe(eventName, subscriptionId));
    this.logger.info(`Subscribed to one-time event: ${eventName}`);
  }

  /**
   * 发布事件 | Publish event
   * @param eventName 事件名称 | Event name
   * @param data 事件数据 | Event data
   * @param source 事件来源 | Event source
   */
  protected emit<T = any>(eventName: string, data?: T, source?: string): void {
    this.eventBus.publish(eventName, data, source || this.constructor.name);
  }

  /**
   * 解析服务 | Resolve service
   * @param token 服务标识符 | Service token
   * @returns 服务实例 | Service instance
   */
  protected resolve<T>(token: string): T {
    return this.diContainer.resolve<T>(token);
  }

  /**
   * 检查服务是否存在 | Check if service exists
   * @param token 服务标识符 | Service token
   * @returns 是否存在 | Whether exists
   */
  protected hasService(token: string): boolean {
    return this.diContainer.has(token);
  }

  /**
   * 清理资源 | Clean up resources
   * 调用此方法来清理所有订阅和资源
   */
  public dispose(): void {
    this.disposables.forEach(dispose => dispose());
    this.disposables = [];
    this.logger.info('ViewModel disposed');
  }

  /**
   * 获取ViewModel名称 | Get ViewModel name
   * @returns ViewModel名称 | ViewModel name
   */
  public get name(): string {
    return this.constructor.name;
  }
}

/**
 * ViewModel工厂 | ViewModel factory
 */
export class ViewModelFactory {
  private static instance: ViewModelFactory | null = null;
  private viewModels: Map<string, BaseViewModel> = new Map();
  private logger: Logger;

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): ViewModelFactory {
    if (!ViewModelFactory.instance) {
      ViewModelFactory.instance = new ViewModelFactory();
    }
    return ViewModelFactory.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('ViewModelFactory');
  }

  /**
   * 创建或获取ViewModel实例 | Create or get ViewModel instance
   * @param viewModelClass ViewModel类 | ViewModel class
   * @returns ViewModel实例 | ViewModel instance
   */
  public get<T extends BaseViewModel>(viewModelClass: new () => T): T {
    const key = viewModelClass.name;
    
    if (!this.viewModels.has(key)) {
      const instance = new viewModelClass();
      this.viewModels.set(key, instance);
      this.logger.info(`Created ViewModel: ${key}`);
    }
    
    return this.viewModels.get(key) as T;
  }

  /**
   * 销毁ViewModel实例 | Destroy ViewModel instance
   * @param viewModelClass ViewModel类 | ViewModel class
   */
  public destroy<T extends BaseViewModel>(viewModelClass: new () => T): void {
    const key = viewModelClass.name;
    const viewModel = this.viewModels.get(key);
    
    if (viewModel) {
      viewModel.dispose();
      this.viewModels.delete(key);
      this.logger.info(`Destroyed ViewModel: ${key}`);
    }
  }

  /**
   * 销毁所有ViewModel实例 | Destroy all ViewModel instances
   */
  public destroyAll(): void {
    this.viewModels.forEach((viewModel, key) => {
      viewModel.dispose();
      this.logger.info(`Destroyed ViewModel: ${key}`);
    });
    this.viewModels.clear();
    this.logger.info('Destroyed all ViewModels');
  }

  /**
   * 获取ViewModel实例数量 | Get ViewModel instance count
   * @returns 实例数量 | Instance count
   */
  public getInstanceCount(): number {
    return this.viewModels.size;
  }

  /**
   * 获取所有ViewModel实例 | Get all ViewModel instances
   * @returns ViewModel实例数组 | ViewModel instance array
   */
  public getAllViewModels(): BaseViewModel[] {
    return Array.from(this.viewModels.values());
  }
}

// 导出ViewModelFactory单例 | Export ViewModelFactory singleton
export const viewModelFactory = ViewModelFactory.getInstance();
