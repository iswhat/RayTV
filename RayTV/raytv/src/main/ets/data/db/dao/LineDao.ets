import Logger from '../../../common/util/Logger';
import { DatabaseManager } from '../DatabaseManager';
import { SQLiteHelper } from '../SQLiteHelper';
import { LINE_TABLE } from '../TableSchema';
import Context from '@ohos.ability.featureAbility';

const TAG = 'LineDao';

/**
 * 线路项接口定义
 */
export interface LineItem {
  id: string;              // 唯一标识
  name: string;            // 线路名称
  url: string;             // 线路URL
  description?: string;    // 线路描述
  type?: 'all' | 'vod' | 'live'; // 线路类型
  updateTime: number;      // 最后更新时间
  createTime: number;      // 创建时间
  sourceCount: number;     // 包含片源数量
  enabled: boolean;        // 是否启用
  current: boolean;        // 是否为当前使用的线路
  cacheTime?: number;      // 缓存时间（小时）
  responseTime?: number;   // 响应时间（毫秒）
}

/**
 * 线路数据访问对象
 */
export class LineDao {
  private sqliteHelper: SQLiteHelper;
  private initialized: boolean = false;

  constructor() {
    this.sqliteHelper = SQLiteHelper.getInstance();
    Logger.info(TAG, 'LineDao initialized');
  }

  /**
   * 初始化表结构
   * @param context 应用上下文
   */
  public async initTable(context?: Context): Promise<void> {
    if (this.initialized) {
      return;
    }

    try {
      Logger.info(TAG, 'Initializing line table...');
      
      // 获取数据库管理器实例
      const dbManager = DatabaseManager.getInstance();
      
      // 初始化数据库
      await dbManager.initialize(context);
      
      this.initialized = true;
      Logger.info(TAG, 'Line table initialized successfully');
    } catch (error) {
      Logger.error(TAG, `Failed to initialize line table: ${error}`);
      throw error;
    }
  }

  /**
   * 保存线路项
   * @param line 线路项
   */
  public async save(line: LineItem): Promise<boolean> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const values = {
        id: line.id,
        name: line.name,
        url: line.url,
        description: line.description || '',
        type: line.type || 'all',
        updateTime: line.updateTime,
        createTime: line.createTime,
        sourceCount: line.sourceCount,
        enabled: line.enabled ? 1 : 0,
        current: line.current ? 1 : 0,
        cacheTime: line.cacheTime || 24,
        responseTime: line.responseTime || 0
      };

      const result = await this.sqliteHelper.insert(LINE_TABLE.NAME, values);
      Logger.info(TAG, `Line saved: ${line.name}`);
      return result > 0;
    } catch (error) {
      Logger.error(TAG, `Failed to save line: ${error}`);
      return false;
    }
  }

  /**
   * 更新线路项
   * @param line 线路项
   */
  public async update(line: LineItem): Promise<boolean> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const values = {
        name: line.name,
        url: line.url,
        description: line.description || '',
        type: line.type || 'all',
        updateTime: line.updateTime,
        sourceCount: line.sourceCount,
        enabled: line.enabled ? 1 : 0,
        current: line.current ? 1 : 0,
        cacheTime: line.cacheTime || 24,
        responseTime: line.responseTime || 0
      };

      const whereClause = 'id = ?';
      const whereArgs = [line.id];

      const result = await this.sqliteHelper.update(LINE_TABLE.NAME, values, whereClause, whereArgs);
      Logger.info(TAG, `Line updated: ${line.name}`);
      return result > 0;
    } catch (error) {
      Logger.error(TAG, `Failed to update line: ${error}`);
      return false;
    }
  }

  /**
   * 删除线路项
   * @param id 线路ID
   */
  public async delete(id: string): Promise<boolean> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const whereClause = 'id = ?';
      const whereArgs = [id];

      const result = await this.sqliteHelper.delete(LINE_TABLE.NAME, whereClause, whereArgs);
      Logger.info(TAG, `Line deleted: ${id}`);
      return result > 0;
    } catch (error) {
      Logger.error(TAG, `Failed to delete line: ${error}`);
      return false;
    }
  }

  /**
   * 根据ID获取线路项
   * @param id 线路ID
   */
  public async getById(id: string): Promise<LineItem | null> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const whereClause = 'id = ?';
      const whereArgs = [id];

      const result = await this.sqliteHelper.query(LINE_TABLE.NAME, null, whereClause, whereArgs);
      
      if (result && result.length > 0) {
        return this.mapRowToLineItem(result[0]);
      }
      
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get line by id: ${error}`);
      return null;
    }
  }

  /**
   * 获取所有线路项
   */
  public async getAll(): Promise<LineItem[]> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const result = await this.sqliteHelper.query(LINE_TABLE.NAME);
      
      if (result && result.length > 0) {
        return result.map(row => this.mapRowToLineItem(row));
      }
      
      return [];
    } catch (error) {
      Logger.error(TAG, `Failed to get all lines: ${error}`);
      return [];
    }
  }

  /**
   * 获取启用的线路项
   */
  public async getEnabled(): Promise<LineItem[]> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const whereClause = 'enabled = 1';
      const result = await this.sqliteHelper.query(LINE_TABLE.NAME, null, whereClause);
      
      if (result && result.length > 0) {
        return result.map(row => this.mapRowToLineItem(row));
      }
      
      return [];
    } catch (error) {
      Logger.error(TAG, `Failed to get enabled lines: ${error}`);
      return [];
    }
  }

  /**
   * 获取当前使用的线路项
   */
  public async getCurrent(): Promise<LineItem | null> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const whereClause = 'current = 1';
      const result = await this.sqliteHelper.query(LINE_TABLE.NAME, null, whereClause);
      
      if (result && result.length > 0) {
        return this.mapRowToLineItem(result[0]);
      }
      
      return null;
    } catch (error) {
      Logger.error(TAG, `Failed to get current line: ${error}`);
      return null;
    }
  }

  /**
   * 设置当前线路
   * @param id 线路ID
   */
  public async setCurrent(id: string): Promise<boolean> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      // 开始事务
      await this.sqliteHelper.beginTransaction();
      
      try {
        // 重置所有线路的current标志
        const resetValues = { current: 0 };
        await this.sqliteHelper.update(LINE_TABLE.NAME, resetValues);
        
        // 设置指定线路为当前线路
        const setValues = { current: 1 };
        const whereClause = 'id = ?';
        const whereArgs = [id];
        
        const result = await this.sqliteHelper.update(LINE_TABLE.NAME, setValues, whereClause, whereArgs);
        
        // 提交事务
        await this.sqliteHelper.commitTransaction();
        
        Logger.info(TAG, `Current line set to: ${id}`);
        return result > 0;
      } catch (error) {
        // 回滚事务
        await this.sqliteHelper.rollbackTransaction();
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to set current line: ${error}`);
      return false;
    }
  }

  /**
   * 批量保存线路项
   * @param lines 线路项数组
   */
  public async saveAll(lines: LineItem[]): Promise<boolean> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      // 开始事务
      await this.sqliteHelper.beginTransaction();
      
      try {
        for (const line of lines) {
          await this.save(line);
        }
        
        // 提交事务
        await this.sqliteHelper.commitTransaction();
        
        Logger.info(TAG, `Saved ${lines.length} lines`);
        return true;
      } catch (error) {
        // 回滚事务
        await this.sqliteHelper.rollbackTransaction();
        throw error;
      }
    } catch (error) {
      Logger.error(TAG, `Failed to save all lines: ${error}`);
      return false;
    }
  }

  /**
   * 清空所有线路数据
   */
  public async clearAll(): Promise<boolean> {
    try {
      if (!this.initialized) {
        throw new Error('LineDao not initialized');
      }

      const result = await this.sqliteHelper.delete(LINE_TABLE.NAME);
      Logger.info(TAG, 'All lines cleared');
      return result > 0;
    } catch (error) {
      Logger.error(TAG, `Failed to clear all lines: ${error}`);
      return false;
    }
  }

  /**
   * 将数据库行映射为LineItem对象
   * @param row 数据库行
   */
  private mapRowToLineItem(row: Record<string, unknown>): LineItem {
    return {
      id: row.id,
      name: row.name,
      url: row.url,
      description: row.description,
      type: row.type as 'all' | 'vod' | 'live',
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

// 导出默认实例
export const lineDao = new LineDao();