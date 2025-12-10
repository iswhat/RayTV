// ArkTSUtils.ets - ArkTS兼容工具函数�?// 提供符合ArkTS语法规范的通用工具函数集合

/**
 * ArkTS兼容工具函数�? * 该模块提供了一组经过优化和兼容处理的工具函数，确保在ArkTS环境中正常工�? */

// 导出类型定义
export * from './types/ArkTSBaseTypes';

// 导出工具函数
export * as TypeUtils from './TypeUtils';
export * as ObjectUtils from './ObjectUtils';
export * as ArrayUtils from './ArrayUtils';
export * as StringUtils from './StringUtils';
export * as ErrorUtils from './ErrorUtils';
export * as AssertUtils from './AssertUtils';

/**
 * ArkTS兼容工具库主�? * 提供统一的工具函数访问入�? */
export default class ArkTSUtils {
  /**
   * 类型相关工具函数
   */
  public static get Type() {
    return TypeUtils;
  }

  /**
   * 对象相关工具函数
   */
  public static get Object() {
    return ObjectUtils;
  }

  /**
   * 数组相关工具函数
   */
  public static get Array() {
    return ArrayUtils;
  }

  /**
   * 字符串相关工具函�?   */
  public static get String() {
    return StringUtils;
  }

  /**
   * 错误处理相关工具函数
   */
  public static get Error() {
    return ErrorUtils;
  }

  /**
   * 断言相关工具函数
   */
  public static get Assert() {
    return AssertUtils;
  }
}
