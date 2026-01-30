/**
 * RepositoryFactory - 仓库工厂类 | Repository factory class
 * 负责创建和管理各种Repository的实现 | Responsible for creating and managing various Repository implementations
 */

import DatabaseRepository from './DatabaseRepository';
import SQLiteDatabaseRepository from './SQLiteDatabaseRepository';
import NetworkRepository from './NetworkRepository';
import DefaultNetworkRepository from './DefaultNetworkRepository';
import { FactoryBase } from '../../common/base/FactoryBase';

/**
 * 定义具有close方法的组件接口 | Define component interface with close method
 */
interface ClosableRepository {
  close?: () => Promise<void>; // 关闭方法 | Close method
}

/**
 * Repository类型枚举 | Repository type enum
 */
export enum RepositoryType {
  DATABASE, // 数据库 | Database
  NETWORK // 网络 | Network
}

/**
 * Repository工厂类 | Repository factory class
 * 负责创建和管理各种Repository的实现 | Responsible for creating and managing various Repository implementations
 */
export default class RepositoryFactory extends FactoryBase<RepositoryType, DatabaseRepository | NetworkRepository> {
  protected readonly TAG: string = 'RepositoryFactory'; // 日志标签 | Log tag

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    super();
  }

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): RepositoryFactory {
    if (!RepositoryFactory.instance) {
      RepositoryFactory.instance = new RepositoryFactory();
    }
    return RepositoryFactory.instance;
  }

  private static instance: RepositoryFactory | null = null;

  /**
   * 初始化所有仓库 | Initialize all repositories
   * @returns 是否初始化成功 | Whether initialization succeeded
   */
  public async initialize(): Promise<boolean> {
    try {
      if (this.isInitialized) {
        console.info(this.TAG + ': 仓库已初始化 | Repositories already initialized');
        return true;
      }

      console.info(this.TAG + ': 正在初始化仓库... | Initializing repositories...');

      // 初始化数据库仓库 | Initialize database repository
      const databaseRepository = new SQLiteDatabaseRepository();
      // 注意：SQLiteDatabaseRepository需要先设置context，这里暂时仅初始化
      // Note: SQLiteDatabaseRepository needs to set context first, only initialize here temporarily
      // 在实际使用前需要调用getContext并initialize
      // Need to call getContext and initialize before actual use
      this.instanceMap.set(RepositoryType.DATABASE, databaseRepository as DatabaseRepository);
      console.info(this.TAG + ': 数据库仓库已创建（需要特定初始化） | Database repository created (needs specific initialization)');

      // 初始化网络仓库（这里使用默认配置，实际使用时需要提供具体配置）| Initialize network repository (using default config here, specific config needed in actual use)
      const networkRepository = new DefaultNetworkRepository();
      // 注意：DefaultNetworkRepository需要先设置config，这里暂时仅初始化
      // Note: DefaultNetworkRepository needs to set config first, only initialize here temporarily
      // 在使用网络仓库之前，需要调用setConfig并initialize
      // Need to call setConfig and initialize before using network repository
      this.instanceMap.set(RepositoryType.NETWORK, networkRepository);
      console.info(this.TAG + ': 网络仓库已创建（需要特定初始化） | Network repository created (needs specific initialization)');

      this.isInitialized = true;
      console.info(this.TAG + ': 所有仓库初始化成功 | All repositories initialized successfully');
      return true;
    } catch (error) {
      console.error(this.TAG + `: 初始化仓库失败: | Failed to initialize repositories: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 获取数据库仓库实例 | Get database repository instance
   * @returns DatabaseRepository实例 | DatabaseRepository instance
   */
  public getDatabaseRepository(): DatabaseRepository {
    return this.getInstance(RepositoryType.DATABASE) as DatabaseRepository;
  }

  /**
   * 获取网络仓库实例 | Get network repository instance
   * @returns NetworkRepository实例 | NetworkRepository instance
   */
  public getNetworkRepository(): NetworkRepository {
    return this.getInstance(RepositoryType.NETWORK) as NetworkRepository;
  }

  /**
   * 设置自定义仓库实例 | Set custom repository instance
   * @param type 仓库类型 | Repository type
   * @param repository 仓库实例 | Repository instance
   */
  public setRepository(type: RepositoryType, repository: DatabaseRepository | NetworkRepository): void {
    this.setInstance(type, repository);
  }

  /**
   * 检查仓库是否初始化 | Check if repository is initialized
   * @param type 仓库类型 | Repository type
   * @returns 是否初始化 | Whether initialized
   */
  public isRepositoryInitialized(type: RepositoryType): boolean {
    return this.isInstanceInitialized(type);
  }

  /**
   * 关闭所有仓库资源 | Close all repository resources
   */
  public async close(): Promise<void> {
    try {
      console.info(this.TAG + ': 正在关闭仓库... | Closing repositories...');

      // 调用父类的close方法关闭仓库实例 | Call parent class close method to close repository instances
      await super.close();
      
      console.info(this.TAG + ': 所有仓库关闭成功 | All repositories closed successfully');
    } catch (error) {
      console.error(this.TAG + `: 关闭仓库失败: | Failed to close repositories: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
