// TypeSafetyUtil - 类型安全工具类
// 提供安全的类型转换和验证功能

/**
 * 类型安全工具类
 * 提供安全的类型转换和验证方法
 */
export class TypeSafetyUtil {
  /**
   * 安全地将值转换为对象
   * @param value 要转换的值
   * @returns 如果是对象则返回对象，否则返回空对象
   */
  public static asObject(value: any): Record<string, any> {
    if (value === null || value === undefined) {
      return {};
    }
    if (typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, any>;
    }
    return {};
  }

  /**
   * 安全地将值转换为数组
   * @param value 要转换的值
   * @returns 如果是数组则返回数组，否则返回空数组
   */
  public static asArray<T = any>(value: any): T[] {
    if (Array.isArray(value)) {
      return value as T[];
    }
    return [];
  }

  /**
   * 安全地将值转换为字符串
   * @param value 要转换的值
   * @param defaultValue 默认值
   * @returns 转换后的字符串
   */
  public static asString(value: any, defaultValue: string = ''): string {
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
  public static asNumber(value: any, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
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
  public static asBoolean(value: any, defaultValue: boolean = false): boolean {
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
    obj: any,
    key: string,
    defaultValue: T
  ): T {
    const safeObj = TypeSafetyUtil.asObject(obj);
    const value = safeObj[key];
    
    // 检查类型兼容性
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
    obj: any,
    path: string,
    defaultValue: T
  ): T {
    if (!path || typeof path !== 'string') {
      return defaultValue;
    }
    
    const keys = path.split('.');
    let current: any = obj;
    
    for (const key of keys) {
      if (current === null || current === undefined) {
        return defaultValue;
      }
      
      const safeObj = TypeSafetyUtil.asObject(current);
      current = safeObj[key];
    }
    
    // 尝试类型转换
    if (current === null || current === undefined) {
      return defaultValue;
    }
    
    return current as T ?? defaultValue;
  }

  /**
   * 安全地设置对象的属性
   * @param obj 对象
   * @param key 属性名
   * @param value 值
   * @returns 是否设置成功
   */
  public static setProperty<T>(
    obj: Record<string, any>,
    key: string,
    value: T
  ): boolean {
    if (obj && typeof obj === 'object' && key) {
      obj[key] = value as any;
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
    obj: Record<string, any>,
    path: string,
    value: T
  ): boolean {
    if (!obj || typeof obj !== 'object' || !path || typeof path !== 'string') {
      return false;
    }
    
    const keys = path.split('.');
    let current: Record<string, any> = obj;
    
    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      if (!current[key] || typeof current[key] !== 'object' || Array.isArray(current[key])) {
        current[key] = {};
      }
      current = current[key] as Record<string, any>;
    }
    
    return TypeSafetyUtil.setProperty(current, keys[keys.length - 1], value);
  }

  /**
   * 安全地获取对象的键列表
   * @param obj 对象
   * @returns 键列表
   */
  public static getObjectKeys(obj: any): string[] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    return Object.keys(safeObj);
  }

  /**
   * 安全地获取对象的值列表
   * @param obj 对象
   * @returns 值列表
   */
  public static getObjectValues<T = any>(obj: any): T[] {
    const safeObj = TypeSafetyUtil.asObject(obj);
    return Object.values(safeObj) as T[];
  }

  /**
   * 安全地获取对象的键值对列表
   * @param obj 对象
   * @returns 键值对列表
   */
  public static getObjectEntries<T = any>(obj: any): [string, T][] {
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
    target: Record<string, any>,
    ...sources: Record<string, any>[]
  ): Record<string, any> {
    const safeTarget = TypeSafetyUtil.asObject(target);
    
    for (const source of sources) {
      const safeSource = TypeSafetyUtil.asObject(source);
      
      for (const [key, value] of TypeSafetyUtil.getObjectEntries(safeSource)) {
        if (value === null || value === undefined) {
          continue;
        }
        
        if (typeof value === 'object' && !Array.isArray(value)) {
          const targetValue = safeTarget[key];
          if (typeof targetValue === 'object' && !Array.isArray(targetValue)) {
            safeTarget[key] = TypeSafetyUtil.mergeObjects(targetValue as Record<string, any>, value as Record<string, any>);
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
    schema: Record<keyof T, (value: any) => boolean>
  ): (obj: any) => obj is T {
    return (obj: any): obj is T => {
      if (!obj || typeof obj !== 'object') {
        return false;
      }
      
      const safeObj = obj as Record<keyof T, any>;
      
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
  public static safeJsonParse<T>(jsonStr: any, defaultValue: T): T {
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
  public static safeJsonStringify(obj: any, defaultValue: string = ''): string {
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
  public static isValidString(value: any): boolean {
    return typeof value === 'string' && value.trim().length > 0;
  }

  /**
   * 检查值是否为有效的非零数字
   * @param value 要检查的值
   * @returns 是否为有效数字
   */
  public static isValidNumber(value: any): boolean {
    return typeof value === 'number' && !isNaN(value) && isFinite(value);
  }

  /**
   * 检查值是否为有效的布尔值
   * @param value 要检查的值
   * @returns 是否为有效布尔值
   */
  public static isValidBoolean(value: any): boolean {
    return typeof value === 'boolean';
  }

  /**
   * 检查值是否为有效的对象
   * @param value 要检查的值
   * @returns 是否为有效对象
   */
  public static isValidObject(value: any): boolean {
    return value !== null && typeof value === 'object' && !Array.isArray(value);
  }

  /**
   * 检查值是否为有效的数组
   * @param value 要检查的值
   * @returns 是否为有效数组
   */
  public static isValidArray(value: any): boolean {
    return Array.isArray(value);
  }
}
