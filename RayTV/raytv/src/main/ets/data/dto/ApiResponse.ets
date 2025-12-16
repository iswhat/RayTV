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
  total: number;       // 总条数
  totalPages: number;  // 总页数
  hasMore: boolean;    // 是否有更多
}

/**
 * 错误详情接口
 */
export interface ErrorDetail {
  field?: string;      // 字段名称（用于验证错误）
  message: string;     // 错误消息
  code?: string;       // 错误代码
  value?: string | number | boolean | null;     // 错误值
}

/**
 * API响应参数接口
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

export default class ApiResponse<T = Record<string, string | number | boolean | null>> {
  code: ResponseCode;             // 响应状态码
  message: string;                // 响应消息
  data?: T;                       // 响应数据
  errors?: ErrorDetail[];         // 错误详情（用于表单验证等）
  pagination?: PaginationInfo;    // 分页信息
  timestamp: number;              // 响应时间戳
  requestId?: string;             // 请求ID（用于跟踪）
  trace?: string;                 // 跟踪信息

  /**
   * 构造函数
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
   * 是否客户端错误
   */
  isClientError(): boolean {
    return this.code >= 400 && this.code < 500 || 
           this.code === ResponseCode.AUTHENTICATION_ERROR || 
           this.code === ResponseCode.PERMISSION_ERROR;
  }

  /**
   * 是否服务器错误
   */
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
   * 是否未找到资源
   */
  isNotFound(): boolean {
    return this.code === ResponseCode.NOT_FOUND;
  }

  /**
   * 获取第一个错误消息
   */
  getFirstErrorMessage(): string | null {
    if (this.errors && this.errors.length > 0) {
      return this.errors[0].message;
    }
    return null;
  }

  /**
   * 获取字段错误信息
   * @param field 字段名
   */
  getFieldError(field: string): ErrorDetail | undefined {
    return this.errors?.find(error => error.field === field);
  }

  /**
   * 获取所有错误消息
   */
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
      Logger.error(TAG, `Error response: ${this.toString()}, errors: ${JSON.stringify(this.errors)}`);
    }
  }

  /**
   * 转换为对象（用于序列化）
   */
  toObject(): Record<string, string | number | boolean | null | T | ErrorDetail[] | PaginationInfo> {
    const result: Record<string, string | number | boolean | null | T | ErrorDetail[] | PaginationInfo> = {
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
   * 从对象创建实例
   * @param obj 对象数据
   */
  static fromObject<T>(obj: Record<string, unknown>): ApiResponse<T> {
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

  // ========== 静态工厂方法 ==========

  /**
   * 创建成功响应
   */
  static success<T = Record<string, string | number | boolean | null>>(data?: T, message: string = 'Success'): ApiResponse<T> {
    return new ApiResponse<T>({
      code: ResponseCode.SUCCESS,
      message,
      data
    });
  }

  /**
   * 创建带分页的成功响应
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
   * 创建错误响应
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
   * 创建参数错误响应
   */
  static badRequest<T = Record<string, string | number | boolean | null>>(message: string = 'Bad Request', errors?: ErrorDetail[]): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.BAD_REQUEST, message, errors);
  }

  /**
   * 创建未授权错误响应
   */
  static unauthorized<T = Record<string, string | number | boolean | null>>(message: string = 'Unauthorized'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.UNAUTHORIZED, message);
  }

  /**
   * 创建禁止访问错误响应
   */
  static forbidden<T = Record<string, string | number | boolean | null>>(message: string = 'Forbidden'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.FORBIDDEN, message);
  }

  /**
   * 创建未找到资源错误响应
   */
  static notFound<T = Record<string, string | number | boolean | null>>(message: string = 'Resource not found'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.NOT_FOUND, message);
  }

  /**
   * 创建服务器错误响应
   */
  static serverError<T = Record<string, string | number | boolean | null>>(message: string = 'Internal server error'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.INTERNAL_SERVER_ERROR, message);
  }

  /**
   * 创建网络错误响应
   */
  static networkError<T = Record<string, string | number | boolean | null>>(message: string = 'Network error'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.NETWORK_ERROR, message);
  }

  /**
   * 创建超时错误响应
   */
  static timeoutError<T = Record<string, string | number | boolean | null>>(message: string = 'Request timeout'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.TIMEOUT_ERROR, message);
  }

  /**
   * 创建解析错误响应
   */
  static parseError<T = Record<string, string | number | boolean | null>>(message: string = 'Parse error'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.PARSE_ERROR, message);
  }

  /**
   * 创建验证错误响应
   */
  static validationError<T = Record<string, string | number | boolean | null>>(errors: ErrorDetail[], message: string = 'Validation failed'): ApiResponse<T> {
    return ApiResponse.error<T>(ResponseCode.VALIDATION_ERROR, message, errors);
  }

  /**
   * 创建单个验证错误响应
   */
  static singleValidationError<T = Record<string, string | number | boolean | null>>(field: string, message: string): ApiResponse<T> {
    const error: ErrorDetail = { field, message };
    return ApiResponse.validationError<T>([error]);
  }

  /**
   * 从错误创建响应
   */
  static fromError<T = Record<string, string | number | boolean | null>>(error: Error): ApiResponse<T> {
    // 可以根据不同类型的错误返回不同的响应
    Logger.error(TAG, `Creating response from error: ${error.message}`, error);
    
    return ApiResponse.error<T>(ResponseCode.UNKNOWN_ERROR, error.message);
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