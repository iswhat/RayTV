// SQLiteHelper.ets - SQLite数据库操作辅助类
// 提供基本的CRUD操作和SQL查询构建功能

import RelationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from './DatabaseManager';
import Logger from '../../common/util/Logger';

const TAG = 'SQLiteHelper';

/**
 * 数据库支持的值类�?*/
export type ValueType = string | number | boolean | null;

/**
 * 数据库记录类�?*/
export type DatabaseRecord = Record<string, ValueType>;

/**
 * SQLiteHelper类定义开�?*/


/**
 * SQL查询条件接口
 */
export interface QueryCondition {
  column: string;
  value: ValueType | ValueType[];
  operator?: '=' | '!=' | '>' | '<' | '>=' | '<=' | 'LIKE' | 'IN' | 'NOT IN';
}

/**
 * SQL排序选项接口
 */
export interface SortOption {
  column: string;
  order?: 'ASC' | 'DESC';
}

/**
 * 数据库操作结果接�?*/
export interface DatabaseResult {
  success: boolean;
  message?: string;
  affectedRows?: number;
  lastInsertRowId?: number;
}

export class SQLiteHelper {
  private static instance: SQLiteHelper;
  private dbManager: DatabaseManager;
  
  /**
   * 获取对象的键数组（ArkTS兼容方法�?*/
  private getObjectKeys<T extends DatabaseRecord>(obj: T): string[] {
    const keys: string[] = [];
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        keys.push(key);
      }
    }
    return keys;
  }
  
  /**
   * 获取对象的值数组（ArkTS兼容方法�?*/
  private getObjectValues<T extends DatabaseRecord>(obj: T): ValueType[] {
    const values: ValueType[] = [];
    for (const key in obj) {
      if (Object.keys(obj).includes(key)) {
        values.push(obj[key]);
      }
    }
    return values;
  }
  
  private constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }
  
  /**
   * 获取SQLiteHelper单例实例
   */
  public static getInstance(): SQLiteHelper {
    if (!SQLiteHelper.instance) {
      SQLiteHelper.instance = new SQLiteHelper();
    }
    return SQLiteHelper.instance;
  }
  
  /**
   * 插入数据
   * @param tableName 表名
   * @param values 要插入的数据
   * @returns 插入结果
   */
  public async insert(tableName: string, values: Record<string, ValueType>): Promise<DatabaseResult> {
    try {
      Logger.debug(TAG, `Inserting data into ${tableName}`);
      
      const database = this.dbManager.getDatabase();
      
      // 构建插入语句
      const columns = this.getObjectKeys(values);
      const placeholders = columns.map(() => '?').join(', ');
      const bindArgs = this.getObjectValues(values);
      
      const sql = `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${placeholders})`;
      
      // 执行插入
      await database.executeSql(sql, bindArgs);
      
      // 获取最后插入的ID
      const result = await database.querySql(`SELECT last_insert_rowid() as id`);
      // Fix type handling for querySql result
      const idIndex = result.columnNames.indexOf('id');
      const lastInsertRowId = result.firstItem ? (result.firstItem.getLong(idIndex) || 0) : -1;
      
      Logger.info(TAG, `Inserted data into ${tableName}, ID: ${lastInsertRowId}`);
      
      return {
        success: true,
        lastInsertRowId,
        affectedRows: 1
      };
    } catch (error) {
      Logger.error(TAG, `Failed to insert into ${tableName}: ${JSON.stringify(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 批量插入数据
   * @param tableName 表名
   * @param dataList 数据列表
   * @returns 插入结果
   */
  public async batchInsert(tableName: string, dataList: Array<Record<string, ValueType>>): Promise<DatabaseResult> {
    if (!dataList || dataList.length === 0) {
      return { success: true, affectedRows: 0 };
    }
    
    try {
      let affectedRows = 0;
      
      await this.dbManager.executeTransaction(async (db) => {
        for (const values of dataList) {
          const columns = this.getObjectKeys(values);
          const placeholders = columns.map(() => '?').join(', ');
          const bindArgs = this.getObjectValues(values);
          
          const sql = `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${placeholders})`;
          await db.executeSql(sql, bindArgs);
          affectedRows++;
        }
      });
      
      Logger.info(TAG, `Batch inserted ${affectedRows} records into ${tableName}`);
      return {
        success: true,
        affectedRows
      };
    } catch (error) {
      Logger.error(TAG, `Failed to batch insert into ${tableName}: ${JSON.stringify(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 更新数据
   * @param tableName 表名
   * @param values 要更新的数据
   * @param conditions 更新条件
   * @returns 更新结果
   */
  public async update(
    tableName: string,
    values: Record<string, ValueType>,
    conditions?: Array<QueryCondition>
  ): Promise<DatabaseResult> {
    try {
      const database = this.dbManager.getDatabase();
      
      // 构建更新语句
      const columns = this.getObjectKeys(values);
      const setClause = columns
        .map(key => `${key} = ?`)
        .join(', ');
      
      let sql = `UPDATE ${tableName} SET ${setClause}`;
      const bindArgs: ValueType[] = this.getObjectValues(values);
      
      // 添加条件
      if (conditions && conditions.length > 0) {
        const whereClause = conditions.map(cond => {
          const operator = cond.operator || '=';
          if (operator === 'IN' || operator === 'NOT IN') {
            const placeholders = Array.isArray(cond.value)
              ? cond.value.map(() => '?').join(', ')
              : '?';
            return `${cond.column} ${operator} (${placeholders})`;
          }
          return `${cond.column} ${operator} ?`;
        }).join(' AND ');
        
        sql += ` WHERE ${whereClause}`;
        
        // 处理IN条件的参�?        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            bindArgs.push(...cond.value);
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            bindArgs.push(cond.value);
          }
        });
      }
      
      // 执行更新
      await database.executeSql(sql, bindArgs);
      
      // 获取影响的行�?      const result = await database.querySql('SELECT changes() as affected_rows');
      const affectedRows = result.firstItem?.getLong(result.columnNames.indexOf('affected_rows')) || 0;
      
      Logger.info(TAG, `Updated ${affectedRows} records in ${tableName}`);
      
      return {
        success: true,
        affectedRows
      };
    } catch (error) {
      Logger.error(TAG, `Failed to update ${tableName}: ${JSON.stringify(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 删除数据
   * @param tableName 表名
   * @param conditions 删除条件
   * @returns 删除结果
   */
  public async delete(
    tableName: string,
    conditions?: Array<QueryCondition>
  ): Promise<DatabaseResult> {
    try {
      const database = this.dbManager.getDatabase();
      
      let sql = `DELETE FROM ${tableName}`;
      const bindArgs: ValueType[] = [];
      
      // 添加条件
      if (conditions && conditions.length > 0) {
        const whereClause = conditions.map(cond => {
          const operator = cond.operator || '=';
          if (operator === 'IN' || operator === 'NOT IN') {
            const placeholders = Array.isArray(cond.value)
              ? cond.value.map(() => '?').join(', ')
              : '?';
            return `${cond.column} ${operator} (${placeholders})`;
          }
          return `${cond.column} ${operator} ?`;
        }).join(' AND ');
        
        sql += ` WHERE ${whereClause}`;
        
        // 处理IN条件的参�?        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            bindArgs.push(...cond.value);
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            bindArgs.push(cond.value);
          }
        });
      }
      
      // 执行删除
      await database.executeSql(sql, bindArgs);
      
      // 获取影响的行�?      const result = await database.querySql('SELECT changes() as affected_rows');
      const affectedRows = result.firstItem?.getLong(result.columnNames.indexOf('affected_rows')) || 0;
      
      Logger.info(TAG, `Deleted ${affectedRows} records from ${tableName}`);
      
      return {
        success: true,
        affectedRows
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete from ${tableName}: ${JSON.stringify(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 查询数据
   * @param tableName 表名
   * @param columns 要查询的�?   * @param conditions 查询条件
   * @param sortOptions 排序选项
   * @param limit 限制数量
   * @param offset 偏移�?   * @returns 查询结果列表
   */
  public async query<T extends DatabaseRecord>(
    tableName: string,
    columns: string[] = ['*'],
    conditions?: Array<QueryCondition>,
    sortOptions?: Array<SortOption>,
    limit?: number,
    offset: number = 0
  ): Promise<T[]> {
    try {
      const database = this.dbManager.getDatabase();
      
      // 构建查询语句
      let sql = `SELECT ${columns.join(', ')} FROM ${tableName}`;
      const bindArgs: ValueType[] = [];
      
      // 添加条件
      if (conditions && conditions.length > 0) {
        const whereClause = conditions.map(cond => {
          const operator = cond.operator || '=';
          if (operator === 'IN' || operator === 'NOT IN') {
            const placeholders = Array.isArray(cond.value)
              ? cond.value.map(() => '?').join(', ')
              : '?';
            return `${cond.column} ${operator} (${placeholders})`;
          }
          return `${cond.column} ${operator} ?`;
        }).join(' AND ');
        
        sql += ` WHERE ${whereClause}`;
        
        // 处理IN条件的参�?        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            bindArgs.push(...cond.value);
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            bindArgs.push(cond.value);
          }
        });
      }
      
      // 添加排序
      if (sortOptions && sortOptions.length > 0) {
        const orderByClause = sortOptions
          .map(option => `${option.column} ${option.order || 'ASC'}`)
          .join(', ');
        sql += ` ORDER BY ${orderByClause}`;
      }
      
      // 添加分页
      if (limit !== undefined) {
        sql += ` LIMIT ? OFFSET ?`;
        bindArgs.push(limit, offset);
      }
      
      Logger.debug(TAG, `Executing query: ${sql}, args: ${JSON.stringify(bindArgs)}`);
      
      // 执行查询
      const result = await database.querySql(sql, bindArgs);
      
      // 处理结果
      const records: T[] = [];
      while (result.goToNextRow()) {
        const record: DatabaseRecord = {};
        result.columnNames.forEach((column, index) => {
          // 根据数据类型获取�?          const value = result.getDouble(index);
          if (!isNaN(value)) {
            // 如果是整数，转换为整�?            if (Number.isInteger(value)) {
              record[column] = Math.floor(value);
            } else {
              record[column] = value;
            }
          } else {
            // 尝试获取字符�?            record[column] = result.getString(index);
          }
        });
        records.push(record);
      }
      
      Logger.info(TAG, `Retrieved ${records.length} records from ${tableName}`);
      return records;
    } catch (error) {
      Logger.error(TAG, `Failed to query ${tableName}: ${JSON.stringify(error)}`);
      return [];
    }
  }
  
  /**
   * 获取单条记录
   * @param tableName 表名
   * @param columns 要查询的�?   * @param conditions 查询条件
   * @returns 单条记录或null
   */
  public async getFirst<T extends DatabaseRecord>(
    tableName: string, 
    columns: string[] = ['*'],
    conditions?: Array<QueryCondition>
  ): Promise<T | null> {
    const results = await this.query<T>(tableName, columns, conditions, undefined, 1);
    return results.length > 0 ? results[0] : null;
  }
  
  /**
   * 获取记录总数
   * @param tableName 表名
   * @param conditions 查询条件
   * @returns 记录总数
   */
  public async count(tableName: string, conditions?: Array<QueryCondition>): Promise<number> {
    try {
      const database = this.dbManager.getDatabase();
      
      let sql = `SELECT COUNT(*) as count FROM ${tableName}`;
      const bindArgs: ValueType[] = [];
      
      // 添加条件
      if (conditions && conditions.length > 0) {
        const whereClause = conditions.map(cond => {
          const operator = cond.operator || '=';
          if (operator === 'IN' || operator === 'NOT IN') {
            const placeholders = Array.isArray(cond.value)
              ? cond.value.map(() => '?').join(', ')
              : '?';
            return `${cond.column} ${operator} (${placeholders})`;
          }
          return `${cond.column} ${operator} ?`;
        }).join(' AND ');
        
        sql += ` WHERE ${whereClause}`;
        
        // 处理IN条件的参�?        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            bindArgs.push(...cond.value);
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            bindArgs.push(cond.value);
          }
        });
      }
      
      const result = await database.querySql(sql, bindArgs);
      if (result.firstItem) {
        const count = result.firstItem.getLong(result.columnNames.indexOf('count'));
        return count || 0;
      }
      return 0;
    } catch (error) {
      Logger.error(TAG, `Failed to count ${tableName}: ${JSON.stringify(error)}`);
      return 0;
    }
  }
  
  /**
   * 检查记录是否存�?   * @param tableName 表名
   * @param conditions 查询条件
   * @returns 是否存在
   */
  public async exists(tableName: string, conditions?: Array<QueryCondition>): Promise<boolean> {
    const count = await this.count(tableName, conditions);
    return count > 0;
  }
  
  /**
   * 执行自定义SQL查询
   * @param sql SQL语句
   * @param bindArgs 绑定参数
   * @returns 查询结果
   */
  public async executeCustomQuery<T>(sql: string, bindArgs?: ValueType[]): Promise<T[]> {
    try {
      const database = this.dbManager.getDatabase();
      
      Logger.debug(TAG, `Executing custom query: ${sql}, args: ${JSON.stringify(bindArgs)}`);
      
      const result = await database.querySql(sql, bindArgs);
      
      // 处理结果
      const records: T[] = [];
      while (result.goToNextRow()) {
        const record: DatabaseRecord = {};
        result.columnNames.forEach((column, index) => {
          // 根据数据类型获取�?          const value = result.getDouble(index);
          if (!isNaN(value)) {
            // 如果是整数，转换为整�?            if (Number.isInteger(value)) {
              record[column] = Math.floor(value);
            } else {
              record[column] = value;
            }
          } else {
            // 尝试获取字符�?            record[column] = result.getString(index);
          }
        });
        records.push(record);
      }
      
      return records;
    } catch (error) {
      Logger.error(TAG, `Failed to execute custom query: ${JSON.stringify(error)}`);
      return [];
    }
  }
}
