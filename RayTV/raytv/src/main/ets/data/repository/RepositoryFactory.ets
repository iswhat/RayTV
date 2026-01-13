// RepositoryFactory - 仓库工厂类 | Repository factory class
import Logger from '../../common/util/Logger';
import DatabaseRepository from './DatabaseRepository';
import SQLiteDatabaseRepository from './SQLiteDatabaseRepository';
import NetworkRepository from './NetworkRepository';
import DefaultNetworkRepository from './DefaultNetworkRepository';
import { FactoryBase } from '../../common/base/FactoryBase';

// 定义具有close方法的组件接口 | Define component interface with close method
interface ClosableRepository {
  close?: () => Promise<void>;
}

/**
 * Repository类型枚举 | Repository type enum
 */
export enum RepositoryType {
  DATABASE,
  NETWORK
}

/**
 * Repository工厂类 | Repository factory class
 * 负责创建和管理各种Repository的实现 | Responsible for creating and managing various Repository implementations
 */
export default class RepositoryFactory extends FactoryBase<RepositoryType, DatabaseRepository | NetworkRepository> {
  protected readonly TAG: string = 'RepositoryFactory';

  /**
 * 私有构造函数 | Private constructor
 */
  private constructor() {
    super();
  }

  /**
 * 初始化所有仓库 | Initialize all repositories
 * @returns 是否初始化成功 | Whether initialization succeeded
 */
  public async initialize(): Promise<boolean> {
    try {
      if (this.isInitialized) {
        Logger.info(this.TAG, 'Repositories already initialized');
        return true;
      }

      Logger.info(this.TAG, 'Initializing repositories...');

      // 初始化数据库仓库 | Initialize database repository
      const databaseRepository = new SQLiteDatabaseRepository();
      // 注意：SQLiteDatabaseRepository需要先设置context，这里暂时仅初始化
      // 在实际使用前需要调用getContext并initialize
      this.instanceMap.set(RepositoryType.DATABASE, databaseRepository as DatabaseRepository);
      Logger.info(this.TAG, 'Database repository created (needs specific initialization)');

      // 初始化网络仓库（这里使用默认配置，实际使用时需要提供具体配置）| Initialize network repository (using default config here, specific config needed in actual use)
      const networkRepository = new DefaultNetworkRepository();
      // 注意：DefaultNetworkRepository需要先设置config，这里暂时仅初始化
      // 在使用网络仓库之前，需要调用setConfig并initialize
      this.instanceMap.set(RepositoryType.NETWORK, networkRepository);
      Logger.info(this.TAG, 'Network repository created (needs specific initialization)');

      this.isInitialized = true;
      Logger.info(this.TAG, 'All repositories initialized successfully');
      return true;
    } catch (error) {
      Logger.error(this.TAG, `Failed to initialize repositories: ${error instanceof Error ? error.message : String(error)}`);
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
      Logger.info(this.TAG, 'Closing repositories...');

      // 调用父类的close方法关闭仓库实例 | Call parent class close method to close repository instances
      await super.close();
      
      Logger.info(this.TAG, 'All repositories closed successfully');
    } catch (error) {
      Logger.error(this.TAG, `Failed to close repositories: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}


