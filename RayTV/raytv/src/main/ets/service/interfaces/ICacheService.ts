interface ICacheService {
  set(key: string, value: any, ttl?: number): Promise<void>;
  get<T>(key: string): Promise<T | null>;
  delete(key: string): Promise<boolean>;
  clear(): Promise<void>;
  getSize(): Promise<number>;
  has(key: string): Promise<boolean>;
}

export { ICacheService };