/**
 * TypeSafetyHelper - 类型安全辅助工具类 | Type safety helper class
 * 提供类型安全检查和转换的辅助方法 | Provides helper methods for type safety checking and conversion
 */

/**
 * 异步执行选项接口 | Async execute options interface
 */
export interface SafeAsyncExecuteOptions<T> {
  onError?: (error: Error) => void;
  defaultValue?: T;
}

/**
 * 安全对象接口 | Safe object interface
 */
export interface SafeObject {
  // 基础对象类型，用于替代any | Basic object type to replace any
  toStringTag?: string;
}

/**
 * 通用对象接口 | Generic object interface
 * 使用 Record 类型支持索引访问 | Use Record type to support indexed access
 */
export type GenericObject = Record<string, string | number | boolean | object | null | undefined>;

/**
 * 通用数组接口 | Generic array interface
 */
export type GenericArray = Array<string | number | boolean | object | null | undefined>;

/**
 * 键值对接口 | Key-value pair interface
 */
export interface KeyValuePair<K extends string, V> {
  key: K;
  value: V;
}

/**
 * 类型安全辅助工具类 | Type safety helper class
 */
export class TypeSafetyHelper {
  private static readonly TAG: string = 'TypeSafetyHelper';

  /**
   * 安全地将值转换为字符串 | Safely converts value to string
   * @param value 要转换的值 | Value to convert
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的字符串 | Converted string
   */
  public static safeString(value: string | number | boolean | object | null | undefined, defaultValue: string = ''): string {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return String(value);
  }

  /**
   * 安全地将值转换为数字 | Safely converts value to number
   * @param value 要转换的值 | Value to convert
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的数字 | Converted number
   */
  public static safeNumber(value: string | number | boolean | object | null | undefined, defaultValue: number = 0): number {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    const num = Number(value);
    return isNaN(num) ? defaultValue : num;
  }

  /**
   * 安全地将值转换为布尔值 | Safely converts value to boolean
   * @param value 要转换的值 | Value to convert
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的布尔值 | Converted boolean
   */
  public static safeBoolean(value: string | number | boolean | object | null | undefined, defaultValue: boolean = false): boolean {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Boolean(value);
  }

  /**
   * 安全地将值转换为数组 | Safely converts value to array
   * @param value 要转换的值 | Value to convert
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的数组 | Converted array
   */
  public static safeArray<T>(value: T[] | string | number | boolean | object | null | undefined, defaultValue: T[] = []): T[] {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    return Array.isArray(value) ? value : defaultValue;
  }

  /**
   * 安全地将值转换为对象 | Safely converts value to object
   * @param value 要转换的值 | Value to convert
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的对象 | Converted object
   */
  public static safeObject<T extends SafeObject>(value: T | string | number | boolean | object | null | undefined, defaultValue: T): T {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    if (typeof value === 'object' && !Array.isArray(value)) {
      return value as T;
    }
    return defaultValue;
  }

  /**
   * 安全获取对象属性 | Safely get object property
   * @param obj 对象 | Object
   * @param key 属性名 | Property name
   * @returns 属性值 | Property value
   */
  private static getSafeProperty(obj: object, key: string): string | number | boolean | object | null | undefined {
    try {
      // 检查属性是否存在
      if (typeof obj === 'object' && obj !== null) {
        const keys: string[] = Object.keys(obj);
        if (keys.includes(key)) {
          return (obj as GenericObject)[key];
        }
      }
      return undefined;
    } catch {
      return undefined;
    }
  }

  /**
   * 安全设置对象属性 | Safely set object property
   * @param obj 对象 | Object
   * @param key 属性名 | Property name
   * @param value 属性值 | Property value
   */
  private static setSafeProperty(obj: object, key: string, value: string | number | boolean | object | null | undefined): void {
    try {
      (obj as GenericObject)[key] = value;
    } catch {
      // 忽略设置属性时的错误
    }
  }

  /**
   * 安全地获取对象属性 | Safely gets object property
   * @param obj 目标对象 | Target object
   * @param path 属性路径 | Property path
   * @param defaultValue 默认值 | Default value
   * @returns 属性值或默认值 | Property value or default value
   */
  public static safeGet<T = string | number | boolean | object | null | undefined>(obj: object, path: string | string[], defaultValue?: T): T | undefined {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return defaultValue;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: object = obj;

    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      // ArkTS 兼容：使用类型断言和Object.hasOwnProperty检查属性是否存在 | ArkTS compatible: use type assertion and Object.hasOwnProperty
      if (typeof current !== 'object' || current === null || Array.isArray(current)) {
        return defaultValue;
      }
      // 检查属性是否存在 | Check if property exists
      const objRecord = current as GenericObject;
      const objKeys = Object.keys(objRecord);
      if (!objKeys.includes(key)) {
        return defaultValue;
      }
      const nextValue = TypeSafetyHelper.getSafeProperty(objRecord, key);
      if (typeof nextValue === 'object' && nextValue !== null && !Array.isArray(nextValue)) {
        current = nextValue;
      } else if (i === keys.length - 1) {
        return nextValue as T;
      } else {
        return defaultValue;
      }
    }

    return current as T;
  }

  /**
   * 安全地设置对象属性 | Safely sets object property
   * @param obj 目标对象 | Target object
   * @param path 属性路径 | Property path
   * @param value 属性值 | Property value
   * @returns 是否设置成功 | Whether set successfully
   */
  public static safeSet(obj: object, path: string | string[], value: string | number | boolean | object | null | undefined): boolean {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return false;
    }

    const keys: string[] = Array.isArray(path) ? path : path.split('.');
    let current: object = obj;

    for (let i = 0; i < keys.length - 1; i++) {
      const key = keys[i];
      // ArkTS 兼容：使用类型断言和Object.hasOwnProperty检查属性是否存在 | ArkTS compatible: use type assertion and Object.hasOwnProperty
      if (typeof current !== 'object' || current === null || Array.isArray(current)) {
        return false;
      }
      const objRecord = current as GenericObject;
      const objKeys = Object.keys(objRecord);
      if (!objKeys.includes(key) || TypeSafetyHelper.getSafeProperty(objRecord, key) === undefined || TypeSafetyHelper.getSafeProperty(objRecord, key) === null) {
        // 创建空对象并使用类型断言 | Create empty object and use type assertion
        const newObj: GenericObject = {};
        TypeSafetyHelper.setSafeProperty(objRecord, key, newObj);
      }
      const nextValue = TypeSafetyHelper.getSafeProperty(objRecord, key);
      if (typeof nextValue !== 'object' || Array.isArray(nextValue) || nextValue === null || nextValue === undefined) {
        return false;
      }
      current = nextValue;
    }

    const lastKey = keys[keys.length - 1];
    // 使用类型断言避免索引访问问题 | Use type assertion to avoid indexed access issues
    const finalObj = current as GenericObject;
    TypeSafetyHelper.setSafeProperty(finalObj, lastKey, value);
    return true;
  }

  /**
   * 安全地调用函数 | Safely calls function
   * @param fn 要调用的函数 | Function to call
   * @param thisArg this上下文 | This context
   * @param args 函数参数 | Function arguments
   * @param defaultValue 默认返回值 | Default return value
   * @returns 函数返回值或默认值 | Function return value or default value
   */
  public static safeCall<T = string | number | boolean | object | null | undefined>(fn: (...args: (string | number | boolean | object | null | undefined)[]) => T, thisArg: object, args: (string | number | boolean | object | null | undefined)[], defaultValue?: T): T | undefined {
    if (typeof fn !== 'function') {
      return defaultValue;
    }
    // ArkTS兼容：直接调用函数，不使用apply方法 | ArkTS compatible: directly call function, not using apply method
    switch (args.length) {
      case 0:
        return fn();
      case 1:
        return fn(args[0]);
      case 2:
        return fn(args[0], args[1]);
      case 3:
        return fn(args[0], args[1], args[2]);
      case 4:
        return fn(args[0], args[1], args[2], args[3]);
      case 5:
        return fn(args[0], args[1], args[2], args[3], args[4]);
      default:
        // 对于超过5个参数的情况，返回默认值 | For cases with more than 5 parameters, return default value
        return defaultValue;
    }
  }

  /**
   * 安全地创建错误对象 | Safely creates error object
   * @param message 错误消息 | Error message
   * @param cause 错误原因 | Error cause
   * @returns 错误对象 | Error object
   */
  public static safeError(message: string, cause?: string | number | boolean | object | null | undefined): Error {
    const error = new Error(message);
    if (cause) {
      // 直接设置cause属性，不使用索引访问 | Directly set cause property, not using indexed access
      error.cause = cause;
    }
    return error;
  }

  /**
   * 安全地获取枚举值 | Safely gets enum value
   * @param enumObj 枚举对象 | Enum object
   * @param value 枚举值 | Enum value
   * @param defaultValue 默认值 | Default value
   * @returns 有效的枚举值或默认值 | Valid enum value or default value
   */
  public static safeEnum<T extends Record<string, string | number | boolean>>(
    enumObj: T, 
    value: string | number | boolean | null | undefined, 
    defaultValue: string | number | boolean
  ): string | number | boolean {
    if (value === null || value === undefined) {
      return defaultValue;
    }
    // ArkTS兼容：手动检查枚举值 | ArkTS compatible: manually check enum value
    const keys: string[] = Object.keys(enumObj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (enumObj[key] === value) {
        return value;
      }
    }
    return defaultValue;
  }

  /**
   * 安全地转换为日期对象 | Safely converts to date object
   * @param value 要转换的值 | Value to convert
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的日期对象或默认值 | Converted date object or default value
   */
  public static safeDate(value: Date | string | number | null | undefined, defaultValue: Date = new Date()): Date {
    if (value instanceof Date) {
      return value;
    }
    if (value === null || value === undefined) {
      return defaultValue;
    }
    const date = new Date(value as string | number);
    return isNaN(date.getTime()) ? defaultValue : date;
  }

  /**
   * 安全地检查值是否为指定类型 | Safely checks if value is of specified type
   * @param value 要检查的值 | Value to check
   * @param type 类型字符串 | Type string
   * @returns 是否为指定类型 | Whether it is of specified type
   */
  public static isType(value: string | number | boolean | object | null | undefined, type: string): boolean {
    if (type === 'null') {
      return value === null;
    }
    if (type === 'undefined') {
      return value === undefined;
    }
    if (type === 'array') {
      return Array.isArray(value);
    }
    if (type === 'date') {
      return value instanceof Date && !isNaN((value as Date).getTime());
    }
    if (type === 'error') {
      return value instanceof Error;
    }
    return typeof value === type;
  }

  /**
   * 安全地获取数组元素 | Safely gets array element
   * @param array 数组 | Array
   * @param index 索引 | Index
   * @param defaultValue 默认值 | Default value
   * @returns 数组元素或默认值 | Array element or default value
   */
  public static safeArrayElement<T>(array: T[], index: number, defaultValue?: T): T | undefined {
    if (!Array.isArray(array) || index < 0 || index >= array.length) {
      return defaultValue;
    }
    return array[index];
  }

  /**
   * 安全地获取Map值 | Safely gets Map value
   * @param map Map对象 | Map object
   * @param key 键 | Key
   * @param defaultValue 默认值 | Default value
   * @returns Map值或默认值 | Map value or default value
   */
  public static safeMapGet<K, V>(map: Map<K, V>, key: K, defaultValue?: V): V | undefined {
    if (!(map instanceof Map)) {
      return defaultValue;
    }
    return map.has(key) ? map.get(key) : defaultValue;
  }

  /**
   * 安全地获取Set元素是否存在 | Safely checks if Set contains element
   * @param set Set对象 | Set object
   * @param value 值 | Value
   * @returns 是否存在 | Whether it exists
   */
  public static safeSetHas<T>(set: Set<T>, value: T): boolean {
    if (!(set instanceof Set)) {
      return false;
    }
    return set.has(value);
  }

  /**
   * 安全地将值转换为指定类型 | Safely converts value to specified type
   * @param value 要转换的值 | Value to convert
   * @param type 类型字符串 | Type string
   * @param defaultValue 默认值 | Default value
   * @returns 转换后的类型或默认值 | Converted type or default value
   */
  public static safeConvert<T = string | number | boolean | object | null | undefined>(value: string | number | boolean | object | null | undefined, type: string, defaultValue: T): T {
    switch (type) {
      case 'string':
        return TypeSafetyHelper.safeString(value, defaultValue as string) as T;
      case 'number':
        return TypeSafetyHelper.safeNumber(value, defaultValue as number) as T;
      case 'boolean':
        return TypeSafetyHelper.safeBoolean(value, defaultValue as boolean) as T;
      case 'array':
        return TypeSafetyHelper.safeArray(value, defaultValue as (string | number | boolean | object | null | undefined)[]) as T;
      case 'object':
        return TypeSafetyHelper.safeObject(value, defaultValue as SafeObject) as T;
      case 'date':
        return TypeSafetyHelper.safeDate(value, defaultValue as Date) as T;
      default:
        return defaultValue;
    }
  }

  /**
   * 安全地执行异步函数 | Safely executes async function
   * @param fn 异步函数 | Async function
   * @param args 函数参数 | Function arguments
   * @param options 选项 | Options
   * @returns 执行结果 | Execution result
   */
  public static async safeAsyncExecute<T = string | number | boolean | object | null | undefined>(
    fn: (...args: (string | number | boolean | object | null | undefined)[]) => Promise<T>,
    args: (string | number | boolean | object | null | undefined)[],
    options?: SafeAsyncExecuteOptions<T>
  ): Promise<T | undefined> {
    try {
      return await fn(...args);
    } catch (error) {
      if (options && options.onError) {
        options.onError(error instanceof Error ? error : new Error(String(error)));
      }
      return options ? options.defaultValue : undefined;
    }
  }

  /**
   * 安全地访问可选链属性 | Safely accesses optional chaining property
   * @param obj 目标对象 | Target object
   * @param path 属性路径 | Property path
   * @param defaultValue 默认值 | Default value
   * @returns 属性值或默认值 | Property value or default value
   */
  public static optionalChain<T = string | number | boolean | object | null | undefined>(obj: object, path: string, defaultValue?: T): T | undefined {
    if (!obj || typeof obj !== 'object' || Array.isArray(obj)) {
      return defaultValue;
    }
    const keys = path.split('.');
    let current: object = obj;
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (current === null || current === undefined) {
        return defaultValue;
      }
      if (typeof current !== 'object' || Array.isArray(current)) {
        return defaultValue;
      }
      // ArkTS 兼容：使用类型断言避免索引访问问题 | ArkTS compatible: use type assertion to avoid indexed access issues
      const objRecord = current as GenericObject;
      const value = objRecord[key];
      if (value !== undefined && value !== null && typeof value === 'object' && !Array.isArray(value)) {
        current = value;
      } else if (i === keys.length - 1) {
        return value as T;
      } else {
        return defaultValue;
      }
    }
    return current as T | undefined;
  }

  /**
   * 安全地合并对象 | Safely merges objects
   * @param target 目标对象 | Target object
   * @param sources 源对象 | Source objects
   * @returns 合并后的对象 | Merged object
   */
  public static safeMerge<T extends SafeObject>(
    target: T,
    ...sources: SafeObject[]
  ): T {
    if (!sources.length) {
      return target;
    }
    // ArkTS兼容：手动创建合并对象，不使用展开运算符 | ArkTS compatible: manually create merged object, not using spread operator
    const merged: GenericObject = {};
    const targetKeys: string[] = Object.keys(target);
    for (let i = 0; i < targetKeys.length; i++) {
      const key = targetKeys[i];
      // ArkTS 兼容：使用类型断言避免索引访问问题 | ArkTS compatible: use type assertion to avoid indexed access issues
      const targetRecord = target as GenericObject;
      merged[key] = targetRecord[key];
    }
    for (const source of sources) {
      if (source && typeof source === 'object') {
        const sourceKeys: string[] = Object.keys(source);
        for (let i = 0; i < sourceKeys.length; i++) {
          const key = sourceKeys[i];
          // ArkTS 兼容：使用类型断言避免索引访问问题 | ArkTS compatible: use type assertion to avoid indexed access issues
          const sourceRecord = source as GenericObject;
          const sourceValue = sourceRecord[key];
          const targetValue = merged[key];
          if (typeof targetValue === 'object' && targetValue !== null && typeof sourceValue === 'object' && sourceValue !== null) {
            // 对于对象类型，直接合并并转换 | For object types, merge directly and convert
            const mergedValue = TypeSafetyHelper.safeMerge(
              targetValue as SafeObject,
              sourceValue as SafeObject
            );
            // 直接赋值 | Direct assignment
            merged[key] = mergedValue;
          } else {
            merged[key] = sourceValue;
          }
        }
      }
    }
    return merged as T;
  }

  /**
   * 安全地克隆对象 | Safely clones object
   * @param obj 要克隆的对象 | Object to clone
   * @returns 克隆后的对象 | Cloned object
   */
  public static safeClone<T = string | number | boolean | object | null | undefined>(obj: T): T {
    if (obj === null || obj === undefined) {
      return obj;
    }
    if (obj instanceof Date) {
      return new Date((obj as Date).getTime()) as T;
    }
    if (Array.isArray(obj)) {
      // ArkTS兼容：手动创建新数组，不使用展开运算符 | ArkTS compatible: manually create new array, not using spread operator
      const clonedArray = [] as (string | number | boolean | object | null | undefined)[];
      for (let i = 0; i < (obj as (string | number | boolean | object | null | undefined)[]).length; i++) {
        const arrayItem = (obj as (string | number | boolean | object | null | undefined)[])[i];
        clonedArray.push(TypeSafetyHelper.safeClone(arrayItem));
      }
      return clonedArray as T;
    }
    if (typeof obj === 'object') {
        const clonedObj: GenericObject = {};
        const keys: string[] = Object.keys(obj as SafeObject);
        for (let i = 0; i < keys.length; i++) {
          const key = keys[i];
          // ArkTS 兼容：使用类型断言避免索引访问问题 | ArkTS compatible: use type assertion to avoid indexed access issues
          const objRecord = obj as GenericObject;
          clonedObj[key] = TypeSafetyHelper.safeClone(objRecord[key]);
        }
        return clonedObj as T;
      }
    return obj;
  }
}

export default TypeSafetyHelper;
