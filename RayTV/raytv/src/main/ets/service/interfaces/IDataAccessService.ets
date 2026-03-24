interface IDataAccessService {
  query<T>(sql: string, params?: string[]): Promise<T[]>;
  execute(sql: string, params?: string[]): Promise<number>;
  beginTransaction(): Promise<void>;
  commitTransaction(): Promise<void>;
  rollbackTransaction(): Promise<void>;
  close(): Promise<void>;
}

export { IDataAccessService };