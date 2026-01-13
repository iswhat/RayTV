// TaskPoolManager.ets - 任务池管理器 // Task pool manager
// 提供基于TaskPool的任务调度和管理功能 // Provides task scheduling and management based on TaskPool
import Logger from '../../common/util/Logger';
import taskPool from '@ohos.taskpool';
import MemoryManager from '../../common/util/MemoryManager';
import { Serializable } from '../../types/commonTypes';

const TAG = 'TaskPoolManager';

/**
 * 任务优先级枚举 // Task priority enum
 */
export enum TaskPriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  CRITICAL = 3
}

/**
 * 任务状态枚举 // Task status enum
 */
export enum TaskStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

/**
 * 任务接口定义 // Task interface definition
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
 * 任务池管理器 // Task pool manager
 * 提供基于TaskPool的任务调度和管理功能 // Provides task scheduling and management based on TaskPool
 */
export class TaskPoolManager {
  static instance: TaskPoolManager;
  taskQueue: Task[] = [];
  runningTasks: Map<string, Task> = new Map();
  maxConcurrentTasks: number = 3;
  isProcessing: boolean = false;
  memoryManager: MemoryManager;

  /**
   * 构造函数 // Constructor
   */
  constructor() {
    Logger.info(TAG, 'TaskPoolManager initialized');
    this.memoryManager = MemoryManager.getInstance();
  }

  /**
   * 获取单例实例 // Get singleton instance
   */
  static getInstance(): TaskPoolManager {
    if (!TaskPoolManager.instance) {
      TaskPoolManager.instance = new TaskPoolManager();
    }
    return TaskPoolManager.instance;
  }

  /**
   * 设置最大并发任务数 // Set maximum concurrent tasks
   * @param max 最大并发任务数 // Maximum concurrent tasks
   */
  setMaxConcurrentTasks(max: number): void {
    if (max > 0) {
      this.maxConcurrentTasks = max;
      Logger.info(TAG, `Max concurrent tasks set to: ${max}`);
      // 重新处理队列 // Reprocess queue
      this.processQueue();
    }
  }

  /**
   * 提交任务到队列 // Submit task to queue
   * @param task 任务对象 // Task object
   */
  submit<T = unknown>(task: Task<T>): void {
    if (!task || !task.execute) {
      Logger.error(TAG, 'Invalid task submitted');
      return;
    }

    // 添加到任务队列 // Add to task queue
    this.taskQueue.push(task);
    Logger.debug(TAG, `Task ${task.id} submitted with priority: ${task.priority}`);

    // 按优先级排序 // Sort by priority
    this.sortTasks();

    // 开始处理队列 // Start processing queue
    this.processQueue();
  }
  
  /**
   * 将自定义优先级转换为TaskPool优先级 // Convert custom priority to TaskPool priority
   * @param priority 自定义优先级 // Custom priority
   * @returns taskPool.Priority 对应的TaskPool优先级 // Corresponding TaskPool priority
   */
  getTaskPoolPriority(priority: TaskPriority): taskPool.Priority {
    switch (priority) {
      case TaskPriority.HIGH:
      case TaskPriority.CRITICAL:
        return taskPool.Priority.HIGH;
      case TaskPriority.NORMAL:
        return taskPool.Priority.MEDIUM;
      case TaskPriority.LOW:
      default:
        return taskPool.Priority.LOW;
    }
  }

  /**
   * 按优先级排序任务队列 // Sort task queue by priority
   */
  sortTasks(): void {
    this.taskQueue.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 取消指定任务 // Cancel specified task
   * @param taskId 任务ID // Task ID
   * @returns boolean 取消是否成功 // Whether cancellation succeeded
   */
  cancelTask(taskId: string): boolean {
    // 检查运行中的任务 // Check running tasks
    const runningTask = this.runningTasks.get(taskId);
    if (runningTask) {
      // 标记为取消状态 // Mark as cancelled
      this.runningTasks.delete(taskId);
      // 执行取消回调 // Execute cancel callback
      if (runningTask.onCancel) {
        runningTask.onCancel();
      }
      Logger.info(TAG, `Task ${taskId} cancelled while running`);
      return true;
    }

    // 检查队列中的任务 // Check queued tasks
    const index = this.taskQueue.findIndex(task => task.id === taskId);
    if (index !== -1) {
      const task = this.taskQueue[index];
      // 执行取消回调 // Execute cancel callback
      if (task.onCancel) {
        task.onCancel();
      }
      // 从队列中移除 // Remove from queue
      this.taskQueue.splice(index, 1);
      Logger.info(TAG, `Task ${taskId} cancelled from queue`);
      return true;
    }

    Logger.warn(TAG, `Task ${taskId} not found for cancellation`);
    return false;
  }

  /**
   * 取消所有任务 // Cancel all tasks
   */
  cancelAllTasks(): void {
    // 取消运行中的任务 // Cancel running tasks
    this.runningTasks.forEach((task, id) => {
      this.cancelTask(id);
    });

    // 清空任务队列 // Clear task queue
    this.taskQueue.forEach(task => {
      if (task.onCancel) {
        task.onCancel();
      }
    });
    this.taskQueue = [];
    Logger.info(TAG, 'All tasks cancelled');
  }

  /**
   * 处理任务队列 // Process task queue
   */
  processQueue(): void {
    // 如果正在处理或队列为空，直接返回 // Return if processing or queue is empty
    if (this.isProcessing || this.taskQueue.length === 0) {
      return;
    }

    this.isProcessing = true;
    Logger.debug(TAG, 'Starting to process task queue');

    // 动态调整并发任务数基于内存使用情况 // Dynamically adjust concurrent tasks based on memory usage
    this.scheduleTasks();
  }

  /**
   * 调度任务执行 // Schedule task execution
   */
  scheduleTasks(): void {
    // 执行尽可能多的并发任务 // Execute as many concurrent tasks as possible
    while (
      this.runningTasks.size < this.maxConcurrentTasks &&
      this.taskQueue.length > 0
    ) {
      // 在每次执行任务前重新检查内存可用性 // Recheck memory availability before each task execution
      if (!this.memoryManager.checkMemoryAvailability()) {
        // 尝试清理内存 // Try to clear memory
        this.memoryManager.clearMemory();
        // 延迟重试，根据内存使用情况动态调整 // Delay retry based on memory usage
        const retryDelay = this.calculateRetryDelay(this.memoryManager.getMemoryStats().currentUsage);
        setTimeout(() => {
          this.processQueue();
        }, retryDelay);
        this.isProcessing = false;
        return;
      }

      // 获取下一个任务 // Get next task
      const task = this.taskQueue.shift()!;
      this.runningTasks.set(task.id, task);
      Logger.debug(TAG, `Starting task ${task.id}, priority: ${task.priority}`);

      // 执行任务 // Execute task
      this.executeTask(task);
    }

    // 如果队列为空，重置处理标记 // If queue is empty, reset processing flag
    if (this.taskQueue.length === 0) {
      Logger.debug(TAG, 'Task queue is empty, stopping processing');
    }

    this.isProcessing = false;
  }

  /**
   * 根据内存使用情况计算重试延迟 // Calculate retry delay based on memory usage
   * @param memoryUsage 内存使用率(0-1) // Memory usage (0-1)
   * @returns number 重试延迟（毫秒） // Retry delay (milliseconds)
   */
  calculateRetryDelay(memoryUsage: number): number {
    // 内存使用率低：使用最大并发数 // Low memory usage: use maximum concurrency
    if (memoryUsage < 0.5) {
      return 500; // 500毫秒 // 500ms
    }
    // 内存使用率50%-70%：使用75%的最大并发数 // Memory usage 50%-70%: use 75% of maximum concurrency
    else if (memoryUsage < 0.7) {
      return 1000; // 1秒 // 1s
    }
    // 内存使用率70%-85%：使用50%的最大并发数 // Memory usage 70%-85%: use 50% of maximum concurrency
    else if (memoryUsage < 0.85) {
      return 2000; // 2秒 // 2s
    }
    // 内存使用率高：只允许1个并发任务 // High memory usage: only allow 1 concurrent task
    else {
      return 3000; // 3秒 // 3s
    }
  }

  /**
   * 执行任务 // Execute task
   * @param task 要执行的任务 // Task to execute
   */
  private async executeTask(task: Task): Promise<void> {
    const startTime = Date.now();
    // 记录任务开始前的内存使用情况 // Record memory usage before task starts
    const startMemoryUsage = this.memoryManager.getCurrentMemoryUsage();

    try {
      // 根据任务优先级和内存情况动态调整任务配置 // Dynamically adjust task configuration based on priority and memory
      const memoryStats = this.memoryManager.getMemoryStats();
      const taskOptions: taskPool.TaskOptions = {
        priority: this.getTaskPoolPriority(task.priority),
        // 内存紧张时，对低优先级任务应用更严格的资源限制 // Apply stricter resource limits for low priority tasks when memory is tight
        maxWorkers: memoryStats.currentUsage > 0.8 && task.priority <= TaskPriority.NORMAL ? 1 : undefined
      };

      // 执行任务 // Execute task
      const taskFunction = async () => {
        return await task.execute();
      };

      // 执行任务 // Execute task
      const result = await taskPool.execute(taskFunction, taskOptions);
      // 处理完成 // Handle completion
      this.handleTaskComplete(task, result);

      // 记录任务完成后的内存使用情况，监控内存泄漏 // Record memory usage after task completion, monitor memory leaks
      this.logTaskMemoryUsage(task.id, startMemoryUsage, startTime);
    } catch (error) {
      // 处理错误 // Handle error
      this.handleTaskError(task, error as Error);
    } finally {
      // 从运行中任务移除 // Remove from running tasks
      this.runningTasks.delete(task.id);
      // 在任务完成后再次检查内存，如果内存使用过高就尝试清理 // Recheck memory after task completion, try to clean up if usage is high
      this.checkAndCleanupMemory();
      // 继续处理队列 // Continue processing queue
      this.processQueue();
    }
  }

  /**
   * 处理任务完成 // Handle task completion
   * @param task 已完成的任务 // Completed task
   * @param result 任务结果 // Task result
   */
  private handleTaskComplete<T>(task: Task<T>, result: T): void {
    Logger.info(TAG, `Task ${task.id} completed successfully`);
    if (task.onComplete) {
      task.onComplete(result);
    }
  }

  /**
   * 处理任务错误 // Handle task error
   * @param task 出错的任务 // Task with error
   * @param error 错误信息 // Error message
   */
  private handleTaskError(task: Task, error: Error): void {
    Logger.error(TAG, `Task ${task.id} failed: ${error.message}`, error);
    if (task.onError) {
      task.onError(error);
    }
  }

  /**
   * 记录任务内存使用情况 // Log task memory usage
   * @param taskId 任务ID // Task ID
   * @param startMemoryUsage 开始时内存使用率 // Start memory usage
   * @param startTime 开始时间 // Start time
   */
  private logTaskMemoryUsage(taskId: string, startMemoryUsage: number, startTime: number): void {
    const endMemoryUsage = this.memoryManager.getCurrentMemoryUsage();
    const duration = Date.now() - startTime;
    const memoryDiff = endMemoryUsage - startMemoryUsage;

    // 如果内存使用增加5%以上，警告开发者 // Warn developers if memory usage increases by more than 5%
    if (memoryDiff > 0.05) {
      Logger.warn(TAG, `Task ${taskId} increased memory usage by ${(memoryDiff * 100).toFixed(1)}%`);
    }

    // 长时间运行的任务也警告 // Also warn about long-running tasks
    if (duration > 10000) {
      Logger.info(TAG, `Long-running task ${taskId} completed in ${duration}ms`);
    }
  }

  /**
   * 检查并清理内存 // Check and clean up memory
   */
  private checkAndCleanupMemory(): void {
    const memoryUsage = this.memoryManager.getCurrentMemoryUsage();
    // 在内存紧张时，对低优先级任务应用更严格的资源限制 // Apply stricter resource limits for low priority tasks when memory is tight
    if (memoryUsage > 0.85) {
      Logger.warn(TAG, `High memory usage detected: ${(memoryUsage * 100).toFixed(1)}%, attempting cleanup`);
      this.memoryManager.clearMemory();
    }
  }

  /**
   * 获取任务状态 // Get task status
   * @param taskId 任务ID // Task ID
   * @returns TaskStatus | undefined 任务状态，如果任务不存在则返回undefined // Task status, returns undefined if task doesn't exist
   */
  getTaskStatus(taskId: string): TaskStatus | undefined {
    // 检查运行中的任务 // Check running tasks
    if (this.runningTasks.has(taskId)) {
      return TaskStatus.RUNNING;
    }

    // 检查队列中的任务 // Check queued tasks
    if (this.taskQueue.find(task => task.id === taskId)) {
      return TaskStatus.PENDING;
    }

    return undefined;
  }

  /**
   * 获取所有任务状态 // Get all task statuses
   * @returns Map<string, TaskStatus> 所有任务的状态映射 // Status map of all tasks
   */
  getAllTaskStatuses(): Map<string, TaskStatus> {
    const statusMap = new Map<string, TaskStatus>();

    // 运行中的任务 // Running tasks
    this.runningTasks.forEach((_, id) => {
      statusMap.set(id, TaskStatus.RUNNING);
    });

    // 队列中的任务 // Queued tasks
    this.taskQueue.forEach(task => {
      statusMap.set(task.id, TaskStatus.PENDING);
    });

    return statusMap;
  }

  /**
   * 获取队列长度 // Get queue length
   * @returns number 队列中的任务数量 // Number of tasks in queue
   */
  getQueueLength(): number {
    return this.taskQueue.length;
  }

  /**
   * 获取当前运行中的任务数量 // Get current running task count
   * @returns number 运行中的任务数量 // Number of running tasks
   */
  getRunningTasksCount(): number {
    return this.runningTasks.size;
  }
}
