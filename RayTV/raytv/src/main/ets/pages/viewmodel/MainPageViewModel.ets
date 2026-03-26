// MainPage视图模型 | MainPage view model
// 分离业务逻辑和UI渲染，提高代码可维护性 | Separate business logic and UI rendering to improve code maintainability

import Logger from '../../common/util/Logger';
import ContentAccessServiceInstance, { ContentAccessService } from '../../service/content/ContentAccessService';
import { handleError, ErrorType } from '../../common/util/ErrorHandler';
import Strings from '../../common/resources/Strings';

/**
 * 推荐媒体项接口 | Featured media item interface
 */
export interface FeaturedMediaItem {
  id: string;
  title: string;
  cover: string;
  type: string;
  siteKey?: string;
  rating?: string;
  sourceId?: string;
  sourceName?: string;
}

/**
 * 主页面视图模型 | Main page view model
 */
export class MainPageViewModel {
  private readonly TAG: string = 'MainPageViewModel';
  private contentService: ContentAccessService = ContentAccessServiceInstance;
  
  /**
   * 加载推荐内容 | Load featured media
   * @returns 推荐媒体项数组 | Featured media items array
   */
  public async loadFeaturedMedia(): Promise<{
    featuredMedia: FeaturedMediaItem[];
    popularMedia: FeaturedMediaItem[];
    newMedia: FeaturedMediaItem[];
    errorMessage?: string;
    hasError: boolean;
  }> {
    try {
      // 确保ContentAccessService已初始化 | Ensure ContentAccessService is initialized
      if (!this.contentService.isInitialized()) {
        await this.contentService.initialize();
      }

      // 从ContentAccessService获取真实的点播站点数据 | Get real VOD site data from ContentAccessService
      const allVodSites = this.contentService.getAllVodSites();

      if (allVodSites.length > 0) {
        // 将VodSiteWithSource转换为FeaturedMediaItem
        const toMediaItem = (site: import('../../service/pool/SourcePoolManager').VodSiteWithSource, idx: number): FeaturedMediaItem => ({
          id: `${site.siteKey}_${idx}`,
          title: site.name,
          cover: '', // VodSiteWithSource 没有 logo 字段，使用空字符串
          type: 'vod',
          siteKey: site.siteKey,
          sourceId: site.sourceId,
          sourceName: site.sourceName
        });

        // 推荐内容：取前5个站点 | Featured: first 5 sites
        const featuredMedia = allVodSites.slice(0, 5).map(toMediaItem);

        // 热门内容：取5-10个站点 | Popular: sites 5-10
        const popularMedia = allVodSites.slice(5, 10).map(toMediaItem);

        // 最新内容：取最后一批站点（最多5个）| New: last batch of sites (up to 5)
        const newStart = Math.max(10, allVodSites.length - 5);
        const newMedia = allVodSites.slice(newStart).map(toMediaItem);

        Logger.info(this.TAG, `Loaded ${allVodSites.length} VOD sites from ContentAccessService`);
        
        return {
          featuredMedia,
          popularMedia,
          newMedia,
          hasError: false
        };
      } else {
        // 无数据时提示用户配置源 | No data: prompt user to configure sources
        Logger.warn(this.TAG, 'No VOD sites available. Please configure network sources in Settings.');
        
        return {
          featuredMedia: [],
          popularMedia: [],
          newMedia: [],
          errorMessage: Strings.mainPage.noSourcesConfigured,
          hasError: true
        };
      }

    } catch (error) {
      const errorInfo = handleError(error, ErrorType.CONTENT_LOAD_ERROR);
      Logger.error(this.TAG, `Failed to load featured media: ${errorInfo.message}`);
      
      return {
        featuredMedia: [],
        popularMedia: [],
        newMedia: [],
        errorMessage: errorInfo.friendlyMessage || Strings.mainPage.loadFailed,
        hasError: true
      };
    }
  }
  
  /**
   * 验证媒体数据完整性 | Validate media data integrity
   * @param media 媒体数据 | Media data
   * @returns 是否有效 | Whether the media data is valid
   */
  public validateMediaData(media: FeaturedMediaItem): boolean {
    return !!(media.id && media.siteKey);
  }
  
  /**
   * 验证菜单键值 | Validate menu key
   * @param key 菜单键值 | Menu key
   * @returns 是否有效 | Whether the menu key is valid
   */
  public validateMenuKey(key: string): boolean {
    return !!key;
  }
  
  /**
   * 验证分类ID | Validate category ID
   * @param categoryId 分类ID | Category ID
   * @returns 是否有效 | Whether the category ID is valid
   */
  public validateCategoryId(categoryId: string): boolean {
    return !!categoryId;
  }
}

// 导出视图模型实例 | Export view model instance
export const mainPageViewModel = new MainPageViewModel();
