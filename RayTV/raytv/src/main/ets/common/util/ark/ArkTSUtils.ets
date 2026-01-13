// ArkTSUtils.ets - ArkTS兼容工具函数库 ArkTS compatible utility functions library
// Provides common utility functions that conform to ArkTS syntax rules

/**
 * ArkTS兼容工具函数库 ArkTS compatible utility functions library
 * This module provides a set of optimized and compatibility-handled utility functions, ensuring smooth operation in ArkTS environment
 */

// Export type definitions
export * from './types/ArkTSBaseTypes';

// Export utility functions
export * as TypeUtils from './TypeUtils';
export * as ObjectUtils from './ObjectUtils';
export * as ArrayUtils from './ArrayUtils';
export * as StringUtils from './StringUtils';
export * as ErrorUtils from './ErrorUtils';
export * as AssertUtils from './AssertUtils';

/**
 * ArkTS兼容工具库主类 ArkTS compatible utility library main class
 * Provides unified utility functions access entry
 */
export default class ArkTSUtils {
  /**
   * 类型相关工具函数 Type related utility functions
   */
  public static get Type() {
    return TypeUtils;
  }

  /**
   * 对象相关工具函数 Object related utility functions
   */
  public static get Object() {
    return ObjectUtils;
  }

  /**
   * 数组相关工具函数 Array related utility functions
   */
  public static get Array() {
    return ArrayUtils;
  }

  /**
   * 字符串相关工具函数 String related utility functions
   */
  public static get String() {
    return StringUtils;
  }

  /**
   * 错误处理相关工具函数 Error handling related utility functions
   */
  public static get Error() {
    return ErrorUtils;
  }

  /**
   * 断言相关工具函数 Assert related utility functions
   */
  public static get Assert() {
    return AssertUtils;
  }
}



