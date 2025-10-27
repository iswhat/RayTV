// StorageUtil - 存储工具类
// 提供统一的本地存储功能，包括数据的保存、读取、删除等操作

import { Logger } from './Logger';
import { LocalStorageType } from '../data/model/LocalModel';

/**
 * 存储工具类
 */
export class StorageUtil {
  private static instance: StorageUtil;
  private logger = Logger.getInstance();
  
  /**
   * 私有构造函数
   */
  private constructor() {
    this.logger.info('StorageUtil initialized');
  }

  /**
   * 获取StorageUtil单例实例
   */
  public static getInstance(): StorageUtil {
    if (!StorageUtil.instance) {
      StorageUtil.instance = new StorageUtil();
    }
    return StorageUtil.instance;
  }

  /**
   * 保存数据到存储
   * @param key 键
   * @param value 值
   * @param storageType 存储类型
   * @param encrypted 是否加密
   */
  public async save<T>(key: string, value: T, storageType: LocalStorageType = LocalStorageType.DEFAULT, encrypted: boolean = false): Promise<boolean> {
    try {
      this.logger.debug(`Saving data for key: ${key}, storageType: ${storageType}`);
      
      const dataToSave = encrypted ? this.encryptData(value) : value;
      const serializedData = this.serialize(dataToSave);
      
      if (storageType === LocalStorageType.SECURE) {
        return this.saveSecure(key, serializedData);
      } else if (storageType === LocalStorageType.TEMPORARY) {
        return this.saveTemporary(key, serializedData);
      } else if (storageType === LocalStorageType.PERSISTENT) {
        return this.savePersistent(key, serializedData);
      } else {
        return this.saveDefault(key, serializedData);
      }
    } catch (error) {
      this.logger.error(`Failed to save data for key: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 从存储中读取数据
   * @param key 键
   * @param storageType 存储类型
   * @param encrypted 是否加密
   */
  public async get<T>(key: string, storageType: LocalStorageType = LocalStorageType.DEFAULT, encrypted: boolean = false): Promise<T | null> {
    try {
      this.logger.debug(`Getting data for key: ${key}, storageType: ${storageType}`);
      
      let serializedData: string | null = null;
      
      if (storageType === LocalStorageType.SECURE) {
        serializedData = await this.getSecure(key);
      } else if (storageType === LocalStorageType.TEMPORARY) {
        serializedData = this.getTemporary(key);
      } else if (storageType === LocalStorageType.PERSISTENT) {
        serializedData = await this.getPersistent(key);
      } else {
        serializedData = this.getDefault(key);
      }
      
      if (!serializedData) {
        return null;
      }
      
      const deserializedData = this.deserialize(serializedData);
      return encrypted ? this.decryptData(deserializedData) : deserializedData as T;
    } catch (error) {
      this.logger.error(`Failed to get data for key: ${key}`, error as Error);
      return null;
    }
  }

  /**
   * 从存储中删除数据
   * @param key 键
   * @param storageType 存储类型
   */
  public async remove(key: string, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      this.logger.debug(`Removing data for key: ${key}, storageType: ${storageType}`);
      
      if (storageType === LocalStorageType.SECURE) {
        return await this.removeSecure(key);
      } else if (storageType === LocalStorageType.TEMPORARY) {
        return this.removeTemporary(key);
      } else if (storageType === LocalStorageType.PERSISTENT) {
        return await this.removePersistent(key);
      } else {
        return this.removeDefault(key);
      }
    } catch (error) {
      this.logger.error(`Failed to remove data for key: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 检查存储中是否存在指定键
   * @param key 键
   * @param storageType 存储类型
   */
  public async exists(key: string, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      if (storageType === LocalStorageType.SECURE) {
        return await this.existsSecure(key);
      } else if (storageType === LocalStorageType.TEMPORARY) {
        return this.existsTemporary(key);
      } else if (storageType === LocalStorageType.PERSISTENT) {
        return await this.existsPersistent(key);
      } else {
        return this.existsDefault(key);
      }
    } catch (error) {
      this.logger.error(`Failed to check existence for key: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 清空所有存储数据
   * @param storageType 存储类型
   */
  public async clear(storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      this.logger.debug(`Clearing all data for storageType: ${storageType}`);
      
      if (storageType === LocalStorageType.SECURE) {
        return await this.clearSecure();
      } else if (storageType === LocalStorageType.TEMPORARY) {
        return this.clearTemporary();
      } else if (storageType === LocalStorageType.PERSISTENT) {
        return await this.clearPersistent();
      } else {
        return this.clearDefault();
      }
    } catch (error) {
      this.logger.error(`Failed to clear data for storageType: ${storageType}`, error as Error);
      return false;
    }
  }

  /**
   * 获取所有键
   * @param storageType 存储类型
   */
  public async getAllKeys(storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<string[]> {
    try {
      this.logger.debug(`Getting all keys for storageType: ${storageType}`);
      
      if (storageType === LocalStorageType.SECURE) {
        return await this.getAllSecureKeys();
      } else if (storageType === LocalStorageType.TEMPORARY) {
        return this.getAllTemporaryKeys();
      } else if (storageType === LocalStorageType.PERSISTENT) {
        return await this.getAllPersistentKeys();
      } else {
        return this.getAllDefaultKeys();
      }
    } catch (error) {
      this.logger.error(`Failed to get all keys for storageType: ${storageType}`, error as Error);
      return [];
    }
  }

  /**
   * 批量保存数据
   * @param dataMap 键值对映射
   * @param storageType 存储类型
   * @param encrypted 是否加密
   */
  public async saveBatch(dataMap: Map<string, any>, storageType: LocalStorageType = LocalStorageType.DEFAULT, encrypted: boolean = false): Promise<boolean> {
    try {
      this.logger.debug(`Saving batch data, count: ${dataMap.size}, storageType: ${storageType}`);
      
      let success = true;
      for (const [key, value] of dataMap.entries()) {
        const result = await this.save(key, value, storageType, encrypted);
        if (!result) {
          success = false;
        }
      }
      
      return success;
    } catch (error) {
      this.logger.error('Failed to save batch data', error as Error);
      return false;
    }
  }

  /**
   * 批量获取数据
   * @param keys 键列表
   * @param storageType 存储类型
   * @param encrypted 是否加密
   */
  public async getBatch<T>(keys: string[], storageType: LocalStorageType = LocalStorageType.DEFAULT, encrypted: boolean = false): Promise<Map<string, T | null>> {
    try {
      this.logger.debug(`Getting batch data, count: ${keys.length}, storageType: ${storageType}`);
      
      const resultMap = new Map<string, T | null>();
      
      for (const key of keys) {
        const value = await this.get<T>(key, storageType, encrypted);
        resultMap.set(key, value);
      }
      
      return resultMap;
    } catch (error) {
      this.logger.error('Failed to get batch data', error as Error);
      return new Map();
    }
  }
  
  /**
   * 保存对象到存储
   * @param key 键
   * @param value 对象值
   * @param storageType 存储类型
   */
  public async setObject<T>(key: string, value: T, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    return await this.save(key, value, storageType, false);
  }
  
  /**
   * 从存储中获取对象
   * @param key 键
   * @param storageType 存储类型
   */
  public async getObject<T>(key: string, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<T | null> {
    return await this.get<T>(key, storageType, false);
  }
  
  /**
   * 保存字符串到存储
   * @param key 键
   * @param value 字符串值
   * @param storageType 存储类型
   */
  public async setString(key: string, value: string, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    return await this.save(key, value, storageType, false);
  }
  
  /**
   * 从存储中获取字符串
   * @param key 键
   * @param storageType 存储类型
   */
  public async getString(key: string, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<string | null> {
    return await this.get<string>(key, storageType, false);
  }

  /**
   * 获取存储使用情况
   * @param storageType 存储类型
   */
  public async getStorageInfo(storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<{ used: number; total?: number; percentage?: number }> {
    try {
      this.logger.debug(`Getting storage info for storageType: ${storageType}`);
      
      // 这里需要实现实际的存储信息获取
      return { used: 0 };
    } catch (error) {
      this.logger.error(`Failed to get storage info for storageType: ${storageType}`, error as Error);
      return { used: 0 };
    }
  }

  /**
   * 设置存储键过期时间
   * @param key 键
   * @param expirationTime 过期时间（毫秒）
   * @param storageType 存储类型
   */
  public async setExpiration(key: string, expirationTime: number, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      this.logger.debug(`Setting expiration for key: ${key}, time: ${expirationTime}ms`);
      
      const expiryData = {
        originalKey: key,
        expiration: Date.now() + expirationTime
      };
      
      return await this.save(`__expiry_${key}`, expiryData, storageType);
    } catch (error) {
      this.logger.error(`Failed to set expiration for key: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 检查键是否已过期
   * @param key 键
   * @param storageType 存储类型
   */
  public async isExpired(key: string, storageType: LocalStorageType = LocalStorageType.DEFAULT): Promise<boolean> {
    try {
      const expiryData = await this.get<{ expiration: number }>(`__expiry_${key}`, storageType);
      
      if (!expiryData || !expiryData.expiration) {
        return false;
      }
      
      const isExpired = Date.now() > expiryData.expiration;
      
      // 如果已过期，自动删除
      if (isExpired) {
        await this.remove(key, storageType);
        await this.remove(`__expiry_${key}`, storageType);
      }
      
      return isExpired;
    } catch (error) {
      this.logger.error(`Failed to check expiration for key: ${key}`, error as Error);
      return false;
    }
  }

  /**
   * 序列化数据
   * @param data 要序列化的数据
   */
  private serialize(data: any): string {
    try {
      return JSON.stringify(data);
    } catch (error) {
      this.logger.error('Failed to serialize data', error as Error);
      throw error;
    }
  }

  /**
   * 反序列化数据
   * @param data 要反序列化的数据
   */
  private deserialize(data: string): any {
    try {
      return JSON.parse(data);
    } catch (error) {
      this.logger.error('Failed to deserialize data', error as Error);
      throw error;
    }
  }

  /**
   * 加密数据
   * @param data 要加密的数据
   */
  private encryptData(data: any): string {
    // 这里需要实现实际的加密逻辑
    this.logger.warn('Encryption is not implemented, using plain text');
    return this.serialize(data);
  }

  /**
   * 解密数据
   * @param data 要解密的数据
   */
  private decryptData(data: any): any {
    // 这里需要实现实际的解密逻辑
    this.logger.warn('Decryption is not implemented, assuming plain text');
    return typeof data === 'string' ? this.deserialize(data) : data;
  }

  // 默认存储实现（基于localStorage）
  private saveDefault(key: string, value: string): boolean {
    try {
      localStorage.setItem(key, value);
      return true;
    } catch (error) {
      this.logger.error('Failed to save to default storage', error as Error);
      return false;
    }
  }

  private getDefault(key: string): string | null {
    try {
      return localStorage.getItem(key);
    } catch (error) {
      this.logger.error('Failed to get from default storage', error as Error);
      return null;
    }
  }

  private removeDefault(key: string): boolean {
    try {
      localStorage.removeItem(key);
      return true;
    } catch (error) {
      this.logger.error('Failed to remove from default storage', error as Error);
      return false;
    }
  }

  private existsDefault(key: string): boolean {
    try {
      return localStorage.getItem(key) !== null;
    } catch (error) {
      this.logger.error('Failed to check existence in default storage', error as Error);
      return false;
    }
  }

  private clearDefault(): boolean {
    try {
      localStorage.clear();
      return true;
    } catch (error) {
      this.logger.error('Failed to clear default storage', error as Error);
      return false;
    }
  }

  private getAllDefaultKeys(): string[] {
    try {
      return Object.keys(localStorage);
    } catch (error) {
      this.logger.error('Failed to get all keys from default storage', error as Error);
      return [];
    }
  }

  // 临时存储实现（基于sessionStorage）
  private saveTemporary(key: string, value: string): boolean {
    try {
      sessionStorage.setItem(key, value);
      return true;
    } catch (error) {
      this.logger.error('Failed to save to temporary storage', error as Error);
      return false;
    }
  }

  private getTemporary(key: string): string | null {
    try {
      return sessionStorage.getItem(key);
    } catch (error) {
      this.logger.error('Failed to get from temporary storage', error as Error);
      return null;
    }
  }

  private removeTemporary(key: string): boolean {
    try {
      sessionStorage.removeItem(key);
      return true;
    } catch (error) {
      this.logger.error('Failed to remove from temporary storage', error as Error);
      return false;
    }
  }

  private existsTemporary(key: string): boolean {
    try {
      return sessionStorage.getItem(key) !== null;
    } catch (error) {
      this.logger.error('Failed to check existence in temporary storage', error as Error);
      return false;
    }
  }

  private clearTemporary(): boolean {
    try {
      sessionStorage.clear();
      return true;
    } catch (error) {
      this.logger.error('Failed to clear temporary storage', error as Error);
      return false;
    }
  }

  private getAllTemporaryKeys(): string[] {
    try {
      return Object.keys(sessionStorage);
    } catch (error) {
      this.logger.error('Failed to get all keys from temporary storage', error as Error);
      return [];
    }
  }

  // 持久化存储实现（需要在实际环境中实现）
  private async savePersistent(key: string, value: string): Promise<boolean> {
    // 在实际环境中，这里需要使用文件系统或其他持久化存储机制
    this.logger.warn('Persistent storage is not fully implemented');
    return this.saveDefault(key, value);
  }

  private async getPersistent(key: string): Promise<string | null> {
    // 在实际环境中，这里需要使用文件系统或其他持久化存储机制
    this.logger.warn('Persistent storage is not fully implemented');
    return this.getDefault(key);
  }

  private async removePersistent(key: string): Promise<boolean> {
    // 在实际环境中，这里需要使用文件系统或其他持久化存储机制
    this.logger.warn('Persistent storage is not fully implemented');
    return this.removeDefault(key);
  }

  private async existsPersistent(key: string): Promise<boolean> {
    // 在实际环境中，这里需要使用文件系统或其他持久化存储机制
    this.logger.warn('Persistent storage is not fully implemented');
    return this.existsDefault(key);
  }

  private async clearPersistent(): Promise<boolean> {
    // 在实际环境中，这里需要使用文件系统或其他持久化存储机制
    this.logger.warn('Persistent storage is not fully implemented');
    return this.clearDefault();
  }

  private async getAllPersistentKeys(): Promise<string[]> {
    // 在实际环境中，这里需要使用文件系统或其他持久化存储机制
    this.logger.warn('Persistent storage is not fully implemented');
    return this.getAllDefaultKeys();
  }

  // 安全存储实现（需要在实际环境中实现）
  private async saveSecure(key: string, value: string): Promise<boolean> {
    // 在实际环境中，这里需要使用系统安全存储机制
    this.logger.warn('Secure storage is not fully implemented');
    return this.saveDefault(key, value);
  }

  private async getSecure(key: string): Promise<string | null> {
    // 在实际环境中，这里需要使用系统安全存储机制
    this.logger.warn('Secure storage is not fully implemented');
    return this.getDefault(key);
  }

  private async removeSecure(key: string): Promise<boolean> {
    // 在实际环境中，这里需要使用系统安全存储机制
    this.logger.warn('Secure storage is not fully implemented');
    return this.removeDefault(key);
  }

  private async existsSecure(key: string): Promise<boolean> {
    // 在实际环境中，这里需要使用系统安全存储机制
    this.logger.warn('Secure storage is not fully implemented');
    return this.existsDefault(key);
  }

  private async clearSecure(): Promise<boolean> {
    // 在实际环境中，这里需要使用系统安全存储机制
    this.logger.warn('Secure storage is not fully implemented');
    return this.clearDefault();
  }

  private async getAllSecureKeys(): Promise<string[]> {
    // 在实际环境中，这里需要使用系统安全存储机制
    this.logger.warn('Secure storage is not fully implemented');
    return [];
  }
}

// 导出默认实例
export default StorageUtil.getInstance();