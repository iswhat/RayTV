// TaskPoolManager - 任务池管理器
import Logger from '../../common/util/Logger';
import taskPool from '@ohos.taskpool';
import MemoryManager from '../../common/util/MemoryManager';

const TAG = 'TaskPoolManager';

/**
 * 任务优先级枚�? */
export enum TaskPriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  CRITICAL = 3
}

/**
 * 任务状态枚�? */
export enum TaskStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

/**
 * 任务接口定义
 */
export interface Task<T = unknown> {
  id: string;
  priority: TaskPriority;
  execute: () => Promise<T>;
  onComplete?: (result: T) => void;
  onError?: (error: Error) => void;
  onCancel?: () => void;
  timeout?: number;
}

/**
 * 任务池管理器
 * 提供基于TaskPool的任务调度和管理功能
 */
export class TaskPoolManager {
  static instance: TaskPoolManager;
  taskQueue: Task[] = [];
  runningTasks: Map<string, Task> = new Map();
  maxConcurrentTasks: number = 3;
  isProcessing: boolean = false;
  memoryManager: MemoryManager;

  /**
   * 构造函�?   */
  constructor() {
    Logger.info(TAG, 'TaskPoolManager initialized');
    this.memoryManager = MemoryManager.getInstance();
  }

  /**
   * 获取单例实例
   */
  static getInstance(): TaskPoolManager {
    if (!TaskPoolManager.instance) {
      TaskPoolManager.instance = new TaskPoolManager();
    }
    return TaskPoolManager.instance;
  }

  /**
   * 设置最大并发任务数
   * @param max 最大并发任务数
   */
  setMaxConcurrentTasks(max: number): void {
    if (max > 0) {
      this.maxConcurrentTasks = max;
      Logger.info(TAG, `Max concurrent tasks set to: ${max}`);
      // 重新处理队列
      this.processQueue();
    }
  }

  /**
   * 提交任务到队�?   * @param task 任务对象
   */
  submit<T = any>(task: Task<T>): void {
    if (!task || !task.execute) {
      Logger.error(TAG, 'Invalid task submitted');
      return;
    }

    // 添加到任务队�?    this.taskQueue.push(task);
    Logger.debug(TAG, `Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}` instanceof Error ? `Task ${task.id} submitted with priority: ${task.priority}` : new Error(String(`Task ${task.id} submitted with priority: ${task.priority}`)))))));

    // 按优先级排序
    this.sortTasks();

    // 开始处理队�?    this.processQueue();
  }
  
  /**
   * 将自定义优先级转换为TaskPool优先�?   * @param priority 自定义优先级
   * @returns taskPool.Priority 对应的TaskPool优先�?   */
  getTaskPoolPriority(priority: TaskPriority): taskPool.Priority {
    switch (priority) {
      case TaskPriority.HIGH:
      case TaskPriority.CRITICAL:
        return taskPool.Priority.HIGH;
      case TaskPriority.NORMAL:
        return taskPool.Priority.MEDIUM;
      case TaskPriority.LOW:
        return taskPool.Priority.LOW;
      default:
        return taskPool.Priority.MEDIUM;
    }
  }

  /**
   * 执行单个任务
   * @param task 要执行的任务
   */
  async execute<T = any>(task: Task<T>): Promise<T> {
    if (!task || !task.execute) {
      throw new Error('Invalid task');
    }

    const taskId = task.id || `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    task.id = taskId;

    return new Promise((resolve, reject) => {
      const timeoutId = task.timeout ? setTimeout(() => {
        const error = new Error(`Task ${taskId} timed out after ${task.timeout}ms`);
        this.handleTaskError(task, error);
        reject(error);
      }, task.timeout) : null;

      this.submit({
        ...task,
        id: taskId,
        onComplete: (result: T) => {
          if (timeoutId) clearTimeout(timeoutId);
          task.onComplete?.(result);
          resolve(result);
        },
        onError: (error: Error) => {
          if (timeoutId) clearTimeout(timeoutId);
          task.onError?.(error);
          reject(error);
        }
      });
    });
  }

  /**
   * 取消任务
   * @param taskId 任务ID
   * @returns 是否成功取消
   */
  cancelTask(taskId: string): boolean {
    // 检查运行中的任�?    const runningTask = this.runningTasks.get(taskId);
    if (runningTask) {
      // 标记为取消状�?      this.runningTasks.delete(taskId);
      try {
        runningTask.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task ${taskId} onCancel callback: ${(error as Error).message}`);
      }
      Logger.info(TAG, `Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled` instanceof Error ? `Running task ${taskId} cancelled` : new Error(String(`Running task ${taskId} cancelled`)))))));
      return true;
    }

    // 检查队列中的任�?    const index = this.taskQueue.findIndex(task => task.id === taskId);
    if (index !== -1) {
      const task = this.taskQueue[index];
      this.taskQueue.splice(index, 1);
      try {
        task.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task ${taskId} onCancel callback: ${(error as Error).message}`);
      }
      Logger.info(TAG, `Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled` instanceof Error ? `Queued task ${taskId} cancelled` : new Error(String(`Queued task ${taskId} cancelled`)))))));
      return true;
    }

    Logger.warn(TAG, `Task ${taskId} not found`);
    return false;
  }

  /**
   * 清空任务队列
   */
  public clearQueue(): void {
    for (const task of this.taskQueue) {
      try {
        task.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task onCancel callback: ${(error as Error).message}`);
      }
    }
    this.taskQueue = [];
    Logger.info(TAG, 'Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared' : new Error(String('Task queue cleared' instanceof Error ? 'Task queue cleared' : new Error(String('Task queue cleared')))))));
  }

  /**
   * 获取任务状�?   * @param taskId 任务ID
   * @returns 任务状态，如果任务不存在返回null
   */
  public getTaskStatus(taskId: string): TaskStatus | null {
    if (this.runningTasks.has(taskId)) {
      return TaskStatus.RUNNING;
    }
    const task = this.taskQueue.find(t => t.id === taskId);
    if (task) {
      return TaskStatus.PENDING;
    }
    return null;
  }

  /**
   * 获取当前运行中的任务数量
   */
  public getRunningTaskCount(): number {
    return this.runningTasks.size;
  }

  /**
   * 获取当前队列中的任务数量
   */
  public getQueuedTaskCount(): number {
    return this.taskQueue.length;
  }

  /**
   * 按优先级排序任务队列
   */
  private sortTasks(): void {
    this.taskQueue.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 处理任务队列
   */
  private processQueue(): void {
    if (this.isProcessing) return;
    
    this.isProcessing = true;
    
    try {
      // 动态调整并发任务数基于内存使用情况
      const memoryStats = this.memoryManager.getMemoryStats();
      const adjustedMaxConcurrentTasks = this.calculateOptimalConcurrentTasks(memoryStats.currentUsage);
      
      // 执行尽可能多的并发任�?      while (
        this.runningTasks.size < adjustedMaxConcurrentTasks &&
        this.taskQueue.length > 0
      ) {
        // 在每次执行任务前重新检查内存可用�?        if (!this.memoryManager.checkMemoryAvailability()) {
          Logger.warn(TAG, `Insufficient memory to process tasks (${(memoryStats.currentUsage * 100).toFixed(1)}%), pausing queue`);
          // 尝试清理内存
          this.memoryManager.clearMemory();
          // 延迟重试，根据内存使用情况动态调整延迟时�?          const retryDelay = this.calculateRetryDelay(memoryStats.currentUsage);
          setTimeout(() => this.processQueue(), retryDelay);
          return;
        }
        
        const task = this.taskQueue.shift();
        if (task) {
          this.executeTask(task);
        }
      }
      
      // 如果队列不为空但没有执行任务，可能是因为内存不足
      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        Logger.info(TAG, `Task queue has ${this.taskQueue.length} tasks, but running at capacity (${this.runningTasks.size}/${adjustedMaxConcurrentTasks})`);
      }
    } finally {
      this.isProcessing = false;
      
      // 如果还有任务在队列中且没有达到最大并发数，继续处�?      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        setTimeout(() => this.processQueue(), 0);
      }
    }
  }
  
  /**
   * 根据内存使用情况计算最佳并发任务数
   * @param memoryUsage 当前内存使用�?   * @returns 调整后的最大并发任务数
   */
  private calculateOptimalConcurrentTasks(memoryUsage: number): number {
    // 内存使用率低�?0%：使用最大并发数
    if (memoryUsage < 0.5) {
      return this.maxConcurrentTasks;
    }
    // 内存使用�?0%-70%：使�?5%的最大并发数
    else if (memoryUsage < 0.7) {
      return Math.max(1, Math.floor(this.maxConcurrentTasks * 0.75));
    }
    // 内存使用�?0%-85%：使�?0%的最大并发数
    else if (memoryUsage < 0.85) {
      return Math.max(1, Math.floor(this.maxConcurrentTasks * 0.5));
    }
    // 内存使用率高�?5%：只允许1个并发任�?    else {
      return 1;
    }
  }
  
  /**
   * 根据内存使用情况计算重试延迟
   * @param memoryUsage 当前内存使用�?   * @returns 重试延迟时间（毫秒）
   */
  private calculateRetryDelay(memoryUsage: number): number {
    // 内存使用越高，重试延迟越�?    if (memoryUsage < 0.7) return 1000;     // 70%以下�?�?    if (memoryUsage < 0.8) return 2000;     // 70%-80%�?�?    if (memoryUsage < 0.9) return 3000;     // 80%-90%�?�?    return 5000;                            // 90%以上�?�?  }

  /**
   * 执行单个任务
   * @param task 要执行的任务
   */
  private async executeTask(task: Task): Promise<void> {
    if (!task.id) {
      task.id = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    this.runningTasks.set(task.id, task);
    Logger.debug(TAG, `Task ${task.id} started execution with priority ${task.priority}`);
    
    // 记录任务开始前的内存使用情�?    const startMemoryUsage = this.memoryManager.getCurrentMemoryUsage();
    const startTime = Date.now();

    try {
      // 根据任务优先级和内存情况动态调整任务配�?      const memoryStats = this.memoryManager.getMemoryStats();
      const taskOptions = this.createOptimizedTaskOptions(task.priority, memoryStats);
      
      // 使用TaskPool执行任务，实现真正的系统级并�?      const taskFunction = async () => {
        try {
          return await task.execute();
        } catch (error) {
          Logger.error(TAG, `Task function execution error: ${error instanceof Error ? error.message : String(error)}`);
          throw error;
        }
      };

      // 执行任务
      const result = await taskPool.execute(taskFunction, taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions : new Error(String(taskOptions instanceof Error ? taskOptions : new Error(String(taskOptions)))))));
      
      // 处理完成
      this.handleTaskComplete(task, result);
      
      // 记录任务完成后的内存使用情况，监控内存泄�?      this.logTaskMemoryUsage(task.id, startMemoryUsage, startTime);
    } catch (error) {
      // 处理错误
      this.handleTaskError(task, error as Error);
    } finally {
      // 从运行中任务移除
      this.runningTasks.delete(task.id);
      
      // 在任务完成后再次检查内存，如果内存使用过高尝试清理
      this.checkAndCleanupMemory();
      
      // 继续处理队列
      this.processQueue();
    }
  }
  
  /**
   * 创建优化的任务选项
   * @param priority 任务优先�?   * @param memoryStats 内存统计信息
   * @returns 优化的任务选项
   */
  private createOptimizedTaskOptions(priority: TaskPriority, memoryStats: { currentUsage: number }): taskPool.TaskOptions {
    const taskOptions: taskPool.TaskOptions = {
      priority: this.getTaskPoolPriority(priority)
    };
    
    // 在内存紧张时，对低优先级任务应用更严格的资源限制
    if (memoryStats.currentUsage > 0.8 && priority <= TaskPriority.NORMAL) {
      Logger.info(TAG, `Applying resource limits for low priority task due to high memory usage (${(memoryStats.currentUsage * 100).toFixed(1)}%)`);
      // 注意：TaskPool可能不直接支持这些选项，这里仅作为示例
      // taskOptions.maxMemoryUsage = 0.1; // 限制任务内存使用
    }
    
    return taskOptions;
  }
  
  /**
   * 记录任务的内存使用情�?   * @param taskId 任务ID
   * @param startUsage 开始时的内存使用率
   * @param startTime 开始时�?   */
  private logTaskMemoryUsage(taskId: string, startUsage: number, startTime: number): void {
    const endUsage = this.memoryManager.getCurrentMemoryUsage();
    const duration = Date.now() - startTime;
    const memoryDiff = endUsage - startUsage;
    
    // 如果内存使用增加�?%以上，记录警�?    if (memoryDiff > 0.05) {
      Logger.warn(TAG, `Task ${taskId} may be leaking memory: memory usage increased by ${(memoryDiff * 100).toFixed(1)}%`);
    }
    
    if (duration > 10000) { // 任务执行超过10�?      Logger.info(TAG, `Long-running task ${taskId} completed in ${duration}ms`);
    }
  }
  
  /**
   * 检查并在需要时清理内存
   */
  private checkAndCleanupMemory(): void {
    const memoryUsage = this.memoryManager.getCurrentMemoryUsage();
    
    // 当内存使用超�?5%时尝试清�?    if (memoryUsage > 0.85) {
      Logger.warn(TAG, `Memory usage high (${(memoryUsage * 100).toFixed(1)}%), attempting cleanup`);
      this.memoryManager.clearMemory();
      
      // 清理后再次检�?      const afterCleanupUsage = this.memoryManager.getCurrentMemoryUsage();
      const freedMemory = memoryUsage - afterCleanupUsage;
      
      if (freedMemory > 0.05) {
        Logger.info(TAG, `Memory cleanup successful: freed ${(freedMemory * 100).toFixed(1)}%`);
      }
    }
  }

  /**
   * 处理任务完成
   * @param task 任务对象
   * @param result 任务结果
   */
  private handleTaskComplete<T>(task: Task<T>, result: T): void {
    Logger.debug(TAG, `Task ${task.id} completed successfully`);
    try {
      task.onComplete?.(result);
    } catch (error) {
      Logger.error(TAG, `Error in task ${task.id} onComplete callback: ${(error as Error).message}`);
    }
  }

  /**
   * 处理任务错误
   * @param task 任务对象
   * @param error 错误对象
   */
  private handleTaskError(task: Task, error: Error instanceof Error ? error: Error : new Error(String(error: Error instanceof Error ? error: Error instanceof Error ? error: Error : new Error(String(error: Error : new Error(String(error: Error instanceof Error ? error: Error : new Error(String(error: Error instanceof Error ? error: Error instanceof Error ? error: Error : new Error(String(error: Error instanceof Error ? error: Error instanceof Error ? error: Error : new Error(String(error: Error : new Error(String(error: Error instanceof Error ? error: Error : new Error(String(error: Error : new Error(String(error: Error instanceof Error ? error: Error : new Error(String(error: Error instanceof Error ? error: Error instanceof Error ? error: Error : new Error(String(error: Error : new Error(String(error: Error instanceof Error ? error: Error : new Error(String(error: Error))))))): void {
    Logger.error(TAG, `Task ${task.id} failed: ${error.message}`);
    try {
      task.onError?.(error);
    } catch (callbackError) {
      Logger.error(TAG, `Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error instanceof Error ? `Error in task ${task.id} onError callback: ${(callbackError as Error : new Error(String(`Error in task ${task.id} onError callback: ${(callbackError as Error))))))).message}`);
    }
  }
}

export default TaskPoolManager.getInstance();


