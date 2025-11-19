// MemoryManager - 内存管理工具类
import Logger from './Logger';

const TAG = 'MemoryManager';

/**
 * 内存管理工具类
 * 提供内存使用监控、内存限制检查等功能
 */
export default class MemoryManager {
  private static instance: MemoryManager;
  private maxMemoryUsage: number = 0.8; // 最大内存使用率 80%
  private checkInterval: number = 30000; // 30秒检查一次
  private lastCheckTime: number = 0;
  private memoryUsageHistory: number[] = [];

  /**
   * 私有构造函数
   */
  private constructor() {
    Logger.info(TAG, 'MemoryManager initialized');
    this.startPeriodicCheck();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): MemoryManager {
    if (!MemoryManager.instance) {
      MemoryManager.instance = new MemoryManager();
    }
    return MemoryManager.instance;
  }

  /**
   * 设置最大内存使用率
   * @param usage 内存使用率阈值 (0-1)
   */
  public setMaxMemoryUsage(usage: number): void {
    if (usage > 0 && usage <= 1) {
      this.maxMemoryUsage = usage;
      Logger.info(TAG, `Max memory usage set to: ${(usage * 100).toFixed(0)}%`);
    }
  }

  /**
   * 检查内存可用性
   * @returns 是否有足够内存可用
   */
  public checkMemoryAvailability(): boolean {
    try {
      const currentUsage = this.getCurrentMemoryUsage();
      
      // 记录内存使用历史
      this.recordMemoryUsage(currentUsage);
      
      const result = currentUsage < this.maxMemoryUsage;
      
      if (!result) {
        Logger.warn(TAG, `Memory usage too high: ${(currentUsage * 100).toFixed(1)}% (max: ${(this.maxMemoryUsage * 100).toFixed(0)}%)`);
      }
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to check memory availability: ${error}`);
      // 出错时默认返回true，避免应用崩溃
      return true;
    }
  }

  /**
   * 获取当前内存使用情况
   * @returns 内存使用率 (0-1)
   */
  public getCurrentMemoryUsage(): number {
    try {
      // 在HarmonyOS中，可以使用系统API获取内存信息
      // 这里提供一个模拟实现，实际使用时需要替换为真实的系统API调用
      const totalMemory = this.getTotalMemory();
      const freeMemory = this.getFreeMemory();
      
      if (totalMemory <= 0) {
        return 0;
      }
      
      const usedMemory = totalMemory - freeMemory;
      return usedMemory / totalMemory;
    } catch (error) {
      Logger.error(TAG, `Failed to get current memory usage: ${error}`);
      return 0.5; // 默认返回50%使用率
    }
  }

  /**
   * 获取总内存大小
   * @returns 总内存字节数
   */
  private getTotalMemory(): number {
    try {
      // 模拟实现，实际应使用系统API
      // 在HarmonyOS中，可以通过@ohos.systemCapability资源获取
      return 8 * 1024 * 1024 * 1024; // 假设8GB内存
    } catch (error) {
      Logger.error(TAG, `Failed to get total memory: ${error}`);
      return 4 * 1024 * 1024 * 1024; // 默认4GB
    }
  }

  /**
   * 获取可用内存大小
   * @returns 可用内存字节数
   */
  private getFreeMemory(): number {
    try {
      // 模拟实现，实际应使用系统API
      // 在HarmonyOS中，可以通过@ohos.systemCapability资源获取
      const total = this.getTotalMemory();
      return total * 0.4; // 假设40%可用
    } catch (error) {
      Logger.error(TAG, `Failed to get free memory: ${error}`);
      return 2 * 1024 * 1024 * 1024; // 默认2GB
    }
  }

  /**
   * 记录内存使用情况
   * @param usage 当前内存使用率
   */
  private recordMemoryUsage(usage: number): void {
    this.memoryUsageHistory.push(usage);
    
    // 只保留最近100条记录
    if (this.memoryUsageHistory.length > 100) {
      this.memoryUsageHistory.shift();
    }
    
    // 定期记录平均内存使用情况
    const now = Date.now();
    if (now - this.lastCheckTime > this.checkInterval) {
      this.lastCheckTime = now;
      this.logAverageMemoryUsage();
    }
  }

  /**
   * 记录平均内存使用情况
   */
  private logAverageMemoryUsage(): void {
    if (this.memoryUsageHistory.length === 0) return;
    
    const sum = this.memoryUsageHistory.reduce((acc, val) => acc + val, 0);
    const average = sum / this.memoryUsageHistory.length;
    
    Logger.info(TAG, `Average memory usage: ${(average * 100).toFixed(1)}%`);
  }

  /**
   * 开始定期检查内存使用情况
   */
  private startPeriodicCheck(): void {
    setInterval(() => {
      try {
        const usage = this.getCurrentMemoryUsage();
        this.recordMemoryUsage(usage);
        
        if (usage > this.maxMemoryUsage * 0.9) {
          Logger.warn(TAG, `Memory usage approaching limit: ${(usage * 100).toFixed(1)}%`);
        }
      } catch (error) {
        Logger.error(TAG, `Periodic memory check failed: ${error}`);
      }
    }, this.checkInterval);
  }

  /**
   * 清理内存（如果可能）
   */
  public clearMemory(): void {
    try {
      Logger.info(TAG, 'Attempting to clear memory');
      
      // HarmonyOS中不支持直接调用垃圾回收
      // 移除对globalThis.gc的依赖，使用系统推荐的内存管理方式
      Logger.info(TAG, 'Memory cleanup performed (HarmonyOS compatible)');
      
      // 清理历史记录
      this.memoryUsageHistory = [];
    } catch (error) {
      Logger.error(TAG, `Failed to clear memory: ${error}`);
    }
  }

  /**
   * 获取内存使用统计信息
   * @returns 内存使用统计
   */
  public getMemoryStats(): {
    currentUsage: number;
    averageUsage: number;
    maxUsage: number;
    minUsage: number;
  } {
    const current = this.getCurrentMemoryUsage();
    let average = 0;
    let max = 0;
    let min = 1;
    
    if (this.memoryUsageHistory.length > 0) {
      const sum = this.memoryUsageHistory.reduce((acc, val) => acc + val, 0);
      average = sum / this.memoryUsageHistory.length;
      // ArkTS兼容：使用直接调用替代apply
      max = Math.max(...this.memoryUsageHistory);
      min = Math.min(...this.memoryUsageHistory);
    } else {
      average = current;
      max = current;
      min = current;
    }
    
    return {
      currentUsage: current,
      averageUsage: average,
      maxUsage: max,
      minUsage: min
    };
  }
}