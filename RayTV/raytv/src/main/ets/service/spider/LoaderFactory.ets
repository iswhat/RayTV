// LoaderFactory.ets - 加载器工厂类 Loader factory class
// 负责创建不同类型的加载器实例 Responsible for creating different types of loader instances
import { Site } from '../../data/bean/Site';
import { BaseLoader, EmptyLoader, LoaderOptions } from './loader/BaseLoader';
import { ArkJsLoader } from './loader/ArkJsLoader';
import { ArkPyLoader } from './loader/ArkPyLoader';
import { ArkJarLoader } from './loader/ArkJarLoader';
import Logger from '../../common/util/Logger';

/**
 * 加载器工厂类 Loader factory class
 * 负责创建不同类型的加载器实例 Responsible for creating different types of loader instances
 */
export class LoaderFactory {
  private static readonly TAG: string = 'LoaderFactory';
  private static instance: LoaderFactory | null = null;

  /**
   * 获取单例实例 Get singleton instance
   * @returns LoaderFactory
   */
  public static getInstance(): LoaderFactory {
    if (!LoaderFactory.instance) {
      LoaderFactory.instance = new LoaderFactory();
    }
    return LoaderFactory.instance;
  }

  /**
   * 创建加载器实例 Create loader instance
   * @param site 站点信息 Site information
   * @param options 加载器选项 Loader options
   * @returns BaseLoader 加载器实例 Loader instance
   */
  public createLoader(site: Site, options: LoaderOptions = {}): BaseLoader {
    try {
      Logger.info(this.TAG, `Creating loader for site: ${site.key}, type: ${site.loaderType || 'js'}`);

      // 根据加载器类型创建不同的加载器实例 Create different loader instances based on loader type
      switch (site.loaderType?.toLowerCase()) {
        case 'js':
        case 'javascript':
          return new ArkJsLoader(site, options);
        case 'py':
        case 'python':
          return new ArkPyLoader(site, options);
        case 'jar':
        case 'java':
          return new ArkJarLoader(site, options);
        default:
          Logger.warn(this.TAG, `Unknown loader type: ${site.loaderType}, using default JS loader`);
          return new ArkJsLoader(site, options);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to create loader:`, error instanceof Error ? error : new Error(String(error)));
      // 如果创建失败，返回空加载器 If creation fails, return empty loader
      return new EmptyLoader(site, options);
    }
  }

  /**
   * 获取支持的加载器类型 Get supported loader types
   * @returns string[] 支持的加载器类型数组 Supported loader types array
   */
  public getSupportedLoaderTypes(): string[] {
    return ['js', 'py', 'jar'];
  }

  /**
   * 验证加载器类型是否支持 Validate if loader type is supported
   * @param type 加载器类型 Loader type
   * @returns boolean 是否支持 Whether supported
   */
  public isLoaderTypeSupported(type: string): boolean {
    return this.getSupportedLoaderTypes().includes(type.toLowerCase());
  }
}
