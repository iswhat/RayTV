/**
 * SQLiteHelper - SQLite数据库操作辅助类
 * 
 * 提供基本的CRUD操作、SQL查询构建、事务管理等功能，支持安全的数据库操作。
 * 实现了单例模式，确保线程安全的数据库访问。
 * 
 * @example
 * ```typescript
 * // 获取SQLiteHelper实例
 * const dbHelper = SQLiteHelper.getInstance();
 * 
 * // 插入数据
 * const result = await dbHelper.insert('users', {
 *   name: 'John Doe',
 *   age: 30,
 *   active: true
 * });
 * 
 * // 查询数据
 * const users = await dbHelper.query('users', ['id', 'name'], [
 *   { column: 'age', value: 30, operator: '>=' }
 * ], [
 *   { column: 'name', order: 'ASC' }
 * ]);
 * ```
 */

import RelationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from './DatabaseManager';
import Logger from '../../common/util/Logger';
import SQLValidator from '../../common/util/SQLValidator';
import CacheService from '../../service/cache/CacheService';
import { CachePriority } from '../../service/cache/CacheService';

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
  private static instance: SQLiteHelper | null = null;
  private static initializationLock: boolean = false;
  private dbManager: DatabaseManager;
  private operationLock: boolean = false;
  private pendingOperations: Array<() => Promise<void>> = [];
  private cacheService: CacheService = CacheService.getInstance();
  private queryCacheEnabled: boolean = true;
  private queryCacheExpiry: number = 300000; // 5分钟
  private maxQueryCacheSize: number = 100;

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
  
  /**
   * 生成查询缓存键
   * 
   * @param tableName 表名
   * @param columns 查询列
   * @param conditions 查询条件
   * @param sortOptions 排序选项
   * @param limit 限制数量
   * @param offset 偏移量
   * @returns 缓存键
   */
  private generateQueryCacheKey(
    tableName: string,
    columns: string[],
    conditions?: Array<QueryCondition>,
    sortOptions?: Array<SortOption>,
    limit?: number,
    offset: number = 0
  ): string {
    const cacheKey = `query_${tableName}_${columns.join('_')}_${JSON.stringify(conditions || [])}_${JSON.stringify(sortOptions || [])}_${limit || 0}_${offset}`;
    return cacheKey;
  }
  
  /**
   * 清理表相关的缓存
   * 
   * @param tableName 表名
   */
  private async clearTableCache(tableName: string): Promise<void> {
    try {
      // 通过标签清理相关缓存
      await this.cacheService.removeByTags(['query', tableName]);
      Logger.debug(TAG, `Cleared cache for table: ${tableName}`);
    } catch (error) {
      Logger.error(TAG, `Failed to clear cache for table ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
  
  private constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }
  
  /**
   * 获取SQLiteHelper单例实例（线程安全）
   * 
   * 实现了双重检查锁定模式，确保线程安全的单例初始化。
   * 
   * @returns {SQLiteHelper} SQLiteHelper的单例实例
   * 
   * @example
   * ```typescript
   * const dbHelper = SQLiteHelper.getInstance();
   * ```
   */
  public static getInstance(): SQLiteHelper {
    if (!SQLiteHelper.instance && !SQLiteHelper.initializationLock) {
      SQLiteHelper.initializationLock = true;
      try {
        if (!SQLiteHelper.instance) {
          SQLiteHelper.instance = new SQLiteHelper();
        }
      } finally {
        SQLiteHelper.initializationLock = false;
      }
    }
    return SQLiteHelper.instance!;
  }
  
  /**
   * 执行数据库操作（带队列和锁定）
   * 
   * 确保同一时间只有一个数据库操作在执行，防止数据库锁定。
   * 
   * @param {() => Promise<T>} operation - 要执行的数据库操作
   * @returns {Promise<T>} 操作的返回结果
   */
  private async executeWithLock<T>(operation: () => Promise<T>): Promise<T> {
    // 如果已经有操作在执行，将当前操作加入队列
    if (this.operationLock) {
      return new Promise((resolve, reject) => {
        this.pendingOperations.push(async () => {
          try {
            const result = await operation();
            resolve(result);
          } catch (error) {
            reject(error);
          }
        });
      });
    }

    // 执行当前操作
    this.operationLock = true;
    try {
      const result = await operation();
      return result;
    } finally {
      this.operationLock = false;
      // 执行队列中的下一个操作
      const nextOperation = this.pendingOperations.shift();
      if (nextOperation) {
        nextOperation().catch(error => {
          Logger.error(TAG, `Pending operation failed: ${error instanceof Error ? error.message : String(error)}`);
        });
      }
    }
  }

  /**
   * 插入数据
   * 
   * 向指定表中插入一条新记录，返回插入结果，包含是否成功、影响的行数和最后插入的ID。
   * 
   * @param {string} tableName - 表名
   * @param {Record<string, ValueType>} values - 要插入的数据，键为列名，值为对应的值
   * @returns {Promise<DatabaseResult>} 插入结果，包含成功状态、影响的行数和最后插入的ID
   * 
   * @example
   * ```typescript
   * const result = await dbHelper.insert('users', {
   *   name: 'John Doe',
   *   age: 30,
   *   email: 'john@example.com'
   * });
   * 
   * if (result.success) {
   *   console.log(`Inserted with ID: ${result.lastInsertRowId}`);
   * }
   * ```
   */
  public async insert(tableName: string, values: Record<string, ValueType>): Promise<DatabaseResult> {
    return this.executeWithLock(async () => {
      try {
        Logger.debug(TAG, `Inserting data into ${tableName}`);

        // 验证表名，防止SQL注入
        SQLValidator.validateTableName(tableName);

        const database = this.dbManager.getDatabase();

        // 构建插入语句 // Build insert statement
        const columns = this.getObjectKeys(values);
        const placeholders = columns.map(() => '?').join(', ');
        const bindArgs = this.getObjectValues(values);

        const sql = `INSERT INTO ${tableName} (${columns.join(', ')}) VALUES (${placeholders})`;

        // 执行插入 // Execute insert
        await database.executeSql(sql, bindArgs);

        // 获取最后插入的ID - 修复空指针访问和资源泄漏问题
        const result: RelationalStore.ResultSet = await database.querySql(`SELECT last_insert_rowid() as id`);
        let lastInsertRowId = -1;

        try {
          if (result.goToFirstRow()) {
            const idIndex = result.columnNames.indexOf('id');
            // 修复问题1：检查idIndex是否有效
            if (idIndex >= 0) {
              lastInsertRowId = result.getLong(idIndex) || 0;
            } else {
              Logger.error(TAG, 'Column "id" not found in result');
            }
          }
        } finally {
          // 修复问题4：确保关闭ResultSet
          result.close();
        }

        // 清理表相关的缓存
        await this.clearTableCache(tableName);

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
    });
  }
  
  /**
   * 批量插入数据
   * 
   * 向指定表中批量插入多条记录，使用事务保护确保操作的原子性。
   * 
   * @param {string} tableName - 表名
   * @param {Array<Record<string, ValueType>>} dataList - 要插入的数据列表
   * @returns {Promise<DatabaseResult>} 插入结果，包含成功状态和影响的行数
   * 
   * @example
   * ```typescript
   * const users = [
   *   { name: 'John', age: 25 },
   *   { name: 'Jane', age: 30 },
   *   { name: 'Bob', age: 35 }
   * ];
   * 
   * const result = await dbHelper.batchInsert('users', users);
   * console.log(`Inserted ${result.affectedRows} users`);
   * ```
   */
  public async batchInsert(tableName: string, dataList: Array<Record<string, ValueType>>): Promise<DatabaseResult> {
    return this.executeWithLock(async () => {
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
        
        // 清理表相关的缓存
        await this.clearTableCache(tableName);

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
    });
  }
  
  /**
   * 更新数据
   * 
   * 根据指定条件更新表中的记录，返回更新结果，包含是否成功和影响的行数。
   * 
   * @param {string} tableName - 表名
   * @param {Record<string, ValueType>} values - 要更新的数据，键为列名，值为对应的值
   * @param {Array<QueryCondition>} [conditions] - 更新条件，可选
   * @returns {Promise<DatabaseResult>} 更新结果，包含成功状态和影响的行数
   * 
   * @example
   * ```typescript
   * const result = await dbHelper.update('users',
   *   { age: 31, active: true },
   *   [
   *     { column: 'id', value: 1 },
   *     { column: 'name', value: 'John Doe' }
   *   ]
   * );
   * 
   * console.log(`Updated ${result.affectedRows} records`);
   * ```
   */
  public async update(
    tableName: string,
    values: Record<string, ValueType>,
    conditions?: Array<QueryCondition>
  ): Promise<DatabaseResult> {
    return this.executeWithLock(async () => {
      try {
        // 验证表名，防止SQL注入
        SQLValidator.validateTableName(tableName);

        const database = this.dbManager.getDatabase();

        // 构建更新语句 // Build update statement
        const columns = this.getObjectKeys(values);

        // 验证列名
        SQLValidator.validateColumnNames(columns);

        const setClause = columns
          .map(key => `${key} = ?`)
          .join(', ');

        let sql = `UPDATE ${tableName} SET ${setClause}`;
        const bindArgs: ValueType[] = this.getObjectValues(values);

        // 添加条件 // Add conditions
        if (conditions && conditions.length > 0) {
          // 验证条件中的列名
          const conditionColumns = conditions.map(cond => cond.column);
          SQLValidator.validateColumnNames(conditionColumns);

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
        
        // 获取影响的行数 // Get affected rows - 修复资源泄漏
        const result = await database.querySql('SELECT changes() as affected_rows');
        let affectedRows = 0;

        try {
          if (result.goToFirstRow()) {
            const index = result.getColumnIndex('affected_rows');
            if (index >= 0) {
              affectedRows = result.getLong(index) || 0;
            }
          }
        } finally {
          result.close();
        }
        
        // 清理表相关的缓存
        await this.clearTableCache(tableName);

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
    });
  }
  
  /**
   * 删除数据
   * 
   * 根据指定条件删除表中的记录，返回删除结果，包含是否成功和影响的行数。
   * 
   * @param {string} tableName - 表名
   * @param {Array<QueryCondition>} [conditions] - 删除条件，可选
   * @returns {Promise<DatabaseResult>} 删除结果，包含成功状态和影响的行数
   * 
   * @example
   * ```typescript
   * const result = await dbHelper.delete('users', [
   *   { column: 'id', value: 1 },
   *   { column: 'active', value: false }
   * ]);
   * 
   * console.log(`Deleted ${result.affectedRows} records`);
   * ```
   */
  public async delete(
    tableName: string,
    conditions?: Array<QueryCondition>
  ): Promise<DatabaseResult> {
    return this.executeWithLock(async () => {
      try {
        // 验证表名，防止SQL注入
        SQLValidator.validateTableName(tableName);

        const database = this.dbManager.getDatabase();

        let sql = `DELETE FROM ${tableName}`;
        const bindArgs: ValueType[] = [];

        // 添加条件 // Add conditions
        if (conditions && conditions.length > 0) {
          // 验证条件中的列名
          const conditionColumns = conditions.map(cond => cond.column);
          SQLValidator.validateColumnNames(conditionColumns);

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
        
        // 获取影响的行 // Get affected rows - 修复资源泄漏和空指针检查
        const result: RelationalStore.ResultSet = await database.querySql('SELECT changes() as affected_rows');
        let affectedRows = 0;

        try {
          if (result.goToFirstRow()) {
            const idIndex = result.columnNames.indexOf('affected_rows');
            if (idIndex >= 0) {
              affectedRows = result.getLong(idIndex) || 0;
            }
          }
        } finally {
          result.close();
        }
        
        // 清理表相关的缓存
        await this.clearTableCache(tableName);

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
    });
  }
  
  /**
   * 查询数据
   * 
   * 根据指定条件查询表中的记录，支持排序、分页等功能，返回查询结果列表。
   * 
   * @template T - 泛型类型，用于指定返回记录的类型
   * @param {string} tableName - 表名
   * @param {string[]} [columns=['*']] - 要查询的列，默认为所有列
   * @param {Array<QueryCondition>} [conditions] - 查询条件，可选
   * @param {Array<SortOption>} [sortOptions] - 排序选项，可选
   * @param {number} [limit] - 限制返回的记录数量，可选
   * @param {number} [offset=0] - 偏移量，默认为0
   * @returns {Promise<T[]>} 查询结果列表
   * 
   * @example
   * ```typescript
   * // 查询所有用户
   * const users = await dbHelper.query('users');
   * 
   * // 查询特定列，带条件和排序
   * const activeUsers = await dbHelper.query('users',
   *   ['id', 'name', 'email'],
   *   [{ column: 'active', value: true }],
   *   [{ column: 'name', order: 'ASC' }]
   * );
   * 
   * // 分页查询
   * const paginatedUsers = await dbHelper.query('users',
   *   ['*'],
   *   undefined,
   *   [{ column: 'created_at', order: 'DESC' }],
   *   10, // 每页10条
   *   20  // 从第21条开始
   * );
   * ```
   */
  public async query<T extends DatabaseRecord>(
    tableName: string,
    columns: string[] = ['*'],
    conditions?: Array<QueryCondition>,
    sortOptions?: Array<SortOption>,
    limit?: number,
    offset: number = 0
  ): Promise<T[]> {
    return this.executeWithLock(async () => {
      try {
        // 生成缓存键
        const cacheKey = this.generateQueryCacheKey(tableName, columns, conditions, sortOptions, limit, offset);
        
        // 检查缓存
        if (this.queryCacheEnabled) {
          const cachedResult = await this.cacheService.get<T[]>(cacheKey);
          if (cachedResult) {
            Logger.debug(TAG, `Cache hit for query: ${cacheKey}`);
            return cachedResult;
          }
        }

        // 验证表名，防止SQL注入
        SQLValidator.validateTableName(tableName);

        // 验证列名（除非是*）
        if (columns[0] !== '*') {
          SQLValidator.validateColumnNames(columns);
        }

        const database = this.dbManager.getDatabase();

        // 构建查询语句 // Build query statement
        let sql = `SELECT ${columns.join(', ')} FROM ${tableName}`;
        const bindArgs: ValueType[] = [];

        // 添加条件 // Add conditions
        if (conditions && conditions.length > 0) {
          // 验证条件中的列名
          const conditionColumns = conditions.map(cond => cond.column);
          SQLValidator.validateColumnNames(conditionColumns);

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
          // 验证排序列名
          const sortColumns = sortOptions.map(opt => opt.column);
          SQLValidator.validateColumnNames(sortColumns);

          const orderByClause = sortOptions
            .map(option => {
              // 验证排序方向
              const order = (option.order || 'ASC').toUpperCase();
              SQLValidator.validateOrder(order);
              return `${option.column} ${order}`;
            })
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

        // 处理结果 - 确保ResultSet被关闭
        try {
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

          // 缓存查询结果
          if (this.queryCacheEnabled) {
            await this.cacheService.set(cacheKey, records, {
              expiry: this.queryCacheExpiry,
              priority: CachePriority.NORMAL,
              tags: ['query', tableName]
            });
            Logger.debug(TAG, `Cached query result: ${cacheKey}`);
          }

          Logger.info(TAG, `Retrieved ${records.length} records from ${tableName}`);
          return records;
        } finally {
          result.close();
        }
      } catch (error) {
        Logger.error(TAG, `Failed to query ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
        return [];
      }
    });
  }
  
  /**
   * 获取单条记录
   * 
   * 根据指定条件查询表中的第一条记录，返回单条记录或null。
   * 
   * @template T - 泛型类型，用于指定返回记录的类型
   * @param {string} tableName - 表名
   * @param {string[]} [columns=['*']] - 要查询的列，默认为所有列
   * @param {Array<QueryCondition>} [conditions] - 查询条件，可选
   * @returns {Promise<T | null>} 单条记录或null
   * 
   * @example
   * ```typescript
   * // 根据ID获取用户
   * const user = await dbHelper.getFirst('users',
   *   ['id', 'name', 'email'],
   *   [{ column: 'id', value: 1 }]
   * );
   * 
   * if (user) {
   *   console.log(`Found user: ${user.name}`);
   * } else {
   *   console.log('User not found');
   * }
   * ```
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
   * 
   * 根据指定条件统计表中的记录数量，返回记录总数。
   * 
   * @param {string} tableName - 表名
   * @param {Array<QueryCondition>} [conditions] - 查询条件，可选
   * @returns {Promise<number>} 记录总数
   * 
   * @example
   * ```typescript
   * // 获取所有用户数量
   * const totalUsers = await dbHelper.count('users');
   * console.log(`Total users: ${totalUsers}`);
   * 
   * // 获取活跃用户数量
   * const activeUsersCount = await dbHelper.count('users',
   *   [{ column: 'active', value: true }]
   * );
   * console.log(`Active users: ${activeUsersCount}`);
   * ```
   */
  public async count(tableName: string, conditions?: Array<QueryCondition>): Promise<number> {
    return this.executeWithLock(async () => {
      try {
        // 验证表名，防止SQL注入
        SQLValidator.validateTableName(tableName);

        const database = this.dbManager.getDatabase();

        let sql = `SELECT COUNT(*) as count FROM ${tableName}`;
        const bindArgs: ValueType[] = [];

        // 添加条件 // Add conditions
        if (conditions && conditions.length > 0) {
          // 验证条件中的列名
          const conditionColumns = conditions.map(cond => cond.column);
          SQLValidator.validateColumnNames(conditionColumns);

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

        try {
          if (result.goToFirstRow()) {
            const countIndex = result.columnNames.indexOf('count');
            if (countIndex >= 0) {
              const count = result.getLong(countIndex);
              return count || 0;
            }
          }
          return 0;
        } finally {
          result.close();
        }
      } catch (error) {
        Logger.error(TAG, `Failed to count ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
        return 0;
      }
    });
  }
  
  /**
   * 检查记录是否存在
   * 
   * 根据指定条件检查表中是否存在记录，返回布尔值表示是否存在。
   * 
   * @param {string} tableName - 表名
   * @param {Array<QueryCondition>} [conditions] - 查询条件，可选
   * @returns {Promise<boolean>} 是否存在记录
   * 
   * @example
   * ```typescript
   * // 检查用户是否存在
   * const userExists = await dbHelper.exists('users',
   *   [{ column: 'email', value: 'john@example.com' }]
   * );
   * 
   * if (userExists) {
   *   console.log('User already exists');
   * } else {
   *   console.log('User does not exist');
   * }
   * ```
   */
  public async exists(tableName: string, conditions?: Array<QueryCondition>): Promise<boolean> {
    const count = await this.count(tableName, conditions);
    return count > 0;
  }
  
  /**
   * 执行自定义SQL查询
   * 
   * 执行自定义的SQL查询语句，返回查询结果列表。
   * 
   * @template T - 泛型类型，用于指定返回记录的类型
   * @param {string} sql - SQL语句
   * @param {ValueType[]} [bindArgs] - 绑定参数，可选
   * @returns {Promise<T[]>} 查询结果列表
   * 
   * @example
   * ```typescript
   * // 执行自定义查询
   * const results = await dbHelper.executeCustomQuery<{
   *   id: number;
   *   name: string;
   *   age: number;
   * }>('SELECT id, name, age FROM users WHERE age > ?', [18]);
   * 
   * results.forEach(user => {
   *   console.log(`${user.name} (${user.age})`);
   * });
   * ```
   */
  public async executeCustomQuery<T extends Record<string, string | number | boolean | null>>(sql: string, bindArgs?: ValueType[]): Promise<T[]> {
    return this.executeWithLock(async () => {
      try {
        const database = this.dbManager.getDatabase();
        
        Logger.debug(TAG, `Executing custom query: ${sql}, args: ${JSON.stringify(bindArgs)}`);
        
        const result: RelationalStore.ResultSet = await database.querySql(sql, bindArgs);
        
        // 处理结果 - 确保ResultSet被关闭
        try {
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
        } finally {
          result.close();
        }
      } catch (error) {
        Logger.error(TAG, `Failed to execute custom query: ${error instanceof Error ? error.message : String(error)}`);
        return [];
      }
    });
  }

  /**
   * 批量更新数据（事务保护）
   * 
   * 批量更新多条记录，使用事务保护确保操作的原子性。
   * 
   * @param {string} tableName - 表名
   * @param {Array<{ values: Record<string, ValueType>, conditions: Array<QueryCondition> }>} updates - 更新数据列表，每条包含要更新的值和条件
   * @returns {Promise<DatabaseResult>} 更新结果，包含成功状态和影响的行数
   * 
   * @example
   * ```typescript
   * const updates = [
   *   {
   *     values: { active: true },
   *     conditions: [{ column: 'id', value: 1 }]
   *   },
   *   {
   *     values: { active: false },
   *     conditions: [{ column: 'id', value: 2 }]
   *   }
   * ];
   * 
   * const result = await dbHelper.batchUpdate('users', updates);
   * console.log(`Updated ${result.affectedRows} records`);
   * ```
   */
  public async batchUpdate(
    tableName: string,
    updates: Array<{ values: Record<string, ValueType>, conditions: Array<QueryCondition> }>
  ): Promise<DatabaseResult> {
    return this.executeWithLock(async () => {
      if (!updates || updates.length === 0) {
        return { success: true, affectedRows: 0 };
      }

      try {
        let affectedRows = 0;

        await this.dbManager.executeTransaction(async (db) => {
          for (const updateData of updates) {
            const setClause = Object.keys(updateData.values)
              .map(key => `${key} = ?`)
              .join(', ');

            const whereClauses = updateData.conditions.map(cond => {
              const operator = cond.operator || '=';
              if (operator === 'IN' || operator === 'NOT IN') {
                const placeholders = Array.isArray(cond.value)
                  ? cond.value.map(() => '?').join(', ')
                  : '?';
                return `${cond.column} ${operator} (${placeholders})`;
              }
              return `${cond.column} ${operator} ?`;
            }).join(' AND ');

            const sql = `UPDATE ${tableName} SET ${setClause} WHERE ${whereClauses}`;

            const bindArgs: ValueType[] = [];
            Object.values(updateData.values).forEach(val => bindArgs.push(val));
            updateData.conditions.forEach(cond => {
              if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
                for (let i = 0; i < cond.value.length; i++) {
                  bindArgs.push(cond.value[i] as ValueType);
                }
              } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
                bindArgs.push(cond.value as ValueType);
              }
            });

            await db.executeSql(sql, bindArgs);
            affectedRows++;
          }
        });

        // 清理表相关的缓存
        await this.clearTableCache(tableName);

        Logger.info(TAG, `Batch updated ${affectedRows} records in ${tableName}`);
        return {
          success: true,
          affectedRows
        };
      } catch (error) {
        Logger.error(TAG, `Failed to batch update ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
        return {
          success: false,
          message: error instanceof Error ? error.message : JSON.stringify(error)
        };
      }
    });
  }

  /**
   * 批量删除数据（事务保护）
   * 
   * 批量删除多条记录，使用事务保护确保操作的原子性。
   * 
   * @param {string} tableName - 表名
   * @param {Array<Array<QueryCondition>>} conditionsList - 删除条件列表，每个元素是一组删除条件
   * @returns {Promise<DatabaseResult>} 删除结果，包含成功状态和影响的行数
   * 
   * @example
   * ```typescript
   * const conditionsList = [
   *   [{ column: 'id', value: 1 }],
   *   [{ column: 'id', value: 2 }],
   *   [{ column: 'active', value: false }]
   * ];
   * 
   * const result = await dbHelper.batchDelete('users', conditionsList);
   * console.log(`Deleted ${result.affectedRows} records`);
   * ```
   */
  public async batchDelete(
    tableName: string,
    conditionsList: Array<Array<QueryCondition>>
  ): Promise<DatabaseResult> {
    return this.executeWithLock(async () => {
      if (!conditionsList || conditionsList.length === 0) {
        return { success: true, affectedRows: 0 };
      }

      try {
        let affectedRows = 0;

        await this.dbManager.executeTransaction(async (db) => {
          for (const conditions of conditionsList) {
            const whereClauses = conditions.map(cond => {
              const operator = cond.operator || '=';
              if (operator === 'IN' || operator === 'NOT IN') {
                const placeholders = Array.isArray(cond.value)
                  ? cond.value.map(() => '?').join(', ')
                  : '?';
                return `${cond.column} ${operator} (${placeholders})`;
              }
              return `${cond.column} ${operator} ?`;
            }).join(' AND ');

            const sql = `DELETE FROM ${tableName} WHERE ${whereClauses}`;

            const bindArgs: ValueType[] = [];
            conditions.forEach(cond => {
              if ((cond.operator === 'IN' || cond.operator === 'NOT IN') && Array.isArray(cond.value)) {
                for (let i = 0; i < cond.value.length; i++) {
                  bindArgs.push(cond.value[i] as ValueType);
                }
              } else if (cond.operator !== 'IN' && cond.operator !== 'NOT IN') {
                bindArgs.push(cond.value as ValueType);
              }
            });

            const result = await db.executeSql(sql, bindArgs);
            affectedRows += result.rowAffected;
          }
        });

        // 清理表相关的缓存
        await this.clearTableCache(tableName);

        Logger.info(TAG, `Batch deleted ${affectedRows} records from ${tableName}`);
      return {
        success: true,
        affectedRows
      };
    } catch (error) {
      Logger.error(TAG, `Failed to batch delete from ${tableName}: ${error instanceof Error ? error.message : String(error)}`);
      return {
        success: false,
        message: error instanceof Error ? error.message : JSON.stringify(error)
      };
    }
    });
  }

  /**
   * 执行事务（事务保护）
   * 
   * 执行一个包含多个数据库操作的事务，确保操作的原子性。
   * 
   * @template T - 泛型类型，用于指定操作的返回类型
   * @param {() => Promise<T>} operation - 要执行的操作函数
   * @returns {Promise<T>} 操作的返回结果
   * 
   * @example
   * ```typescript
   * const result = await dbHelper.executeTransaction(async () => {
   *   // 插入一条记录
   *   const insertResult = await dbHelper.insert('users', {
   *     name: 'John Doe',
   *     age: 30
   *   });
   * 
   *   // 更新另一条记录
   *   await dbHelper.update('users',
   *     { active: true },
   *     [{ column: 'id', value: insertResult.lastInsertRowId }]
   *   );
   * 
   *   return insertResult.lastInsertRowId;
   * });
   * 
   * console.log(`Transaction completed, new user ID: ${result}`);
   * ```
   */
  public async executeTransaction<T>(operation: () => Promise<T>): Promise<T> {
    try {
      return await this.dbManager.executeTransaction(operation);
    } catch (error) {
      Logger.error(TAG, `Transaction failed: ${error instanceof Error ? error.message : String(error)}`);
      throw error;
    }
  }
}
