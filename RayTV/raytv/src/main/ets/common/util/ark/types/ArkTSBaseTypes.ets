// ArkTSBaseTypes.ets - ArkTS兼容的基本类型定义 ArkTS compatible basic type definitions

/**
 * 基础类型工具函数 Basic type utility functions
 * 提供ArkTS环境中常用的类型定义和辅助函数 Provides common type definitions and helper functions in ArkTS environment
 */
/**
 * 定义Any类型，对应TypeScript的any，在ArkTS中提供更安全的类型使用 Defines Any type, corresponding to TypeScript's any, provides safer type usage in ArkTS
 */
export type SafeAny = string | number | boolean | object | null | undefined;
/**
 * 定义函数类型，避免使用function关键字 Defines function type, avoids using function keyword
 */
export type SafeFunction = (...args: (string | number | boolean | object | null | undefined)[]) => void;

/**
 * 定义Async函数类型 Defines Async function type
 */
export type SafeAsyncFunction = (...args: (string | number | boolean | object | null | undefined)[]) => Promise<void>;

/**
 * 键值对类型 Key-value pair type
 */
export interface KeyValuePair<K, V> {
  key: K;
  value: V;
}

/**
 * 可序列化的数据类型 Serializable data type
 */
export type SerializableData = 
  | string
  | number
  | boolean
  | null
  | string[]
  | number[]
  | boolean[]
  | null[];

/**
 * 结果类型，包含成功和失败两种状态 Result type, includes success and failure states
 */
export interface Result<T, E = Error> {
  success: boolean;
  data?: T;
  error?: E;
}

/**
 * 可选类型 Optional type
 */
export type Optional<T> = T | undefined | null;

/**
 * 非空检查函数 Non-null check function
 */
export function isNotNull<T>(value: Optional<T>): boolean {
  return value !== null && value !== undefined;
}

/**
 * 断言非空函数 Assert non-null function
 */
export function assertNotNull<T>(value: Optional<T>): void {
  if (value === null || value === undefined) {
    throw new Error('Value cannot be null or undefined');
  }
}




