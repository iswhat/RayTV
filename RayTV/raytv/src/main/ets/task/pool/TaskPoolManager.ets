// TaskPoolManager - 浠诲姟姹犵鐞嗗�?import Logger from '../../common/util/Logger';
import taskPool from '@ohos.taskpool';
import MemoryManager from '../../common/util/MemoryManager';

const TAG = 'TaskPoolManager';

/**
 * 浠诲姟浼樺厛绾ф灇�? */
export enum TaskPriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  CRITICAL = 3
}

/**
 * 浠诲姟鐘舵€佹灇�? */
export enum TaskStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

/**
 * 浠诲姟鎺ュ彛瀹氫�? */
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
 * 浠诲姟姹犵鐞嗗�? * 鎻愪緵鍩轰簬TaskPool鐨勪换鍔¤皟搴﹀拰绠＄悊鍔熻�? */
export class TaskPoolManager {
  static instance: TaskPoolManager;
  taskQueue: Task[] = [];
  runningTasks: Map<string, Task> = new Map();
  maxConcurrentTasks: number = 3;
  isProcessing: boolean = false;
  memoryManager: MemoryManager;

  /**
   * 鏋勯€犲嚱锟?   */
  constructor() {
    Logger.info(TAG, 'TaskPoolManager initialized');
    this.memoryManager = MemoryManager.getInstance();
  }

  /**
   * 鑾峰彇鍗曚緥瀹炰�?   */
  static getInstance(): TaskPoolManager {
    if (!TaskPoolManager.instance) {
      TaskPoolManager.instance = new TaskPoolManager();
    }
    return TaskPoolManager.instance;
  }

  /**
   * 璁剧疆鏈€澶у苟鍙戜换鍔℃�?   * @param max 鏈€澶у苟鍙戜换鍔℃暟
   */
  setMaxConcurrentTasks(max: number): void {
    if (max > 0) {
      this.maxConcurrentTasks = max;
      Logger.info(TAG, `Max concurrent tasks set to: ${max}`);
      // 閲嶆柊澶勭悊闃熷�?      this.processQueue();
    }
  }

  /**
   * 鎻愪氦浠诲姟鍒伴槦锟?   * @param task 浠诲姟瀵硅�?   */
  submit<T = unknown>(task: Task<T>): void {
    if (!task || !task.execute) {
      Logger.error(TAG, 'Invalid task submitted');
      return;
    }

    // 娣诲姞鍒颁换鍔￠槦锟?    this.taskQueue.push(task);
    Logger.debug(TAG, `Task ${task.id} submitted with priority: ${task.priority}`);

    // 鎸変紭鍏堢骇鎺掑�?    this.sortTasks();

    // 寮€濮嬪鐞嗛槦�?    this.processQueue();
  }
  
  /**
   * 灏嗚嚜瀹氫箟浼樺厛绾ц浆鎹负TaskPool浼樺厛锟?   * @param priority 鑷畾涔変紭鍏堢�?   * @returns taskPool.Priority 瀵瑰簲鐨凾askPool浼樺厛锟?   */
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
   * 鎵ц鍗曚釜浠诲姟
   * @param task 瑕佹墽琛岀殑浠诲姟
   */
  async execute<T = unknown>(task: Task<T>): Promise<T> {
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
   * 鍙栨秷浠诲姟
   * @param taskId 浠诲姟ID
   * @returns 鏄惁鎴愬姛鍙栨�?   */
  cancelTask(taskId: string): boolean {
    // 妫€鏌ヨ繍琛屼腑鐨勪换锟?    const runningTask = this.runningTasks.get(taskId);
    if (runningTask) {
      // 鏍囪涓哄彇娑堢姸锟?      this.runningTasks.delete(taskId);
      try {
        runningTask.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task ${taskId} onCancel callback: ${(error as Error).message}`);
      }
      Logger.info(TAG, `Running task ${taskId} cancelled`);
      return true;
    }

    // 妫€鏌ラ槦鍒椾腑鐨勪换锟?    const index = this.taskQueue.findIndex(task => task.id === taskId);
    if (index !== -1) {
      const task = this.taskQueue[index];
      this.taskQueue.splice(index, 1);
      try {
        task.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task ${taskId} onCancel callback: ${(error as Error).message}`);
      }
      Logger.info(TAG, `Queued task ${taskId} cancelled`);
      return true;
    }

    Logger.warn(TAG, `Task ${taskId} not found`);
    return false;
  }

  /**
   * 娓呯┖浠诲姟闃熷�?   */
  public clearQueue(): void {
    for (const task of this.taskQueue) {
      try {
        task.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task onCancel callback: ${(error as Error).message}`);
      }
    }
    this.taskQueue = [];
    Logger.info(TAG, 'Task queue cleared');
  }

  /**
   * 鑾峰彇浠诲姟鐘讹�?   * @param taskId 浠诲姟ID
   * @returns 浠诲姟鐘舵€侊紝濡傛灉浠诲姟涓嶅瓨鍦ㄨ繑鍥瀗ull
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
   * 鑾峰彇褰撳墠杩愯涓殑浠诲姟鏁伴噺
   */
  public getRunningTaskCount(): number {
    return this.runningTasks.size;
  }

  /**
   * 鑾峰彇褰撳墠闃熷垪涓殑浠诲姟鏁伴噺
   */
  public getQueuedTaskCount(): number {
    return this.taskQueue.length;
  }

  /**
   * 鎸変紭鍏堢骇鎺掑簭浠诲姟闃熷�?   */
  private sortTasks(): void {
    this.taskQueue.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 澶勭悊浠诲姟闃熷�?   */
  private processQueue(): void {
    if (this.isProcessing) return;
    
    this.isProcessing = true;
    
    try {
      // 鍔ㄦ€佽皟鏁村苟鍙戜换鍔℃暟鍩轰簬鍐呭瓨浣跨敤鎯呭喌
      const memoryStats = this.memoryManager.getMemoryStats();
      const adjustedMaxConcurrentTasks = this.calculateOptimalConcurrentTasks(memoryStats.currentUsage);
      
      // 鎵ц灏藉彲鑳藉鐨勫苟鍙戜换�?      while (
        this.runningTasks.size < adjustedMaxConcurrentTasks &&
        this.taskQueue.length > 0
      ) {
        // 鍦ㄦ瘡娆℃墽琛屼换鍔″墠閲嶆柊妫€鏌ュ唴瀛樺彲鐢拷?        if (!this.memoryManager.checkMemoryAvailability()) {
          Logger.warn(TAG, `Insufficient memory to process tasks (${(memoryStats.currentUsage * 100).toFixed(1)}%), pausing queue`);
          // 灏濊瘯娓呯悊鍐呭�?          this.memoryManager.clearMemory();
          // 寤惰繜閲嶈瘯锛屾牴鎹唴瀛樹娇鐢ㄦ儏鍐靛姩鎬佽皟鏁村欢杩熸椂�?          const retryDelay = this.calculateRetryDelay(memoryStats.currentUsage);
          setTimeout(() => this.processQueue(), retryDelay);
          return;
        }
        
        const task = this.taskQueue.shift();
        if (task) {
          this.executeTask(task);
        }
      }
      
      // 濡傛灉闃熷垪涓嶄负绌轰絾娌℃湁鎵ц浠诲姟锛屽彲鑳芥槸鍥犱负鍐呭瓨涓嶈�?      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        Logger.info(TAG, `Task queue has ${this.taskQueue.length} tasks, but running at capacity (${this.runningTasks.size}/${adjustedMaxConcurrentTasks})`);
      }
    } finally {
      this.isProcessing = false;
      
      // 濡傛灉杩樻湁浠诲姟鍦ㄩ槦鍒椾腑涓旀病鏈夎揪鍒版渶澶у苟鍙戞暟锛岀户缁�?      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        setTimeout(() => this.processQueue(), 0);
      }
    }
  }
  
  /**
   * 鏍规嵁鍐呭瓨浣跨敤鎯呭喌璁＄畻鏈€浣冲苟鍙戜换鍔℃暟
   * @param memoryUsage 褰撳墠鍐呭瓨浣跨敤锟?   * @returns 璋冩暣鍚庣殑鏈€澶у苟鍙戜换鍔℃暟
   */
  private calculateOptimalConcurrentTasks(memoryUsage: number): number {
    // 鍐呭瓨浣跨敤鐜囦綆锟?0%锛氫娇鐢ㄦ渶澶у苟鍙戞�?    if (memoryUsage < 0.5) {
      return this.maxConcurrentTasks;
    }
    // 鍐呭瓨浣跨敤�?0%-70%锛氫娇锟?5%鐨勬渶澶у苟鍙戞暟
    else if (memoryUsage < 0.7) {
      return Math.max(1, Math.floor(this.maxConcurrentTasks * 0.75));
    }
    // 鍐呭瓨浣跨敤�?0%-85%锛氫娇锟?0%鐨勬渶澶у苟鍙戞暟
    else if (memoryUsage < 0.85) {
      return Math.max(1, Math.floor(this.maxConcurrentTasks * 0.5));
    }
    // 鍐呭瓨浣跨敤鐜囬珮锟?5%锛氬彧鍏佽1涓苟鍙戜换�?    else {
      return 1;
    }
  }
  
  /**
   * 鏍规嵁鍐呭瓨浣跨敤鎯呭喌璁＄畻閲嶈瘯寤惰�?   * @param memoryUsage 褰撳墠鍐呭瓨浣跨敤锟?   * @returns 閲嶈瘯寤惰繜鏃堕棿锛堟绉掞�?   */
  private calculateRetryDelay(memoryUsage: number): number {
    // 鍐呭瓨浣跨敤瓒婇珮锛岄噸璇曞欢杩熻秺�?    if (memoryUsage < 0.7) return 1000;     // 70%浠ヤ笅锟?�?    if (memoryUsage < 0.8) return 2000;     // 70%-80%�?�?    if (memoryUsage < 0.9) return 3000;     // 80%-90%�?�?    return 5000;                            // 90%浠ヤ笂锟?�?  }

  /**
   * 鎵ц鍗曚釜浠诲姟
   * @param task 瑕佹墽琛岀殑浠诲姟
   */
  private async executeTask(task: Task): Promise<void> {
    if (!task.id) {
      task.id = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    this.runningTasks.set(task.id, task);
    Logger.debug(TAG, `Task ${task.id} started execution with priority ${task.priority}`);
    
    // 璁板綍浠诲姟寮€濮嬪墠鐨勫唴瀛樹娇鐢ㄦ儏�?    const startMemoryUsage = this.memoryManager.getCurrentMemoryUsage();
    const startTime = Date.now();

    try {
      // 鏍规嵁浠诲姟浼樺厛绾у拰鍐呭瓨鎯呭喌鍔ㄦ€佽皟鏁翠换鍔￠厤�?      const memoryStats = this.memoryManager.getMemoryStats();
      const taskOptions = this.createOptimizedTaskOptions(task.priority, memoryStats);
      
      // 浣跨敤TaskPool鎵ц浠诲姟锛屽疄鐜扮湡姝ｇ殑绯荤粺绾у苟锟?      const taskFunction = async () => {
        try {
          return await task.execute();
        } catch (error) {
          Logger.error(TAG, `Task function execution error: ${error instanceof Error ? error.message : String(error)}`);
          throw error;
        }
      };

      // 鎵ц浠诲�?      const result = await taskPool.execute(taskFunction, taskOptions);
      
      // 澶勭悊瀹屾�?      this.handleTaskComplete(task, result);
      
      // 璁板綍浠诲姟瀹屾垚鍚庣殑鍐呭瓨浣跨敤鎯呭喌锛岀洃鎺у唴瀛樻硠锟?      this.logTaskMemoryUsage(task.id, startMemoryUsage, startTime);
    } catch (error) {
      // 澶勭悊閿欒
      this.handleTaskError(task, error as Error);
    } finally {
      // 浠庤繍琛屼腑浠诲姟绉婚櫎
      this.runningTasks.delete(task.id);
      
      // 鍦ㄤ换鍔″畬鎴愬悗鍐嶆妫€鏌ュ唴瀛橈紝濡傛灉鍐呭瓨浣跨敤杩囬珮灏濊瘯娓呯�?      this.checkAndCleanupMemory();
      
      // 缁х画澶勭悊闃熷垪
      this.processQueue();
    }
  }
  
  /**
   * 鍒涘缓浼樺寲鐨勪换鍔￠€夐�?   * @param priority 浠诲姟浼樺厛�?   * @param memoryStats 鍐呭瓨缁熻淇℃�?   * @returns 浼樺寲鐨勪换鍔￠€夐�?   */
  private createOptimizedTaskOptions(priority: TaskPriority, memoryStats: { currentUsage: number }): taskPool.TaskOptions {
    const taskOptions: taskPool.TaskOptions = {
      priority: this.getTaskPoolPriority(priority)
    };
    
    // 鍦ㄥ唴瀛樼揣寮犳椂锛屽浣庝紭鍏堢骇浠诲姟搴旂敤鏇翠弗鏍肩殑璧勬簮闄愬�?    if (memoryStats.currentUsage > 0.8 && priority <= TaskPriority.NORMAL) {
      Logger.info(TAG, `Applying resource limits for low priority task due to high memory usage (${(memoryStats.currentUsage * 100).toFixed(1)}%)`);
      // 娉ㄦ剰锛歍askPool鍙兘涓嶇洿鎺ユ敮鎸佽繖浜涢€夐」锛岃繖閲屼粎浣滀负绀轰緥
      // taskOptions.maxMemoryUsage = 0.1; // 闄愬埗浠诲姟鍐呭瓨浣跨敤
    }
    
    return taskOptions;
  }
  
  /**
   * 璁板綍浠诲姟鐨勫唴瀛樹娇鐢ㄦ儏�?   * @param taskId 浠诲姟ID
   * @param startUsage 寮€濮嬫椂鐨勫唴瀛樹娇鐢ㄧ巼
   * @param startTime 寮€濮嬫椂锟?   */
  private logTaskMemoryUsage(taskId: string, startUsage: number, startTime: number): void {
    const endUsage = this.memoryManager.getCurrentMemoryUsage();
    const duration = Date.now() - startTime;
    const memoryDiff = endUsage - startUsage;
    
    // 濡傛灉鍐呭瓨浣跨敤澧炲姞�?%浠ヤ笂锛岃褰曡锟?    if (memoryDiff > 0.05) {
      Logger.warn(TAG, `Task ${taskId} may be leaking memory: memory usage increased by ${(memoryDiff * 100).toFixed(1)}%`);
    }
    
    if (duration > 10000) { // 浠诲姟鎵ц瓒呰繃10�?      Logger.info(TAG, `Long-running task ${taskId} completed in ${duration}ms`);
    }
  }
  
  /**
   * 妫€鏌ュ苟鍦ㄩ渶瑕佹椂娓呯悊鍐呭�?   */
  private checkAndCleanupMemory(): void {
    const memoryUsage = this.memoryManager.getCurrentMemoryUsage();
    
    // 褰撳唴瀛樹娇鐢ㄨ秴�?5%鏃跺皾璇曟竻�?    if (memoryUsage > 0.85) {
      Logger.warn(TAG, `Memory usage high (${(memoryUsage * 100).toFixed(1)}%), attempting cleanup`);
      this.memoryManager.clearMemory();
      
      // 娓呯悊鍚庡啀娆℃锟?      const afterCleanupUsage = this.memoryManager.getCurrentMemoryUsage();
      const freedMemory = memoryUsage - afterCleanupUsage;
      
      if (freedMemory > 0.05) {
        Logger.info(TAG, `Memory cleanup successful: freed ${(freedMemory * 100).toFixed(1)}%`);
      }
    }
  }

  /**
   * 澶勭悊浠诲姟瀹屾�?   * @param task 浠诲姟瀵硅�?   * @param result 浠诲姟缁撴灉
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
   * 澶勭悊浠诲姟閿欒�?   * @param task 浠诲姟瀵硅�?   * @param error 閿欒瀵硅�?   */
  private handleTaskError(task: Task, error: Error): void {
    Logger.error(TAG, `Task ${task.id} failed: ${error.message}`);
    try {
      task.onError?.(error);
    } catch (callbackError) {
      Logger.error(TAG, `Error in task ${task.id} onError callback: ${callbackError instanceof Error ? callbackError.message : String(callbackError)}`);
    }
  }
}

export default TaskPoolManager.getInstance();







