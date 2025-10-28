import Logger from '../../common/util/Logger';
import { LineItem } from '../../service/config/LineManager';
import { DatabaseService } from '../../service/DatabaseService';

const TAG = 'LineDao';
const TABLE_NAME = 'line_items';

/**
 * 线路数据访问对象
 * 负责线路数据的持久化操作
 */
export class LineDao {
  private dbService?: DatabaseService;

  /**
   * 初始化数据表
   * @param context 应用上下文
   */
  public async initTable(context?: any): Promise<void> {
    try {
      Logger.info(TAG, 'Initializing line table');
      
      // 获取数据库服务实例
      if (!this.dbService) {
        this.dbService = new DatabaseService(context);
      }
      
      // 创建线路表
      await this.dbService.executeSql(`
        CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          url TEXT NOT NULL,
          description TEXT,
          type TEXT DEFAULT 'all',
          updateTime INTEGER,
          createTime INTEGER,
          sourceCount INTEGER DEFAULT 0,
          enabled INTEGER DEFAULT 1,
          current INTEGER DEFAULT 0,
          cacheTime INTEGER DEFAULT 24,
          responseTime INTEGER DEFAULT 0,
          UNIQUE(id)
        );
      `);
      
      // 创建索引（可选）
      await this.dbService.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_line_current ON ${TABLE_NAME}(current);
      `);
      
      Logger.info(TAG, 'Line table initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize line table: ${error}`);
      throw error;
    }
  }

  /**
   * 保存单个线路
   * @param line 线路对象
   */
  public async save(line: LineItem): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      // 使用REPLACE INTO确保更新已存在的线路
      await this.dbService.executeSql(
        `REPLACE INTO ${TABLE_NAME} 
         (id, name, url, description, type, updateTime, createTime, sourceCount, enabled, current, cacheTime, responseTime) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          line.id,
          line.name,
          line.url,
          line.description || '',
          line.type || 'all',
          line.updateTime,
          line.createTime,
          line.sourceCount,
          line.enabled ? 1 : 0,
          line.current ? 1 : 0,
          line.cacheTime || 24,
          line.responseTime || 0
        ]
      );

      Logger.debug(TAG, `Saved line: ${line.name} (${line.id})`);
    } catch (error) {
      Logger.error(TAG, `Failed to save line: ${error}`);
      throw error;
    }
  }

  /**
   * 批量保存线路
   * @param lines 线路数组
   */
  public async saveAll(lines: LineItem[]): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      // 开始事务以提高批量操作性能
      await this.dbService.beginTransaction();
      
      try {
        // 先清空现有数据
        await this.dbService.executeSql(`DELETE FROM ${TABLE_NAME}`);
        
        // 批量插入新数据
        for (const line of lines) {
          await this.dbService.executeSql(
            `INSERT INTO ${TABLE_NAME} 
             (id, name, url, description, type, updateTime, createTime, sourceCount, enabled, current, cacheTime, responseTime) 
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
            [
              line.id,
              line.name,
              line.url,
              line.description || '',
              line.type || 'all',
              line.updateTime,
              line.createTime,
              line.sourceCount,
              line.enabled ? 1 : 0,
              line.current ? 1 : 0,
              line.cacheTime || 24,
              line.responseTime || 0
            ]
          );
        }
        
        // 提交事务
        await this.dbService.commitTransaction();
        Logger.debug(TAG, `Saved ${lines.length} lines in batch`);
      } catch (error) {
        // 回滚事务
        await this.dbService.rollbackTransaction();
        Logger.error(TAG, `Failed to save lines in batch: ${error}`);
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save all lines: ${error}`);
      throw error;
    }
  }

  /**
   * 根据ID获取线路
   * @param id 线路ID
   */
  public async getById(id: string): Promise<LineItem | null> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT * FROM ${TABLE_NAME} WHERE id = ?`,
        [id]
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows.item(0);
      return this.rowToLineItem(row);
    } catch (error) {
      Logger.error(TAG, `Failed to get line by id: ${error}`);
      return null;
    }
  }

  /**
   * 获取所有线路
   */
  public async getAll(): Promise<LineItem[]> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT * FROM ${TABLE_NAME} ORDER BY current DESC, updateTime DESC`,
        []
      );

      const lines: LineItem[] = [];
      for (let i = 0; i < result.rows.length; i++) {
        const row = result.rows.item(i);
        lines.push(this.rowToLineItem(row));
      }

      return lines;
    } catch (error) {
      Logger.error(TAG, `Failed to get all lines: ${error}`);
      return [];
    }
  }

  /**
   * 获取当前使用的线路
   */
  public async getCurrent(): Promise<LineItem | null> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT * FROM ${TABLE_NAME} WHERE current = 1 LIMIT 1`,
        []
      );

      if (result.rows.length === 0) {
        return null;
      }

      const row = result.rows.item(0);
      return this.rowToLineItem(row);
    } catch (error) {
      Logger.error(TAG, `Failed to get current line: ${error}`);
      return null;
    }
  }

  /**
   * 获取启用的线路列表
   */
  public async getEnabled(): Promise<LineItem[]> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT * FROM ${TABLE_NAME} WHERE enabled = 1 ORDER BY current DESC, updateTime DESC`,
        []
      );

      const lines: LineItem[] = [];
      for (let i = 0; i < result.rows.length; i++) {
        const row = result.rows.item(i);
        lines.push(this.rowToLineItem(row));
      }

      return lines;
    } catch (error) {
      Logger.error(TAG, `Failed to get enabled lines: ${error}`);
      return [];
    }
  }

  /**
   * 更新线路状态
   * @param id 线路ID
   * @param enabled 是否启用
   */
  public async updateEnabled(id: string, enabled: boolean): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      await this.dbService.executeSql(
        `UPDATE ${TABLE_NAME} SET enabled = ? WHERE id = ?`,
        [enabled ? 1 : 0, id]
      );

      Logger.debug(TAG, `Updated line ${id} enabled status: ${enabled}`);
    } catch (error) {
      Logger.error(TAG, `Failed to update line enabled status: ${error}`);
      throw error;
    }
  }

  /**
   * 更新当前使用的线路
   * @param id 线路ID
   */
  public async updateCurrent(id: string): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      // 开始事务
      await this.dbService.beginTransaction();
      
      try {
        // 先将所有线路设置为非当前
        await this.dbService.executeSql(
          `UPDATE ${TABLE_NAME} SET current = 0`,
          []
        );
        
        // 设置指定线路为当前
        await this.dbService.executeSql(
          `UPDATE ${TABLE_NAME} SET current = 1 WHERE id = ?`,
          [id]
        );
        
        // 提交事务
        await this.dbService.commitTransaction();
        Logger.debug(TAG, `Updated current line to: ${id}`);
      } catch (error) {
        // 回滚事务
        await this.dbService.rollbackTransaction();
        Logger.error(TAG, `Failed to update current line: ${error}`);
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to update current line: ${error}`);
      throw error;
    }
  }

  /**
   * 更新线路缓存时间
   * @param id 线路ID
   * @param cacheTime 缓存时间（小时）
   */
  public async updateCacheTime(id: string, cacheTime: number): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      await this.dbService.executeSql(
        `UPDATE ${TABLE_NAME} SET cacheTime = ? WHERE id = ?`,
        [cacheTime, id]
      );

      Logger.debug(TAG, `Updated line ${id} cache time: ${cacheTime} hours`);
    } catch (error) {
      Logger.error(TAG, `Failed to update line cache time: ${error}`);
      throw error;
    }
  }

  /**
   * 更新线路响应时间
   * @param id 线路ID
   * @param responseTime 响应时间（毫秒）
   */
  public async updateResponseTime(id: string, responseTime: number): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      await this.dbService.executeSql(
        `UPDATE ${TABLE_NAME} SET responseTime = ? WHERE id = ?`,
        [responseTime, id]
      );

      Logger.debug(TAG, `Updated line ${id} response time: ${responseTime}ms`);
    } catch (error) {
      Logger.error(TAG, `Failed to update line response time: ${error}`);
      throw error;
    }
  }

  /**
   * 删除线路
   * @param id 线路ID
   */
  public async delete(id: string): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      await this.dbService.executeSql(
        `DELETE FROM ${TABLE_NAME} WHERE id = ?`,
        [id]
      );

      Logger.debug(TAG, `Deleted line: ${id}`);
    } catch (error) {
      Logger.error(TAG, `Failed to delete line: ${error}`);
      throw error;
    }
  }

  /**
   * 清空所有线路
   */
  public async clearAll(): Promise<void> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      await this.dbService.executeSql(
        `DELETE FROM ${TABLE_NAME}`,
        []
      );

      Logger.debug(TAG, 'Cleared all lines');
    } catch (error) {
      Logger.error(TAG, `Failed to clear all lines: ${error}`);
      throw error;
    }
  }

  /**
   * 获取线路数量
   */
  public async count(): Promise<number> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT COUNT(*) as count FROM ${TABLE_NAME}`,
        []
      );

      return result.rows.item(0).count || 0;
    } catch (error) {
      Logger.error(TAG, `Failed to count lines: ${error}`);
      return 0;
    }
  }

  /**
   * 获取启用的线路数量
   */
  public async countEnabled(): Promise<number> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT COUNT(*) as count FROM ${TABLE_NAME} WHERE enabled = 1`,
        []
      );

      return result.rows.item(0).count || 0;
    } catch (error) {
      Logger.error(TAG, `Failed to count enabled lines: ${error}`);
      return 0;
    }
  }

  /**
   * 检查表是否存在
   */
  public async isTableExists(): Promise<boolean> {
    try {
      if (!this.dbService) {
        throw new Error('Database service not initialized');
      }

      const result = await this.dbService.executeSql(
        `SELECT name FROM sqlite_master WHERE type='table' AND name='${TABLE_NAME}'`,
        []
      );

      return result.rows.length > 0;
    } catch (error) {
      Logger.error(TAG, `Failed to check table existence: ${error}`);
      return false;
    }
  }

  /**
   * 将数据库行转换为LineItem对象
   * @param row 数据库行
   */
  private rowToLineItem(row: any): LineItem {
    return {
      id: row.id,
      name: row.name,
      url: row.url,
      description: row.description,
      type: row.type as 'all' | 'vod' | 'live' | undefined,
      updateTime: row.updateTime,
      createTime: row.createTime,
      sourceCount: row.sourceCount,
      enabled: row.enabled === 1,
      current: row.current === 1,
      cacheTime: row.cacheTime,
      responseTime: row.responseTime
    };
  }
}
