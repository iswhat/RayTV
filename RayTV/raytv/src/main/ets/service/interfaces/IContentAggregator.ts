/**
 * 内容聚合服务接口 | Content Aggregation Service Interface
 * 定义壳应用内容聚合的核心接口 | Defines core interfaces for shell app content aggregation
 */
import ApiResponse from '../../data/dto/ApiResponse';
import { ConfigSource, MediaSite } from '../interfaces/IConfigSourceService';

// 聚合内容结果 | Aggregated content result
export interface AggregatedContent {
  sites: AggregatedSite[];
  categories: ContentCategory[];
  parsers: string[];
  timestamp: number;
  sourceCount: number;
  totalSiteCount: number;
  uniqueSiteCount: number;
}

// 聚合站点信息 | Aggregated site information
export interface AggregatedSite {
  key: string;
  name: string;
  type: number;
  api: string;
  searchable: boolean;
  quickSearch: boolean;
  filterable: boolean;
  sourceUrls: string[]; // 来源URL列表 | Source URL list
  qualityScore: number; // 质量评分 | Quality score
  reliabilityScore: number; // 可靠性评分 | Reliability score
  lastSeen: number; // 最后出现时间 | Last seen time
  ext?: string | object;
  jar?: string;
  headers?: Record<string, string>;
}

// 内容分类 | Content category
export interface ContentCategory {
  id: string;
  name: string;
  siteCount: number;
  typeDistribution: Record<string, number>;
}

// 内容聚合服务接口 | Content aggregation service interface
export interface IContentAggregator {
  /**
   * 从所有激活的配置源聚合内容 | Aggregate content from all active config sources
   * @returns 聚合结果 | Aggregation result
   */
  aggregateAllSources(): Promise<ApiResponse<AggregatedContent>>;
  
  /**
   * 从指定配置源聚合内容 | Aggregate content from specified config sources
   * @param sourceUrls 配置源URL列表 | Config source URL list
   * @returns 聚合结果 | Aggregation result
   */
  aggregateFromSources(sourceUrls: string[]): Promise<ApiResponse<AggregatedContent>>;
  
  /**
   * 获取聚合的站点列表 | Get aggregated site list
   * @param includeInactive 是否包含非激活站点 | Whether to include inactive sites
   * @returns 站点列表 | Site list
   */
  getSites(includeInactive?: boolean): Promise<ApiResponse<AggregatedSite[]>>;
  
  /**
   * 根据分类获取站点 | Get sites by category
   * @param categoryId 分类ID | Category ID
   * @returns 站点列表 | Site list
   */
  getSitesByCategory(categoryId: string): Promise<ApiResponse<AggregatedSite[]>>;
  
  /**
   * 搜索站点 | Search sites
   * @param keyword 搜索关键词 | Search keyword
   * @returns 匹配的站点列表 | Matching site list
   */
  searchSites(keyword: string): Promise<ApiResponse<AggregatedSite[]>>;
  
  /**
   * 获取内容分类 | Get content categories
   * @returns 分类列表 | Category list
   */
  getCategories(): Promise<ApiResponse<ContentCategory[]>>;
  
  /**
   * 刷新聚合缓存 | Refresh aggregation cache
   * @returns 刷新结果 | Refresh result
   */
  refreshAggregation(): Promise<ApiResponse<boolean>>;
  
  /**
   * 获取聚合统计信息 | Get aggregation statistics
   * @returns 统计信息 | Statistics
   */
  getStatistics(): Promise<ApiResponse<AggregationStatistics>>;
}

// 聚合统计信息 | Aggregation statistics
export interface AggregationStatistics {
  totalSources: number;
  activeSources: number;
  totalSites: number;
  uniqueSites: number;
  categories: number;
  parsers: number;
  lastAggregation: number;
  averageResponseTime: number;
  successRate: number;
  cacheHitRate: number;
}

// 站点质量评估 | Site quality assessment
export interface SiteQualityMetrics {
  availability: number; // 可用性 | Availability
  responseTime: number; // 响应时间 | Response time
  contentFreshness: number; // 内容新鲜度 | Content freshness
  userRating: number; // 用户评分 | User rating
  overallScore: number; // 综合评分 | Overall score
}