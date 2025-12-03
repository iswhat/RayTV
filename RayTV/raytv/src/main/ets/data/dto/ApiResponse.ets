// ApiResponse - API响应数据传输对象
import Logger from '../../common/util/Logger';

const TAG = 'ApiResponse';

/**
 * 响应状态码枚举
 */
export enum ResponseCode {
  // 成功状态码
  SUCCESS = 200,
  CREATED = 201,
  NO_CONTENT = 204,
  
  // 客户端错误状态码
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  FORBIDDEN = 403,
  NOT_FOUND = 404,
  METHOD_NOT_ALLOWED = 405,
  CONFLICT = 409,
  VALIDATION_ERROR = 422,
  
  // 服务器错误状态码
  INTERNAL_SERVER_ERROR = 500,
  SERVICE_UNAVAILABLE = 503,
  GATEWAY_TIMEOUT = 504,
  
  // 自定义状态码
  NETWORK_ERROR = -100,
  TIMEOUT_ERROR = -101,
  PARSE_ERROR = -102,
  UNKNOWN_ERROR = -103,
  CACHE_ERROR = -104,
  AUTHENTICATION_ERROR = -401,
  PERMISSION_ERROR = -403
}

/**
 * 分页信息接口
 */
export interface PaginationInfo {
  page: number;        // 当前页码
  pageSize: number;    // 每页大小
  total: number;       // 总条�?  totalPages: number;  // 总页�?  hasMore: boolean;    // 是否有更�?}

/**
   * 错误详情接口
   */
export interface ErrorDetail {
  field?: string;      // 字段名称（用于验证错误）
  message: string;     // 错误消息
  code?: string;       // 错误代码
  value?: string | number | boolean | null;     // 错误�?}

/**
 * API响应�? * 用于标准化API响应结构
 */
// API响应参数接口
export interface ApiResponseParams<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  code: ResponseCode;
  message: string;
  data?: T;
  errors?: ErrorDetail[];
  pagination?: PaginationInfo;
  requestId?: string;
  trace?: string;
}

export default class ApiResponse<T = string | number | boolean | null | Record<string, string | number | boolean | null>> {
  code: ResponseCode;             // 响应状态码
  message: string;                // 响应消息
  data?: T;                       // 响应数据
  errors?: ErrorDetail[];         // 错误详情（用于表单验证等�?  pagination?: PaginationInfo;    // 分页信息
  timestamp: number;              // 响应时间�?  requestId?: string;             // 请求ID（用于跟踪）
  trace?: string;                 // 跟踪信息

  /**
   * 构造函�?   */
  constructor(params: ApiResponseParams<T>) {
    this.code = params.code;
    this.message = params.message;
    this.data = params.data;
    this.errors = params.errors;
    this.pagination = params.pagination;
    this.timestamp = Date.now();
    this.requestId = params.requestId;
    this.trace = params.trace;
  }

  /**
   * 是否成功响应
   */
  isSuccess(): boolean {
    return this.code >= 200 && this.code < 300;
  }

  /**
   * 是否错误响应
   */
  isError(): boolean {
    return !this.isSuccess();
  }

  /**
   * 是否客户端错�?   */
  isClientError(): boolean {
    return this.code >= 400 && this.code < 500 || 
           this.code === ResponseCode.AUTHENTICATION_ERROR || 
           this.code === ResponseCode.PERMISSION_ERROR;
  }

  /**
   * 是否服务器错�?   */
  isServerError(): boolean {
    return this.code >= 500 || 
           this.code === ResponseCode.NETWORK_ERROR ||
           this.code === ResponseCode.TIMEOUT_ERROR ||
           this.code === ResponseCode.UNKNOWN_ERROR;
  }

  /**
   * 是否网络错误
   */
  isNetworkError(): boolean {
    return [
      ResponseCode.NETWORK_ERROR,
      ResponseCode.TIMEOUT_ERROR
    ].includes(this.code);
  }

  /**
   * 是否认证错误
   */
  isAuthError(): boolean {
    return this.code === ResponseCode.UNAUTHORIZED || 
           this.code === ResponseCode.AUTHENTICATION_ERROR;
  }

  /**
   * 是否权限错误
   */
  isPermissionError(): boolean {
    return this.code === ResponseCode.FORBIDDEN || 
           this.code === ResponseCode.PERMISSION_ERROR;
  }

  /**
   * 是否未找到资�?   */
  isNotFound(): boolean {
    return this.code === ResponseCode.NOT_FOUND;
  }

  /**
   * 获取第一个错误消�?   */
  getFirstErrorMessage(): string | null {
    if (this.errors && this.errors.length > 0) {
      return this.errors[0].message;
    }
    return null;
  }

  /**
   * 获取字段错误信息
   * @param field 字段�?   */
  getFieldError(field: string): ErrorDetail | undefined {
    return this.errors?.find(error => error.field === field);
  }

  /**
   * 获取所有错误消�?   */
  getAllErrorMessages(): string[] {
    if (!this.errors || this.errors.length === 0) {
      return [];
    }
    return this.errors.map(error => error.message);
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    return `ApiResponse(code=${this.code}, message=${this.message}, hasData=${!!this.data})`;
  }

  /**
   * 记录日志
   */
  log(): void {
    if (this.isSuccess()) {
      Logger.info(TAG, `Success response: ${this.toString()}`);
    } else {
      Logger.error(TAG, `Error response: ${this.toString()}, errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors instanceof Error ? errors: ${JSON.stringify(this.errors : new Error(String(errors: ${JSON.stringify(this.errors)))))))}`);
    }
  }

  /**
   * 转换为对象（用于序列化）
   */
  toObject(): Record<string, unknown> {
    return {
      code: this.code,
      message: this.message,
      data: this.data,
      errors: this.errors,
      pagination: this.pagination,
      timestamp: this.timestamp,
      requestId: this.requestId,
      trace: this.trace
    };
  }

  /**
   * 从对象创建实�?   * @param obj 对象数据
   */
  static fromObject<T = unknown>(obj: Record<string, unknown>): ApiResponse<T> {
    const params: ApiResponseParams<T> = {
      code: typeof obj.code === 'number' ? obj.code : ResponseCode.SUCCESS,
      message: typeof obj.message === 'string' ? obj.message : 'Unknown response',
      data: obj.data as T,
      errors: Array.isArray(obj.errors) ? obj.errors : undefined,
      pagination: typeof obj.pagination === 'object' && obj.pagination !== null ? obj.pagination : undefined,
      requestId: typeof obj.requestId === 'string' ? obj.requestId : undefined,
      trace: typeof obj.trace === 'string' ? obj.trace : undefined
    };
    return new ApiResponse<T>(params);
  }

  // ========== 静态工厂方�?==========

  /**
   * 创建成功响应
   */
  static success<T = unknown>(data?: T, message: string = 'Success'): ApiResponse<T> {
    return new ApiResponse<T>({
      code: ResponseCode.SUCCESS,
      message,
      data
    });
  }

  /**
   * 创建带分页的成功响应
   */
  static successWithPagination<T = unknown>(
    data: T,
    pagination: PaginationInfo,
    message: string = 'Success'
  ): ApiResponse<T> {
    return new ApiResponse<T>({
      code: ResponseCode.SUCCESS,
      message,
      data,
      pagination
    });
  }

  /**
   * 创建错误响应
   */
  static error<T = unknown>(
    code: ResponseCode,
    message: string,
    errors?: ErrorDetail[]
  ): ApiResponse<T> {
    return new ApiResponse<T>({
      code,
      message,
      errors
    });
  }

  /**
   * 创建参数错误响应
   */
  static badRequest<T = unknown>(message: string = 'Bad Request', errors?: ErrorDetail[]): ApiResponse<T> {
    return this.error<T>(ResponseCode.BAD_REQUEST, message, errors);
  }

  /**
   * 创建未授权错误响�?   */
  static unauthorized<T = unknown>(message: string = 'Unauthorized'): ApiResponse<T> {
    return this.error<T>(ResponseCode.UNAUTHORIZED, message);
  }

  /**
   * 创建禁止访问错误响应
   */
  static forbidden<T = unknown>(message: string = 'Forbidden'): ApiResponse<T> {
    return this.error<T>(ResponseCode.FORBIDDEN, message);
  }

  /**
   * 创建未找到资源错误响�?   */
  static notFound<T = unknown>(message: string = 'Resource not found'): ApiResponse<T> {
    return this.error<T>(ResponseCode.NOT_FOUND, message);
  }

  /**
   * 创建服务器错误响�?   */
  static serverError<T = unknown>(message: string = 'Internal server error'): ApiResponse<T> {
    return this.error<T>(ResponseCode.INTERNAL_SERVER_ERROR, message);
  }

  /**
   * 创建网络错误响应
   */
  static networkError<T = unknown>(message: string = 'Network error'): ApiResponse<T> {
    return this.error<T>(ResponseCode.NETWORK_ERROR, message);
  }

  /**
   * 创建超时错误响应
   */
  static timeoutError<T = unknown>(message: string = 'Request timeout'): ApiResponse<T> {
    return this.error<T>(ResponseCode.TIMEOUT_ERROR, message);
  }

  /**
   * 创建解析错误响应
   */
  static parseError<T = unknown>(message: string = 'Parse error'): ApiResponse<T> {
    return this.error<T>(ResponseCode.PARSE_ERROR, message);
  }

  /**
   * 创建验证错误响应
   */
  static validationError<T = unknown>(errors: ErrorDetail[], message: string = 'Validation failed'): ApiResponse<T> {
    return this.error<T>(ResponseCode.VALIDATION_ERROR, message, errors);
  }

  /**
   * 创建单个验证错误响应
   */
  static singleValidationError<T = unknown>(field: string, message: string): ApiResponse<T> {
    const error: ErrorDetail = { field, message };
    return this.validationError<T>([error]);
  }

  /**
   * 从错误创建响�?   */
  static fromError<T = unknown>(error: Error): ApiResponse<T> {
    // 可以根据不同类型的错误返回不同的响应
    Logger.error(TAG, `Creating response from error: ${error.message}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    
    return this.error<T>(ResponseCode.UNKNOWN_ERROR, error.message);
  }

  /**
   * 创建分页信息
   */
  static createPagination(
    page: number,
    pageSize: number,
    total: number
  ): PaginationInfo {
    const totalPages = Math.ceil(total / pageSize);
    return {
      page,
      pageSize,
      total,
      totalPages,
      hasMore: page < totalPages
    };
  }

  /**
   * 创建错误详情
   */
  static createErrorDetail(
    message: string,
    field?: string,
    code?: string,
    value?: Record<string, string | number | boolean | null>
  ): ErrorDetail {
    return {
      field,
      message,
      code,
      value
    };
  }
}


