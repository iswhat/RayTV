// MovieService - 电影/视频服务�?import Logger from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import { NetworkRepository } from '../../data/repository/NetworkRepository';
import { DatabaseRepository } from '../../data/repository/DatabaseRepository';

// 导入模型和DTO
import Movie, { VideoType, VideoQuality, RatingInfo, VideoSource, Episode } from '../model/Movie';
import {
  SearchRequest,
  SearchResponseData,
  SearchSuggestionsResponseData,
  HotSearchResponseData,
  SearchType,
  SearchSort,
  SearchFilter,
  SearchUtils
} from '../dto/SearchDto';
import {
  MovieDetailData,
  EpisodesResponseData,
  VideoSourcesResponseData,
  PlaybackState,
  VideoSourceRequest,
  MovieDetailUtils
} from '../dto/MovieDetailDto';
import ApiResponse, { ResponseCode } from '../dto/ApiResponse';

// 常量定义
const TAG = 'MovieService';
const CACHE_PREFIX: Record<string, string | number | boolean | null> = { ... };
const CACHE_DURATION: Record<string, string | number | boolean | null> = { ... };

// API端点
const API_ENDPOINTS: Record<string, string | number | boolean | null> = { ... };

/**
 * 电影/视频服务�? * 负责处理电影/视频相关的业务逻辑
 */
export default class MovieService {
  private static instance: MovieService;
  private networkRepo: NetworkRepository;
  private databaseRepo: DatabaseRepository;

  /**
   * 构造函数（私有，防止外部实例化�?   */
  private constructor() {
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): MovieService {
    if (!MovieService.instance) {
      MovieService.instance = new MovieService();
    }
    return MovieService.instance;
  }

  /**
   * 初始化服�?   * 用于兼容AppService的初始化流程
   */
  public async initialize(): Promise<void> {
    Logger.info(TAG, 'MovieService initialized');
    // 空实现，用于兼容AppService初始化流�?  }

  /**
   * 搜索电影/视频
   */
  public async search(request: SearchRequest): Promise<ApiResponse<SearchResponseData>> {
    try {
      Logger.info(TAG, 'Searching movies...', { keyword: request.keyword, type: request.type });

      // 验证搜索关键�?      if (!SearchUtils.validateKeyword(request.keyword)) {
        return ApiResponse.validationError<SearchResponseData>([
          { field: 'keyword', message: '搜索关键词不能为�? }
        ]);
      }

      // 生成缓存�?      const cacheKey = `${CACHE_PREFIX.SEARCH_RESULT}${request.keyword}_${request.type}_${request.page}_${request.pageSize}`;

      // 尝试从缓存获�?      const cachedData = await this.getCachedData<ApiResponse<SearchResponseData>>(cacheKey, CACHE_DURATION.SEARCH_RESULT);
      if (cachedData) {
        Logger.info(TAG, 'Returning search results from cache');
        return cachedData;
      }

      // 调用搜索API
      const response = await this.networkRepo.request<ApiResponse<SearchResponseData>>({
        url: API_ENDPOINTS.SEARCH,
        method: 'GET',
        params: request
      });

      // 缓存结果
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.SEARCH_RESULT);
        Logger.info(TAG, 'Search completed successfully', { results: response.data?.items.length });
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Search failed', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<SearchResponseData>('搜索失败，请检查网络连接或稍后重试');
    }
  }

  /**
   * 获取搜索建议
   */
  public async getSearchSuggestions(keyword: string, type: SearchType = SearchType.ALL): Promise<ApiResponse<SearchSuggestionsResponseData>> {
    try {
      Logger.info(TAG, 'Getting search suggestions...', { keyword });

      // 验证关键词长�?      if (keyword.length < 1) {
        return ApiResponse.success<SearchSuggestionsResponseData>({
          suggestions: [],
          keyword,
          totalSuggestions: 0
        });
      }

      // 调用搜索建议API
      const response = await this.networkRepo.request<ApiResponse<SearchSuggestionsResponseData>>({
        url: API_ENDPOINTS.SEARCH_SUGGESTIONS,
        method: 'GET',
        params: { keyword, type }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get search suggestions', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      // 失败时返回空建议，不影响用户体验
      return ApiResponse.success<SearchSuggestionsResponseData>({
        suggestions: [],
        keyword,
        totalSuggestions: 0
      });
    }
  }

  /**
   * 获取热门搜索
   */
  public async getHotSearch(): Promise<ApiResponse<HotSearchResponseData>> {
    try {
      Logger.info(TAG, 'Getting hot search keywords...');

      // 生成缓存�?      const cacheKey = `${CACHE_PREFIX.HOT_SEARCH}`;

      // 尝试从缓存获�?      const cachedData = await this.getCachedData<ApiResponse<HotSearchResponseData>>(cacheKey, CACHE_DURATION.HOT_SEARCH);
      if (cachedData) {
        Logger.info(TAG, 'Returning hot search from cache');
        return cachedData;
      }

      // 调用热门搜索API
      const response = await this.networkRepo.request<ApiResponse<HotSearchResponseData>>({
        url: API_ENDPOINTS.HOT_SEARCH,
        method: 'GET'
      });

      // 缓存结果
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.HOT_SEARCH);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get hot search', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<HotSearchResponseData>('获取热门搜索失败');
    }
  }

  /**
   * 获取电影/视频详情
   */
  public async getMovieDetail(movieId: string): Promise<ApiResponse<MovieDetailData>> {
    try {
      Logger.info(TAG, 'Getting movie detail...', { movieId });

      // 验证ID
      if (!movieId) {
        return ApiResponse.validationError<MovieDetailData>([
          { field: 'movieId', message: '电影ID不能为空' }
        ]);
      }

      // 生成缓存�?      const cacheKey = `${CACHE_PREFIX.MOVIE_DETAIL}${movieId}`;

      // 尝试从缓存获�?      const cachedData = await this.getCachedData<ApiResponse<MovieDetailData>>(cacheKey, CACHE_DURATION.MOVIE_DETAIL);
      if (cachedData) {
        // 检查是否已收藏
        const isFavorite = await this.databaseRepo.isMovieFavorite(movieId);
        if (cachedData.data) {
          cachedData.data.isFavorite = isFavorite;
        }
        
        // 检查观看进�?        const watchProgress = await this.databaseRepo.getWatchProgress(movieId);
        if (cachedData.data && watchProgress) {
          cachedData.data.watchProgress = watchProgress.progress;
          cachedData.data.lastWatchTime = watchProgress.timestamp;
        }
        
        Logger.info(TAG, 'Returning movie detail from cache');
        return cachedData;
      }

      // 调用详情API
      const response = await this.networkRepo.request<ApiResponse<MovieDetailData>>({
        url: API_ENDPOINTS.MOVIE_DETAIL,
        method: 'GET',
        params: { id: movieId }
      });

      if (response.isSuccess() && response.data) {
        // 添加收藏和观看进度信�?        response.data.isFavorite = await this.databaseRepo.isMovieFavorite(movieId);
        
        const watchProgress = await this.databaseRepo.getWatchProgress(movieId);
        if (watchProgress) {
          response.data.watchProgress = watchProgress.progress;
          response.data.lastWatchTime = watchProgress.timestamp;
        }
        
        // 缓存结果
        await this.setCachedData(cacheKey, response, CACHE_DURATION.MOVIE_DETAIL);
        
        // 同步到本地数据库
        await this.syncMovieToLocal(response.data);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get movie detail', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData>('获取电影详情失败');
    }
  }

  /**
   * 获取剧集列表
   */
  public async getEpisodes(movieId: string, season?: number): Promise<ApiResponse<EpisodesResponseData>> {
    try {
      Logger.info(TAG, 'Getting episodes...', { movieId, season });

      // 调用剧集API
      const response = await this.networkRepo.request<ApiResponse<EpisodesResponseData>>({
        url: API_ENDPOINTS.EPISODES,
        method: 'GET',
        params: { id: movieId, season }
      });

      if (response.isSuccess() && response.data?.episodes) {
        // 加载每集的观看进�?        for (const episode of response.data.episodes) {
          const progress = await this.databaseRepo.getEpisodeWatchProgress(movieId, episode.id);
          if (progress) {
            episode.watchProgress = progress.progress;
            episode.watchTime = progress.timestamp;
            episode.isWatched = progress.progress >= 95; // 进度超过95%视为已观�?          }
        }
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get episodes', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<EpisodesResponseData>('获取剧集列表失败');
    }
  }

  /**
   * 获取视频播放�?   */
  public async getVideoSources(request: VideoSourceRequest): Promise<ApiResponse<VideoSourcesResponseData>> {
    try {
      Logger.info(TAG, 'Getting video sources...', { 
        contentId: request.contentId,
        episodeId: request.episodeId
      });

      // 生成缓存�?      let cacheKey = `${CACHE_PREFIX.VIDEO_SOURCES}${request.contentId}`;
      if (request.episodeId) {
        cacheKey += `_${request.episodeId}`;
      }

      // 尝试从缓存获�?      const cachedData = await this.getCachedData<ApiResponse<VideoSourcesResponseData>>(cacheKey, CACHE_DURATION.VIDEO_SOURCES);
      if (cachedData) {
        Logger.info(TAG, 'Returning video sources from cache');
        return cachedData;
      }

      // 调用视频源API
      const response = await this.networkRepo.request<ApiResponse<VideoSourcesResponseData>>({
        url: API_ENDPOINTS.VIDEO_SOURCES,
        method: 'GET',
        params: request
      });

      // 缓存结果
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.VIDEO_SOURCES);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get video sources', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<VideoSourcesResponseData>('获取播放源失�?);
    }
  }

  /**
   * 更新播放状�?   */
  public async updatePlaybackState(state: PlaybackState): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Updating playback state...', {
        contentId: state.contentId,
        position: state.position,
        completed: state.completed
      });

      // 保存到本地数据库
      await this.databaseRepo.savePlaybackState(state);

      // 如果播放完成，记录观看历�?      if (state.completed) {
        await this.databaseRepo.addToHistory({
          userId: 'current', // 实际应用中应该使用当前登录用户ID
          contentId: state.contentId,
          episodeId: state.episodeId,
          progress: 100,
          duration: state.duration,
          timestamp: Date.now(),
          completed: true
        });
      }

      return ApiResponse.success(true, '播放状态更新成�?);
    } catch (error) {
      Logger.error(TAG, 'Failed to update playback state', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新播放状态失�?);
    }
  }

  /**
   * 获取播放状�?   */
  public async getPlaybackState(contentId: string, episodeId?: string): Promise<ApiResponse<PlaybackState | null>> {
    try {
      Logger.info(TAG, 'Getting playback state...', { contentId, episodeId });

      // 从本地数据库获取
      const state = await this.databaseRepo.getPlaybackState(contentId, episodeId);
      
      return ApiResponse.success(state, '获取播放状态成�?);
    } catch (error) {
      Logger.error(TAG, 'Failed to get playback state', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.success<null>(null, '获取播放状态失败，返回�?);
    }
  }

  /**
   * 添加/移除收藏
   */
  public async toggleFavorite(movieId: string): Promise<ApiResponse<{ isFavorite: boolean }>> {
    try {
      Logger.info(TAG, 'Toggling favorite status...', { movieId });

      // 检查当前收藏状�?      const isFavorite = await this.databaseRepo.isMovieFavorite(movieId);
      
      if (isFavorite) {
        // 移除收藏
        await this.databaseRepo.removeFromFavorites(movieId);
        Logger.info(TAG, 'Movie removed from favorites', { movieId });
      } else {
        // 添加收藏
        // 先获取电影详�?        const detailResponse = await this.getMovieDetail(movieId);
        if (detailResponse.isSuccess() && detailResponse.data) {
          await this.databaseRepo.addToFavorites({
            id: movieId,
            title: detailResponse.data.title,
            coverUrl: detailResponse.data.posters?.[0]?.url,
            type: detailResponse.data.type,
            rating: detailResponse.data.rating?.score,
            releaseYear: detailResponse.data.releaseYear,
            addedAt: Date.now()
          });
          Logger.info(TAG, 'Movie added to favorites', { movieId });
        } else {
          return ApiResponse.error(ResponseCode.NOT_FOUND, '获取电影信息失败，无法添加收�?);
        }
      }

      // 返回新的收藏状�?      const newFavoriteStatus = !isFavorite;
      
      // 清除详情缓存，以便下次加载时更新收藏状�?      await this.clearMovieDetailCache(movieId);
      
      return ApiResponse.success({ isFavorite: newFavoriteStatus }, 
        newFavoriteStatus ? '添加收藏成功' : '移除收藏成功');
    } catch (error) {
      Logger.error(TAG, 'Failed to toggle favorite status', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '操作收藏失败');
    }
  }

  /**
   * 获取推荐内容
   */
  public async getRecommendations(movieId?: string, limit: number = 20): Promise<ApiResponse<MovieDetailData[]>> {
    try {
      Logger.info(TAG, 'Getting recommendations...', { movieId, limit });

      const response = await this.networkRepo.request<ApiResponse<MovieDetailData[]>>({
        url: API_ENDPOINTS.RECOMMENDATIONS,
        method: 'GET',
        params: { id: movieId, limit }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get recommendations', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData[]>('获取推荐内容失败');
    }
  }

  /**
   * 获取相似内容
   */
  public async getSimilarMovies(movieId: string, limit: number = 10): Promise<ApiResponse<MovieDetailData[]>> {
    try {
      Logger.info(TAG, 'Getting similar movies...', { movieId, limit });

      const response = await this.networkRepo.request<ApiResponse<MovieDetailData[]>>({
        url: API_ENDPOINTS.SIMILAR,
        method: 'GET',
        params: { id: movieId, limit }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get similar movies', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData[]>('获取相似内容失败');
    }
  }

  /**
   * 获取分类列表
   */
  public async getCategories(type: VideoType = VideoType.ALL): Promise<ApiResponse<unknown[]>> {
    try {
      Logger.info(TAG, 'Getting categories...', { type });

      // 生成缓存�?      const cacheKey = `${CACHE_PREFIX.CATEGORY_LIST}${type}`;

      // 尝试从缓存获�?      const cachedData = await this.getCachedData<ApiResponse<unknown[]>>(cacheKey, CACHE_DURATION.CATEGORY_LIST);
      if (cachedData) {
        Logger.info(TAG, 'Returning categories from cache');
        return cachedData;
      }

      // 调用分类API
      const response = await this.networkRepo.request<ApiResponse<unknown[]>>({
        url: API_ENDPOINTS.CATEGORIES,
        method: 'GET',
        params: { type }
      });

      // 缓存结果
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.CATEGORY_LIST);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get categories', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<unknown[]>('获取分类列表失败');
    }
  }

  /**
   * 获取分类内容
   */
  public async getCategoryItems(categoryId: string, page: number = 1, pageSize: number = 20): Promise<ApiResponse<SearchResponseData>> {
    try {
      Logger.info(TAG, 'Getting category items...', { categoryId, page });

      // 调用分类内容API
      const response = await this.networkRepo.request<ApiResponse<SearchResponseData>>({
        url: API_ENDPOINTS.CATEGORY_ITEMS,
        method: 'GET',
        params: { id: categoryId, page, pageSize }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get category items', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<SearchResponseData>('获取分类内容失败');
    }
  }

  /**
   * 获取热门内容
   */
  public async getTrending(type: VideoType = VideoType.ALL, limit: number = 20): Promise<ApiResponse<MovieDetailData[]>> {
    try {
      Logger.info(TAG, 'Getting trending movies...', { type, limit });

      const response = await this.networkRepo.request<ApiResponse<MovieDetailData[]>>({
        url: API_ENDPOINTS.TRENDING,
        method: 'GET',
        params: { type, limit }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get trending movies', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData[]>('获取热门内容失败');
    }
  }

  /**
   * 获取最新上�?   */
  public async getNewReleases(type: VideoType = VideoType.ALL, limit: number = 20): Promise<ApiResponse<MovieDetailData[]>> {
    try {
      Logger.info(TAG, 'Getting new releases...', { type, limit });

      const response = await this.networkRepo.request<ApiResponse<MovieDetailData[]>>({
        url: API_ENDPOINTS.NEW_RELEASES,
        method: 'GET',
        params: { type, limit }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get new releases', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData[]>('获取最新上线失�?);
    }
  }

  /**
   * 获取流行内容
   */
  public async getPopular(type: VideoType = VideoType.ALL, limit: number = 20): Promise<ApiResponse<MovieDetailData[]>> {
    try {
      Logger.info(TAG, 'Getting popular movies...', { type, limit });

      const response = await this.networkRepo.request<ApiResponse<MovieDetailData[]>>({
        url: API_ENDPOINTS.POPULAR,
        method: 'GET',
        params: { type, limit }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get popular movies', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData[]>('获取流行内容失败');
    }
  }

  /**
   * 获取高评分内�?   */
  public async getTopRated(type: VideoType = VideoType.ALL, limit: number = 20): Promise<ApiResponse<MovieDetailData[]>> {
    try {
      Logger.info(TAG, 'Getting top rated movies...', { type, limit });

      const response = await this.networkRepo.request<ApiResponse<MovieDetailData[]>>({
        url: API_ENDPOINTS.TOP_RATED,
        method: 'GET',
        params: { type, limit }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get top rated movies', error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return ApiResponse.networkError<MovieDetailData[]>('获取高评分内容失�?);
    }
  }

  // ========== 缓存相关方法 ==========

  /**
   * 从缓存获取数�?   */
  private async getCachedData<T>(key: string, maxAge: number): Promise<T | null> {
    try {
      const cached = await StorageUtil.getObject<{ data: T; timestamp: number }>(key);
      
      if (!cached) {
        return null;
      }

      const now = Date.now();
      if (now - cached.timestamp > maxAge) {
        // 缓存已过�?        await StorageUtil.remove(key);
        return null;
      }

      return cached.data;
    } catch (error) {
      Logger.error(TAG, `Failed to get cached data for key ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
      return null;
    }
  }

  /**
   * 设置缓存数据
   */
  private async setCachedData<T>(key: string, data: T, maxAge: number): Promise<void> {
    try {
      await StorageUtil.setObject(key, {
        data,
        timestamp: Date.now()
      });
    } catch (error) {
      Logger.error(TAG, `Failed to set cached data for key ${key}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  /**
   * 清除电影详情缓存
   */
  private async clearMovieDetailCache(movieId: string): Promise<void> {
    try {
      const cacheKey = `${CACHE_PREFIX.MOVIE_DETAIL}${movieId}`;
      await StorageUtil.remove(cacheKey);
    } catch (error) {
      Logger.error(TAG, `Failed to clear movie detail cache for movieId ${movieId}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }

  // ========== 本地数据同步方法 ==========

  /**
   * 将电影数据同步到本地数据�?   */
  private async syncMovieToLocal(movieData: MovieDetailData): Promise<void> {
    try {
      // 创建Movie对象
      const movie = new Movie({
        id: movieData.id,
        title: movieData.title,
        originalTitle: movieData.originalTitle,
        type: movieData.type,
        description: movieData.description,
        coverUrl: movieData.posters?.[0]?.url,
        backdropUrl: movieData.backdrops?.[0]?.url,
        rating: movieData.rating,
        releaseYear: movieData.releaseYear,
        genres: movieData.genres,
        duration: movieData.runtime,
        directors: movieData.directors?.map(d => d.name) || [],
        actors: movieData.actors?.map(a => a.name) || [],
        sources: movieData.sources || [],
        totalEpisodes: movieData.totalEpisodes,
        airedEpisodes: movieData.airedEpisodes,
        isVip: movieData.isVip,
        isNew: movieData.isNew,
        isHot: movieData.isHot,
        updateTime: Date.now()
      });

      // 保存到本地数据库
      await this.databaseRepo.saveMovie(movie);
    } catch (error) {
      Logger.error(TAG, `Failed to sync movie to local database: ${movieData.id}`, error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error instanceof Error ? error instanceof Error ? error : new Error(String(error : new Error(String(error instanceof Error ? error : new Error(String(error)))))));
    }
  }
}


