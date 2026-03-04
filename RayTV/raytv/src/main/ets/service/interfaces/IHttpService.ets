interface HttpResponse<T> {
  data: T;
  status: number;
  headers: Record<string, string>;
}

interface HttpOptions {
  headers?: Record<string, string>;
  timeout?: number;
  params?: Record<string, string>;
}

interface IHttpService {
  get<T>(url: string, options?: HttpOptions): Promise<HttpResponse<T>>;
  post<T>(url: string, data?: any, options?: HttpOptions): Promise<HttpResponse<T>>;
  put<T>(url: string, data?: any, options?: HttpOptions): Promise<HttpResponse<T>>;
  delete<T>(url: string, options?: HttpOptions): Promise<HttpResponse<T>>;
  batch<T>(requests: Array<{ method: string; url: string; data?: any; options?: HttpOptions }>): Promise<Array<HttpResponse<T>>>;
}

export { IHttpService, HttpResponse, HttpOptions };