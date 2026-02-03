/**
 * SQLValidator - SQL安全验证工具
 * 防止SQL注入攻击
 */

export class SQLValidator {
  // 表名白名单
  private static readonly VALID_TABLE_NAMES: Set<string> = new Set([
    'videos',
    'channels',
    'favorites',
    'history',
    'categories',
    'playback_history',
    'settings',
    'cache'
  ]);

  // 列名白名单
  private static readonly VALID_COLUMN_NAMES: Set<string> = new Set([
    'id',
    'title',
    'url',
    'thumbnail',
    'description',
    'created_at',
    'updated_at',
    'site_key',
    'type',
    'episode',
    'duration',
    'played',
    'progress',
    'rating',
    'year',
    'region',
    'director',
    'actor',
    'category_id',
    'source_id',
    'last_played_at',
    'play_count',
    'is_favorite',
    'is_deleted',
    'config_key',
    'config_value',
    'cache_key',
    'cache_data',
    'expiry',
    'priority',
    'tags',
    'size',
    'storage_path'
  ]);

  /**
   * 验证表名
   * @param tableName 表名
   * @throws {Error} 如果表名无效
   */
  public static validateTableName(tableName: string): void {
    if (!tableName || typeof tableName !== 'string') {
      throw new Error(`Invalid table name: ${tableName}`);
    }

    const trimmedName = tableName.trim().toLowerCase();
    if (!this.VALID_TABLE_NAMES.has(trimmedName)) {
      throw new Error(`Table name not in whitelist: ${tableName}`);
    }

    // 检查SQL注入模式
    const injectionPatterns = [
      /['";]/,          // 引号或分号
      /\s+(or|and|union|select|insert|update|delete|drop|exec)/i, // SQL关键字
      /--/,             // SQL注释
      /\/\*/,           // 多行注释开始
      /\*\//            // 多行注释结束
    ];

    for (const pattern of injectionPatterns) {
      if (pattern.test(tableName)) {
        throw new Error(`Potential SQL injection in table name: ${tableName}`);
      }
    }
  }

  /**
   * 验证列名
   * @param columnName 列名
   * @throws {Error} 如果列名无效
   */
  public static validateColumnName(columnName: string): void {
    if (!columnName || typeof columnName !== 'string') {
      throw new Error(`Invalid column name: ${columnName}`);
    }

    const trimmedName = columnName.trim().toLowerCase();
    if (!this.VALID_COLUMN_NAMES.has(trimmedName)) {
      throw new Error(`Column name not in whitelist: ${columnName}`);
    }

    // 检查SQL注入模式
    const injectionPatterns = [
      /['";]/,
      /\s+(or|and|union|select|insert|update|delete|drop|exec)/i,
      /--/,
      /\/\*/,
      /\*\//
    ];

    for (const pattern of injectionPatterns) {
      if (pattern.test(columnName)) {
        throw new Error(`Potential SQL injection in column name: ${columnName}`);
      }
    }
  }

  /**
   * 验证多个列名
   * @param columnNames 列名数组
   * @throws {Error} 如果任一列名无效
   */
  public static validateColumnNames(columnNames: string[]): void {
    if (!Array.isArray(columnNames)) {
      throw new Error('Column names must be an array');
    }

    for (const columnName of columnNames) {
      this.validateColumnName(columnName);
    }
  }

  /**
   * 验证排序方向
   * @param order 排序方向
   * @throws {Error} 如果排序方向无效
   */
  public static validateOrder(order: string): void {
    const validOrders = ['ASC', 'DESC'];
    const upperOrder = order.toUpperCase();

    if (!validOrders.includes(upperOrder)) {
      throw new Error(`Invalid order direction: ${order}. Must be ASC or DESC`);
    }
  }

  /**
   * 验证WHERE条件（只检查基本安全性，不做完整SQL解析）
   * @param whereClause WHERE子句
   * @throws {Error} 如果WHERE子句包含可疑内容
   */
  public static validateWhereClause(whereClause: string): void {
    if (!whereClause || typeof whereClause !== 'string') {
      return;
    }

    const dangerousPatterns = [
      /;\s*drop/i,
      /;\s*delete/i,
      /;\s*truncate/i,
      /;\s*alter/i,
      /;\s*exec/i,
      /xp_cmdshell/i,
      /sp_executesql/i
    ];

    for (const pattern of dangerousPatterns) {
      if (pattern.test(whereClause)) {
        throw new Error(`Potential SQL injection in WHERE clause: ${whereClause}`);
      }
    }
  }

  /**
   * 转义SQL字符串值
   * 注意：在ArkTS中使用参数化查询，此方法仅用于特殊情况
   * @param value 需要转义的值
   * @returns 转义后的值
   */
  public static escapeSQLValue(value: string): string {
    if (!value || typeof value !== 'string') {
      return '';
    }

    return value
      .replace(/'/g, "''")  // 转义单引号
      .replace(/"/g, '""')  // 转义双引号
      .replace(/\\/g, '\\\\') // 转义反斜杠
      .replace(/\n/g, '\\n')  // 转义换行符
      .replace(/\r/g, '\\r')  // 转义回车符
      .replace(/\t/g, '\\t'); // 转义制表符
  }
}

export default SQLValidator;
