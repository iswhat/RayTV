// MovieService - 电影/视频服务类 Movie/Video service class
import Logger from '../../common/util/Logger';
import JsonUtil from '../../common/util/JsonUtil';
import StorageUtil from '../../common/util/StorageUtil';
import DateUtil from '../../common/util/DateUtil';
import RepositoryFactory from '../../data/repository/RepositoryFactory';
import { NetworkRepository } from '../../data/repository/NetworkRepository';
import { DatabaseRepository } from '../../data/repository/DatabaseRepository';

// 导入类型和DTO Import types and DTO
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

// 常量定义 Constants definition
const TAG = 'MovieService';
const CACHE_PREFIX: Record<string, string | number | boolean | null> = { ... };
const CACHE_DURATION: Record<string, string | number | boolean | null> = { ... };

// API端点 API endpoints
const API_ENDPOINTS: Record<string, string | number | boolean | null> = { ... };

/**
 * 电影/视频服务类 Movie/Video service class
 * 负责处理电影/视频相关的业务逻辑 Responsible for handling movie/video related business logic
 */
export default class MovieService {
  private static instance: MovieService;
  private networkRepo: NetworkRepository;
  private databaseRepo: DatabaseRepository;

  /**
   * 构造函数（私有，防止外部实例化）Constructor (private, prevent external instantiation)
   */
  private constructor() {
    this.networkRepo = RepositoryFactory.getRepository('network') as NetworkRepository;
    this.databaseRepo = RepositoryFactory.getRepository('database') as DatabaseRepository;
  }

  /**
   * 获取单例实例 Get singleton instance
   */
  public static getInstance(): MovieService {
    if (!MovieService.instance) {
      MovieService.instance = new MovieService();
    }
    return MovieService.instance;
  }

  /**
   * 初始化服务 Initialize service
   * 用于配合AppService的初始化流程 Used to coordinate with AppService initialization process
   */
  public async initialize(): Promise<void> {
    Logger.info(TAG, 'MovieService initialized');
    // 空实现，用于配合AppService初始化流程 Empty implementation, used to coordinate with AppService initialization process  }

  /**
   * 搜索电影/视频 Search movies/videos
   */
  public async search(request: SearchRequest): Promise<ApiResponse<SearchResponseData>> {
    try {
      Logger.info(TAG, 'Searching movies...', { keyword: request.keyword, type: request.type });

      // 验证搜索关键词 Validate search keyword      if (!SearchUtils.validateKeyword(request.keyword)) {
        return ApiResponse.validationError<SearchResponseData>([
          { field: 'keyword', message: '搜索关键词不能为空 Search keyword cannot be empty' }
        ]);
      }

      // 生成缓存键 Generate cache key      const cacheKey = `${CACHE_PREFIX.SEARCH_RESULT}${request.keyword}_${request.type}_${request.page}_${request.pageSize}`;

      // 尝试从缓存获取 Try to get from cache      const cachedData = await this.getCachedData<ApiResponse<SearchResponseData>>(cacheKey, CACHE_DURATION.SEARCH_RESULT);
      if (cachedData) {
        Logger.info(TAG, 'Returning search results from cache');
        return cachedData;
      }

      // 调用搜索API Call search API
      const response = await this.networkRepo.request<ApiResponse<SearchResponseData>>({
        url: API_ENDPOINTS.SEARCH,
        method: 'GET',
        params: request
      });

      // 缓存结果 Cache result
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.SEARCH_RESULT);
        Logger.info(TAG, 'Search completed successfully', { results: response.data?.items.length });
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Search failed', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<SearchResponseData>('搜索失败，请检查网络连接或稍后重试 Search failed, please check network connection or try again later');
    }
  }

  /**
   * 获取搜索建议 Get search suggestions
   */
  public async getSearchSuggestions(keyword: string, type: SearchType = SearchType.ALL): Promise<ApiResponse<SearchSuggestionsResponseData>> {
    try {
      Logger.info(TAG, 'Getting search suggestions...', { keyword });

      // 验证关键词长度 Validate keyword length      if (keyword.length < 1) {
        return ApiResponse.success<SearchSuggestionsResponseData>({
          suggestions: [],
          keyword,
          totalSuggestions: 0
        });
      }

      // 调用搜索建议API Call search suggestions API
      const response = await this.networkRepo.request<ApiResponse<SearchSuggestionsResponseData>>({
        url: API_ENDPOINTS.SEARCH_SUGGESTIONS,
        method: 'GET',
        params: { keyword, type }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get search suggestions', error instanceof Error ? error : new Error(String(error)));
      // 错误时返回空建议，不影响用户体验 Return empty suggestions on error, do not affect user experience
      return ApiResponse.success<SearchSuggestionsResponseData>({
        suggestions: [],
        keyword,
        totalSuggestions: 0
      });
    }
  }

  /**
   * 获取热门搜索 Get hot search
   */
  public async getHotSearch(): Promise<ApiResponse<HotSearchResponseData>> {
    try {
      Logger.info(TAG, 'Getting hot search keywords...');

      // 生成缓存键 Generate cache key      const cacheKey = `${CACHE_PREFIX.HOT_SEARCH}`;

      // 尝试从缓存获取 Try to get from cache      const cachedData = await this.getCachedData<ApiResponse<HotSearchResponseData>>(cacheKey, CACHE_DURATION.HOT_SEARCH);
      if (cachedData) {
        Logger.info(TAG, 'Returning hot search from cache');
        return cachedData;
      }

      // 调用热门搜索API Call hot search API
      const response = await this.networkRepo.request<ApiResponse<HotSearchResponseData>>({
        url: API_ENDPOINTS.HOT_SEARCH,
        method: 'GET'
      });

      // 缓存结果 Cache result
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.HOT_SEARCH);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get hot search', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<HotSearchResponseData>('获取热门搜索失败 Failed to get hot search');
    }
  }

  /**
   * 获取电影/视频详情 Get movie/video detail
   */
  public async getMovieDetail(movieId: string): Promise<ApiResponse<MovieDetailData>> {
    try {
      Logger.info(TAG, 'Getting movie detail...', { movieId });

      // 验证ID Validate ID
      if (!movieId) {
        return ApiResponse.validationError<MovieDetailData>([
          { field: 'movieId', message: '电影ID不能为空 Movie ID cannot be empty' }
        ]);
      }

      // 生成缓存键 Generate cache key      const cacheKey = `${CACHE_PREFIX.MOVIE_DETAIL}${movieId}`;

      // 尝试从缓存获取 Try to get from cache      const cachedData = await this.getCachedData<ApiResponse<MovieDetailData>>(cacheKey, CACHE_DURATION.MOVIE_DETAIL);
      if (cachedData) {
        // 检查是否已收藏 Check if already favorited
        const isFavorite = await this.databaseRepo.isMovieFavorite(movieId);
        if (cachedData.data) {
          cachedData.data.isFavorite = isFavorite;
        }
        
        // 检查观看进度 Check watch progress        const watchProgress = await this.databaseRepo.getWatchProgress(movieId);
        if (cachedData.data && watchProgress) {
          cachedData.data.watchProgress = watchProgress.progress;
          cachedData.data.lastWatchTime = watchProgress.timestamp;
        }
        
        Logger.info(TAG, 'Returning movie detail from cache');
        return cachedData;
      }

      // 调用详情API Call detail API
      const response = await this.networkRepo.request<ApiResponse<MovieDetailData>>({
        url: API_ENDPOINTS.MOVIE_DETAIL,
        method: 'GET',
        params: { id: movieId }
      });

      if (response.isSuccess() && response.data) {
        // 添加收藏和观看进度信息 Add favorite and watch progress information        response.data.isFavorite = await this.databaseRepo.isMovieFavorite(movieId);
        
        const watchProgress = await this.databaseRepo.getWatchProgress(movieId);
        if (watchProgress) {
          response.data.watchProgress = watchProgress.progress;
          response.data.lastWatchTime = watchProgress.timestamp;
        }
        
        // 缓存结果 Cache result
        await this.setCachedData(cacheKey, response, CACHE_DURATION.MOVIE_DETAIL);
        
        // 同步到本地数据库 Sync to local database
        await this.syncMovieToLocal(response.data);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get movie detail', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData>('获取电影详情失败 Failed to get movie detail');
    }
  }

  /**
   * 获取剧集列表 Get episodes list
   */
  public async getEpisodes(movieId: string, season?: number): Promise<ApiResponse<EpisodesResponseData>> {
    try {
      Logger.info(TAG, 'Getting episodes...', { movieId, season });

      // 调用剧集API Call episodes API
      const response = await this.networkRepo.request<ApiResponse<EpisodesResponseData>>({
        url: API_ENDPOINTS.EPISODES,
        method: 'GET',
        params: { id: movieId, season }
      });

      if (response.isSuccess() && response.data?.episodes) {
        // 加载每集的观看进度 Load watch progress for each episode        for (const episode of response.data.episodes) {
          const progress = await this.databaseRepo.getEpisodeWatchProgress(movieId, episode.id);
          if (progress) {
            episode.watchProgress = progress.progress;
            episode.watchTime = progress.timestamp;
            episode.isWatched = progress.progress >= 95; // 进度超过95%视为已观看 Progress over 95% considered watched          }
        }
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get episodes', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<EpisodesResponseData>('获取剧集列表失败 Failed to get episodes list');
    }
  }

  /**
   * 获取视频播放源 Get video playback sources
   */
  public async getVideoSources(request: VideoSourceRequest): Promise<ApiResponse<VideoSourcesResponseData>> {
    try {
      Logger.info(TAG, 'Getting video sources...', { 
        contentId: request.contentId,
        episodeId: request.episodeId
      });

      // 生成缓存键 Generate cache key      let cacheKey = `${CACHE_PREFIX.VIDEO_SOURCES}${request.contentId}`;
      if (request.episodeId) {
        cacheKey += `_${request.episodeId}`;
      }

      // 尝试从缓存获取 Try to get from cache      const cachedData = await this.getCachedData<ApiResponse<VideoSourcesResponseData>>(cacheKey, CACHE_DURATION.VIDEO_SOURCES);
      if (cachedData) {
        Logger.info(TAG, 'Returning video sources from cache');
        return cachedData;
      }

      // 调用视频源API Call video sources API
      const response = await this.networkRepo.request<ApiResponse<VideoSourcesResponseData>>({
        url: API_ENDPOINTS.VIDEO_SOURCES,
        method: 'GET',
        params: request
      });

      // 缓存结果 Cache result
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.VIDEO_SOURCES);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get video sources', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<VideoSourcesResponseData>('获取播放源失败 Failed to get playback sources');
    }
  }

  /**
   * 更新播放状态 Update playback state
   */
  public async updatePlaybackState(state: PlaybackState): Promise<ApiResponse<boolean>> {
    try {
      Logger.info(TAG, 'Updating playback state...', {
        contentId: state.contentId,
        position: state.position,
        completed: state.completed
      });

      // 保存到本地数据库 Save to local database
      await this.databaseRepo.savePlaybackState(state);

      // 如果播放完成，记录观看历史 If playback completed, record watch history      if (state.completed) {
        await this.databaseRepo.addToHistory({
          userId: 'current', // 实际应用中应该使用当前登录用户ID Should use current logged-in user ID in actual application
          contentId: state.contentId,
          episodeId: state.episodeId,
          progress: 100,
          duration: state.duration,
          timestamp: Date.now(),
          completed: true
        });
      }

      return ApiResponse.success(true, '播放状态更新成功 Playback state updated successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to update playback state', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '更新播放状态失败 Failed to update playback state');
    }
  }

  /**
   * 获取播放状态 Get playback state
   */
  public async getPlaybackState(contentId: string, episodeId?: string): Promise<ApiResponse<PlaybackState | null>> {
    try {
      Logger.info(TAG, 'Getting playback state...', { contentId, episodeId });

      // 从本地数据库获取 Get from local database
      const state = await this.databaseRepo.getPlaybackState(contentId, episodeId);
      
      return ApiResponse.success(state, '获取播放状态成功 Got playback state successfully');
    } catch (error) {
      Logger.error(TAG, 'Failed to get playback state', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.success<null>(null, '获取播放状态失败，返回空 Failed to get playback state, returning null');
    }
  }

  /**
   * 添加/移除收藏 Add/remove favorite
   */
  public async toggleFavorite(movieId: string): Promise<ApiResponse<{ isFavorite: boolean }>> {
    try {
      Logger.info(TAG, 'Toggling favorite status...', { movieId });

      // 检查当前收藏状态 Check current favorite status      const isFavorite = await this.databaseRepo.isMovieFavorite(movieId);
      
      if (isFavorite) {
        // 移除收藏 Remove from favorites
        await this.databaseRepo.removeFromFavorites(movieId);
        Logger.info(TAG, 'Movie removed from favorites', { movieId });
      } else {
        // 添加收藏 Add to favorites
        // 先获取电影信息 First get movie information        const detailResponse = await this.getMovieDetail(movieId);
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
          return ApiResponse.error(ResponseCode.NOT_FOUND, '获取电影信息失败，无法添加收藏 Failed to get movie information, cannot add to favorites');
        }
      }

      // 返回新的收藏状态 Return new favorite status      const newFavoriteStatus = !isFavorite;
      
      // 清除详情缓存，以便下次加载时更新收藏状态 Clear detail cache to update favorite status on next load      await this.clearMovieDetailCache(movieId);
      
      return ApiResponse.success({ isFavorite: newFavoriteStatus }, 
        newFavoriteStatus ? '添加收藏成功 Added to favorites' : '移除收藏成功 Removed from favorites');
    } catch (error) {
      Logger.error(TAG, 'Failed to toggle favorite status', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.error(ResponseCode.UNKNOWN_ERROR, '操作收藏失败 Failed to operate favorite');
    }
  }

  /**
   * 获取推荐内容 Get recommended content
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
      Logger.error(TAG, 'Failed to get recommendations', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData[]>('获取推荐内容失败 Failed to get recommended content');
    }
  }

  /**
   * 获取相似内容 Get similar content
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
      Logger.error(TAG, 'Failed to get similar movies', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData[]>('获取相似内容失败 Failed to get similar content');
    }
  }

  /**
   * 获取分类列表 Get categories list
   */
  public async getCategories(type: VideoType = VideoType.ALL): Promise<ApiResponse<unknown[]>> {
    try {
      Logger.info(TAG, 'Getting categories...', { type });

      // 生成缓存键 Generate cache key      const cacheKey = `${CACHE_PREFIX.CATEGORY_LIST}${type}`;

      // 尝试从缓存获取 Try to get from cache      const cachedData = await this.getCachedData<ApiResponse<unknown[]>>(cacheKey, CACHE_DURATION.CATEGORY_LIST);
      if (cachedData) {
        Logger.info(TAG, 'Returning categories from cache');
        return cachedData;
      }

      // 调用分类API Call categories API
      const response = await this.networkRepo.request<ApiResponse<unknown[]>>({
        url: API_ENDPOINTS.CATEGORIES,
        method: 'GET',
        params: { type }
      });

      // 缓存结果 Cache result
      if (response.isSuccess()) {
        await this.setCachedData(cacheKey, response, CACHE_DURATION.CATEGORY_LIST);
      }

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get categories', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<unknown[]>('获取分类列表失败 Failed to get categories list');
    }
  }

  /**
   * 获取分类内容 Get category content
   */
  public async getCategoryItems(categoryId: string, page: number = 1, pageSize: number = 20): Promise<ApiResponse<SearchResponseData>> {
    try {
      Logger.info(TAG, 'Getting category items...', { categoryId, page });

      // 调用分类内容API Call category content API
      const response = await this.networkRepo.request<ApiResponse<SearchResponseData>>({
        url: API_ENDPOINTS.CATEGORY_ITEMS,
        method: 'GET',
        params: { id: categoryId, page, pageSize }
      });

      return response;
    } catch (error) {
      Logger.error(TAG, 'Failed to get category items', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<SearchResponseData>('获取分类内容失败 Failed to get category content');
    }
  }

  /**
   * 获取热门内容 Get trending content
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
      Logger.error(TAG, 'Failed to get trending movies', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData[]>('获取热门内容失败 Failed to get trending content');
    }
  }

  /**
   * 获取最新上线 Get new releases
   */
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
      Logger.error(TAG, 'Failed to get new releases', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData[]>('获取最新上线失败 Failed to get new releases');
    }
  }

  /**
   * 获取热播内容 Get popular content
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
      Logger.error(TAG, 'Failed to get popular movies', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData[]>('获取热播内容失败 Failed to get popular content');
    }
  }

  /**
   * 获取高评分内容 Get top rated content
   */
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
      Logger.error(TAG, 'Failed to get top rated movies', error instanceof Error ? error : new Error(String(error)));
      return ApiResponse.networkError<MovieDetailData[]>('获取高评分内容失败 Failed to get top rated content');
    }
  }

  // ========== 缓存相关方法 ========== Cache related methods

  /**
   * 从缓存获取数据 Get data from cache
   */
  private async getCachedData<T>(key: string, maxAge: number): Promise<T | null> {
    try {
      const cached = await StorageUtil.getObject<{ data: T; timestamp: number }>(key);
      
      if (!cached) {
        return null;
      }

      const now = Date.now();
      if (now - cached.timestamp > maxAge) {
        // 缓存已过期 Cache expired
        await StorageUtil.remove(key);
        return null;
      }

      return cached.data;
    } catch (error) {
      Logger.error(TAG, `Failed to get cached data for key ${key}`, error instanceof Error ? error : new Error(String(error)));
      return null;
    }
  }

  /**
   * 设置缓存数据 Set cached data
   */
  private async setCachedData<T>(key: string, data: T, maxAge: number): Promise<void> {
    try {
      await StorageUtil.setObject(key, {
        data,
        timestamp: Date.now()
      });
    } catch (error) {
      Logger.error(TAG, `Failed to set cached data for key ${key}`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  /**
   * 清除电影详情缓存 Clear movie detail cache
   */
  private async clearMovieDetailCache(movieId: string): Promise<void> {
    try {
      const cacheKey = `${CACHE_PREFIX.MOVIE_DETAIL}${movieId}`;
      await StorageUtil.remove(cacheKey);
    } catch (error) {
      Logger.error(TAG, `Failed to clear movie detail cache for movieId ${movieId}`, error instanceof Error ? error : new Error(String(error)));
    }
  }

  // ========== 本地数据同步方法 ========== Local data sync methods

  /**
   * 将电影数据同步到本地数据库 Sync movie data to local database
   */
  private async syncMovieToLocal(movieData: MovieDetailData): Promise<void> {
    try {
      // 创建Movie对象 Create Movie object
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

      // 保存到本地数据库 Save to local database
      await this.databaseRepo.saveMovie(movie);
    } catch (error) {
      Logger.error(TAG, `Failed to sync movie to local database: ${movieData.id}`, error instanceof Error ? error : new Error(String(error)));
    }
  }
}





