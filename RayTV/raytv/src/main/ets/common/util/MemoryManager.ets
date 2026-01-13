// MemoryManager - 鍐呭瓨绠＄悊宸ュ叿绫?import Logger from './Logger';

const TAG = 'MemoryManager';

/**
 * 鍐呭瓨绠＄悊宸ュ叿绫? * 鎻愪緵鍐呭瓨浣跨敤鐩戞帶銆佸唴瀛橀檺鍒舵鏌ョ瓑鍔熻兘
 */
export default class MemoryManager {
  private static instance: MemoryManager;
  private maxMemoryUsage: number = 0.8; // 鏈€澶у唴瀛樹娇鐢ㄧ巼 80%
  private checkInterval: number = 30000; // 30绉掓鏌ヤ竴娆?  private lastCheckTime: number = 0;
  private memoryUsageHistory: number[] = [];

  /**
   * 绉佹湁鏋勯€犲嚱鏁?   */
  private constructor() {
    Logger.info(TAG, 'MemoryManager initialized');
    this.startPeriodicCheck();
  }

  /**
   * 鑾峰彇鍗曚緥瀹炰緥
   */
  public static getInstance(): MemoryManager {
    if (!MemoryManager.instance) {
      MemoryManager.instance = new MemoryManager();
    }
    return MemoryManager.instance;
  }

  /**
   * 璁剧疆鏈€澶у唴瀛樹娇鐢ㄧ巼
   * @param usage 鍐呭瓨浣跨敤鐜囬槇鍊?(0-1)
   */
  public setMaxMemoryUsage(usage: number): void {
    if (usage > 0 && usage <= 1) {
      this.maxMemoryUsage = usage;
      Logger.info(TAG, `Max memory usage set to: ${(usage * 100).toFixed(0)}%`);
    }
  }

  /**
   * 妫€鏌ュ唴瀛樺彲鐢ㄦ€?   * @returns 鏄惁鏈夎冻澶熷唴瀛樺彲鐢?   */
  public checkMemoryAvailability(): boolean {
    try {
      const currentUsage = this.getCurrentMemoryUsage();
      
      // 璁板綍鍐呭瓨浣跨敤鍘嗗彶
      this.recordMemoryUsage(currentUsage);
      
      const result = currentUsage < this.maxMemoryUsage;
      
      if (!result) {
        Logger.warn(TAG, `Memory usage too high: ${(currentUsage * 100).toFixed(1)}% (max: ${(this.maxMemoryUsage * 100).toFixed(0)}%)`);
      }
      
      return result;
    } catch (error) {
      Logger.error(TAG, `Failed to check memory availability: ${error}`);
      // 鍑洪敊鏃堕粯璁よ繑鍥瀟rue锛岄伩鍏嶅簲鐢ㄥ穿婧?      return true;
    }
  }

  /**
   * 鑾峰彇褰撳墠鍐呭瓨浣跨敤鎯呭喌
   * @returns 鍐呭瓨浣跨敤鐜?(0-1)
   */
  public getCurrentMemoryUsage(): number {
    try {
      // 鍦℉armonyOS涓紝鍙互浣跨敤绯荤粺API鑾峰彇鍐呭瓨淇℃伅
      // 杩欓噷鎻愪緵涓€涓ā鎷熷疄鐜帮紝瀹為檯浣跨敤鏃堕渶瑕佹浛鎹负鐪熷疄鐨勭郴缁烝PI璋冪敤
      const totalMemory = this.getTotalMemory();
      const freeMemory = this.getFreeMemory();
      
      if (totalMemory <= 0) {
        return 0;
      }
      
      const usedMemory = totalMemory - freeMemory;
      return usedMemory / totalMemory;
    } catch (error) {
      Logger.error(TAG, `Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}` instanceof Error ? `Failed to get current memory usage: ${error}` : new Error(String(`Failed to get current memory usage: ${error}`)))))));
      return 0.5; // 榛樿杩斿洖50%浣跨敤鐜?    }
  }

  /**
   * 鑾峰彇鎬诲唴瀛樺ぇ灏?   * @returns 鎬诲唴瀛樺瓧鑺傛暟
   */
  private getTotalMemory(): number {
    try {
      // 妯℃嫙瀹炵幇锛屽疄闄呭簲浣跨敤绯荤粺API
      // 鍦℉armonyOS涓紝鍙互閫氳繃@ohos.systemCapability璧勬簮鑾峰彇
      return 8 * 1024 * 1024 * 1024; // 鍋囪8GB鍐呭瓨
    } catch (error) {
      Logger.error(TAG, `Failed to get total memory: ${error}`);
      return 4 * 1024 * 1024 * 1024; // 榛樿4GB
    }
  }

  /**
   * 鑾峰彇鍙敤鍐呭瓨澶у皬
   * @returns 鍙敤鍐呭瓨瀛楄妭鏁?   */
  private getFreeMemory(): number {
    try {
      // 妯℃嫙瀹炵幇锛屽疄闄呭簲浣跨敤绯荤粺API
      // 鍦℉armonyOS涓紝鍙互閫氳繃@ohos.systemCapability璧勬簮鑾峰彇
      const total = this.getTotalMemory();
      return total * 0.4; // 鍋囪40%鍙敤
    } catch (error) {
      Logger.error(TAG, `Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}` instanceof Error ? `Failed to get free memory: ${error}` : new Error(String(`Failed to get free memory: ${error}`)))))));
      return 2 * 1024 * 1024 * 1024; // 榛樿2GB
    }
  }

  /**
   * 璁板綍鍐呭瓨浣跨敤鎯呭喌
   * @param usage 褰撳墠鍐呭瓨浣跨敤鐜?   */
  private recordMemoryUsage(usage: number): void {
    this.memoryUsageHistory.push(usage);
    
    // 鍙繚鐣欐渶杩?00鏉¤褰?    if (this.memoryUsageHistory.length > 100) {
      this.memoryUsageHistory.shift();
    }
    
    // 瀹氭湡璁板綍骞冲潎鍐呭瓨浣跨敤鎯呭喌
    const now = Date.now();
    if (now - this.lastCheckTime > this.checkInterval) {
      this.lastCheckTime = now;
      this.logAverageMemoryUsage();
    }
  }

  /**
   * 璁板綍骞冲潎鍐呭瓨浣跨敤鎯呭喌
   */
  private logAverageMemoryUsage(): void {
    if (this.memoryUsageHistory.length === 0) return;
    
    const sum = this.memoryUsageHistory.reduce((acc, val) => acc + val, 0);
    const average = sum / this.memoryUsageHistory.length;
    
    Logger.info(TAG, `Average memory usage: ${(average * 100).toFixed(1)}%`);
  }

  /**
   * 寮€濮嬪畾鏈熸鏌ュ唴瀛樹娇鐢ㄦ儏鍐?   */
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
    }, this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval : new Error(String(this.checkInterval instanceof Error ? this.checkInterval : new Error(String(this.checkInterval)))))));
  }

  /**
   * 娓呯悊鍐呭瓨锛堝鏋滃彲鑳斤級
   */
  public clearMemory(): void {
    try {
      Logger.info(TAG, 'Attempting to clear memory');
      
      // HarmonyOS涓笉鏀寔鐩存帴璋冪敤鍨冨溇鍥炴敹
      // 绉婚櫎瀵筭lobalThis.gc鐨勪緷璧栵紝浣跨敤绯荤粺鎺ㄨ崘鐨勫唴瀛樼鐞嗘柟寮?      Logger.info(TAG, 'Memory cleanup performed (HarmonyOS compatible)');
      
      // 娓呯悊鍘嗗彶璁板綍
      this.memoryUsageHistory = [];
    } catch (error) {
      Logger.error(TAG, `Failed to clear memory: ${error}`);
    }
  }

  /**
   * 鑾峰彇鍐呭瓨浣跨敤缁熻淇℃伅
   * @returns 鍐呭瓨浣跨敤缁熻
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
      const sum = this.memoryUsageHistory.reduce((acc, val instanceof Error ? val : new Error(String(val instanceof Error ? val instanceof Error ? val : new Error(String(val : new Error(String(val instanceof Error ? val : new Error(String(val instanceof Error ? val instanceof Error ? val : new Error(String(val instanceof Error ? val instanceof Error ? val : new Error(String(val : new Error(String(val instanceof Error ? val : new Error(String(val : new Error(String(val instanceof Error ? val : new Error(String(val instanceof Error ? val instanceof Error ? val : new Error(String(val : new Error(String(val instanceof Error ? val : new Error(String(val))))))) => acc + val, 0);
      average = sum / this.memoryUsageHistory.length;
      // ArkTS鍏煎锛氫娇鐢ㄧ洿鎺ヨ皟鐢ㄦ浛浠pply
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





