// ArkTSBaseTypes.ets - ArkTS兼容的基础类型定义

/**
 * 基础类型工具函数
 * 提供ArkTS环境中常用的类型定义和工具函�? */

/**
 * 定义Any类型，替代TypeScript的any，在ArkTS中提供更安全的类型使�? */
export type SafeAny = unknown;

/**
 * 定义函数类型，避免使用Function关键�? */
export type SafeFunction = (...args: Record<string, string | number | boolean | null>[]) => unknown;

/**
 * 定义Async函数类型
 */
export type SafeAsyncFunction = (...args: Record<string, string | number | boolean | null>[]) => Promise<unknown>;

/**
 * 安全对象类型，替代索引签�? */
export interface SafeObject {
  [key: string]: string | number | boolean | object | null | undefined;
}

/**
 * 键值对类型
 */
export interface KeyValuePair<K, V> {
  key: K;
  value: V;
}

/**
 * 可序列化的数据类�? */
export type SerializableData = 
  | string
  | number
  | boolean
  | null
  | SerializableData[]
  | Record<string, SerializableData>;

/**
 * 结果类型，包含成功和失败两种状�? */
export interface Result<T, E = Error> {
  success: boolean;
  data?: T;
  error?: E;
}

/**
 * 可选值类�? */
export type Optional<T> = T | undefined | null;

/**
 * 非空值类型断言函数
 */
export function assertNotNull<T>(value: Optional<T>): asserts value is T {
  if (value === null || value === undefined) {
    throw new Error('Value cannot be null or undefined');
  }
}

/**
 * 类型守卫函数：检查值是否为非null和非undefined
 */
export function isNonNull<T>(value: Optional<T>): value is T {
  return value !== null && value !== undefined;
}

