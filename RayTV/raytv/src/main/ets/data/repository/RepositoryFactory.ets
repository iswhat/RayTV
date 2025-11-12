// RepositoryFactory - 仓库工厂类
import Logger from '../../common/util/Logger';
import DatabaseRepository from './DatabaseRepository';
import SQLiteDatabaseRepository from './SQLiteDatabaseRepository';
import NetworkRepository from './NetworkRepository';
import DefaultNetworkRepository from './DefaultNetworkRepository';

const TAG = 'RepositoryFactory';

/**
 * Repository类型枚举
 */
export enum RepositoryType {
  DATABASE,
  NETWORK
}

/**
 * Repository工厂类
 * 负责创建和管理各种Repository的实例
 */
export default class RepositoryFactory {
  private static instance: RepositoryFactory;
  private repositoryMap: Map<RepositoryType, DatabaseRepository | NetworkRepository> = new Map();
  private isInitialized: boolean = false;

  /**
   * 私有构造函数
   */
  private constructor() {}

  /**
   * 获取单例实例
   * @returns RepositoryFactory实例
   */
  public static getInstance(): RepositoryFactory {
    if (!RepositoryFactory.instance) {
      RepositoryFactory.instance = new RepositoryFactory();
    }
    return RepositoryFactory.instance;
  }

  /**
   * 初始化所有仓库
   * @returns 是否初始化成功
   */
  public async initialize(): Promise<boolean> {
    try {
      if (this.isInitialized) {
        Logger.info(TAG, 'Repositories already initialized');
        return true;
      }

      Logger.info(TAG, 'Initializing repositories...');

      // 初始化数据库仓库
      const databaseRepository = new SQLiteDatabaseRepository();
      const dbInitResult = await databaseRepository.initialize();
      
      if (!dbInitResult.success) {
        Logger.error(TAG, `Failed to initialize database repository: ${dbInitResult.message || 'Unknown error'}`);
        return false;
      }
      
      this.repositoryMap.set(RepositoryType.DATABASE, databaseRepository);
      Logger.info(TAG, 'Database repository initialized successfully');

      // 初始化网络仓库（这里使用默认配置，实际使用时需要提供具体配置）
      const networkRepository = new DefaultNetworkRepository();
      // 注意：这里不进行初始化，因为需要具体的baseUrl配置
      // 在使用网络仓库之前，需要调用setConfig并initialize
      this.repositoryMap.set(RepositoryType.NETWORK, networkRepository);
      Logger.info(TAG, 'Network repository created (needs specific initialization)');

      this.isInitialized = true;
      Logger.info(TAG, 'All repositories initialized successfully');
      return true;
    } catch (error) {
      Logger.error(TAG, `Failed to initialize repositories: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
  }

  /**
   * 获取数据库仓库实例
   * @returns DatabaseRepository实例
   */
  public getDatabaseRepository(): DatabaseRepository {
    const repository = this.repositoryMap.get(RepositoryType.DATABASE);
    if (!repository) {
      throw new Error('Database repository not initialized. Call initialize() first.');
    }
    return repository;
  }

  /**
   * 获取网络仓库实例
   * @returns NetworkRepository实例
   */
  public getNetworkRepository(): NetworkRepository {
    const repository = this.repositoryMap.get(RepositoryType.NETWORK);
    if (!repository) {
      throw new Error('Network repository not initialized. Call initialize() first.');
    }
    return repository;
  }

  /**
   * 设置自定义仓库实例
   * @param type 仓库类型
   * @param repository 仓库实例
   */
  public setRepository(type: RepositoryType, repository: DatabaseRepository | NetworkRepository): void {
    this.repositoryMap.set(type, repository);
    Logger.info(TAG, `Custom repository set for type: ${type}`);
  }

  /**
   * 检查仓库是否初始化
   * @param type 仓库类型
   * @returns 是否初始化
   */
  public isRepositoryInitialized(type: RepositoryType): boolean {
    return this.repositoryMap.has(type);
  }

  /**
   * 关闭所有仓库资源
   */
  public async close(): Promise<void> {
    try {
      Logger.info(TAG, 'Closing repositories...');

      // 关闭数据库仓库
      const dbRepository = this.repositoryMap.get(RepositoryType.DATABASE);
      if (dbRepository && typeof dbRepository.close === 'function') {
        await dbRepository.close();
        Logger.info(TAG, 'Database repository closed');
      }

      // 清理仓库映射
      this.repositoryMap.clear();
      this.isInitialized = false;
      
      Logger.info(TAG, 'All repositories closed successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to close repositories: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /**
   * 重置工厂（主要用于测试）
   */
  public static reset(): void {
    if (RepositoryFactory.instance) {
      RepositoryFactory.instance.close().catch(error => {
        Logger.error(TAG, `Error during factory reset: ${error instanceof Error ? error.message : String(error)}`);
      });
      RepositoryFactory.instance = null;
    }
    Logger.info(TAG, 'Repository factory reset');
  }
}