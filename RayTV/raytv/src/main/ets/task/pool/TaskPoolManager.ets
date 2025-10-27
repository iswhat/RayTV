// TaskPoolManager - 任务池管理器
import Logger from '../../common/util/Logger';

const TAG = 'TaskPoolManager';

/**
 * 任务优先级枚举
 */
export enum TaskPriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  CRITICAL = 3
}

/**
 * 任务状态枚举
 */
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
export interface Task<T = any> {
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
  private static instance: TaskPoolManager;
  private taskQueue: Task[] = [];
  private runningTasks: Map<string, Task> = new Map();
  private maxConcurrentTasks: number = 3;
  private isProcessing: boolean = false;

  /**
   * 私有构造函数
   */
  private constructor() {
    Logger.info(TAG, 'TaskPoolManager initialized');
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): TaskPoolManager {
    if (!TaskPoolManager.instance) {
      TaskPoolManager.instance = new TaskPoolManager();
    }
    return TaskPoolManager.instance;
  }

  /**
   * 设置最大并发任务数
   * @param max 最大并发任务数
   */
  public setMaxConcurrentTasks(max: number): void {
    if (max > 0) {
      this.maxConcurrentTasks = max;
      Logger.info(TAG, `Max concurrent tasks set to: ${max}`);
      // 重新处理队列
      this.processQueue();
    }
  }

  /**
   * 提交任务到队列
   * @param task 任务对象
   */
  public submit<T = any>(task: Task<T>): void {
    if (!task || !task.execute) {
      Logger.error(TAG, 'Invalid task submitted');
      return;
    }

    // 添加到任务队列
    this.taskQueue.push(task);
    Logger.debug(TAG, `Task ${task.id} submitted with priority: ${task.priority}`);

    // 按优先级排序
    this.sortTasks();

    // 开始处理队列
    this.processQueue();
  }

  /**
   * 执行单个任务
   * @param task 要执行的任务
   */
  public async execute<T = any>(task: Task<T>): Promise<T> {
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
  public cancelTask(taskId: string): boolean {
    // 检查运行中的任务
    const runningTask = this.runningTasks.get(taskId);
    if (runningTask) {
      // 标记为取消状态
      this.runningTasks.delete(taskId);
      runningTask.onCancel?.();
      Logger.info(TAG, `Running task ${taskId} cancelled`);
      return true;
    }

    // 检查队列中的任务
    const index = this.taskQueue.findIndex(task => task.id === taskId);
    if (index !== -1) {
      const task = this.taskQueue[index];
      this.taskQueue.splice(index, 1);
      task.onCancel?.();
      Logger.info(TAG, `Queued task ${taskId} cancelled`);
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
      task.onCancel?.();
    }
    this.taskQueue = [];
    Logger.info(TAG, 'Task queue cleared');
  }

  /**
   * 获取任务状态
   * @param taskId 任务ID
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
      // 执行尽可能多的并发任务
      while (
        this.runningTasks.size < this.maxConcurrentTasks &&
        this.taskQueue.length > 0
      ) {
        const task = this.taskQueue.shift();
        if (task) {
          this.executeTask(task);
        }
      }
    } finally {
      this.isProcessing = false;
      
      // 如果还有任务在队列中，继续处理
      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        setTimeout(() => this.processQueue(), 0);
      }
    }
  }

  /**
   * 执行单个任务
   * @param task 要执行的任务
   */
  private async executeTask(task: Task): Promise<void> {
    if (!task.id) {
      task.id = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    this.runningTasks.set(task.id, task);
    Logger.debug(TAG, `Task ${task.id} started execution`);

    try {
      // 执行任务
      const result = await task.execute();
      
      // 处理完成
      this.handleTaskComplete(task, result);
    } catch (error) {
      // 处理错误
      this.handleTaskError(task, error as Error);
    } finally {
      // 从运行中任务移除
      this.runningTasks.delete(task.id);
      
      // 继续处理队列
      this.processQueue();
    }
  }

  /**
   * 处理任务完成
   * @param task 任务对象
   * @param result 任务结果
   */
  private handleTaskComplete(task: Task, result: any): void {
    Logger.debug(TAG, `Task ${task.id} completed successfully`);
    task.onComplete?.(result);
  }

  /**
   * 处理任务错误
   * @param task 任务对象
   * @param error 错误对象
   */
  private handleTaskError(task: Task, error: Error): void {
    Logger.error(TAG, `Task ${task.id} failed: ${error.message}`);
    task.onError?.(error);
  }
}

export default TaskPoolManager.getInstance();