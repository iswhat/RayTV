// TypeSafetyUtil - 类型安全工具�?
// 提供安全的类型转换和验证功能

// 定义基础类型接口，避免使用any/unknown
export interface TypeWrapper<T> {
  value: T;
}

// 定义具体的参数类型，避免使用过于宽泛的联合类�?
export interface BasicValue {
  value: string | number | boolean | null;
}

// 移除函数调用签名接口，使用普通函数类型替�?
export type EnhancedFunction<T, A> = (...args: A) => T;

/**
 * 类型安全工具�?
 * 提供安全的类型转换和验证方法
 */
export class TypeSafetyUtil {
  /**
   * 安全处理错误对象，确保返回有效的Error实例
   * @param error 错误对象或�?
   * @param message 可选的自定义错误消息前缀
   * @returns 规范化的Error实例
   */
  public static safeError(error: string | number | boolean | null, message?: string): Error {
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
   * 安全地访问嵌套属�?
   * @param obj 目标对象
   * @param path 属性路径，可以是字符串或字符串数组
   * @param defaultValue 默认�?
   * @returns 访问结果或默认�?
   */
  public static safeAccess<T = string | number | boolean | null>(obj: Record<string, string | number | boolean | null>, path: string | string[], defaultValue?: T): T | undefined {
    if (!obj || typeof obj !== 'object') {
      return defaultValue;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: Record<string, string | number | boolean | null> = obj;

    for (const key of keys) {
      // 跳过无效�?
      if (!key || typeof key !== 'string') {
        return defaultValue;
      }
      
      // 安全地进行索引访�?
      const objRef = current;
      // 使用Object.keys检查属性存在�?
      if (Object.keys(objRef).includes(key)) {
        const nextValue = objRef[key];
        // 检查nextValue是否是有效对�?
        if (nextValue !== null && typeof nextValue === 'object') {
          current = nextValue as Record<string, string | number | boolean | null>;
        } else if (nextValue === null || 
                   typeof nextValue === 'string' || 
                   typeof nextValue === 'number' || 
                   typeof nextValue === 'boolean') {
          // 对于基本类型，检查是否是最后一个键
          if (keys.indexOf(key) === keys.length - 1) {
            return nextValue as T ?? defaultValue;
          }
          return defaultValue; // 非对象类型不能继续访问嵌套属�?
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    
    // 如果循环结束且current仍是对象，返回默认�?
    return defaultValue;
  }

  /**
   * 安全地获取对象属性�?
   * @param obj - 要获取属性的对象
   * @param key - 属性键�?
   * @returns 属性值，如果属性不存在则返回undefined
   */
  public static getPropertyValue(obj: Record<string, string | number | boolean | null>, key: string): string | number | boolean | null | undefined {
    if (!obj || typeof obj !== 'object') {
      return undefined;
    }
    
    // 使用Object.keys检查属性存在性，避免使用Object.hasOwnProperty.call
    if (!Object.keys(obj).includes(key)) {
      return undefined;
    }
    
    // 使用类型安全的属性访问方�?
    return obj[key];
  }

  /**
   * 安全地设置对象属性�?
   * @param obj - 要设置属性的对象
   * @param key - 属性键�?
   * @param value - 属性�?
   * @returns 是否设置成功
   */
  public static safeSet(obj: Record<string, string | number | boolean | null>, key: string, value: string | number | boolean | null): boolean {
    if (obj === null || obj === undefined || typeof obj !== 'object') {
      return false;
    }
    
    try {
      // 修复：使用更精确的类型断言和类型安全的属性访�?
      const safeObj = obj as Record<string | number, string | number | boolean | object | null>;
      // 使用类型安全的属性访问方�?
      const propertyValue = TypeSafetyUtil.getPropertyValue(safeObj, key);
      if (propertyValue !== undefined) {
        safeObj[key] = value;
        return true;
      }
      return false;
    } catch {
      return false;
    }
  }
  
  /**
   * 安全地处理属性名，确保它是有效的标识�?
   * @param propertyName 原始属性名
   * @returns 安全的属性名
   */
  public static safePropertyName(propertyName: string): string {
    // 如果已经是有效的标识符，直接返回
    if (/^[a-zA-Z_$][a-zA-Z0-9_$]*$/.test(propertyName)) {
      return propertyName;
    }
    
    // 对于非标识符属性名，进行安全处�?
    // 1. 替换特殊字符为下划线
    let safeName = propertyName.replace(/[^a-zA-Z0-9_$]/g, '_');
    
    // 2. 确保不以数字开�?
    if (/^[0-9]/.test(safeName)) {
      safeName = '_' + safeName;
    }
    
    return safeName;
  }
  
  /**
   * 移除索引签名接口，使用Record类型替代
   */
  
  /**
   * 创建带有安全属性名的对�?
   * @param obj 原始对象
   * @returns 带有安全属性名的新对象
   */
  public static createSafeObject(obj: Record<string, string | number | boolean | object | null>): Record<string, string | number | boolean | object | null> {
    const safeObj: Record<string, string | number | boolean | object | null> = {};
    
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
   * 泛型类型推断辅助函数，帮助TypeScript更好地推断泛型类�?
   * @param value 要包装的�?
   * @returns 包装后的对象，保留原始类型信�?
   */
  public static withType<T>(value: T): TypeWrapper<T> {
    // 使用完整的对象属性赋值语法并添加明确类型
    const wrapper: TypeWrapper<T> = { value: value };
    return wrapper;
  }
  
  /**
   * 增强的类型守卫函数，提供更精确的类型推断
   * @param value 要检查的�?
   * @param guard 类型守卫函数
   * @returns 经过类型守卫后的�?
   */
  public static narrowType<T extends string | number | boolean | null>(value: string | number | boolean | object | null, guard: (v: string | number | boolean | object | null) => boolean): T | null {
    // 在ArkTS中，使用返回布尔值的函数替代类型守卫
    if (guard(value)) {
      // 额外的运行时检查确保类型安�?
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
   * 安全地进行类型转换，提供运行时类型检查和编译时类型推�?
   * @param value 要转换的�?
   * @param transformer 转换函数
   * @param guard 可选的类型守卫函数，用于验证转换结�?
   * @returns 转换后的值或默认�?
   */
  public static safeCast<T, U>(
    value: T,
    transformer: (v: T) => U,
    guard?: (v: string | number | boolean | object | null) => boolean,
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
   * 泛型工厂函数，创建具有特定类型的对象
   * @param factory 工厂函数
   * @param args 工厂函数参数
   * @returns 创建的对�?
   */
  public static createWithType<T, A extends Array<string | number | boolean | object | null>>(factory: (...args: A) => T, ...args: A): T {
    return factory(...args);
  }
  
  /**
   * 安全执行函数，捕获异常并返回默认�?
   * @param fn 要执行的函数
   * @param defaultValue 默认�?
   * @returns 函数执行结果或默认�?
   */
  public static safeExecute<T>(fn: () => T, defaultValue: T): T {
    try {
      return fn();
    } catch {
      return defaultValue;
    }
  }
  
  /**
   * 类型断言函数，提供编译时类型检�?
   * @param value 要断言的�?
   * @returns 断言后的�?
   */
  public static asType<T>(value: string | number | boolean | object | null): T {
    return value as T;
  }
  
  /**
   * 创建增强的泛型函数，提供更好的类型推�?
   * @param fn 原始函数
   * @returns 增强后的函数
   */
  public static createEnhancedGenericFunction<T, R>(fn: (arg: T) => R): EnhancedFunction<R, [T]> {
    const enhancedFn: EnhancedFunction<R, [T]> = (arg: T): R => {
      return fn(arg);
    };
    return enhancedFn;
  }
  
  /**
   * 安全地将值转换为对象
   * @param value 要转换的�?
   * @returns 转换后的安全对象
   */
  public static asObject(value: string | number | boolean | object | null): Record<string, string | number | boolean | null> {
    if (value === null || value === undefined) {
      return {};
    }
    if (typeof value === 'object' && !Array.isArray(value)) {
      // 转换对象，只保留基本类型值和嵌套对象
      const result: Record<string, string | number | boolean | null> = {};
      const obj = value as Record<string, string | number | boolean | null>;
      
      // 使用Object.keys和forEach替代for..in循环
      const keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key !== undefined) {
          const propValue = obj[key];
          if (typeof propValue === 'string' || 
              typeof propValue === 'number' || 
              typeof propValue === 'boolean' || 
              propValue === null) {
            result[key] = propValue;
          }
        }
      }
      
      return result;
    }
    try {
      // 对于非对象类型，尝试JSON序列�?反序列化来创建安全对�?
      const serialized = JSON.stringify(value);
      const parsed = JSON.parse(serialized) as Record<string, string | number | boolean | null>;
      return typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)
          ? parsed
          : {};
    } catch {
      return {};
    }
  }

  /**
   * 将值安全地转换为数�?
   * @param value - 要转换的�?
   * @returns 转换后的数组，如果转换失败则返回空数�?
   */
  public static asArray<T = string | number | boolean | null>(value: string | number | boolean | null | Array<string | number | boolean | null>): T[] {
    if (Array.isArray(value)) {
      return value as T[];
    }
    return [] as T[];
  }

  /**
   * 将值安全地转换为字符串
   * @param value - 要转换的�?
   * @param defaultValue - 默认�?
   * @returns 转换后的字符串，如果转换失败则返回默认�?
   */
  public static asString(value: string | number | boolean | null, defaultValue: string = ""): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * 将值安全地转换为数�?
   * @param value - 要转换的�?
   * @param defaultValue - 默认�?
   * @returns 转换后的数字，如果转换失败则返回默认�?
   */
  public static asNumber(value: string | number | boolean | null, defaultValue: number = 0): number {
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
   * 安全地将值转换为布尔�?
   * @param value 要转换的�?
   * @returns 转换后的布尔值，如果转换失败则返回false
   */
  public static asBoolean(value: string | number | boolean | null): boolean {
    if (value === null || value === undefined) {
      return false;
    }
    return Boolean(value);
  }

  /**
   * 安全地从对象中获取属性，提供类型检�?
   * @param obj 对象
   * @param key 属性名
   * @param defaultValue 默认�?
   * @returns 属性值或默认�?
   */
  public static getProperty<T extends string | number | boolean | null>(
    obj: Record<string, string | number | boolean | null>,
    key: string,
    defaultValue: T
  ): T {
    const safeObj = TypeSafetyUtil.asObject(obj);
    
    // 使用Object.keys和includes检查属性存在性，避免使用in操作�?
    if (key !== undefined && Object.keys(safeObj).includes(key)) {
      const value = safeObj[key];
      // 确保返回值是基本类型且符合预期类�?
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
   * 安全地从对象中获取嵌套属�?
   * @param obj 对象
   * @param path 属性路径，�?'user.profile.name'
   * @param defaultValue 默认�?
   * @returns 属性值或默认�?
   */
  public static getNestedProperty<T>(
    obj: Record<string, string | number | boolean | object | null>,
    path: string,
    defaultValue: T
  ): T {
    if (!obj || typeof obj !== 'object' || !path || typeof path !== 'string') {
      return defaultValue;
    }
    
    const keys = path.split('.');
    let current: Record<string, string | number | boolean | object | null> = obj;
    
    for (const key of keys) {
      // 跳过无效�?
      if (!key || typeof key !== 'string') {
        return defaultValue;
      }
      
      // 使用Object.keys检查属性存在�?
      if (Object.keys(current).includes(key)) {
        const nextValue = current[key];
        // 检查nextValue是否是有效对�?
        if (nextValue !== null && typeof nextValue === 'object' && !Array.isArray(nextValue)) {
          current = nextValue as Record<string, string | number | boolean | object | null>;
        } else if (nextValue === null || 
                   typeof nextValue === 'string' || 
                   typeof nextValue === 'number' || 
                   typeof nextValue === 'boolean') {
          // 对于基本类型，检查是否是最后一个键
          if (keys.indexOf(key) === keys.length - 1) {
            return nextValue as T;
          }
          return defaultValue; // 非对象类型不能继续访问嵌套属�?
        } else {
          return defaultValue;
        }
      } else {
        return defaultValue;
      }
    }
    
    // 如果循环结束且current仍是对象，尝试进行类型转�?
    return current as T;
  }

  /**
   * 安全地设置对象的属�?
   * @param obj 对象
   * @param key 属性名
   * @param value �?
   * @returns 是否设置成功
   */
  public static setProperty<T extends string | number | boolean | null>(
    obj: Record<string, string | number | boolean | object | null>,
    key: string,
    value: T
  ): boolean {
    if (obj && typeof obj === 'object' && key && !Array.isArray(obj)) {
      // 使用类型安全的属性访问方�?
      const propertyValue = TypeSafetyUtil.getPropertyValue(obj, key);
      if (propertyValue !== undefined) {
        obj[key] = value;
        return true;
      }
    }
    return false;
  }

  /**
   * 安全地设置对象的嵌套属�?
   * @param obj 对象
   * @param path 属性路�?
   * @param value �?
   * @returns 是否设置成功
   */
  public static setNestedProperty<T extends string | number | boolean | null>(
    obj: Record<string, string | number | boolean | object | null>,
    path: string,
    value: T
  ): boolean {
    if (!obj || typeof obj !== 'object' || !path || typeof path !== 'string') {
      return false;
    }
    
    const keys = path.split('.');
    let current: Record<string, string | number | boolean | object | null> = obj;
    
    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      if (!current[key] || typeof current[key] !== 'object' || Array.isArray(current[key])) {
        // 使用明确的类型声明，避免使用空对象字面量
        current[key] = {} as Record<string, string | number | boolean | object | null>;
      }
      current = current[key] as Record<string, string | number | boolean | object | null>;
    }
    
    return TypeSafetyUtil.setProperty(current, keys[keys.length - 1], value);
  }

  /**
   * 安全地访问包含特殊字符的属�?
   * @param obj 要访问的对象
   * @param propertyName 属性名（可能包含特殊字符）
   * @param defaultValue 默认�?
   * @returns 属性值或默认�?
   */
  public static getPropertyWithSpecialChars<T extends string | number | boolean | null>(obj: Record<string, string | number | boolean | object | null>, propertyName: string, defaultValue: T): T {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return defaultValue;
    }
    
    try {
      if (propertyName !== undefined && Object.keys(obj).includes(propertyName)) {
        const value = obj[propertyName];
        // 确保返回值是基本类型且符合预期类�?
        if ((value === null || 
             typeof value === 'string' || 
             typeof value === 'number' || 
             typeof value === 'boolean') && 
            value !== undefined) {
          return value as T;
        }
      }
      return defaultValue;
    } catch {
      return defaultValue;
    }
  }
  
  /**
   * 安全地设置包含特殊字符的属�?
   * @param obj 要设置属性的对象
   * @param propertyName 属性名（可能包含特殊字符）
   * @param value 属性�?
   * @returns 是否设置成功
   */
  public static setPropertyWithSpecialChars<T extends string | number | boolean | null>(
    obj: Record<string, string | number | boolean | object | null>,
    propertyName: string,
    value: T
  ): boolean {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return false;
    }
    
    try {
      // 使用索引访问器安全地设置属�?
      obj[propertyName] = value;
      return true;
    } catch {
      return false;
    }
  }
  
  /**
   * 创建安全的数据库记录对象
   * @param data 原始数据对象
   * @returns 安全的数据库记录对象
   */
  public static createSafeDatabaseRecord(data: Record<string, string | number | boolean | object | null>): Record<string, string | number | boolean | null> {
    const result: Record<string, string | number | boolean | null> = {};
    
    if (!data || typeof data !== 'object' || Array.isArray(data)) {
      return result;
    }
    
    // 安全地复制所有属性，包括那些包含特殊字符的属�?
    const keys = Object.keys(data);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // 安全地检查属性是否属于对象自�?
      if (key !== undefined && Object.keys(data).includes(key)) {
        // 只保留基本类型�?
        const value = data[key];
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
   * 安全地获取对象的键列�?
   * @param obj 对象
   * @returns 键列�?
   */
  public static getObjectKeys(obj: Record<string, string | number | boolean | null>): string[] {
    return Object.keys(obj);
  }

  /**
   * 安全地获取对象的值列�?
   * @param obj 对象
   * @returns 值列�?
   */
  public static getObjectValues<T extends string | number | boolean | null>(obj: Record<string, string | number | boolean | null>): T[] {
    const values = Object.values(obj);
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
  public static getObjectEntries<T extends string | number | boolean | null>(obj: Record<string, string | number | boolean | null>): [string, T][] {
    const entries = Object.entries(obj);
    // 过滤并转换键值对，确保返回的是指定类�?
    return entries.filter((entry) => {
      const value = entry[1];
      return typeof value === 'string' || 
             typeof value === 'number' || 
             typeof value === 'boolean' || 
             value === null;
    }) as [string, T][];
  }

  /**
   * 合并对象，处理类型安�?
   * @param target 目标对象
   * @param sources 源对�?
   * @returns 合并后的对象
   */
  public static mergeObjects(
    target: Record<string, string | number | boolean | null>,
    ...sources: Record<string, string | number | boolean | null>[]
  ): Record<string, string | number | boolean | null> {
    // 创建目标对象的副本，避免直接修改原对�?
    const result: Record<string, string | number | boolean | null> = {};
    
    // 复制目标对象的属�?
    const targetEntries = TypeSafetyUtil.getObjectEntries<string | number | boolean | null>(target);
    for (let i = 0; i < targetEntries.length; i++) {
      const entry = targetEntries[i];
      const key = entry[0];
      const value = entry[1];
      result[key] = value;
    }
    
    for (const source of sources) {
      const entries = TypeSafetyUtil.getObjectEntries<string | number | boolean | null>(source);
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const key = entry[0];
        const value = entry[1];
        if (value === null || value === undefined) {
          continue;
        }
        
        if (TypeSafetyUtil.isValidObject(value)) {
          const targetValue = result[key];
          if (TypeSafetyUtil.isValidObject(targetValue)) {
            result[key] = TypeSafetyUtil.mergeObjects(
              targetValue as Record<string, string | number | boolean | null>, 
              value as Record<string, string | number | boolean | null>
            );
          } else {
            // 避免使用对象展开操作，改用明确的对象创建
            result[key] = TypeSafetyUtil.asObject(value);
          }
        } else if (TypeSafetyUtil.isValidArray(value)) {
          // 避免使用数组展开操作，改用Array.from创建新数�?
          result[key] = Array.from(value as string[]);
        } else {
          result[key] = value;
        }
      }
    }
    
    return result;
  }

  /**
   * 创建类型检查函�?
   * @param schema 属性验证函数的映射
   * @returns 类型检查函数，返回布尔�?
   */
  public static createTypeGuard(
    schema: Record<string, (value: string | number | boolean | object | null) => boolean>
  ): (obj: Record<string, string | number | boolean | object | null>) => boolean {
    return (obj: Record<string, string | number | boolean | object | null>): boolean => {
      if (!TypeSafetyUtil.isValidObject(obj)) {
        return false;
      }
      
      // 验证所有必需的属性都存在且符合类�?      const entries = TypeSafetyUtil.getObjectEntries<(value: string | number | boolean | object | null) => boolean>(schema);
      for (let i = 0; i < entries.length; i++) {
        const entry = entries[i];
        const key = entry[0];
        const validator = entry[1];
        // 安全地获取对象属性并验证
        let value = TypeSafetyUtil.safeAccess(obj, key.toString(), null);
        // 确保value不是undefined，使用null作为默认�?        if (value === undefined) {
          value = null;
        }
        if (!validator(value)) {
          return false;
        }
      }
      
      return true;
    };
  }

  /**
   * 安全地解析JSON字符�?
   * @param jsonStr JSON字符�?
   * @param defaultValue 默认�?
   * @returns 解析后的对象或默认�?
   */
  public static safeJsonParse<T>(jsonStr: string | number | boolean | object | null, defaultValue: T): T {
    try {
      // 确保jsonStr是字符串类型
      if (typeof jsonStr !== 'string') {
        return defaultValue;
      }
      const parsed = JSON.parse(jsonStr) as T;
      return parsed !== null ? parsed : defaultValue;
    } catch {
      return defaultValue;
    }
  }

  /**
   * 安全地序列化对象为JSON字符�?
   * @param obj 要序列化的对�?
   * @param defaultValue 默认�?
   * @returns 序列化后的字符串或默认�?
   */
  public static safeJsonStringify(obj: string | number | boolean | object | null, defaultValue: string): string {
    try {
      return JSON.stringify(obj);
    } catch {
      return defaultValue;
    }
  }

  /**
   * 检查值是否为有效的非空字符串
   * @param value 要检查的�?
   * @returns 是否为有效字符串
   */
  public static isValidString(value: string | number | boolean | object | null): boolean {
    return typeof value === 'string' && value.trim().length > 0;
  }

  /**
   * 检查值是否为有效的非零数�?
   * @param value 要检查的�?
   * @returns 是否为有效数�?
   */
  public static isValidNumber(value: string | number | boolean | object | null): boolean {
    return typeof value === 'number' && !isNaN(value) && isFinite(value);
  }

  /**
   * 检查值是否为有效的布尔�?
   * @param value 要检查的�?
   * @returns 是否为有效布尔�?
   */
  public static isValidBoolean(value: string | number | boolean | object | null): boolean {
    return typeof value === 'boolean';
  }

  /**
   * 检查值是否为有效的对�?
   * @param value 要检查的�?
   * @returns 是否为有效对�?
   */
  public static isValidObject(value: string | number | boolean | object | null): boolean {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  /**
   * 检查值是否为有效的数�?
   * @param value 要检查的�?
   * @returns 是否为有效数�?
   */
  public static isValidArray(value: string | number | boolean | object | null): boolean {
    return Array.isArray(value);
  }

  /**
   * 创建类型安全的映射对�?
   * @param entries 键值对数组
   * @returns 类型安全的映射对�?
   */
  public static createSafeMap<K extends string, V extends string | number | boolean | null>(
    entries: [K, V][]
  ): Record<K, V> {
    const result = {} as Record<K, V>;
    
    for (let i = 0; i < entries.length; i++) {
      const entry = entries[i];
      const key = entry[0];
      const value = entry[1];
      if (key !== undefined && value !== undefined) {
        // 使用类型安全的属性访问方�?
        const propertyValue = TypeSafetyUtil.getPropertyValue(result, key);
        if (propertyValue !== undefined) {
          result[key] = value;
        }
      }
    }
    
    return result;
  }

  /**
   * 从对象中选择指定的属�?
   * @param obj 源对�?
   * @param keys 要选择的属性名数组
   * @returns 包含选定属性的新对�?
   */
  public static pickProperties<T extends Record<string, string | number | boolean | object | null>, K extends keyof T>(
    obj: T,
    keys: K[]
  ): Record<string, string | number | boolean | object | null> {
    const result: Record<string, string | number | boolean | object | null> = {};
    
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key !== undefined && obj[key] !== undefined) {
        // 使用类型安全的属性访问方�?
        const propertyValue = TypeSafetyUtil.getPropertyValue(obj, key);
        if (propertyValue !== undefined) {
          result[key as string] = propertyValue;
        }
      }
    }
    
    return result;
  }

  /**
   * 从对象中排除指定的属�?
   * @param obj 源对�?
   * @param keys 要排除的属性名数组
   * @returns 排除指定属性后的新对象
   */
  public static omitProperties<T extends Record<string, string | number | boolean | object | null>, K extends keyof T>(
    obj: T,
    keys: K[]
  ): Record<string, string | number | boolean | object | null> {
    const result: Record<string, string | number | boolean | object | null> = {};
    const objKeys = Object.keys(obj) as (keyof T)[];
    
    for (let i = 0; i < objKeys.length; i++) {
      const key = objKeys[i];
      // 检查key是否在要排除的键列表�?
      let shouldExclude = false;
      for (let j = 0; j < keys.length; j++) {
        if (key === keys[j]) {
          shouldExclude = true;
          break;
        }
      }
      
      if (!shouldExclude && key !== undefined) {
        // 使用类型安全的属性访问方�?
        const propertyValue = TypeSafetyUtil.getPropertyValue(obj, key);
        if (propertyValue !== undefined) {
          result[key as string] = propertyValue;
        }
      }
    }
    
    return result;
  }
}

// 类型定义，避免使用对象字面量作为类型
// 接口已在文件顶部定义，此处不再重�
