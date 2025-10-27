import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from '../DatabaseManager';
import { CONFIG_TABLE } from '../TableSchema';
import Logger from '../../../common/util/Logger';
import JsonUtil from '../../../common/util/JsonUtil';

const TAG = 'ConfigDao';

export interface Config {
  key: string;
  value: any;
  type: string;
  group: string;
  updatedAt: number;
}

export class ConfigDao {
  private db: relationalStore.RdbStore;
  
  constructor() {
    this.db = DatabaseManager.getInstance().getDatabase();
  }
  
  // 保存配置
  public async save(config: Config): Promise<void> {
    try {
      // 检查是否已存在
      const existing = await this.getByKey(config.key);
      
      const valuesBucket: relationalStore.ValuesBucket = {
        [CONFIG_TABLE.COLUMNS.KEY]: config.key,
        [CONFIG_TABLE.COLUMNS.VALUE]: JsonUtil.stringify(config.value),
        [CONFIG_TABLE.COLUMNS.TYPE]: config.type,
        [CONFIG_TABLE.COLUMNS.GROUP]: config.group,
        [CONFIG_TABLE.COLUMNS.UPDATED_AT]: config.updatedAt
      };
      
      if (existing) {
        // 更新
        const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
        predicates.equalTo(CONFIG_TABLE.COLUMNS.KEY, config.key);
        await this.db.update(valuesBucket, predicates);
      } else {
        // 插入
        await this.db.insert(CONFIG_TABLE.TABLE_NAME, valuesBucket);
      }
      
      Logger.info(TAG, `Saved config: ${config.key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to save config: ${error}`);
      throw error;
    }
  }
  
  // 批量保存配置
  public async saveBatch(configs: Config[]): Promise<void> {
    try {
      for (const config of configs) {
        await this.save(config);
      }
      Logger.info(TAG, `Saved ${configs.length} config items`);
    } catch (error) {
      Logger.error(TAG, `Failed to save batch configs: ${error}`);
      throw error;
    }
  }
  
  // 根据key获取配置
  public async getByKey(key: string): Promise<Config | null> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.KEY, key);
      
      const resultSet = await this.db.query(predicates);
      const configs = this.parseResultSet(resultSet);
      return configs.length > 0 ? configs[0] : null;
    } catch (error) {
      Logger.error(TAG, `Failed to get config by key: ${error}`);
      throw error;
    }
  }
  
  // 获取指定分组的配置
  public async getByGroup(group: string): Promise<Config[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.GROUP, group);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get configs by group: ${error}`);
      throw error;
    }
  }
  
  // 获取所有配置
  public async getAll(): Promise<Config[]> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
      
      const resultSet = await this.db.query(predicates);
      return this.parseResultSet(resultSet);
    } catch (error) {
      Logger.error(TAG, `Failed to get all configs: ${error}`);
      throw error;
    }
  }
  
  // 删除配置
  public async delete(key: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.KEY, key);
      
      await this.db.delete(predicates);
      Logger.info(TAG, `Deleted config: ${key}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete config: ${error}`);
      throw error;
    }
  }
  
  // 清空指定分组的配置
  public async clearByGroup(group: string): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
      predicates.equalTo(CONFIG_TABLE.COLUMNS.GROUP, group);
      
      await this.db.delete(predicates);
      Logger.info(TAG, `Cleared configs for group: ${group}`);
    } catch (error) {
      Logger.error(TAG, `Failed to clear configs by group: ${error}`);
      throw error;
    }
  }
  
  // 清空所有配置
  public async clearAll(): Promise<void> {
    try {
      const predicates = new relationalStore.RdbPredicates(CONFIG_TABLE.TABLE_NAME);
      await this.db.delete(predicates);
      Logger.info(TAG, 'Cleared all configs');
    } catch (error) {
      Logger.error(TAG, `Failed to clear all configs: ${error}`);
      throw error;
    }
  }
  
  // 解析结果集
  private parseResultSet(resultSet: relationalStore.ResultSet): Config[] {
    const configs: Config[] = [];
    
    if (resultSet.rowCount > 0) {
      resultSet.goToFirstRow();
      do {
        try {
          const valueStr = resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.VALUE));
          const value = JsonUtil.parse(valueStr);
          
          configs.push({
            key: resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.KEY)),
            value,
            type: resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.TYPE)),
            group: resultSet.getString(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.GROUP)),
            updatedAt: resultSet.getLong(resultSet.getColumnIndex(CONFIG_TABLE.COLUMNS.UPDATED_AT))
          });
        } catch (parseError) {
          Logger.error(TAG, `Failed to parse config value: ${parseError}`);
        }
      } while (resultSet.goToNextRow());
    }
    
    resultSet.close();
    return configs;
  }
}