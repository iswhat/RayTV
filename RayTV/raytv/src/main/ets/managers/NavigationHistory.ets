/**
 * 导航历史管理器
 * 管理页面导航历史记录
 */
export class NavigationHistory {
  private static instance: NavigationHistory;
  private history: NavigationRecord[] = [];
  private maxHistorySize: number = 50;

  private constructor() {}

  static getInstance(): NavigationHistory {
    if (!NavigationHistory.instance) {
      NavigationHistory.instance = new NavigationHistory();
    }
    return NavigationHistory.instance;
  }

  /**
   * 推入新的导航记录
   */
  push(record: Omit<NavigationRecord, 'id'>): void {
    const newRecord: NavigationRecord = {
      id: this.generateId(),
      ...record
    };

    this.history.push(newRecord);

    // 限制历史记录大小
    if (this.history.length > this.maxHistorySize) {
      this.history.shift();
    }

    console.log(`Navigation pushed: ${record.path}`);
  }

  /**
   * 弹出最后的导航记录
   */
  pop(): NavigationRecord | null {
    if (this.history.length === 0) return null;
    
    const record = this.history.pop();
    console.log(`Navigation popped: ${record?.path}`);
    return record || null;
  }

  /**
   * 获取历史记录
   */
  getHistory(): NavigationRecord[] {
    return [...this.history];
  }

  /**
   * 获取历史记录长度
   */
  getLength(): number {
    return this.history.length;
  }

  /**
   * 清空历史记录
   */
  clear(): void {
    this.history = [];
    console.log('Navigation history cleared');
  }

  /**
   * 获取上一个页面路径
   */
  getPreviousPath(): string | null {
    if (this.history.length < 2) return null;
    
    const previousRecord = this.history[this.history.length - 2];
    return previousRecord.path;
  }

  /**
   * 检查是否可以返回
   */
  canGoBack(): boolean {
    return this.history.length > 1;
  }

  /**
   * 获取特定路径的历史记录
   */
  getRecordsByPath(path: string): NavigationRecord[] {
    return this.history.filter(record => record.path === path);
  }

  /**
   * 移除特定路径的所有记录
   */
  removePathRecords(path: string): number {
    const initialLength = this.history.length;
    this.history = this.history.filter(record => record.path !== path);
    const removedCount = initialLength - this.history.length;
    
    if (removedCount > 0) {
      console.log(`Removed ${removedCount} records for path: ${path}`);
    }
    
    return removedCount;
  }

  /**
   * 获取最近的导航记录
   */
  getRecent(count: number = 5): NavigationRecord[] {
    return this.history.slice(-count).reverse();
  }

  /**
   * 查找特定条件的记录
   */
  find(predicate: (record: NavigationRecord) => boolean): NavigationRecord | null {
    for (let i = this.history.length - 1; i >= 0; i--) {
      if (predicate(this.history[i])) {
        return this.history[i];
      }
    }
    return null;
  }

  /**
   * 替换当前记录
   */
  replaceCurrent(record: Omit<NavigationRecord, 'id'>): boolean {
    if (this.history.length === 0) return false;
    
    const lastIndex = this.history.length - 1;
    this.history[lastIndex] = {
      id: this.history[lastIndex].id,
      ...record
    };
    
    console.log(`Navigation record replaced: ${record.path}`);
    return true;
  }

  private generateId(): string {
    return `nav_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

/**
 * 导航记录接口
 */
interface NavigationRecord {
  /** 唯一标识符 */
  id: string;
  
  /** 页面路径 */
  path: string;
  
  /** 时间戳 */
  timestamp: number;
  
  /** 页面参数 */
  params?: any;
  
  /** 页面标题 */
  title?: string;
  
  /** 页面状态 */
  state?: any;
}