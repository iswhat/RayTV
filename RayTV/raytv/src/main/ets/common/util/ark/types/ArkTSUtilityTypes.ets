// ArkTSUtilityTypes.ets - ArkTS兼容的TypeScript Utility Types实现

/**
 * ArkTS兼容的TypeScript Utility Types实现
 * 提供与TypeScript标准库中类似功能的类型定义，但符合ArkTS语法规范
 */

// ============= 基础工具类型 =============

/**
 * 将所有属性设置为可�? * 替代TypeScript的Partial<T>
 * ArkTS简化版本，不使用映射类�? */
export type ArkTSPartial<T> = T;

/**
 * 将所有属性设置为必需
 * 替代TypeScript的Required<T>
 * ArkTS简化版本，不使用映射类�? */
export type ArkTSRequired<T> = T;

/**
 * 从对象类型中选取指定的属�? * 替代TypeScript的Pick<T, K>
 * ArkTS简化版�? */
export type ArkTSPick<T, K> = T;

/**
 * 从对象类型中排除指定的属�? * 替代TypeScript的Omit<T, K>
 * ArkTS简化版�? */
export type ArkTSOmit<T, K> = T;

/**
 * 创建具有指定键类型和值类型的对象类型
 * 替代TypeScript的Record<K, T>
 * ArkTS简化版�? */
export type ArkTSRecord<K extends string | number | symbol, T> = Record<string | number | symbol, T>;

/**
 * 将所有属性设置为只读
 * 替代TypeScript的Readonly<T>
 * ArkTS简化版�? */
export type ArkTSReadonly<T> = T;

/**
 * 排除联合类型中的一部分类型
 * 替代TypeScript的Exclude<T, U>
 * ArkTS简化版本，直接返回T
 */
export type ArkTSExclude<T, U> = T;

/**
 * 从联合类型中提取与指定类型匹配的类型
 * 替代TypeScript的Extract<T, U>
 * ArkTS简化版本，直接返回T
 */
export type ArkTSExtract<T, U> = T;

/**
 * 获取函数的返回类�? * 替代TypeScript的ReturnType<T>
 * ArkTS简化版本，使用unknown作为返回类型
 */
export type ArkTSReturnType<T> = unknown;

/**
 * 获取函数的参数类型元�? * 替代TypeScript的Parameters<T>
 * ArkTS简化版本，返回unknown[]
 */
export type ArkTSParameters<T> = unknown[];

/**
 * 获取构造函数的参数类型元组
 * 替代TypeScript的ConstructorParameters<T>
 * ArkTS简化版本，返回unknown[]
 */
export type ArkTSConstructorParameters<T> = unknown[];

/**
 * 获取构造函数的实例类型
 * 替代TypeScript的InstanceType<T>
 * ArkTS简化版本，使用unknown
 */
export type ArkTSInstanceType<T> = unknown;

/**
 * 确保类型不为null或undefined
 * 替代TypeScript的NonNullable<T>
 * ArkTS简化版本，直接返回T
 */
export type ArkTSNonNullable<T> = T;

/**
 * 获取Promise解析后的类型
 * 替代TypeScript的Awaited<T>
 * ArkTS简化版本，直接返回T
 */
export type ArkTSAwaited<T> = T;

// ============= 高级工具类型 =============

/**
 * 深度Partial类型
 * ArkTS简化版本，不使用条件类�? */
export type ArkTSDeepPartial<T> = T;

/**
 * 深度Required类型
 * ArkTS简化版本，不使用条件类�? */
export type ArkTSDeepRequired<T> = T;

/**
 * 深度数组接口
 * ArkTS简化版�? */
export interface ArkTSDeepArray<T> extends Array<T> {}

/**
 * 深度Readonly类型
 * ArkTS简化版本，不使用条件类�? */
export type ArkTSDeepReadonly<T> = T;

/**
 * 深度Readonly数组接口
 * ArkTS简化版�? */
export interface ArkTSDeepReadonlyArray<T> extends ReadonlyArray<T> {}

/**
 * 可写类型
 * ArkTS简化版本，不使用映射类�? */
export type ArkTSWritable<T> = T;

/**
 * 深度Writable类型
 * ArkTS简化版本，不使用条件类�? */
export type ArkTSDeepWritable<T> = T;

/**
 * 深度Writable数组接口
 * ArkTS简化版�? */
export interface ArkTSDeepWritableArray<T> extends Array<T> {}

/**
 * 扁平化对象类�? * 将嵌套对象的属性展平为单层
 * ArkTS简化版�? */
export type Flatten<T> = T;

/**
 * 合并两个对象类型
 * ArkTS简化版�? */
export type Merge<T, U> = T & U;

/**
 * 联合类型转交叉类�? * ArkTS简化版本，直接返回U
 */
export type UnionToIntersection<U> = U;

/**
 * 获取对象的键类型的联�? */
export type KeyOf<T> = keyof T;

/**
 * 获取对象的值类型的联合
 */
export type ValueOf<T> = T[keyof T];

/**
 * 索引访问类型辅助
 */
export type IndexAccess<T, K extends keyof T> = T[K];

/**
 * 类型断言函数工具类型
 */
export type TypeGuard<T> = (value: Record<string, string | number | boolean | null>) => value is T;

/**
 * 类型转换函数工具类型
 */
export type Transformer<T, U> = (value: T) => U;

/**
 * 可选的类型，相当于 T | null | undefined
 */
export type Optional<T> = T | null | undefined;

/**
 * 可为空的类型，相当于 T | null
 */
export type Nullable<T> = T | null;

/**
 * 可能未定义的类型，相当于 T | undefined
 */
export type MaybeUndefined<T> = T | undefined;

/**
 * 函数属性类�? * ArkTS简化版�? */
export type FunctionPropertyNames<T> = string;

/**
 * 非函数属性类�? * ArkTS简化版�? */
export type NonFunctionPropertyNames<T> = string;

/**
 * 仅获取对象的函数属�? * ArkTS简化版�? */
export type FunctionProperties<T> = T;

/**
 * 仅获取对象的非函数属�? * ArkTS简化版�? */
export type NonFunctionProperties<T> = T;

/**
 * 字符串属性键类型
 * ArkTS简化版�? */
export type StringPropertyNames<T> = string;

/**
 * 数字属性键类型
 * ArkTS简化版�? */
export type NumberPropertyNames<T> = number;

/**
 * 符号属性键类型
 * ArkTS简化版�? */
export type SymbolPropertyNames<T> = symbol;

/**
 * 仅获取对象的字符串键属�? * ArkTS简化版�? */
export type StringProperties<T> = T;

/**
 * 仅获取对象的数字键属�? * ArkTS简化版�? */
export type NumberProperties<T> = T;

/**
 * 仅获取对象的符号键属�? * ArkTS简化版�? */
export type SymbolProperties<T> = T;

/**
 * 确保所有属性值类型一�? */
export type HomogeneousObject<T> = Record<string | number | symbol, T>;

/**
 * 精确类型，不允许额外属�? * ArkTS简化版�? */
export type Exact<T, U> = T;

/**
 * 延迟解析的类�? */
export type Deferred<T> = T;

/**
 * 条件类型替代方案 - 如果T是U的子类型，则返回X，否则返回Y
 * 在ArkTS中，这是一个简化版本的条件类型
 */
export type If<T, U, X, Y> = T;



