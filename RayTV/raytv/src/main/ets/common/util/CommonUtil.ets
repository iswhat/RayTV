// 通用工具类
// 提供各种辅助函数

/**
 * 通用工具类
 */
export class CommonUtil {
  private static instance: CommonUtil;
  
  private constructor() {
    // 初始化
  }
  
  /**
   * 获取CommonUtil单例实例
   */
  public static getInstance(): CommonUtil {
    if (!CommonUtil.instance) {
      CommonUtil.instance = new CommonUtil();
    }
    return CommonUtil.instance;
  }
  
  /**
   * 获取对象的所有键
   * 替代Object.keys，兼容ArkTS语法
   */
  private getObjectKeys<T extends object>(obj: T): string[] {
    const keys: string[] = [];
    for (const key in obj) {
      if (Object.prototype.hasOwnProperty.call(obj, key)) {
        keys.push(key);
      }
    }
    return keys;
  }
  
  /**
   * 生成唯一ID
   * @param prefix ID前缀
   * @returns 唯一ID字符串
   */
  public generateUniqueId(prefix: string = 'id'): string {
    const timestamp = Date.now();
    const random = Math.random().toString(36).substr(2, 9);
    return `${prefix}_${timestamp}_${random}`;
  }
  
  /**
   * 深拷贝对象
   * @param obj 要拷贝的对象
   * @returns 拷贝后的新对象
   */
  public deepClone<T>(obj: T): T {
    if (obj === null || typeof obj !== 'object') {
      return obj;
    }
    
    if (obj instanceof Date) {
      return new Date(obj.getTime()) as T;
    }
    
    if (obj instanceof Array) {
      const clonedArray = [];
      for (const item of obj) {
        clonedArray.push(this.deepClone(item));
      }
      return clonedArray as T;
    }
    
    if (obj instanceof Object) {
      const clonedObj: Record<string, unknown> = {};
      // 使用getObjectKeys替代Object.keys
      const keys = this.getObjectKeys(obj);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (Object.prototype.hasOwnProperty.call(obj, key)) {
          clonedObj[key] = this.deepClone(obj[key]);
        }
      }
      return clonedObj as T;
    }
    
    return obj;
  }
  
  /**
   * 防抖函数
   * @param func 要防抖的函数
   * @param delay 延迟时间（毫秒）
   * @returns 防抖后的函数
   */
  public debounce<T extends (...args: unknown[]) => unknown>(func: T, delay: number): (...args: Parameters<T>) => void {
    let timeoutId: number | undefined;
    
    return (...args: Parameters<T>) => {
      clearTimeout(timeoutId);
      timeoutId = setTimeout(() => func.apply(null, args), delay);
    };
  }
  
  /**
   * 节流函数
   * @param func 要节流的函数
   * @param limit 时间限制（毫秒）
   * @returns 节流后的函数
   */
  public throttle<T extends (...args: unknown[]) => unknown>(func: T, limit: number): (...args: Parameters<T>) => void {
    let inThrottle: boolean = false;
    
    return (...args: Parameters<T>) => {
      if (!inThrottle) {
        func.apply(null, args);
        inThrottle = true;
        setTimeout(() => inThrottle = false, limit);
      }
    };
  }
  
  /**
   * 格式化时间
   * @param date 日期对象或时间戳
   * @param format 格式化字符串
   * @returns 格式化后的时间字符串
   */
  public formatDate(date: Date | number | string, format: string = 'YYYY-MM-DD HH:mm:ss'): string {
    const d = new Date(date);
    
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    const hours = String(d.getHours()).padStart(2, '0');
    const minutes = String(d.getMinutes()).padStart(2, '0');
    const seconds = String(d.getSeconds()).padStart(2, '0');
    
    return format
      .replace('YYYY', String(year))
      .replace('MM', month)
      .replace('DD', day)
      .replace('HH', hours)
      .replace('mm', minutes)
      .replace('ss', seconds);
  }
  
  /**
   * 格式化文件大小
   * @param bytes 字节数
   * @returns 格式化后的大小字符串
   */
  public formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B';
    
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    
    return `${(bytes / Math.pow(1024, i)).toFixed(2)} ${sizes[i]}`;
  }
  
  /**
   * 格式化播放时长
   * @param seconds 秒数
   * @returns 格式化后的时长字符串
   */
  public formatDuration(seconds: number): string {
    if (isNaN(seconds) || seconds < 0) {
      return '00:00';
    }
    
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = Math.floor(seconds % 60);
    
    if (hours > 0) {
      return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    } else {
      return `${String(minutes).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
    }
  }
  
  /**
   * 截断文本
   * @param text 文本内容
   * @param maxLength 最大长度
   * @param suffix 后缀
   * @returns 截断后的文本
   */
  public truncateText(text: string, maxLength: number, suffix: string = '...'): string {
    if (!text || text.length <= maxLength) {
      return text;
    }
    
    return text.substring(0, maxLength - suffix.length) + suffix;
  }
  
  /**
   * 验证邮箱格式
   * @param email 邮箱地址
   * @returns 是否为有效邮箱
   */
  public isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
  
  /**
   * 验证手机号格式
   * @param phone 手机号码
   * @returns 是否为有效手机号
   */
  public isValidPhone(phone: string): boolean {
    // 简单的中国手机号验证
    const phoneRegex = /^1[3-9]\d{9}$/;
    return phoneRegex.test(phone);
  }
  
  /**
   * 验证密码强度
   * @param password 密码
   * @returns 密码强度：0-弱，1-中，2-强
   */
  public checkPasswordStrength(password: string): 0 | 1 | 2 {
    let strength = 0;
    
    // 长度检查
    if (password.length >= 8) strength++;
    
    // 包含数字
    if (/\d/.test(password)) strength++;
    
    // 包含小写字母
    if (/[a-z]/.test(password)) strength++;
    
    // 包含大写字母
    if (/[A-Z]/.test(password)) strength++;
    
    // 包含特殊字符
    if (/[!@#$%^&*(),.?":{}|<>]/.test(password)) strength++;
    
    if (strength < 3) return 0;
    if (strength < 5) return 1;
    return 2;
  }
  
  /**
   * 随机打乱数组
   * @param array 要打乱的数组
   * @returns 打乱后的新数组
   */
  public shuffleArray<T>(array: T[]): T[] {
    // 使用slice替代spread操作符
    const shuffled = array.slice();
    
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    
    return shuffled;
  }
  
  /**
   * 数组去重
   * @param array 要去重的数组
   * @param key 用于比较的键（对象数组）
   * @returns 去重后的新数组
   */
  public uniqueArray<T>(array: T[], key?: keyof T): T[] {
    if (!array || array.length === 0) {
      return [];
    }
    
    if (key) {
      // 对象数组去重
      const seen = new Set();
      return array.filter(item => {
        const value = item[key];
        const isDuplicate = seen.has(value);
        seen.add(value);
        return !isDuplicate;
      });
    } else {
      // 原始类型数组去重
      return Array.from(new Set(array));
    }
  }
  
  /**
   * 延迟执行
   * @param ms 延迟毫秒数
   * @returns Promise
   */
  public delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  /**
   * 重试函数
   * @param fn 要重试的函数
   * @param retries 重试次数
   * @param delay 重试间隔（毫秒）
   * @returns 函数执行结果
   */
  public async retry<T>(fn: () => Promise<T>, retries: number = 3, delay: number = 1000): Promise<T> {
    try {
      return await fn();
    } catch (error) {
      if (retries <= 0) {
        throw error;
      }
      
      await this.delay(delay);
      return this.retry(fn, retries - 1, delay * 2);
    }
  }
  
  /**
   * 获取对象差异
   * @param obj1 对象1
   * @param obj2 对象2
   * @returns 差异对象
   */
  public getObjectDiff(obj1: Record<string, unknown>, obj2: Record<string, unknown>): Record<string, unknown> {
    const diff: Record<string, unknown> = {};
    
    // 使用getObjectKeys替代Object.keys
    const keys1 = this.getObjectKeys(obj1);
    for (let i = 0; i < keys1.length; i++) {
      const key = keys1[i];
      if (Object.prototype.hasOwnProperty.call(obj1, key)) {
        if (Object.prototype.hasOwnProperty.call(obj2, key)) {
          if (obj1[key] !== obj2[key]) {
            if (typeof obj1[key] === 'object' && typeof obj2[key] === 'object') {
              const nestedDiff = this.getObjectDiff(obj1[key], obj2[key]);
              if (this.getObjectKeys(nestedDiff).length > 0) {
                diff[key] = nestedDiff;
              }
            } else {
              diff[key] = obj2[key];
            }
          }
        } else {
          diff[key] = undefined;
        }
      }
    }
    
    // 使用getObjectKeys替代Object.keys
    const keys2 = this.getObjectKeys(obj2);
    for (let i = 0; i < keys2.length; i++) {
      const key = keys2[i];
      if (Object.prototype.hasOwnProperty.call(obj2, key) && !Object.prototype.hasOwnProperty.call(obj1, key)) {
        diff[key] = obj2[key];
      }
    }
    
    return diff;
  }
  
  /**
   * 合并对象
   * @param target 目标对象
   * @param sources 源对象
   * @returns 合并后的对象
   */
  public mergeObjects(target: Record<string, unknown>, ...sources: Record<string, unknown>[]): Record<string, unknown> {
    if (!sources.length) return target;
    
    const source = sources.shift();
    
    if (target && source && (typeof target === 'object' && typeof source === 'object')) {
      // 使用getObjectKeys替代Object.keys
      const keys = this.getObjectKeys(source);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (Object.prototype.hasOwnProperty.call(source, key)) {
          if (source[key] && typeof source[key] === 'object') {
            if (!target[key]) {
              // 手动创建新属性，避免使用Object.assign（ArkTS限制）
              target[key] = {};
            }
            this.mergeObjects(target[key] as Record<string, unknown>, source[key] as Record<string, unknown>);
          } else {
            // 手动设置属性值，避免使用Object.assign（ArkTS限制）
            target[key] = source[key];
          }
        }
      }
    }
    
    // 使用apply替代spread操作符
    return this.mergeObjects.apply(this, [target].concat(sources));
  }
  
  /**
   * 生成随机颜色
   * @param alpha 透明度
   * @returns 颜色字符串
   */
  public generateRandomColor(alpha: number = 1): string {
    const r = Math.floor(Math.random() * 256);
    const g = Math.floor(Math.random() * 256);
    const b = Math.floor(Math.random() * 256);
    
    if (alpha === 1) {
      return `rgb(${r}, ${g}, ${b})`;
    } else {
      return `rgba(${r}, ${g}, ${b}, ${alpha})`;
    }
  }
  
  /**
   * 十六进制颜色转RGB
   * @param hex 十六进制颜色
   * @returns RGB对象
   */
  public hexToRgb(hex: string): { r: number; g: number; b: number } | null {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
    
    return result ? {
      r: parseInt(result[1], 16),
      g: parseInt(result[2], 16),
      b: parseInt(result[3], 16)
    } : null;
  }
  
  /**
   * RGB颜色转十六进制
   * @param r 红色通道
   * @param g 绿色通道
   * @param b 蓝色通道
   * @returns 十六进制颜色字符串
   */
  public rgbToHex(r: number, g: number, b: number): string {
    return `#${[r, g, b].map(x => {
      const hex = x.toString(16);
      return hex.length === 1 ? '0' + hex : hex;
    }).join('')}`;
  }
  
  /**
   * 计算文本相似度（Levenshtein距离）
   * @param str1 文本1
   * @param str2 文本2
   * @returns 相似度（0-1）
   */
  public calculateSimilarity(str1: string, str2: string): number {
    if (str1 === str2) return 1;
    
    const len1 = str1.length;
    const len2 = str2.length;
    
    if (len1 === 0 || len2 === 0) return 0;
    
    const matrix: number[][] = [];
    
    // 初始化矩阵
    for (let i = 0; i <= len2; i++) {
      matrix[i] = [i];
    }
    
    for (let j = 0; j <= len1; j++) {
      matrix[0][j] = j;
    }
    
    // 填充矩阵
    for (let i = 1; i <= len2; i++) {
      for (let j = 1; j <= len1; j++) {
        const cost = str1[j - 1] === str2[i - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        );
      }
    }
    
    // 计算相似度
    const distance = matrix[len2][len1];
    const maxLen = Math.max(len1, len2);
    return 1 - distance / maxLen;
  }
  
  /**
   * 解析URL参数
   * @param url URL字符串
   * @returns 参数对象
   */
  public parseUrlParams(url: string): Record<string, string> {
    const params: Record<string, string> = {};
    const searchParams = new URL(url).searchParams;
    
    searchParams.forEach((value, key) => {
      params[key] = value;
    });
    
    return params;
  }
  
  /**
   * 构建URL
   * @param baseUrl 基础URL
   * @param params 查询参数
   * @returns 构建后的URL
   */
  public buildUrl(baseUrl: string, params?: Record<string, unknown>): string {
    if (!params || this.getObjectKeys(params).length === 0) {
      return baseUrl;
    }
    
    const queryString = Object.entries(params)
      .filter(([_, value]) => value !== undefined && value !== null)
      .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(String(value))}`)
      .join('&');
    
    const hasQuery = baseUrl.includes('?');
    return `${baseUrl}${hasQuery ? '&' : '?'}${queryString}`;
  }
  
  /**
   * 检查值是否为空
   * @param value 要检查的值
   * @returns 是否为空
   */
  public isEmpty(value: unknown): boolean {
    if (value === null || value === undefined) return true;
    if (typeof value === 'string') return value.trim() === '';
    if (Array.isArray(value)) return value.length === 0;
    if (typeof value === 'object') return this.getObjectKeys(value).length === 0;
    return false;
  }
  
  /**
   * 安全地获取嵌套属性
   * @param obj 对象
   * @param path 属性路径
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public getNestedProperty<T>(obj: unknown, path: string, defaultValue: T): T {
    const keys = path.split('.');
    let result = obj;
    
    for (const key of keys) {
      if (result === null || result === undefined || (typeof result !== 'object' && !Array.isArray(result))) {
        return defaultValue;
      }
      result = (result as Record<string, unknown>)[key];
    }
    
    return result !== undefined && result !== null ? result as T : defaultValue;
  }
  
  /**
   * 安全地设置嵌套属性
   * @param obj 对象
   * @param path 属性路径
   * @param value 属性值
   * @returns 是否设置成功
   */
  public setNestedProperty(obj: Record<string, unknown>, path: string, value: unknown): boolean {
    if (!obj || typeof obj !== 'object') return false;
    
    const keys = path.split('.');
    let current: Record<string, unknown> = obj;
    
    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      
      if (current[key] === undefined) {
        current[key] = {};
      } else if (typeof current[key] !== 'object') {
        return false;
      }
      
      current = current[key];
    }
    
    current[keys[keys.length - 1]] = value;
    return true;
  }
  
  /**
   * 计算数组中元素出现次数
   * @param array 数组
   * @returns 元素出现次数映射
   */
  public countOccurrences<T>(array: T[]): Record<string, number> {
    const counts: Record<string, number> = {};
    
    array.forEach(item => {
      const key = String(item);
      counts[key] = (counts[key] || 0) + 1;
    });
    
    return counts;
  }
  
  /**
   * 按属性对对象数组进行排序
   * @param array 数组
   * @param key 排序键
   * @param order 排序顺序
   * @returns 排序后的数组
   */
  public sortByProperty<T>(array: T[], key: keyof T, order: 'asc' | 'desc' = 'asc'): T[] {
    return [...array].sort((a, b) => {
      const valueA = a[key];
      const valueB = b[key];
      
      if (valueA < valueB) return order === 'asc' ? -1 : 1;
      if (valueA > valueB) return order === 'asc' ? 1 : -1;
      return 0;
    });
  }
  
  /**
   * 分组对象数组
   * @param array 数组
   * @param key 分组键或分组函数
   * @returns 分组后的映射
   */
  public groupBy<T>(array: T[], key: keyof T | ((item: T) => string)): Record<string, T[]> {
    const groups: Record<string, T[]> = {};
    
    array.forEach(item => {
      const groupKey = typeof key === 'function' ? key(item) : String(item[key]);
      
      if (!groups[groupKey]) {
        groups[groupKey] = [];
      }
      
      groups[groupKey].push(item);
    });
    
    return groups;
  }
  
  /**
   * 从数组中提取唯一的值列表
   * @param array 对象数组
   * @param key 属性键
   * @returns 唯一值数组
   */
  public extractUniqueValues<T, K extends keyof T>(array: T[], key: K): T[K][] {
    const values = array.map(item => item[key]);
    return this.uniqueArray(values);
  }
  
  /**
   * 检查是否为数字
   * @param value 要检查的值
   * @returns 是否为数字
   */
  public isNumber(value: unknown): boolean {
    return typeof value === 'number' && !isNaN(value);
  }
  
  /**
   * 检查是否为整数
   * @param value 要检查的值
   * @returns 是否为整数
   */
  public isInteger(value: unknown): boolean {
    return Number.isInteger(value);
  }
  
  /**
   * 限制数字在指定范围内
   * @param value 要限制的数字
   * @param min 最小值
   * @param max 最大值
   * @returns 限制后的数字
   */
  public clamp(value: number, min: number, max: number): number {
    return Math.min(Math.max(value, min), max);
  }
  
  /**
   * 线性插值
   * @param start 起始值
   * @param end 结束值
   * @param t 插值因子（0-1）
   * @returns 插值结果
   */
  public lerp(start: number, end: number, t: number): number {
    const clampedT = this.clamp(t, 0, 1);
    return start + (end - start) * clampedT;
  }
}

// 导出通用工具单例
export const commonUtil = CommonUtil.getInstance();

// 导出常用函数类型
export type { CommonUtil };