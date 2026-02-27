/**
 * 性能监控工具 | Performance Monitor Utility
 * 用于监控应用性能指标和资源使用情况 | Used to monitor application performance metrics and resource usage
 */
import Logger from '../util/Logger';

// 性能指标接口 | Performance metrics interface
export interface PerformanceMetric {
  id: string;
  operation: string;
  startTime: number;
  endTime: number;
  duration: number;
  memoryUsage: number;
  cpuUsage?: number;
  success: boolean;
  metadata?: Record<string, any>;
}

// 内存信息接口 | Memory information interface
export interface MemoryInfo {
  used: number;
  total: number;
  free: number;
  percentage: number;
}

// CPU信息接口 | CPU information interface
export interface CpuInfo {
  usage: number;
  cores: number;
  frequency?: number;
}

/**
 * 性能监控类 | Performance monitor class
 */
export class PerformanceMonitor {
  private static instance: PerformanceMonitor | null = null;
  private metrics: Map<string, PerformanceMetric[]> = new Map();
  private logger: Logger;
  private maxMetricsPerOperation: number = 1000;
  private slowOperationThreshold: number = 1000; // 1秒阈值 | 1 second threshold

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): PerformanceMonitor {
    if (!PerformanceMonitor.instance) {
      PerformanceMonitor.instance = new PerformanceMonitor();
    }
    return PerformanceMonitor.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.logger = new Logger('PerformanceMonitor');
  }

  /**
   * 开始性能测量 | Start performance measurement
   * @param operation 操作名称 | Operation name
   * @param metadata 元数据 | Metadata
   * @returns 测量ID | Measurement ID
   */
  public startMeasurement(operation: string, metadata?: Record<string, any>): string {
    const id = this.generateId();
    const metric: PerformanceMetric = {
      id,
      operation,
      startTime: performance.now(),
      endTime: 0,
      duration: 0,
      memoryUsage: this.getCurrentMemoryUsage(),
      success: false,
      metadata
    };

    // 初始化操作的指标数组 | Initialize metrics array for operation
    if (!this.metrics.has(operation)) {
      this.metrics.set(operation, []);
    }

    const operationMetrics = this.metrics.get(operation)!;
    operationMetrics.push(metric);

    // 限制指标数量 | Limit number of metrics
    if (operationMetrics.length > this.maxMetricsPerOperation) {
      operationMetrics.shift();
    }

    this.logger.debug(`Started measurement: ${operation} (${id})`);
    return id;
  }

  /**
   * 结束性能测量 | End performance measurement
   * @param id 测量ID | Measurement ID
   * @param success 是否成功 | Whether successful
   * @returns 性能指标 | Performance metric
   */
  public endMeasurement(id: string, success: boolean = true): PerformanceMetric | null {
    for (const [operation, metrics] of this.metrics) {
      const metric = metrics.find(m => m.id === id);
      if (metric) {
        metric.endTime = performance.now();
        metric.duration = metric.endTime - metric.startTime;
        metric.memoryUsage = this.getCurrentMemoryUsage() - metric.memoryUsage;
        metric.success = success;

        // 记录慢操作警告 | Log slow operation warning
        if (metric.duration > this.slowOperationThreshold) {
          this.logger.warn(`Slow operation detected: ${operation} took ${metric.duration.toFixed(2)}ms`);
        }

        this.logger.debug(`Ended measurement: ${operation} (${id}) - Duration: ${metric.duration.toFixed(2)}ms`);
        return metric;
      }
    }
    return null;
  }

  /**
   * 获取操作的性能统计 | Get performance statistics for operation
   * @param operation 操作名称 | Operation name
   * @returns 统计信息 | Statistics
   */
  public getOperationStats(operation: string): {
    count: number;
    avgDuration: number;
    minDuration: number;
    maxDuration: number;
    successRate: number;
    avgMemoryUsage: number;
  } | null {
    const metrics = this.metrics.get(operation);
    if (!metrics || metrics.length === 0) {
      return null;
    }

    const successfulMetrics = metrics.filter(m => m.success);
    const durations = metrics.map(m => m.duration);
    const memoryUsages = metrics.map(m => Math.abs(m.memoryUsage));

    return {
      count: metrics.length,
      avgDuration: durations.reduce((a, b) => a + b, 0) / durations.length,
      minDuration: Math.min(...durations),
      maxDuration: Math.max(...durations),
      successRate: successfulMetrics.length / metrics.length,
      avgMemoryUsage: memoryUsages.reduce((a, b) => a + b, 0) / memoryUsages.length
    };
  }

  /**
   * 获取所有操作的统计信息 | Get statistics for all operations
   * @returns 所有操作的统计信息 | Statistics for all operations
   */
  public getAllStats(): Record<string, any> {
    const stats: Record<string, any> = {};
    
    for (const operation of this.metrics.keys()) {
      stats[operation] = this.getOperationStats(operation);
    }
    
    return stats;
  }

  /**
   * 获取内存信息 | Get memory information
   * @returns 内存信息 | Memory information
   */
  public getMemoryInfo(): MemoryInfo {
    try {
      // 注意：HarmonyOS中可能需要特定的API来获取内存信息 | Note: HarmonyOS may require specific APIs to get memory info
      const memoryUsage = this.getCurrentMemoryUsage();
      return {
        used: memoryUsage,
        total: 0, // 需要系统API获取 | Need system API to get
        free: 0,  // 需要系统API获取 | Need system API to get
        percentage: 0 // 需要总内存信息计算 | Need total memory info to calculate
      };
    } catch (error) {
      this.logger.error('Failed to get memory info', error);
      return {
        used: 0,
        total: 0,
        free: 0,
        percentage: 0
      };
    }
  }

  /**
   * 获取CPU信息 | Get CPU information
   * @returns CPU信息 | CPU information
   */
  public getCpuInfo(): CpuInfo {
    try {
      // 注意：HarmonyOS中可能需要特定的API来获取CPU信息 | Note: HarmonyOS may require specific APIs to get CPU info
      return {
        usage: 0, // 需要系统API获取 | Need system API to get
        cores: navigator.hardwareConcurrency || 1,
        frequency: 0 // 需要系统API获取 | Need system API to get
      };
    } catch (error) {
      this.logger.error('Failed to get CPU info', error);
      return {
        usage: 0,
        cores: 1,
        frequency: 0
      };
    }
  }

  /**
   * 清理旧的性能数据 | Clean up old performance data
   * @param maxAge 最大数据年龄(毫秒) | Maximum data age (milliseconds)
   */
  public cleanup(maxAge: number = 3600000): void { // 默认1小时 | Default 1 hour
    const cutoffTime = Date.now() - maxAge;
    let cleanedCount = 0;

    for (const [operation, metrics] of this.metrics) {
      const oldMetrics = metrics.filter(metric => 
        metric.startTime < cutoffTime || metric.endTime < cutoffTime
      );
      
      if (oldMetrics.length > 0) {
        const newMetrics = metrics.filter(metric => 
          metric.startTime >= cutoffTime && metric.endTime >= cutoffTime
        );
        this.metrics.set(operation, newMetrics);
        cleanedCount += oldMetrics.length;
      }
    }

    if (cleanedCount > 0) {
      this.logger.info(`Cleaned up ${cleanedCount} old performance metrics`);
    }
  }

  /**
   * 重置所有性能数据 | Reset all performance data
   */
  public reset(): void {
    this.metrics.clear();
    this.logger.info('Performance metrics reset');
  }

  /**
   * 导出性能数据 | Export performance data
   * @returns 性能数据 | Performance data
   */
  public exportData(): string {
    const data = {
      timestamp: Date.now(),
      metrics: Object.fromEntries(this.metrics),
      memoryInfo: this.getMemoryInfo(),
      cpuInfo: this.getCpuInfo()
    };
    
    return JSON.stringify(data, null, 2);
  }

  /**
   * 获取当前内存使用量 | Get current memory usage
   * @returns 内存使用量(字节) | Memory usage (bytes)
   */
  private getCurrentMemoryUsage(): number {
    // 简化的内存使用量获取 | Simplified memory usage retrieval
    // 实际实现可能需要HarmonyOS特定的API | Actual implementation may need HarmonyOS specific APIs
    if ('memory' in performance) {
      // @ts-ignore
      return (performance as any).memory.usedJSHeapSize || 0;
    }
    return 0;
  }

  /**
   * 生成唯一ID | Generate unique ID
   * @returns 唯一ID | Unique ID
   */
  private generateId(): string {
    return `perf_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }
}

// 便捷的装饰器 | Convenient decorators

/**
 * 性能监控装饰器 | Performance monitoring decorator
 * @param operation 操作名称 | Operation name
 */
export function MonitorPerformance(operation: string) {
  return function (target: any, propertyKey: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = function (...args: any[]) {
      const monitor = PerformanceMonitor.getInstance();
      const measurementId = monitor.startMeasurement(operation, {
        className: target.constructor.name,
        methodName: propertyKey,
        args: args.slice(0, 3) // 只记录前3个参数避免数据过大 | Only record first 3 args to avoid large data
      });

      try {
        const result = originalMethod.apply(this, args);
        
        if (result instanceof Promise) {
          return result.then(resolvedResult => {
            monitor.endMeasurement(measurementId, true);
            return resolvedResult;
          }).catch(error => {
            monitor.endMeasurement(measurementId, false);
            throw error;
          });
        } else {
          monitor.endMeasurement(measurementId, true);
          return result;
        }
      } catch (error) {
        monitor.endMeasurement(measurementId, false);
        throw error;
      }
    };
    
    return descriptor;
  };
}

// 导出单例实例 | Export singleton instance
export default PerformanceMonitor.getInstance();