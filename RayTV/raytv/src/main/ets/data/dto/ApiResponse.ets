// ApiResponse - API响应数据传输对象 | API response data transfer object
import Logger from '../../common/util/Logger';

const TAG = 'ApiResponse';

/**
 * 响应状态码枚举 | Response status code enum
 */
export enum ResponseCode {
  // 成功状态码 | Success status codes
  SUCCESS = 200,
  CREATED = 201,
  NO_CONTENT = 204,
  
  // 客户端错误状态码 | Client error status codes
  BAD_REQUEST = 400,
  UNAUTHORIZED = 401,
  FORBIDDEN = 403,
  NOT_FOUND = 404,
  METHOD_NOT_ALLOWED = 405,
  CONFLICT = 409,
  VALIDATION_ERROR = 422,
  
  // 服务器错误状态码 | Server error status codes
  INTERNAL_SERVER_ERROR = 500,
  SERVICE_UNAVAILABLE = 503,
  GATEWAY_TIMEOUT = 504,
  
  // 自定义状态码 | Custom status codes
  NETWORK_ERROR = -100,
  TIMEOUT_ERROR = -101,
  PARSE_ERROR = -102,
  UNKNOWN_ERROR = -103,
  CACHE_ERROR = -104,
  AUTHENTICATION_ERROR = -401,
  PERMISSION_ERROR = -403
}

/**
 * 分页信息接口 | Pagination information interface
 */
export interface PaginationInfo {
  page: number;        // 当前页码 | Current page number
  pageSize: number;    // 每页大小 | Page size
  total: number;       // 总条数 | Total count
  totalPages: number;  // 总页数 | Total pages
  hasMore: boolean;    // 是否有更多 | Whether has more
}

/**
 * 错误详情接口 | Error detail interface
 */
export interface ErrorDetail {
  field?: string;      // 字段名称（用于验证错误） | Field name (for validation errors)
  message: string;     // 错误消息 | Error message
  code?: string;       // 错误代码 | Error code
  value?: string | number | boolean | null;     // 错误值 | Error value
}

/**
 * API响应参数接口 | API response parameters interface
 */
export interface ApiResponseParams<T = Record<string, string | number | boolean | null>> {
  code: ResponseCode;
  message: string;
  data?: T;
  errors?: ErrorDetail[];
  pagination?: PaginationInfo;
  requestId?: string;
  trace?: string;
}

/**
 * API响应对象接口（用于序列化） | API response object interface (for serialization)
 */
export interface ApiResponseObject<T = Record<string, string | number | boolean | null>> {
  code: ResponseCode;
  message: string;
  timestamp: number;
  data?: T;
  errors?: ErrorDetail[];
  pagination?: PaginationInfo;
  requestId?: string;
  trace?: string;
}

export default class ApiResponse<T = Record<string, string | number | boolean | null>> {
  code: ResponseCode;             // 响应状态码 | Response status code
  message: string;                // 响应消息 | Response message
  data?: T;                       // 响应数据 | Response data
  errors?: ErrorDetail[];         // 错误详情（用于表单验证等） | Error details (for form validation, etc.)
  pagination?: PaginationInfo;    // 分页信息 | Pagination information
  timestamp: number;              // 响应时间戳 | Response timestamp
  requestId?: string;             // 请求ID（用于追溯） | Request ID (for tracing)
  trace?: string;                 // 追踪信息 | Trace information

  /**
   * 构造函数 | Constructor
   */
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
   * 是否成功响应 | Whether success response
   */
  isSuccess(): boolean {
    return this.code >= 200 && this.code < 300;
  }

  /**
   * 是否错误响应 | Whether error response
   */
  isError(): boolean {
    return !this.isSuccess();
  }

  /**
   * 是否客户端错误 | Whether client error
   */
  isClientError(): boolean {
    return this.code >= 400 && this.code < 500 || 
           this.code === ResponseCode.AUTHENTICATION_ERROR || 
           this.code === ResponseCode.PERMISSION_ERROR;
  }

  /**
   * 是否服务器错误 | Whether server error
   */
  isServerError(): boolean {
    return this.code >= 500 || 
           this.code === ResponseCode.NETWORK_ERROR ||
           this.code === ResponseCode.TIMEOUT_ERROR ||
           this.code === ResponseCode.UNKNOWN_ERROR;
  }

  /**
   * 是否网络错误 | Whether network error
   */
  isNetworkError(): boolean {
    return [
      ResponseCode.NETWORK_ERROR,
      ResponseCode.TIMEOUT_ERROR
    ].includes(this.code);
  }

  /**
   * 是否认证错误 | Whether authentication error
   */
  isAuthError(): boolean {
    return this.code === ResponseCode.UNAUTHORIZED || 
           this.code === ResponseCode.AUTHENTICATION_ERROR;
  }

  /**
   * 是否权限错误 | Whether permission error
   */
  isPermissionError(): boolean {
    return this.code === ResponseCode.FORBIDDEN || 
           this.code === ResponseCode.PERMISSION_ERROR;
  }

  /**
   * 是否未找到资源 | Whether resource not found
   */
  isNotFound(): boolean {
    return this.code === ResponseCode.NOT_FOUND;
  }

  /**
   * 获取第一个错误消息 | Get first error message
   */
  getFirstErrorMessage(): string | null {
    if (this.errors && this.errors.length > 0) {
      return this.errors[0].message;
    }
    return null;
  }

  /**
   * 获取字段错误信息 | Get field error information
   * @param field 字段名 | Field name
   */
  getFieldError(field: string): ErrorDetail | undefined {
    return this.errors?.find(error => error.field === field);
  }

  /**
   * 获取所有错误消息 | Get all error messages
   */
  getAllErrorMessages(): string[] {
    if (!this.errors || this.errors.length === 0) {
      return [];
    }
    return this.errors.map(error => error.message);
  }

  /**
   * 转换为字符串 | Convert to string
   */
  toString(): string {
    return `ApiResponse(code=${this.code}, message=${this.message}, hasData=${!!this.data})`;
  }

  /**
   * 记录日志 | Log
   */
  log(): void {
    if (this.isSuccess()) {
      Logger.info(TAG, `Success response: ${this.toString()}`);
    } else {
      Logger.error(TAG, `Error response: ${this.toString()}, errors: ${JSON.stringify(this.errors)}`);
    }
  }

  /**
   * 转换为对象（用于序列化） | Convert to object (for serialization)
   */
  toObject(): ApiResponseObject<T> {
    const result: ApiResponseObject<T> = {
      code: this.code,
      message: this.message,
      timestamp: this.timestamp
    };
    
    if (this.data !== undefined) {
      result.data = this.data;
    }
    
    if (this.errors !== undefined) {
      result.errors = this.errors;
    }
    
    if (this.pagination !== undefined) {
      result.pagination = this.pagination;
    }
    
    if (this.requestId !== undefined) {
      result.requestId = this.requestId;
    }
    
    if (this.trace !== undefined) {
      result.trace = this.trace;
    }
    
    return result;
  }

  /**
   * 从对象创建实例 | Create instance from object
   * @param obj 对象数据 | Object data
   */
  static fromObject<T>(obj: Record<string, string | number | boolean | null | T | ErrorDetail[] | PaginationInfo>): ApiResponse<T> {
    const params: ApiResponseParams<T> = {
      code: typeof obj.code === 'number' ? obj.code : ResponseCode.SUCCESS,
      message: typeof obj.message === 'string' ? obj.message : 'Unknown response',
      data: obj.data as T,
      errors: Array.isArray(obj.errors) ? obj.errors as ErrorDetail[] : undefined,
      pagination: typeof obj.pagination === 'object' && obj.pagination !== null ? obj.pagination as PaginationInfo : undefined,
      requestId: typeof obj.requestId === 'string' ? obj.requestId : undefined,
      trace: typeof obj.trace === 'string' ? obj.trace : undefined
    };
    return new ApiResponse<T>(params);
  }

  // ========== 便捷工厂方法 ========== | ========== Convenient factory methods ==========

  /**
   * 创建成功响应 | Create success response
   */
  static success<T = Record<string, string | number | boolean | null>>(data?: T, message: string = 'Success'): ApiResponse<T> {
    return new ApiResponse<T>({
      code: ResponseCode.SUCCESS,
      message,
      data
    });
  }

  /**
   * 创建带分页的成功响应 | Create success response with pagination
   */
  static successWithPagination<T = Record<string, string | number | boolean | null>>(
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
   * 创建错误响应 | Create error response
   */
  static error<T = Record<string, string | number | boolean | null>>(
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
   * 创建参数错误响应 | Create bad request response
   */
  static badRequest<T = Record<string, string | number | boolean | null>>(message: string = 'Bad Request', errors?: ErrorDetail[]): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.BAD_REQUEST, message, errors);
  }

  /**
   * 创建未授权错误响应 | Create unauthorized response
   */
  static unauthorized<T = Record<string, string | number | boolean | null>>(message: string = 'Unauthorized'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.UNAUTHORIZED, message);
  }

  /**
   * 创建禁止访问错误响应 | Create forbidden response
   */
  static forbidden<T = Record<string, string | number | boolean | null>>(message: string = 'Forbidden'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.FORBIDDEN, message);
  }

  /**
   * 创建未找到资源错误响应 | Create not found response
   */
  static notFound<T = Record<string, string | number | boolean | null>>(message: string = 'Resource not found'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.NOT_FOUND, message);
  }

  /**
   * 创建服务器错误响应 | Create server error response
   */
  static serverError<T = Record<string, string | number | boolean | null>>(message: string = 'Internal server error'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.INTERNAL_SERVER_ERROR, message);
  }

  /**
   * 创建网络错误响应 | Create network error response
   */
  static networkError<T = Record<string, string | number | boolean | null>>(message: string = 'Network error'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.NETWORK_ERROR, message);
  }

  /**
   * 创建超时错误响应 | Create timeout error response
   */
  static timeoutError<T = Record<string, string | number | boolean | null>>(message: string = 'Request timeout'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.TIMEOUT_ERROR, message);
  }

  /**
   * 创建解析错误响应 | Create parse error response
   */
  static parseError<T = Record<string, string | number | boolean | null>>(message: string = 'Parse error'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.PARSE_ERROR, message);
  }

  /**
   * 创建验证错误响应 | Create validation error response
   */
  static validationError<T = Record<string, string | number | boolean | null>>(errors: ErrorDetail[], message: string = 'Validation failed'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.VALIDATION_ERROR, message, errors);
  }

  /**
   * 创建单个验证错误响应 | Create single validation error response
   */
  static singleValidationError<T = Record<string, string | number | boolean | null>>(field: string, message: string): ApiResponse<T> {
    const error: ErrorDetail = { field, message };
    return ApiResponse.validationError<T>([error]);
  }

  /**
   * 从错误创建响应 | Create response from error
   */
  static fromError<T = Record<string, string | number | boolean | null>>(error: Error): ApiResponse<T> {
    // 可以根据不同类型的错误返回不同的响应 | Can return different responses based on different error types
    Logger.error(TAG, `Creating response from error: ${error.message}`, error);
    
    return ApiResponse.error<T>(ResponseCode.UNKNOWN_ERROR, error.message);
  }

  /**
   * 创建分页信息 | Create pagination information
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
   * 创建错误详情 | Create error detail
   */
  static createErrorDetail(
    message: string,
    field?: string,
    code?: string,
    value?: string | number | boolean | null
  ): ErrorDetail {
    return {
      field,
      message,
      code,
      value
    };
  }
}
