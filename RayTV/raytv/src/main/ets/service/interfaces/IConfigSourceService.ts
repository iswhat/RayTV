/**
 * 配置源服务接口 | Config Source Service Interface
 * 定义壳应用配置源管理的核心接口 | Defines core interfaces for shell app config source management
 */
import ApiResponse from '../../data/dto/ApiResponse';

// 配置源基本信息 | Basic config source information
export interface ConfigSource {
  id: string;
  name: string;
  url: string;
  type: 'json' | 'xml' | 'custom';
  version: string;
  lastUpdated: number;
  isActive: boolean;
  priority: number;
  metadata?: ConfigMetadata;
}

// 配置元数据 | Config metadata
export interface ConfigMetadata {
  author?: string;
  description?: string;
  siteCount?: number;
  parserCount?: number;
  lastChecked?: number;
  healthStatus?: 'healthy' | 'warning' | 'error';
}

// 解析后的配置数据 | Parsed config data
export interface ParsedConfig {
  sites: MediaSite[];
  parsers: ParserConfig[];
  rules: RuleConfig[];
  wallpapers: string[];
  lives: LiveSource[];
  spider?: SpiderConfig;
}

// 媒体站点配置 | Media site configuration
export interface MediaSite {
  key: string;
  name: string;
  type: number;
  api: string;
  searchable: boolean;
  quickSearch: boolean;
  filterable: boolean;
  ext?: string | object;
  jar?: string;
  playerType?: number | string;
  headers?: Record<string, string>;
  timeout?: number;
  changeable?: boolean;
  style?: StyleConfig;
}

// 解析器配置 | Parser configuration
export interface ParserConfig {
  name: string;
  type: number;
  url: string;
  ext?: object;
  flag?: string[];
  header?: Record<string, string>;
}

// 规则配置 | Rule configuration
export interface RuleConfig {
  name: string;
  hosts: string[];
  regex?: string[];
  script?: string[];
}

// 直播源配置 | Live source configuration
export interface LiveSource {
  name: string;
  type: number;
  url: string;
  playerType?: number;
  ua?: string;
  timeout?: number;
  epg?: string;
  logo?: string;
  boot?: boolean;
}

// 爬虫配置 | Spider configuration
export interface SpiderConfig {
  path: string;
  md5: string;
}

// 样式配置 | Style configuration
export interface StyleConfig {
  type: 'list' | 'rect' | 'oval';
  ratio?: number;
}

// 配置源服务接口 | Config source service interface
export interface IConfigSourceService {
  /**
   * 加载远程配置源 | Load remote config source
   * @param url 配置源URL | Config source URL
   * @returns 配置源数据 | Config source data
   */
  loadConfigSource(url: string): Promise<ApiResponse<ConfigSource>>;
  
  /**
   * 解析配置内容 | Parse config content
   * @param content 配置内容 | Config content
   * @returns 解析后的配置 | Parsed configuration
   */
  parseConfigContent(content: string): Promise<ApiResponse<ParsedConfig>>;
  
  /**
   * 验证配置格式 | Validate config format
   * @param config 配置数据 | Config data
   * @returns 是否有效 | Whether valid
   */
  validateConfigFormat(config: any): boolean;
  
  /**
   * 获取所有激活的配置源 | Get all active config sources
   * @returns 配置源列表 | Config source list
   */
  getActiveSources(): Promise<ApiResponse<ConfigSource[]>>;
  
  /**
   * 添加新的配置源 | Add new config source
   * @param url 配置源URL | Config source URL
   * @param name 配置源名称 | Config source name
   * @returns 添加结果 | Add result
   */
  addSource(url: string, name: string): Promise<ApiResponse<ConfigSource>>;
  
  /**
   * 删除配置源 | Remove config source
   * @param id 配置源ID | Config source ID
   * @returns 删除结果 | Remove result
   */
  removeSource(id: string): Promise<ApiResponse<boolean>>;
  
  /**
   * 更新配置源状态 | Update config source status
   * @param id 配置源ID | Config source ID
   * @param isActive 是否激活 | Whether active
   * @returns 更新结果 | Update result
   */
  updateSourceStatus(id: string, isActive: boolean): Promise<ApiResponse<boolean>>;
  
  /**
   * 获取解析后的媒体站点 | Get parsed media sites
   * @param sourceId 配置源ID | Config source ID
   * @returns 媒体站点列表 | Media site list
   */
  getMediaSites(sourceId: string): Promise<ApiResponse<MediaSite[]>>;
  
  /**
   * 检查配置源健康状态 | Check config source health
   * @param id 配置源ID | Config source ID
   * @returns 健康状态 | Health status
   */
  checkSourceHealth(id: string): Promise<ApiResponse<'healthy' | 'warning' | 'error'>>;
}