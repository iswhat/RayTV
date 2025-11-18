// TypeSafetyUtil - 类型安全工具类
// 提供安全的类型转换和验证功能

/**
 * 类型安全工具类
 * 提供安全的类型转换和验证方法
 */
export class TypeSafetyUtil {
  /**
   * 安全处理错误对象，确保返回有效的Error实例
   * @param error 错误对象或值
   * @param message 可选的自定义错误消息前缀
   * @returns 规范化的Error实例
   */
  public static safeError(error: unknown, message?: string): Error {
    if (error instanceof Error) {
      if (message) {
        // 如果提供了自定义消息，则创建一个新的Error实例
        return new Error(`${message}: ${error.message}`, { cause: error });
      }
      return error;
    }
    // 对于非Error类型的值，转换为字符串并创建新的Error实例
    const errorStr = String(error);
    return message ? new Error(`${message}: ${errorStr}`) : new Error(errorStr);
  }

  /**
   * 安全地访问对象属性
   * @param obj 要访问的对象
   * @param key 属性名
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static safeAccess<T extends object, K extends keyof T, D>(
    obj: T | null | undefined,
    key: K | string | number,
    defaultValue: D
  ): T[K] | D {
    if (obj === null || obj === undefined) {
      return defaultValue;
    }
    
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      return obj[key as keyof T];
    }
    
    return defaultValue;
  }

  /**
   * 安全地设置对象属性
   * @param obj 要设置属性的对象
   * @param key 属性名
   * @param value 属性值
   * @returns 是否设置成功
   */
  public static safeSet<T extends object>(
    obj: T | null | undefined,
    key: string | number,
    value: unknown
  ): boolean {
    if (obj === null || obj === undefined || typeof obj !== 'object') {
      return false;
    }
    
    try {
      (obj as Record<string, unknown>)[key] = value;
      return true;
    } catch {
      return false;
    }
  }
  
  /**
   * 安全地处理属性名，确保它是有效的标识符
   * @param propertyName 原始属性名
   * @returns 安全的属性名
   */
  public static safePropertyName(propertyName: string): string {
    // 如果已经是有效的标识符，直接返回
    if (/^[a-zA-Z_$][a-zA-Z0-9_$]*$/.test(propertyName)) {
      return propertyName;
    }
    
    // 对于非标识符属性名，进行安全处理
    // 1. 替换特殊字符为下划线
    let safeName = propertyName.replace(/[^a-zA-Z0-9_$]/g, '_');
    
    // 2. 确保不以数字开头
    if (/^[0-9]/.test(safeName)) {
      safeName = '_' + safeName;
    }
    
    return safeName;
  }
  
  /**
   * 创建带有安全属性名的对象
   * @param obj 原始对象
   * @returns 带有安全属性名的新对象
   */
  public static createSafeObject(obj: Record<string, unknown>): Record<string, unknown> {
    const safeObj: Record<string, unknown> = {};
    
    for (const [key, value] of Object.entries(obj)) {
      const safeKey = TypeSafetyUtil.safePropertyName(key);
      safeObj[safeKey] = value;
    }
    
    return safeObj;
  }
  
  /**
   * 泛型类型推断辅助函数，帮助TypeScript更好地推断泛型类型
   * @param value 要包装的值
   * @returns 包装后的对象，保留原始类型信息
   */
  public static withType<T>(value: T): { value: T } {
    return { value };
  }
  
  /**
   * 增强的类型守卫函数，提供更精确的类型推断
   * @param value 要检查的值
   * @param guard 类型守卫函数
   * @returns 经过类型守卫后的值
   */
  public static narrowType<T extends U, U = unknown>(value: U, guard: (v: U) => v is T): T | null {
    return guard(value) ? value : null;
  }
  
  /**
   * 安全地进行类型转换，提供运行时类型检查和编译时类型推断
   * @param value 要转换的值
   * @param transformer 转换函数
   * @param guard 可选的类型守卫函数，用于验证转换结果
   * @returns 转换后的值或默认值
   */
  public static safeCast<T, U>(
    value: T,
    transformer: (v: T) => U,
    guard?: (v: U) => boolean,
    defaultValue?: U
  ): U | null {
    try {
      const result = transformer(value);
      if (guard && !guard(result)) {
        return defaultValue ?? null;
      }
      return result;
    } catch {
      return defaultValue ?? null;
    }
  }
  
  /**
   * 泛型工厂函数辅助方法，帮助创建具有精确类型的对象
   * @param factory 工厂函数
   * @param args 工厂函数参数
   * @returns 工厂函数创建的对象
   */
  public static createWithType<T>(factory: (...args: unknown[]) => T, ...args: unknown[]): T | null {
    try {
      return factory(...args);
    } catch {
      return null;
    }
  }
  
  /**
   * 安全地进行类型断言
   * 用于解决泛型函数调用类型推断受限的问题
   * @param value 要断言的值
   * @param typeGuard 可选的类型守卫函数
   * @returns 断言后的类型
   */
  public static asType<T>(value: unknown, typeGuard?: (value: unknown) => value is T): T {
    // 如果提供了类型守卫函数，使用它来验证类型
    if (typeGuard && !typeGuard(value)) {
      console.warn('Type assertion failed: value does not match the expected type');
    }
    
    // 执行类型断言
    return value as T;
  }
  
  /**
   * 创建增强的泛型函数，解决类型推断受限问题
   * @param fn 原始函数
   * @returns 包装后的函数，具有更好的类型推断
   */
  public static createEnhancedGenericFunction<T extends (...args: any[]) => any>(fn: T): T {
    return function(this: any, ...args: any[]): ReturnType<T> {
      return fn.apply(this, args);
    } as T;
  }
  /**
   * 安全地将值转换为对象
   * @param value 要转换的值
   * @returns 如果是对象则返回对象，否则返回空对象
   */
  public static asObject(value: unknown): Record<string, unknown> {
    if (value === null || value === undefined) {
      return {};
    }
    if (typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }
    return {};
  }

  /**
   * 安全地将值转换为数组
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的数组或默认值
   */
  public static asArray<T = unknown>(value: unknown, defaultValue: T[] = []): T[] {
    if (Array.isArray(value)) {
      // 避免类型断言，返回类型安全的数组
      return [...value] as T[];
    }
    return [];
  }

  /**
   * 安全地将值转换为字符串
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的字符串
   */
  public static asString(value: unknown, defaultValue: string = ''): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * 安全地将值转换为数字
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的数字
   */
  public static asNumber(value: unknown, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    
    // 使用类型守卫确保安全转换
    if (typeof value === 'number') {
      return isFinite(value) ? value : defaultValue;
    }
    
    const num = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  /**
   * 安全地将值转换为布尔值
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的布尔值
   */
  public static asBoolean(value: unknown, defaultValue: boolean = false): boolean {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Boolean(value);
  }

  /**
   * 安全地从对象中获取属性，提供类型检查
   * @param obj 对象
   * @param key 属性名
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static getProperty<T>(
    obj: unknown,
    key: string,
    defaultValue: T
  ): T {
    const safeObj = TypeSafetyUtil.asObject(obj);
    
    // 使用hasOwnProperty确保属性安全访问
    if (!Object.prototype.hasOwnProperty.call(safeObj, key)) {
      return defaultValue;
    }
    
    const value = safeObj[key];
    
    // 检查值是否为null或undefined
    if (value === null || value === undefined) {
      return defaultValue;
    }
    
    return value as T ?? defaultValue;
  }

  /**
   * 安全地从对象中获取嵌套属性
   * @param obj 对象
   * @param path 属性路径，如 'user.profile.name'
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static getNestedProperty<T>(
    obj: unknown,
    path: string,
    defaultValue: T
  ): T {
    if (!path || typeof path !== 'string') {
      return defaultValue;
    }
    
    const keys = path.split('.');
    let current: unknown = obj;
    
    for (const key of keys) {
      if (current === null || current === undefined) {
        return defaultValue;
      }
      
      const safeObj = TypeSafetyUtil.asObject(current);
      
      // 使用hasOwnProperty确保属性安全访问
      if (!Object.prototype.hasOwnProperty.call(safeObj, key)) {
        return defaultValue;
      }
      
      current = (safeObj as Record<string, unknown>)[key];
    }
    
    // 尝试类型转换
    if (current === null || current === undefined) {
      return defaultValue;
    }
    
    return current as T;
  }

  /**
   * 安全地设置对象的属性
   * @param obj 对象
   * @param key 属性名
   * @param value 值
   * @returns 是否设置成功
   */
  public static setProperty<T>(
    obj: Record<string, unknown>,
    key: string,
    value: T
  ): boolean {
    if (obj && typeof obj === 'object' && key && !Array.isArray(obj)) {
      obj[key] = value as unknown;
      return true;
    }
    return false;
  }

  /**
   * 安全地设置对象的嵌套属性
   * @param obj 对象
   * @param path 属性路径
   * @param value 值
   * @returns 是否设置成功
   */
  public static setNestedProperty<T>(
    obj: Record<string, unknown>,
    path: string,
    value: T
  ): boolean {
    if (!obj || typeof obj !== 'object' || !path || typeof path !== 'string') {
      return false;
    }
    
    const keys = path.split('.');
    let current: Record<string, unknown> = obj;
    
    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      if (!current[key] || typeof current[key] !== 'object' || Array.isArray(current[key])) {
        current[key] = {};
      }
      current = current[key] as Record<string, unknown>;
    }
    
    return TypeSafetyUtil.setProperty(current, keys[keys.length - 1], value);
  }

  /**
   * 安全地访问包含特殊字符的属性
   * @param obj 要访问的对象
   * @param propertyName 属性名（可能包含特殊字符）
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static getPropertyWithSpecialChars<T>(obj: unknown, propertyName: string, defaultValue: T): T {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return defaultValue;
    }
    
    try {
      // 使用索引访问器安全地访问属性
      const objRecord = obj as Record<string, unknown>;
      if (Object.prototype.hasOwnProperty.call(objRecord, propertyName)) {
        return objRecord[propertyName] as T;
      }
      return defaultValue;
    } catch (error) {
      // 移除Logger引用，因为原代码中没有使用Logger
      return defaultValue;
    }
  }
  
  /**
   * 安全地设置包含特殊字符的属性
   * @param obj 要设置属性的对象
   * @param propertyName 属性名（可能包含特殊字符）
   * @param value 属性值
   * @returns 是否设置成功
   */
  public static setPropertyWithSpecialChars(obj: unknown, propertyName: string, value: unknown): boolean {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return false;
    }
    
    try {
      // 使用索引访问器安全地设置属性
      (obj as Record<string, unknown>)[propertyName] = value;
      return true;
    } catch (error) {
      // 移除Logger引用，因为原代码中没有使用Logger
      return false;
    }
  }
  
  /**
   * 创建安全的数据库记录对象
   * @param data 原始数据对象
   * @returns 安全的数据库记录对象
   */
  public static createSafeDatabaseRecord(data: unknown): Record<string, unknown> {
    const result: Record<string, unknown> = {};
    
    if (!data || typeof data !== 'object' || Array.isArray(data)) {
      return result;
    }
    
    // 安全地复制所有属性，包括那些包含特殊字符的属性
    for (const key in data) {
      if (Object.prototype.hasOwnProperty.call(data, key)) {
        result[key] = data[key];
      }
    }
    
    return result;
  }

  /**
   * 安全地获取对象的键列表
   * @param obj 对象
   * @returns 键列表
   */
  public static getObjectKeys(obj: unknown): string[] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    return Object.keys(safeObj);
  }

  /**
   * 安全地获取对象的值列表
   * @param obj 对象
   * @returns 值列表
   */
  public static getObjectValues<T = unknown>(obj: unknown): T[] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    return Object.values(safeObj) as T[];
  }

  /**
   * 安全地获取对象的键值对列表
   * @param obj 对象
   * @returns 键值对列表
   */
  public static getObjectEntries<T = unknown>(obj: unknown): [string, T][] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    return Object.entries(safeObj) as [string, T][];
  }

  /**
   * 合并对象，处理类型安全
   * @param target 目标对象
   * @param sources 源对象
   * @returns 合并后的对象
   */
  public static mergeObjects(
    target: Record<string, unknown>,
    ...sources: Record<string, unknown>[]
  ): Record<string, unknown> {
    const safeTarget = TypeSafetyUtil.asObject(target);
    
    for (const source of sources) {
      const safeSource = TypeSafetyUtil.asObject(source);
      
      for (const [key, value] of TypeSafetyUtil.getObjectEntries<unknown>(safeSource)) {
        if (value === null || value === undefined) {
          continue;
        }
        
        if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
          const targetValue = safeTarget[key];
          if (targetValue !== null && typeof targetValue === 'object' && !Array.isArray(targetValue)) {
            safeTarget[key] = TypeSafetyUtil.mergeObjects(targetValue as Record<string, unknown>, value as Record<string, unknown>);
          } else {
            safeTarget[key] = { ...value };
          }
        } else if (Array.isArray(value)) {
          safeTarget[key] = [...value];
        } else {
          safeTarget[key] = value;
        }
      }
    }
    
    return safeTarget;
  }

  /**
   * 创建类型守卫函数，用于验证对象是否符合特定接口
   * @param schema 属性验证函数的映射
   * @returns 类型守卫函数
   */
  public static createTypeGuard<T>(
    schema: Record<keyof T, (value: unknown) => boolean>
  ): (obj: unknown) => obj is T {
    return (obj: unknown): obj is T => {
      if (!obj || typeof obj !== 'object') {
        return false;
      }
      
      const safeObj = obj as Record<keyof T, unknown>;
      
      // 验证所有必需的属性都存在且符合类型
      for (const [key, validator] of TypeSafetyUtil.getObjectEntries(schema)) {
        if (!validator(safeObj[key])) {
          return false;
        }
      }
      
      return true;
    };
  }

  /**
   * 安全地解析JSON字符串
   * @param jsonStr JSON字符串
   * @param defaultValue 默认值
   * @returns 解析后的对象或默认值
   */
  public static safeJsonParse<T>(jsonStr: unknown, defaultValue: T): T {
    try {
      const str = TypeSafetyUtil.asString(jsonStr);
      const parsed = JSON.parse(str);
      return parsed !== null ? (parsed as T) : defaultValue;
    } catch (error) {
      return defaultValue;
    }
  }

  /**
   * 安全地序列化对象为JSON字符串
   * @param obj 要序列化的对象
   * @param defaultValue 默认值
   * @returns 序列化后的字符串或默认值
   */
  public static safeJsonStringify(obj: unknown, defaultValue: string = ''): string {
    try {
      return JSON.stringify(obj);
    } catch (error) {
      return defaultValue;
    }
  }

  /**
   * 检查值是否为有效的非空字符串
   * @param value 要检查的值
   * @returns 是否为有效字符串
   */
  public static isValidString(value: unknown): boolean {
    return typeof value === 'string' && value.trim().length > 0;
  }

  /**
   * 检查值是否为有效的非零数字
   * @param value 要检查的值
   * @returns 是否为有效数字
   */
  public static isValidNumber(value: unknown): boolean {
    return typeof value === 'number' && !isNaN(value) && isFinite(value);
  }

  /**
   * 检查值是否为有效的布尔值
   * @param value 要检查的值
   * @returns 是否为有效布尔值
   */
  public static isValidBoolean(value: unknown): boolean {
    return typeof value === 'boolean';
  }

  /**
   * 检查值是否为有效的对象
   * @param value 要检查的值
   * @returns 是否为有效对象
   */
  public static isValidObject(value: unknown): boolean {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  /**
   * 检查值是否为有效的数组
   * @param value 要检查的值
   * @returns 是否为有效数组
   */
  public static isValidArray(value: unknown): boolean {
    return Array.isArray(value);
  }
}
