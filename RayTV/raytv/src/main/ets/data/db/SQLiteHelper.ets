// SQLiteHelper.ets - SQLite数据库操作辅助类 // SQLite Database Operation Helper Class
// 提供基本的CRUD操作和SQL查询构建功能 // Provide basic CRUD operations and SQL query building capabilities

import RelationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from './DatabaseManager';
import Logger from '../../common/util/Logger';

const TAG = 'SQLiteHelper';

/**
 * 数据库支持的类型 // Database supported types
 */
export type ValueType = string | number | boolean | null;

/**
 * 数据库记录类型 // Database record type
 */
export type DatabaseRecord = Record<string, ValueType>;

/**
 * SQL查询条件接口 // SQL query condition interface
 */
export interface QueryCondition {
  column: string;
  value: ValueType | ValueType[];
  operator?: '=' | '!=' | '>' | '<' | '>=' | '<=' | 'LIKE' | 'IN' | 'NOT IN';
}

/**
 * SQL排序选项接口 // SQL sort option interface
 */
export interface SortOption {
  column: string;
  order?: 'ASC' | 'DESC';
}

/**
 * 数据库操作结果接口 // Database operation result interface
 */
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
   * 获取对象的键数组（ArkTS兼容方法） // Get object key array (ArkTS compatible method)
   */
  private getObjectKeys<T extends DatabaseRecord>(obj: T): string[] {
    try {
      const jsonString = JSON.stringify(obj);
      // 使用字符串解析来提取键，避免使用Object.keys // Use string parsing to extract keys, avoid using Object.keys
      const keys: string[] = [];
      let inKey = false;
      let currentKey = '';
      let isEscaped = false;
      
      // 跳过JSON对象的开始大括号 // Skip JSON object opening brace
      let i = 1;
      
      while (i < jsonString.length) {
        const char = jsonString[i];
        
        if (isEscaped) {
          currentKey += char;
          isEscaped = false;
        } else if (char === '\\') {
          isEscaped = true;
        } else if (char === '"' && !inKey) {
          inKey = true;
          currentKey = '';
        } else if (char === '"' && inKey) {
          inKey = false;
          keys.push(currentKey);
        } else if (inKey) {
          currentKey += char;
        } else if (char === '}') {
          break;
        }
        i++;
      }
      
      return keys;
    } catch {
      return [];
    }
  }
  
  /**
   * 获取对象的值数组（ArkTS兼容方法） // Get object value array (ArkTS compatible method)
   */
  private getObjectValues<T extends DatabaseRecord>(obj: T): ValueType[] {
    try {
      const keys = this.getObjectKeys(obj);
      const values: ValueType[] = [];
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        values.push(obj[key]);
      }
      
      return values;
    } catch {
      return [];
    }
  }
  
  private constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }
  
  /**
   * 获取SQLiteHelper单例实例 // Get SQLiteHelper singleton instance
   */
  public static getInstance(): SQLiteHelper {
    if (!SQLiteHelper.instance) {
      SQLiteHelper.instance = new SQLiteHelper();
    }
    return SQLiteHelper.instance;
  }
  
  /**
   * 插入数据 // Insert data
   * @param tableName 表名 // Table name
   * @param values 要插入的数据 // Data to insert
   * @returns 插入结果 // Insert result
   */
  public async insert(tableName: string, values: Record<string, ValueType>): Promise<DatabaseResult> {
    try {
      Logger.debug(TAG, `Inserting data into ${tableName}`);
      
      const database = this.dbManager.getDatabase();
      
      // 构建插入语句 // Build insert statement
      const columns = this.getObjectKeys(values);
      const placeholders = columns.map(() => '?').join(', ');
      const bindArgs = this.getObjectValues(values);
      
      const sql = `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${placeholders})`;
      
      // 执行插入 // Execute insert
      await database.executeSql(sql, bindArgs);
      
      // 获取最后插入的ID // Get last inserted ID
      const result: RelationalStore.ResultSet = await database.querySql(`SELECT last_insert_rowid() as id`);
      let lastInsertRowId = -1;
      if (result.goToFirstRow()) {
        const idIndex = result.columnNames.indexOf('id');
        lastInsertRowId = result.getLong(idIndex) || 0;
      }
      
      Logger.info(TAG, `Inserted data into ${tableName}, ID: ${lastInsertRowId}`);
      
      return {
        success: true,
        lastInsertRowId,
        affectedRows: 1
      };
    } catch (error) {
      Logger.error(TAG, `Failed to insert into ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 批量插入数据 // Batch insert data
   * @param tableName 表名 // Table name
   * @param dataList 数据列表 // Data list
   * @returns 插入结果 // Insert result
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
      Logger.error(TAG, `Failed to batch insert into ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 更新数据 // Update data
   * @param tableName 表名 // Table name
   * @param values 要更新的数据 // Data to update
   * @param conditions 更新条件 // Update conditions
   * @returns 更新结果 // Update result
   */
  public async update(
    tableName: string,
    values: Record<string, ValueType>,
    conditions?: Array<QueryCondition>
  ): Promise<DatabaseResult> {
    try {
      const database = this.dbManager.getDatabase();
      
      // 构建更新语句 // Build update statement
      const columns = this.getObjectKeys(values);
      const setClause = columns
        .map(key => `${key} = ?`)
        .join(', ');
      
      let sql = `UPDATE ${tableName} SET ${setClause}`;
      const bindArgs: ValueType[] = this.getObjectValues(values);
      
      // 添加条件 // Add conditions
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
        
        // 处理IN条件的参数 // Handle IN condition parameters
        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            // 替换spread运算符，使用传统的for循环 // Replace spread operator, use traditional for loop
            for (let i = 0; i < cond.value.length; i++) {
              bindArgs.push(cond.value[i] as ValueType);
            }
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            // 确保cond.value不是数组 // Ensure cond.value is not array
            if (!Array.isArray(cond.value)) {
              bindArgs.push(cond.value as ValueType);
            }
          }
        });
      }
      
      // 执行更新 // Execute update
      await database.executeSql(sql, bindArgs);
      
      // 获取影响的行数 // Get affected rows
      const result = await database.querySql('SELECT changes() as affected_rows');
      let affectedRows = 0;
      if (result.goToFirstRow()) {
        const index = result.getColumnIndex('affected_rows');
        affectedRows = result.getLong(index) || 0;
      }
      
      Logger.info(TAG, `Updated ${affectedRows} records in ${tableName}`);
      
      return {
        success: true,
        affectedRows
      };
    } catch (error) {
      Logger.error(TAG, `Failed to update ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 删除数据 // Delete data
   * @param tableName 表名 // Table name
   * @param conditions 删除条件 // Delete conditions
   * @returns 删除结果 // Delete result
   */
  public async delete(
    tableName: string,
    conditions?: Array<QueryCondition>
  ): Promise<DatabaseResult> {
    try {
      const database = this.dbManager.getDatabase();
      
      let sql = `DELETE FROM ${tableName}`;
      const bindArgs: ValueType[] = [];
      
      // 添加条件 // Add conditions
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
        
        // 处理IN条件的参数 // Handle IN condition parameters
        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            // 替换spread运算符，使用传统的for循环 // Replace spread operator, use traditional for loop
            for (let i = 0; i < cond.value.length; i++) {
              bindArgs.push(cond.value[i]);
            }
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            // 确保cond.value不是数组 // Ensure cond.value is not array
            if (!Array.isArray(cond.value)) {
              bindArgs.push(cond.value as ValueType);
            }
          }
        });
      }
      
      // 执行删除 // Execute delete
      await database.executeSql(sql, bindArgs);
      
      // 获取影响的行 // Get affected rows
      const result: RelationalStore.ResultSet = await database.querySql('SELECT changes() as affected_rows');
      let affectedRows = 0;
      if (result.goToFirstRow()) {
        const idIndex = result.columnNames.indexOf('affected_rows');
        affectedRows = result.getLong(idIndex) || 0;
      }
      
      Logger.info(TAG, `Deleted ${affectedRows} records from ${tableName}`);
      
      return {
        success: true,
        affectedRows
      };
    } catch (error) {
      Logger.error(TAG, `Failed to delete from ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
  }
  
  /**
   * 查询数据 // Query data
   * @param tableName 表名 // Table name
   * @param columns 要查询的列 // Columns to query
   * @param conditions 查询条件 // Query conditions
   * @param sortOptions 排序选项 // Sort options
   * @param limit 限制数量 // Limit count
   * @param offset 偏移量 // Offset
   * @returns 查询结果列表 // Query result list
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
      
      // 构建查询语句 // Build query statement
      let sql = `SELECT ${columns.join(', ')} FROM ${tableName}`;
      const bindArgs: ValueType[] = [];
      
      // 添加条件 // Add conditions
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
        
        // 处理IN条件的参数 // Handle IN condition parameters
        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            // 替换spread运算符，使用传统的for循环 // Replace spread operator, use traditional for loop
            for (let i = 0; i < cond.value.length; i++) {
              bindArgs.push(cond.value[i]);
            }
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            // 确保cond.value不是数组 // Ensure cond.value is not array
            if (!Array.isArray(cond.value)) {
              bindArgs.push(cond.value as ValueType);
            }
          }
        });
      }
      
      // 添加排序 // Add sorting
      if (sortOptions && sortOptions.length > 0) {
        const orderByClause = sortOptions
          .map(option => `${option.column} ${option.order || 'ASC'}`)
          .join(', ');
        sql += ` ORDER BY ${orderByClause}`;
      }
      
      // 添加分页 // Add pagination
      if (limit !== undefined) {
        sql += ` LIMIT ? OFFSET ?`;
        bindArgs.push(limit, offset);
      }
      
      Logger.debug(TAG, `Executing query: ${sql}, args: ${JSON.stringify(bindArgs)}`);
      
      // 执行查询 // Execute query
      const result: RelationalStore.ResultSet = await database.querySql(sql, bindArgs);
      
      // 处理结果 // Process results
      const records: T[] = [];
      while (result.goToNextRow()) {
        const record: DatabaseRecord = {};
        const columnNames = result.columnNames;
        for (let index = 0; index < columnNames.length; index++) {
          const column = columnNames[index];
          
          // 先尝试获取字符串 // First try to get string
          const stringValue = result.getString(index);
          if (stringValue !== null) {
            record[column] = stringValue;
          } else {
            // 尝试获取数字 // Try to get number
            const longValue = result.getLong(index);
            if (longValue !== null) {
              record[column] = longValue;
            } else {
              // 尝试获取浮点数 // Try to get float
              const doubleValue = result.getDouble(index);
              if (doubleValue !== null && !isNaN(doubleValue)) {
                record[column] = doubleValue;
              } else {
                // 获取布尔值 - 使用getLong判断 // Get boolean value - use getLong to judge
                const boolLongValue = result.getLong(index);
                if (boolLongValue !== null) {
                  record[column] = boolLongValue === 1;
                } else {
                  record[column] = null;
                }
              }
            }
          }
        }
        records.push(record as T);
      }
      
      Logger.info(TAG, `Retrieved ${records.length} records from ${tableName}`);
      return records;
    } catch (error) {
      Logger.error(TAG, `Failed to query ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
  
  /**
   * 获取单条记录 // Get single record
   * @param tableName 表名 // Table name
   * @param columns 要查询的列 // Columns to query
   * @param conditions 查询条件 // Query conditions
   * @returns 单条记录或null // Single record or null
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
   * 获取记录总数 // Get total record count
   * @param tableName 表名 // Table name
   * @param conditions 查询条件 // Query conditions
   * @returns 记录总数 // Total record count
   */
  public async count(tableName: string, conditions?: Array<QueryCondition>): Promise<number> {
    try {
      const database = this.dbManager.getDatabase();
      
      let sql = `SELECT COUNT(*) as count FROM ${tableName}`;
      const bindArgs: ValueType[] = [];
      
      // 添加条件 // Add conditions
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
        
        // 处理IN条件的参数 // Handle IN condition parameters
        conditions.forEach(cond => {
          if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
            // 替换spread运算符，使用传统的for循环 // Replace spread operator, use traditional for loop
            for (let i = 0; i < cond.value.length; i++) {
              bindArgs.push(cond.value[i] as ValueType);
            }
          } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
            // 确保cond.value是ValueType类型，不是数组 // Ensure cond.value is ValueType, not array
            if (!Array.isArray(cond.value)) {
              bindArgs.push(cond.value as ValueType);
            }
          }
        });
      }
      
      const result: RelationalStore.ResultSet = await database.querySql(sql, bindArgs);
      if (result.goToFirstRow()) {
        const countIndex = result.columnNames.indexOf('count');
        const count = result.getLong(countIndex);
        return count || 0;
      }
      return 0;
    } catch (error) {
      Logger.error(TAG, `Failed to count ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return 0;
    }
  }
  
  /**
   * 检查记录是否存在 // Check if record exists
   * @param tableName 表名 // Table name
   * @param conditions 查询条件 // Query conditions
   * @returns 是否存在 // Whether exists
   */
  public async exists(tableName: string, conditions?: Array<QueryCondition>): Promise<boolean> {
    const count = await this.count(tableName, conditions);
    return count > 0;
  }
  
  /**
   * 执行自定义SQL查询 // Execute custom SQL query
   * @param sql SQL语句 // SQL statement
   * @param bindArgs 绑定参数 // Bind arguments
   * @returns 查询结果 // Query result
   */
  public async executeCustomQuery<T extends Record<string, string | number | boolean | null>>(sql: string, bindArgs?: ValueType[]): Promise<T[]> {
    try {
      const database = this.dbManager.getDatabase();
      
      Logger.debug(TAG, `Executing custom query: ${sql}, args: ${JSON.stringify(bindArgs)}`);
      
      const result: RelationalStore.ResultSet = await database.querySql(sql, bindArgs);
      
      // 处理结果 // Process results
      const records: T[] = [];
      while (result.goToNextRow()) {
        const record: Record<string, string | number | boolean | null> = {};
        const columnNames = result.columnNames;
        for (let index = 0; index < columnNames.length; index++) {
          const column = columnNames[index];
          
          // 先尝试获取字符串 // First try to get string
          const stringValue = result.getString(index);
          if (stringValue !== null) {
            record[column] = stringValue;
          } else {
            // 尝试获取数字 // Try to get number
            const longValue = result.getLong(index);
            if (longValue !== null) {
              record[column] = longValue;
            } else {
              // 尝试获取浮点数 // Try to get float
              const doubleValue = result.getDouble(index);
              if (doubleValue !== null && !isNaN(doubleValue)) {
                record[column] = doubleValue;
              } else {
                // 获取布尔值 - 使用getLong判断 // Get boolean value - use getLong to judge
                const boolLongValue = result.getLong(index);
                if (boolLongValue !== null) {
                  record[column] = boolLongValue === 1;
                } else {
                  record[column] = null;
                }
              }
            }
          }
        }
        records.push(record as T);
      }
      
      return records;
    } catch (error) {
      Logger.error(TAG, `Failed to execute custom query: ${error instanceof Error ? error.message : String(error)}`);
      return [];
    }
  }
}
