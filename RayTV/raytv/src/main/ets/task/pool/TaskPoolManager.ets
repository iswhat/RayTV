// TaskPoolManager - 娴犺濮熷Ч鐘殿吀閻炲棗娅?import Logger from '../../common/util/Logger';
import taskPool from '@ohos.taskpool';
import MemoryManager from '../../common/util/MemoryManager';

const TAG = 'TaskPoolManager';

/**
 * 娴犺濮熸导妯哄帥缁狙勭亣閿? */
export enum TaskPriority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2,
  CRITICAL = 3
}

/**
 * 娴犺濮熼悩鑸碘偓浣圭亣閿? */
export enum TaskStatus {
  PENDING = 'pending',
  RUNNING = 'running',
  COMPLETED = 'completed',
  FAILED = 'failed',
  CANCELLED = 'cancelled'
}

/**
 * 娴犺濮熼幒銉ュ經鐎规矮绠? */
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
 * 娴犺濮熷Ч鐘殿吀閻炲棗娅? * 閹绘劒绶甸崺杞扮艾TaskPool閻ㄥ嫪鎹㈤崝陇鐨熸惔锕€鎷扮粻锛勬倞閸旂喕鍏? */
export class TaskPoolManager {
  static instance: TaskPoolManager;
  taskQueue: Task[] = [];
  runningTasks: Map<string, Task> = new Map();
  maxConcurrentTasks: number = 3;
  isProcessing: boolean = false;
  memoryManager: MemoryManager;

  /**
   * 閺嬪嫰鈧姴鍤遍敓?   */
  constructor() {
    Logger.info(TAG, 'TaskPoolManager initialized');
    this.memoryManager = MemoryManager.getInstance();
  }

  /**
   * 閼惧嘲褰囬崡鏇氱伐鐎圭偘绶?   */
  static getInstance(): TaskPoolManager {
    if (!TaskPoolManager.instance) {
      TaskPoolManager.instance = new TaskPoolManager();
    }
    return TaskPoolManager.instance;
  }

  /**
   * 鐠佸墽鐤嗛張鈧径褍鑻熼崣鎴滄崲閸斺剝鏆?   * @param max 閺堚偓婢堆冭嫙閸欐垳鎹㈤崝鈩冩殶
   */
  setMaxConcurrentTasks(max: number): void {
    if (max > 0) {
      this.maxConcurrentTasks = max;
      Logger.info(TAG, `Max concurrent tasks set to: ${max}`);
      // 闁插秵鏌婃径鍕倞闂冪喎鍨?      this.processQueue();
    }
  }

  /**
   * 閹绘劒姘︽禒璇插閸掍即妲﹂敓?   * @param task 娴犺濮熺€电钖?   */
  submit<T = unknown>(task: Task<T>): void {
    if (!task || !task.execute) {
      Logger.error(TAG, 'Invalid task submitted');
      return;
    }

    // 濞ｈ濮為崚棰佹崲閸旓繝妲﹂敓?    this.taskQueue.push(task);
    Logger.debug(TAG, `Task ${task.id} submitted with priority: ${task.priority}`);

    // 閹稿绱崗鍫㈤獓閹烘帒绨?    this.sortTasks();

    // 瀵偓婵顦╅悶鍡涙Е閿?    this.processQueue();
  }
  
  /**
   * 鐏忓棜鍤滅€规矮绠熸导妯哄帥缁狙嗘祮閹诡澀璐烼askPool娴兼ê鍘涢敓?   * @param priority 閼奉亜鐣炬稊澶夌喘閸忓牏楠?   * @returns taskPool.Priority 鐎电懓绨查惃鍑綼skPool娴兼ê鍘涢敓?   */
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
   * 閹笛嗩攽閸楁洑閲滄禒璇插
   * @param task 鐟曚焦澧界悰宀€娈戞禒璇插
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
   * 閸欐牗绉锋禒璇插
   * @param taskId 娴犺濮烮D
   * @returns 閺勵垰鎯侀幋鎰閸欐牗绉?   */
  cancelTask(taskId: string): boolean {
    // 濡偓閺屻儴绻嶇悰灞艰厬閻ㄥ嫪鎹㈤敓?    const runningTask = this.runningTasks.get(taskId);
    if (runningTask) {
      // 閺嶅洩顔囨稉鍝勫絿濞戝牏濮搁敓?      this.runningTasks.delete(taskId);
      try {
        runningTask.onCancel?.();
      } catch (error) {
        Logger.error(TAG, `Error in task ${taskId} onCancel callback: ${(error as Error).message}`);
      }
      Logger.info(TAG, `Running task ${taskId} cancelled`);
      return true;
    }

    // 濡偓閺屻儵妲﹂崚妞捐厬閻ㄥ嫪鎹㈤敓?    const index = this.taskQueue.findIndex(task => task.id === taskId);
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
   * 濞撳懐鈹栨禒璇插闂冪喎鍨?   */
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
   * 閼惧嘲褰囨禒璇插閻樿鎷?   * @param taskId 娴犺濮烮D
   * @returns 娴犺濮熼悩鑸碘偓渚婄礉婵″倹鐏夋禒璇插娑撳秴鐡ㄩ崷銊ㄧ箲閸ョ€梪ll
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
   * 閼惧嘲褰囪ぐ鎾冲鏉╂劘顢戞稉顓犳畱娴犺濮熼弫浼村櫤
   */
  public getRunningTaskCount(): number {
    return this.runningTasks.size;
  }

  /**
   * 閼惧嘲褰囪ぐ鎾冲闂冪喎鍨稉顓犳畱娴犺濮熼弫浼村櫤
   */
  public getQueuedTaskCount(): number {
    return this.taskQueue.length;
  }

  /**
   * 閹稿绱崗鍫㈤獓閹烘帒绨禒璇插闂冪喎鍨?   */
  private sortTasks(): void {
    this.taskQueue.sort((a, b) => b.priority - a.priority);
  }

  /**
   * 婢跺嫮鎮婃禒璇插闂冪喎鍨?   */
  private processQueue(): void {
    if (this.isProcessing) return;
    
    this.isProcessing = true;
    
    try {
      // 閸斻劍鈧浇鐨熼弫鏉戣嫙閸欐垳鎹㈤崝鈩冩殶閸╄桨绨崘鍛摠娴ｈ法鏁ら幆鍛枌
      const memoryStats = this.memoryManager.getMemoryStats();
      const adjustedMaxConcurrentTasks = this.calculateOptimalConcurrentTasks(memoryStats.currentUsage);
      
      // 閹笛嗩攽鐏忚棄褰查懗钘夘樋閻ㄥ嫬鑻熼崣鎴滄崲閿?      while (
        this.runningTasks.size < adjustedMaxConcurrentTasks &&
        this.taskQueue.length > 0
      ) {
        // 閸︺劍鐦″▎鈩冨⒔鐞涘奔鎹㈤崝鈥冲闁插秵鏌婂Λ鈧弻銉ュ敶鐎涙ê褰查悽顭掓嫹?        if (!this.memoryManager.checkMemoryAvailability()) {
          Logger.warn(TAG, `Insufficient memory to process tasks (${(memoryStats.currentUsage * 100).toFixed(1)}%), pausing queue`);
          // 鐏忔繆鐦〒鍛倞閸愬懎鐡?          this.memoryManager.clearMemory();
          // 瀵ゆ儼绻滈柌宥堢槸閿涘本鐗撮幑顔煎敶鐎涙ü濞囬悽銊﹀剰閸愰潧濮╅幀浣界殶閺佹潙娆㈡潻鐔告閿?          const retryDelay = this.calculateRetryDelay(memoryStats.currentUsage);
          setTimeout(() => this.processQueue(), retryDelay);
          return;
        }
        
        const task = this.taskQueue.shift();
        if (task) {
          this.executeTask(task);
        }
      }
      
      // 婵″倹鐏夐梼鐔峰灙娑撳秳璐熺粚杞扮稻濞屸剝婀侀幍褑顢戞禒璇插閿涘苯褰查懗鑺ユЦ閸ョ姳璐熼崘鍛摠娑撳秷鍐?      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        Logger.info(TAG, `Task queue has ${this.taskQueue.length} tasks, but running at capacity (${this.runningTasks.size}/${adjustedMaxConcurrentTasks})`);
      }
    } finally {
      this.isProcessing = false;
      
      // 婵″倹鐏夋潻妯绘箒娴犺濮熼崷銊╂Е閸掓ぞ鑵戞稉鏃€鐥呴張澶庢彧閸掔増娓舵径褍鑻熼崣鎴炴殶閿涘瞼鎴风紒顓烆槱閿?      if (this.taskQueue.length > 0 && this.runningTasks.size < this.maxConcurrentTasks) {
        setTimeout(() => this.processQueue(), 0);
      }
    }
  }
  
  /**
   * 閺嶈宓侀崘鍛摠娴ｈ法鏁ら幆鍛枌鐠侊紕鐣婚張鈧担鍐茶嫙閸欐垳鎹㈤崝鈩冩殶
   * @param memoryUsage 瑜版挸澧犻崘鍛摠娴ｈ法鏁ら敓?   * @returns 鐠嬪啯鏆ｉ崥搴ｆ畱閺堚偓婢堆冭嫙閸欐垳鎹㈤崝鈩冩殶
   */
  private calculateOptimalConcurrentTasks(memoryUsage: number): number {
    // 閸愬懎鐡ㄦ担璺ㄦ暏閻滃洣缍嗛敓?0%閿涙矮濞囬悽銊︽付婢堆冭嫙閸欐垶鏆?    if (memoryUsage < 0.5) {
      return this.maxConcurrentTasks;
    }
    // 閸愬懎鐡ㄦ担璺ㄦ暏閿?0%-70%閿涙矮濞囬敓?5%閻ㄥ嫭娓舵径褍鑻熼崣鎴炴殶
    else if (memoryUsage < 0.7) {
      return Math.max(1, Math.floor(this.maxConcurrentTasks * 0.75));
    }
    // 閸愬懎鐡ㄦ担璺ㄦ暏閿?0%-85%閿涙矮濞囬敓?0%閻ㄥ嫭娓舵径褍鑻熼崣鎴炴殶
    else if (memoryUsage < 0.85) {
      return Math.max(1, Math.floor(this.maxConcurrentTasks * 0.5));
    }
    // 閸愬懎鐡ㄦ担璺ㄦ暏閻滃洭鐝敓?5%閿涙艾褰ч崗浣筋啅1娑擃亜鑻熼崣鎴滄崲閿?    else {
      return 1;
    }
  }
  
  /**
   * 閺嶈宓侀崘鍛摠娴ｈ法鏁ら幆鍛枌鐠侊紕鐣婚柌宥堢槸瀵ゆ儼绻?   * @param memoryUsage 瑜版挸澧犻崘鍛摠娴ｈ法鏁ら敓?   * @returns 闁插秷鐦鎯扮箿閺冨爼妫块敍鍫燁嚑缁夋帪绱?   */
  private calculateRetryDelay(memoryUsage: number): number {
    // 閸愬懎鐡ㄦ担璺ㄦ暏鐡掑﹪鐝敍宀勫櫢鐠囨洖娆㈡潻鐔荤Ш閿?    if (memoryUsage < 0.7) return 1000;     // 70%娴犮儰绗呴敓?閿?    if (memoryUsage < 0.8) return 2000;     // 70%-80%閿?閿?    if (memoryUsage < 0.9) return 3000;     // 80%-90%閿?閿?    return 5000;                            // 90%娴犮儰绗傞敓?閿?  }

  /**
   * 閹笛嗩攽閸楁洑閲滄禒璇插
   * @param task 鐟曚焦澧界悰宀€娈戞禒璇插
   */
  private async executeTask(task: Task): Promise<void> {
    if (!task.id) {
      task.id = `task_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    }

    this.runningTasks.set(task.id, task);
    Logger.debug(TAG, `Task ${task.id} started execution with priority ${task.priority}`);
    
    // 鐠佹澘缍嶆禒璇插瀵偓婵澧犻惃鍕敶鐎涙ü濞囬悽銊﹀剰閿?    const startMemoryUsage = this.memoryManager.getCurrentMemoryUsage();
    const startTime = Date.now();

    try {
      // 閺嶈宓佹禒璇插娴兼ê鍘涚痪褍鎷伴崘鍛摠閹懎鍠岄崝銊︹偓浣界殶閺佺繝鎹㈤崝锟犲帳閿?      const memoryStats = this.memoryManager.getMemoryStats();
      const taskOptions = this.createOptimizedTaskOptions(task.priority, memoryStats);
      
      // 娴ｈ法鏁askPool閹笛嗩攽娴犺濮熼敍灞界杽閻滄壆婀″锝囨畱缁崵绮虹痪褍鑻熼敓?      const taskFunction = async () => {
        try {
          return await task.execute();
        } catch (error) {
          Logger.error(TAG, `Task function execution error: ${error instanceof Error ? error.message : String(error)}`);
          throw error;
        }
      };

      // 閹笛嗩攽娴犺濮?      const result = await taskPool.execute(taskFunction, taskOptions);
      
      // 婢跺嫮鎮婄€瑰本鍨?      this.handleTaskComplete(task, result);
      
      // 鐠佹澘缍嶆禒璇插鐎瑰本鍨氶崥搴ｆ畱閸愬懎鐡ㄦ担璺ㄦ暏閹懎鍠岄敍宀€娲冮幒褍鍞寸€涙ɑ纭犻敓?      this.logTaskMemoryUsage(task.id, startMemoryUsage, startTime);
    } catch (error) {
      // 婢跺嫮鎮婇柨娆掝嚖
      this.handleTaskError(task, error as Error);
    } finally {
      // 娴犲氦绻嶇悰灞艰厬娴犺濮熺粔濠氭珟
      this.runningTasks.delete(task.id);
      
      // 閸︺劋鎹㈤崝鈥崇暚閹存劕鎮楅崘宥嗩偧濡偓閺屻儱鍞寸€涙﹫绱濇俊鍌涚亯閸愬懎鐡ㄦ担璺ㄦ暏鏉╁洭鐝亸婵婄槸濞撳懐鎮?      this.checkAndCleanupMemory();
      
      // 缂佈呯敾婢跺嫮鎮婇梼鐔峰灙
      this.processQueue();
    }
  }
  
  /**
   * 閸掓稑缂撴导妯哄閻ㄥ嫪鎹㈤崝锟犫偓澶愩€?   * @param priority 娴犺濮熸导妯哄帥閿?   * @param memoryStats 閸愬懎鐡ㄧ紒鐔活吀娣団剝浼?   * @returns 娴兼ê瀵查惃鍕崲閸旓繝鈧銆?   */
  private createOptimizedTaskOptions(priority: TaskPriority, memoryStats: { currentUsage: number }): taskPool.TaskOptions {
    const taskOptions: taskPool.TaskOptions = {
      priority: this.getTaskPoolPriority(priority)
    };
    
    // 閸︺劌鍞寸€涙鎻ｅ鐘虫閿涘苯顕担搴濈喘閸忓牏楠囨禒璇插鎼存梻鏁ら弴缈犲紬閺嶈偐娈戠挧鍕爱闂勬劕鍩?    if (memoryStats.currentUsage > 0.8 && priority <= TaskPriority.NORMAL) {
      Logger.info(TAG, `Applying resource limits for low priority task due to high memory usage (${(memoryStats.currentUsage * 100).toFixed(1)}%)`);
      // 濞夈劍鍓伴敍姝峚skPool閸欘垵鍏樻稉宥囨纯閹恒儲鏁幐浣界箹娴滄盯鈧銆嶉敍宀冪箹闁插奔绮庢担婊€璐熺粈杞扮伐
      // taskOptions.maxMemoryUsage = 0.1; // 闂勬劕鍩楁禒璇插閸愬懎鐡ㄦ担璺ㄦ暏
    }
    
    return taskOptions;
  }
  
  /**
   * 鐠佹澘缍嶆禒璇插閻ㄥ嫬鍞寸€涙ü濞囬悽銊﹀剰閿?   * @param taskId 娴犺濮烮D
   * @param startUsage 瀵偓婵妞傞惃鍕敶鐎涙ü濞囬悽銊у芳
   * @param startTime 瀵偓婵妞傞敓?   */
  private logTaskMemoryUsage(taskId: string, startUsage: number, startTime: number): void {
    const endUsage = this.memoryManager.getCurrentMemoryUsage();
    const duration = Date.now() - startTime;
    const memoryDiff = endUsage - startUsage;
    
    // 婵″倹鐏夐崘鍛摠娴ｈ法鏁ゆ晶鐐插閿?%娴犮儰绗傞敍宀冾唶瑜版洝顒熼敓?    if (memoryDiff > 0.05) {
      Logger.warn(TAG, `Task ${taskId} may be leaking memory: memory usage increased by ${(memoryDiff * 100).toFixed(1)}%`);
    }
    
    if (duration > 10000) { // 娴犺濮熼幍褑顢戠搾鍛扮箖10閿?      Logger.info(TAG, `Long-running task ${taskId} completed in ${duration}ms`);
    }
  }
  
  /**
   * 濡偓閺屻儱鑻熼崷銊╂付鐟曚焦妞傚〒鍛倞閸愬懎鐡?   */
  private checkAndCleanupMemory(): void {
    const memoryUsage = this.memoryManager.getCurrentMemoryUsage();
    
    // 瑜版挸鍞寸€涙ü濞囬悽銊ㄧТ閿?5%閺冭泛鐨剧拠鏇熺閿?    if (memoryUsage > 0.85) {
      Logger.warn(TAG, `Memory usage high (${(memoryUsage * 100).toFixed(1)}%), attempting cleanup`);
      this.memoryManager.clearMemory();
      
      // 濞撳懐鎮婇崥搴″晙濞嗏剝顥呴敓?      const afterCleanupUsage = this.memoryManager.getCurrentMemoryUsage();
      const freedMemory = memoryUsage - afterCleanupUsage;
      
      if (freedMemory > 0.05) {
        Logger.info(TAG, `Memory cleanup successful: freed ${(freedMemory * 100).toFixed(1)}%`);
      }
    }
  }

  /**
   * 婢跺嫮鎮婃禒璇插鐎瑰本鍨?   * @param task 娴犺濮熺€电钖?   * @param result 娴犺濮熺紒鎾寸亯
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
   * 婢跺嫮鎮婃禒璇插闁挎瑨顕?   * @param task 娴犺濮熺€电钖?   * @param error 闁挎瑨顕ょ€电钖?   */
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







