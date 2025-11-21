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
   * 安全地访问嵌套属性
   * @param obj 目标对象
   * @param path 属性路径，可以是字符串或字符串数组
   * @param defaultValue 默认值
   * @returns 访问结果或默认值
   */
  public static safeAccess<T = string | number | boolean | null>(obj: object, path: string | string[], defaultValue?: T): T | undefined {
    if (!obj || typeof obj !== 'object') {
      return defaultValue;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: object = obj;

    for (const key of keys) {
      // 跳过无效键
      if (!key || typeof key !== 'string') {
        return defaultValue;
      }
      
      // 安全地进行索引访问
      const objRef = current as Record<string, string | number | boolean | object | null>;
      // 使用Object.keys检查属性存在性
      if (Object.keys(objRef).includes(key)) {
        const nextValue = objRef[key];
        // 检查nextValue是否是有效对象
        if (nextValue !== null && typeof nextValue === 'object') {
          current = nextValue;
        } else if (nextValue === null || 
                   typeof nextValue === 'string' || 
                   typeof nextValue === 'number' || 
                   typeof nextValue === 'boolean') {
          // 对于基本类型，检查是否是最后一个键
          if (keys.indexOf(key) === keys.length - 1) {
            return nextValue as T ?? defaultValue;
          }
          return defaultValue; // 非对象类型不能继续访问嵌套属性
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    
    // 如果循环结束且current仍是对象，返回默认值
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
      // 修复：使用更精确的类型断言
      const safeObj = obj as Record<string | number, unknown>;
      safeObj[key] = value;
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
   * 定义安全对象类型，避免使用object literals as types
   */
  export type SafeObject = Record<string, string | number | boolean | object | null>;
  
  /**
   * 创建带有安全属性名的对象
   * @param obj 原始对象
   * @returns 带有安全属性名的新对象
   */
  public static createSafeObject(obj: Record<string, unknown>): SafeObject {
    // 修复：使用明确的类型注解，避免未类型化对象字面量
    const safeObj: SafeObject = {};
    
    const entries = Object.entries(obj);
    for (let i = 0; i < entries.length; i++) {
      const key = entries[i][0];
      const value = entries[i][1];
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
  public static withType<T>(value: T): TypeWrapper<T> {
    // 使用完整的对象属性赋值语法并添加明确类型
    const wrapper: TypeWrapper<T> = { value: value };
    return wrapper;
  }
  
  /**
   * 增强的类型守卫函数，提供更精确的类型推断
   * @param value 要检查的值
   * @param guard 类型守卫函数
   * @returns 经过类型守卫后的值
   */
  public static narrowType<T extends string | number | boolean | null>(value: unknown, guard: (v: unknown) => boolean): T | null {
    // 在ArkTS中，使用返回布尔值的函数替代类型守卫
    if (guard(value)) {
      // 额外的运行时检查确保类型安全
      const result = value as T;
      if (result === null || 
          typeof result === 'string' || 
          typeof result === 'number' || 
          typeof result === 'boolean') {
        return result;
      }
    }
    return null;
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
    guard?: (v: unknown) => boolean,
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
  public static createWithType<T, A extends unknown[]>(factory: (...args: A) => T, ...args: A): T | null {
    // 修复：使用泛型参数A来捕获准确的参数类型，而不是使用unknown[]
    try {
      return factory(...args);
    } catch {
      return null;
    }
  }
  
  /**
   * 安全地执行函数
   * @param fn 要执行的函数
   * @param defaultValue 默认值
   * @param args 函数参数
   * @returns 执行结果或默认值
   */
  public static safeExecute<T>(
    fn: (...args: unknown[]) => T,
    defaultValue: T,
    ...args: unknown[]
  ): T {
    try {
      return typeof fn === 'function' ? fn(...args) : defaultValue;
    } catch {
      return defaultValue;
    }
  }

  /**
   * 安全地进行类型断言
   * 用于解决泛型函数调用类型推断受限的问题
   * @param value 要断言的值
   * @param typeGuard 可选的类型检查函数
   * @returns 断言后的类型
   */
  public static asType<T extends string | number | boolean | null>(value: unknown, typeGuard?: (value: unknown) => boolean): T | null {
    // 在ArkTS中，使用返回布尔值的函数替代类型守卫
    if (typeGuard && !typeGuard(value)) {
      console.warn('Type assertion failed: value does not match the expected type');
      // 返回默认值而不是直接断言
      return null;
    }
    
    // 确保返回值符合基本类型约束
    if (value === null || 
        typeof value === 'string' || 
        typeof value === 'number' || 
        typeof value === 'boolean') {
      return value as T;
    }
    
    // 对于不匹配的类型，返回null
    return null;
  }
  
  /**
   * 创建增强的泛型函数，解决类型推断受限问题
   * @param fn 原始函数
   * @returns 包装后的函数，具有更好的类型推断
   */
  // 修复：使用更具体的泛型类型定义，避免any[]
  public static createEnhancedGenericFunction<T, A extends unknown[]>(fn: (...args: A) => T): EnhancedFunction<T, A> {
    // 在ArkTS中使用更简单的方式实现，使用箭头函数替代普通函数表达式
    const enhancedFn: EnhancedFunction<T, A> = (...args: A): T => {
      // 使用标准函数调用
      try {
        if (typeof fn === 'function') {
          return fn(...args);
        }
        // 确保抛出的是Error类型的错误
        const error = new Error('fn is not a function');
        throw error;
      } catch (e: Error) {
        console.error('Function execution failed:', e);
        // 确保抛出的是Error类型的错误
        const error: Error = e instanceof Error ? e : new Error(String(e));
        throw error;
      }
    };
    return enhancedFn;
  }

  /**
   * 安全地将值转换为对象
   * @param value 要转换的值
   * @returns 如果是对象则返回对象，否则返回空对象
   */
  public static asObject(value: unknown): SafeObject {
    if (value === null || value === undefined) {
      return {} as SafeObject;
    }
    if (typeof value === 'object' && !Array.isArray(value)) {
      // 转换对象，只保留基本类型值和嵌套对象
      const result: SafeObject = {};
      const obj = value as Record<string, unknown>;
      
      // 使用Object.keys和forEach替代for..in循环
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key !== undefined) {
          const propValue = obj[key];
          if (typeof propValue === 'string' || 
              typeof propValue === 'number' || 
              typeof propValue === 'boolean' || 
              propValue === null ||
              (typeof propValue === 'object' && propValue !== null && !Array.isArray(propValue))) {
            result[key] = propValue as string | number | boolean | object | null;
          }
        }
      }
      
      return result;
    }
    try {
      // 对于非对象类型，尝试JSON序列化/反序列化来创建安全对象
      const serialized = JSON.stringify(value);
      const parsed = JSON.parse(serialized);
      return typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)
          ? parsed as SafeObject
          : {} as SafeObject;
    } catch {
      return {} as SafeObject;
    }
  }

  /**
   * 安全地将值转换为数组
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的数组或默认值
   */
  // 修复：移除类型参数默认值，使用defaultValue参数
  public static asArray<T>(value: unknown, defaultValue: T[]): T[] {
    if (Array.isArray(value)) {
      return value as T[];
    }
    return defaultValue;
  }

  /**
   * 安全地将值转换为字符串
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的字符串
   */
  public static asString(value: unknown, defaultValue: string): string {
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
  public static asNumber(value: unknown, defaultValue: number): number {
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
  public static asBoolean(value: unknown, defaultValue: boolean): boolean {
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
  public static getProperty<T extends string | number | boolean | null>(
    obj: unknown,
    key: string,
    defaultValue: T
  ): T {
    const safeObj: SafeObject = TypeSafetyUtil.asObject(obj);
    
    // 使用Object.keys和includes检查属性存在性，避免使用in操作符
    if (key !== undefined && Object.keys(safeObj).includes(key)) {
      const value = safeObj[key];
      // 确保返回值是基本类型且符合预期类型
      if ((value === null || 
           typeof value === 'string' || 
           typeof value === 'number' || 
           typeof value === 'boolean') && 
          value !== undefined) {
        return value as T;
      }
    }
    
    return defaultValue;
  }

  /**
   * 安全地从对象中获取嵌套属性
   * @param obj 对象
   * @param path 属性路径，如 'user.profile.name'
   * @param defaultValue 默认值
   * @returns 属性值或默认值
   */
  public static getNestedProperty<T>(
    obj: object,
    path: string,
    defaultValue: T
  ): T {
    if (!obj || typeof obj !== 'object' || !path || typeof path !== 'string') {
      return defaultValue;
    }
    
    const keys = path.split('.');
    let current: object = obj;
    
    for (const key of keys) {
      // 跳过无效键
      if (!key || typeof key !== 'string') {
        return defaultValue;
      }
      
      // 安全地进行类型转换
      const safeObj = current as SafeObject;
      // 使用Object.keys检查属性存在性
      if (Object.keys(safeObj).includes(key)) {
        const nextValue = safeObj[key];
        // 检查nextValue是否是有效对象
        if (nextValue !== null && typeof nextValue === 'object') {
          current = nextValue;
        } else if (nextValue === null || 
                   typeof nextValue === 'string' || 
                   typeof nextValue === 'number' || 
                   typeof nextValue === 'boolean') {
          // 对于基本类型，检查是否是最后一个键
          if (keys.indexOf(key) === keys.length - 1) {
            return nextValue as T;
          }
          return defaultValue; // 非对象类型不能继续访问嵌套属性
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    
    // 如果循环结束且current仍是对象，尝试进行类型转换
    return current as T;
  }

  /**
   * 安全地设置对象的属性
   * @param obj 对象
   * @param key 属性名
   * @param value 值
   * @returns 是否设置成功
   */
  public static setProperty<T extends string | number | boolean | null>(
    obj: Record<string, unknown>,
    key: string,
    value: T
  ): boolean {
    if (obj && typeof obj === 'object' && key && !Array.isArray(obj)) {
      obj[key] = value;
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
  public static getPropertyWithSpecialChars<T extends string | number | boolean | null>(obj: unknown, propertyName: string, defaultValue: T): T {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return defaultValue;
    }
    
    try {
      // 安全地进行索引访问
      const safeObj = obj as Record<string, unknown>;
      if (propertyName !== undefined && Object.keys(safeObj).includes(propertyName)) {
        const value = safeObj[propertyName];
        // 确保返回值是基本类型且符合预期类型
        if ((value === null || 
             typeof value === 'string' || 
             typeof value === 'number' || 
             typeof value === 'boolean') && 
            value !== undefined) {
          return value as T;
        }
      }
      return defaultValue;
    } catch (error: Error) {
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
  public static setPropertyWithSpecialChars<T extends string | number | boolean | null>(
    obj: unknown,
    propertyName: string,
    value: T
  ): boolean {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return false;
    }
    
    try {
      // 使用索引访问器安全地设置属性
      const safeObj = obj as Record<string, unknown>;
      safeObj[propertyName] = value;
      return true;
    } catch (error: Error) {
      // 移除Logger引用，因为原代码中没有使用Logger
      return false;
    }
  }
  
  /**
   * 创建安全的数据库记录对象
   * @param data 原始数据对象
   * @returns 安全的数据库记录对象
   */
  public static createSafeDatabaseRecord(data: unknown): Record<string, string | number | boolean | null> {
    const result: Record<string, string | number | boolean | null> = {};
    
    if (!data || typeof data !== 'object' || Array.isArray(data)) {
      return result;
    }
    
    // 安全地复制所有属性，包括那些包含特殊字符的属性
    const safeData = data as Record<string, unknown>;
    for (const key in safeData) {
      // 安全地检查属性是否属于对象自身
      if (key !== undefined && Object.keys(safeData).includes(key)) {
        // 只保留基本类型值
        const value = safeData[key];
        if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean' || value === null) {
          result[key] = value;
        } else {
          // 对于复杂类型，转换为字符串或忽略
          result[key] = value === undefined ? null : String(value);
        }
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
  public static getObjectValues<T extends string | number | boolean | null>(obj: unknown): T[] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    const values = Object.values(safeObj);
    // 过滤并转换值，确保返回的是指定类型
    return values.filter(value => 
      typeof value === 'string' || 
      typeof value === 'number' || 
      typeof value === 'boolean' || 
      value === null
    ) as T[];
  }

  /**
   * 安全地获取对象的键值对列表
   * @param obj 对象
   * @returns 键值对列表
   */
  public static getObjectEntries<T extends string | number | boolean | null>(obj: unknown): [string, T][] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    const entries = Object.entries(safeObj);
    // 过滤并转换键值对，确保返回的是指定类型
    return entries.filter(([_, value]) => 
      typeof value === 'string' || 
      typeof value === 'number' || 
      typeof value === 'boolean' || 
      value === null
    ) as [string, T][];
  }

  /**
   * 合并对象，处理类型安全
   * @param target 目标对象
   * @param sources 源对象
   * @returns 合并后的对象
   */
  public static mergeObjects(
    target: Record<string, string | number | boolean | null>,
    ...sources: Record<string, string | number | boolean | null>[]
  ): Record<string, string | number | boolean | null> {
    const safeTarget = TypeSafetyUtil.asObject(target);
    
    for (const source of sources) {
      const safeSource = TypeSafetyUtil.asObject(source);
      
      const entries = TypeSafetyUtil.getObjectEntries<unknown>(safeSource);
      for (let i = 0; i < entries.length; i++) {
        const [key, value] = entries[i];
        if (value === null || value === undefined) {
          continue;
        }
        
        if (TypeSafetyUtil.isValidObject(value)) {
          const targetValue = safeTarget[key];
          if (TypeSafetyUtil.isValidObject(targetValue)) {
            safeTarget[key] = TypeSafetyUtil.mergeObjects(
              targetValue as Record<string, string | number | boolean | object | null>, 
              value as Record<string, string | number | boolean | object | null>
            );
          } else {
            // 避免使用对象展开操作，改用明确的对象创建
            safeTarget[key] = TypeSafetyUtil.asObject(value);
          }
        } else if (TypeSafetyUtil.isValidArray(value)) {
          // 避免使用数组展开操作，改用Array.from创建新数组
          safeTarget[key] = Array.from(value as unknown[]);
        } else {
          safeTarget[key] = value;
        }
      }
    }
    
    return safeTarget;
  }

  /**
   * 创建类型检查函数
   * @param schema 属性验证函数的映射
   * @returns 类型检查函数，返回布尔值
   */
  public static createTypeGuard<T extends Record<string, unknown>>(
    schema: Record<string | number, (value: unknown) => boolean>
  ): (obj: unknown) => boolean {
    return (obj: unknown): boolean => {
      if (!TypeSafetyUtil.isValidObject(obj)) {
        return false;
      }
      
      const safeObj = obj as Record<string | number, unknown>;
      
      // 验证所有必需的属性都存在且符合类型
      for (const [key, validator] of TypeSafetyUtil.getObjectEntries<(value: unknown) => boolean>(schema)) {
        // 安全地获取对象属性并验证
        const value = TypeSafetyUtil.safeAccess(safeObj, key.toString(), undefined);
        if (!validator(value)) {
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
      // 确保jsonStr是字符串类型
      if (typeof jsonStr !== 'string') {
        return defaultValue;
      }
      const parsed = JSON.parse(jsonStr);
      return parsed !== null ? (parsed as T) : defaultValue;
    } catch (error: Error) {
      return defaultValue;
    }
  }

  /**
   * 安全地序列化对象为JSON字符串
   * @param obj 要序列化的对象
   * @param defaultValue 默认值
   * @returns 序列化后的字符串或默认值
   */
  public static safeJsonStringify(obj: unknown, defaultValue: string): string {
    try {
      return JSON.stringify(obj);
    } catch (error: Error) {
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

  /**
   * 创建类型安全的映射对象
   * @param entries 键值对数组
   * @returns 类型安全的映射对象
   */
  public static createSafeMap<K extends string, V extends string | number | boolean | null>(
    entries: [K, V][]
  ): Record<K, V> {
    const result = {} as Record<K, V>;
    
    for (let i = 0; i < entries.length; i++) {
      const [key, value] = entries[i];
      if (key !== undefined && value !== undefined) {
        result[key] = value;
      }
    }
    
    return result;
  }

  /**
   * 从对象中选择指定的属性
   * @param obj 源对象
   * @param keys 要选择的属性名数组
   * @returns 包含选定属性的新对象
   */
  public static pickProperties<T extends Record<string, unknown>, K extends keyof T>(
    obj: T,
    keys: K[]
  ): Pick<T, K> {
    const result = {} as Pick<T, K>;
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key !== undefined && obj[key] !== undefined) {
        result[key] = obj[key];
      }
    }
    
    return result;
  }

  /**
   * 从对象中排除指定的属性
   * @param obj 源对象
   * @param keys 要排除的属性名数组
   * @returns 排除指定属性后的新对象
   */
  public static omitProperties<T extends Record<string, unknown>, K extends keyof T>(
    obj: T,
    keys: K[]
  ): Omit<T, K> {
    const result = {} as Omit<T, K>;
    const objKeys = Object.keys(obj) as (keyof T)[];
    
    for (let i = 0; i < objKeys.length; i++) {
      const key = objKeys[i];
      // 检查key是否在要排除的键列表中
      let shouldExclude = false;
      for (let j = 0; j < keys.length; j++) {
        if (key === keys[j]) {
          shouldExclude = true;
          break;
        }
      }
      
      if (!shouldExclude && key !== undefined) {
        result[key] = obj[key];
      }
    }
    
    return result;
  }
}

// 类型定义，避免使用对象字面量作为类型
export interface TypeWrapper<T> {
  value: T;
}

export interface EnhancedFunction<T, A extends unknown[]> {
  (...args: A): T;
}