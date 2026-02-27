// BaseMapper.ts - 基础映射器
// 提供数据映射的基础功能和接口定义

/**
 * 基础映射器接口 | Base mapper interface
 * 定义数据映射的基本方法
 */
export interface BaseMapper<Domain, DTO> {
  /**
   * 将领域模型转换为DTO | Convert domain model to DTO
   */
  toDTO(domain: Domain): DTO;
  
  /**
   * 将DTO转换为领域模型 | Convert DTO to domain model
   */
  toDomain(dto: DTO): Domain;
  
  /**
   * 将领域模型数组转换为DTO数组 | Convert domain model array to DTO array
   */
  toDTOList(domains: Domain[]): DTO[];
  
  /**
   * 将DTO数组转换为领域模型数组 | Convert DTO array to domain model array
   */
  toDomainList(dtos: DTO[]): Domain[];
}

/**
 * 基础映射器实现 | Base mapper implementation
 * 提供映射器的基本实现
 */
export abstract class Mapper<Domain, DTO> implements BaseMapper<Domain, DTO> {
  /**
   * 将领域模型转换为DTO | Convert domain model to DTO
   */
  abstract toDTO(domain: Domain): DTO;
  
  /**
   * 将DTO转换为领域模型 | Convert DTO to domain model
   */
  abstract toDomain(dto: DTO): Domain;
  
  /**
   * 将领域模型数组转换为DTO数组 | Convert domain model array to DTO array
   */
  toDTOList(domains: Domain[]): DTO[] {
    return domains.map(domain => this.toDTO(domain));
  }
  
  /**
   * 将DTO数组转换为领域模型数组 | Convert DTO array to domain model array
   */
  toDomainList(dtos: DTO[]): Domain[] {
    return dtos.map(dto => this.toDomain(dto));
  }
}

/**
 * 映射器工厂 | Mapper factory
 * 负责创建和管理映射器实例
 */
export class MapperFactory {
  private static instance: MapperFactory;
  private mappers: Map<string, BaseMapper<any, any>> = new Map();

  private constructor() {}

  /**
   * 获取MapperFactory实例 | Get MapperFactory instance
   */
  static getInstance(): MapperFactory {
    if (!MapperFactory.instance) {
      MapperFactory.instance = new MapperFactory();
    }
    return MapperFactory.instance;
  }

  /**
   * 注册映射器 | Register mapper
   */
  registerMapper<T extends BaseMapper<any, any>>(key: string, mapper: T): void {
    this.mappers.set(key, mapper);
  }

  /**
   * 获取映射器 | Get mapper
   */
  getMapper<Domain, DTO>(key: string): BaseMapper<Domain, DTO> {
    const mapper = this.mappers.get(key);
    if (!mapper) {
      throw new Error(`Mapper for key ${key} not found`);
    }
    return mapper as BaseMapper<Domain, DTO>;
  }

  /**
   * 检查映射器是否存在 | Check if mapper exists
   */
  hasMapper(key: string): boolean {
    return this.mappers.has(key);
  }

  /**
   * 移除映射器 | Remove mapper
   */
  removeMapper(key: string): void {
    this.mappers.delete(key);
  }

  /**
   * 清除所有映射器 | Clear all mappers
   */
  clearAllMappers(): void {
    this.mappers.clear();
  }

  /**
   * 获取所有映射器 | Get all mappers
   */
  getAllMappers(): Map<string, BaseMapper<any, any>> {
    return new Map(this.mappers);
  }
}

export default MapperFactory.getInstance();