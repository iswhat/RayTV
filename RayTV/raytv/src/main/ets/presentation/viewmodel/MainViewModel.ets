/**
 * 主ViewModel | Main ViewModel
 * 负责应用的主要状态管理和数据转换
 */
import { BaseViewModel } from './BaseViewModel';
import { AppEvents } from '../../common/event/EventBus';
import Logger from '../../common/util/Logger';

// 视图状态接口 | View state interface
interface ViewState {
  selectedTab: string;
  featuredMedia: MediaItem[];
  categories: CategoryItem[];
  isLoading: boolean;
  error: string | null;
  searchQuery: string;
  networkStatus: NetworkStatus;
}

// 媒体项接口 | Media item interface
interface MediaItem {
  id: string;
  title: string;
  coverUrl: string;
  type: 'vod' | 'live' | 'series';
  rating?: number;
  duration?: number;
}

// 分类项接口 | Category item interface
interface CategoryItem {
  id: string;
  name: string;
  icon?: string;
}

// 网络状态 | Network status
interface NetworkStatus {
  isConnected: boolean;
  type: 'wifi' | 'mobile' | 'ethernet' | 'unknown';
  strength?: number;
}

/**
 * 主ViewModel类 | Main ViewModel class
 */
export class MainViewModel extends BaseViewModel {
  // 视图状态 | View state
  private _state: ViewState = {
    selectedTab: 'vod',
    featuredMedia: [],
    categories: [],
    isLoading: false,
    error: null,
    searchQuery: '',
    networkStatus: {
      isConnected: true,
      type: 'unknown'
    }
  };

  // 服务实例 | Service instances
  private mediaService: string;
  private configService: string;
  private networkService: string;

  /**
   * 构造函数 | Constructor
   */
  constructor() {
    super();
    this.initializeServices();
  }

  /**
   * 初始化服务 | Initialize services
   */
  private initializeServices(): void {
    try {
      // 尝试解析服务 | Try to resolve services
      if (this.hasService('mediaService')) {
        this.mediaService = this.resolve('mediaService');
      }
      if (this.hasService('configService')) {
        this.configService = this.resolve('configService');
      }
      if (this.hasService('networkService')) {
        this.networkService = this.resolve('networkService');
      }
    } catch (error) {
      this.logger.error('Failed to initialize services:', error);
    }
  }

  /**
   * 设置事件订阅 | Set up event subscriptions
   */
  protected setupSubscriptions(): void {
    // 监听配置变化 | Listen for config changes
    this.subscribe(AppEvents.CONFIG_SOURCE_UPDATED, () => {
      this.refreshContent();
    });

    // 监听网络状态变化 | Listen for network status changes
    this.subscribe(AppEvents.NETWORK_STATUS_CHANGE, (status: NetworkStatus) => {
      this.handleNetworkChange(status);
    });

    // 监听内容聚合完成 | Listen for content aggregation complete
    this.subscribe(AppEvents.CONTENT_AGGREGATION_COMPLETE, () => {
      this.refreshContent();
    });

    // 监听内容聚合错误 | Listen for content aggregation error
    this.subscribe(AppEvents.CONTENT_AGGREGATION_ERROR, (error: string) => {
      this.setState(prev => ({
        ...prev,
        error,
        isLoading: false
      }));
    });
  }

  /**
   * 获取状态 | Get state
   */
  public get state(): ViewState {
    return this._state;
  }

  /**
   * 设置状态 | Set state
   * @param updater 状态更新函数 | State updater function
   */
  public setState(updater: (prevState: ViewState) => ViewState): void {
    this._state = updater(this._state);
    this.emit('main:stateChanged', this._state);
  }

  /**
   * 加载初始数据 | Load initial data
   */
  public async loadInitialData(): Promise<void> {
    this.setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      await Promise.all([
        this.loadCategories(),
        this.loadFeaturedContent()
      ]);
    } catch (error) {
      this.setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Failed to load initial data',
        isLoading: false
      }));
    }
  }

  /**
   * 刷新内容 | Refresh content
   */
  public async refreshContent(): Promise<void> {
    this.setState(prev => ({ ...prev, isLoading: true, error: null }));

    try {
      await this.loadFeaturedContent();
    } catch (error) {
      this.setState(prev => ({
        ...prev,
        error: error instanceof Error ? error.message : 'Failed to refresh content',
        isLoading: false
      }));
    }
  }

  /**
   * 加载分类 | Load categories
   */
  private async loadCategories(): Promise<void> {
    try {
      if (this.configService) {
        const categories = await this.configService.getCategories();
        this.setState(prev => ({
          ...prev,
          categories
        }));
      } else {
        // 使用默认分类 | Use default categories
        this.setState(prev => ({
          ...prev,
          categories: [
            { id: 'all', name: '全部' },
            { id: 'movie', name: '电影' },
            { id: 'tv', name: '电视剧' },
            { id: 'anime', name: '动漫' },
            { id: 'variety', name: '综艺' }
          ]
        }));
      }
    } catch (error) {
      this.logger.error('Failed to load categories:', error);
      // 使用默认分类 | Use default categories
      this.setState(prev => ({
        ...prev,
        categories: [
          { id: 'all', name: '全部' },
          { id: 'movie', name: '电影' },
          { id: 'tv', name: '电视剧' },
          { id: 'anime', name: '动漫' },
          { id: 'variety', name: '综艺' }
        ]
      }));
    }
  }

  /**
   * 加载推荐内容 | Load featured content
   */
  private async loadFeaturedContent(): Promise<void> {
    try {
      if (this.mediaService) {
        const content = await this.mediaService.getRecommendedContent();
        this.setState(prev => ({
          ...prev,
          featuredMedia: content,
          isLoading: false
        }));
      } else {
        // 使用模拟数据 | Use mock data
        this.setState(prev => ({
          ...prev,
          featuredMedia: this.getMockMediaItems(),
          isLoading: false
        }));
      }
    } catch (error) {
      this.logger.error('Failed to load featured content:', error);
      // 使用模拟数据 | Use mock data
      this.setState(prev => ({
        ...prev,
        featuredMedia: this.getMockMediaItems(),
        isLoading: false
      }));
    }
  }

  /**
   * 选择标签页 | Select tab
   * @param tab 标签页名称 | Tab name
   */
  public selectTab(tab: string): void {
    this.setState(prev => ({
      ...prev,
      selectedTab: tab
    }));

    if (tab === 'vod') {
      this.loadFeaturedContent();
    }
  }

  /**
   * 设置搜索查询 | Set search query
   * @param query 搜索查询 | Search query
   */
  public setSearchQuery(query: string): void {
    this.setState(prev => ({
      ...prev,
      searchQuery: query
    }));
  }

  /**
   * 处理网络状态变化 | Handle network status change
   * @param status 网络状态 | Network status
   */
  private handleNetworkChange(status: NetworkStatus): void {
    this.setState(prev => ({
      ...prev,
      networkStatus: status
    }));

    // 如果网络重新连接且有错误，尝试刷新内容 | If network reconnects and there's an error, try to refresh content
    if (status.isConnected && this._state.error) {
      this.refreshContent();
    }
  }

  /**
   * 获取模拟媒体数据 | Get mock media items
   */
  private getMockMediaItems(): MediaItem[] {
    return [
      {
        id: '1',
        title: '复仇者联盟4：终局之战',
        coverUrl: 'https://example.com/avengers4.jpg',
        type: 'movie',
        rating: 8.5,
        duration: 181
      },
      {
        id: '2',
        title: '权力的游戏 第八季',
        coverUrl: 'https://example.com/got8.jpg',
        type: 'series',
        rating: 7.5
      },
      {
        id: '3',
        title: '进击的巨人 最终季',
        coverUrl: 'https://example.com/aot.jpg',
        type: 'anime',
        rating: 9.0
      },
      {
        id: '4',
        title: '奔跑吧兄弟 第九季',
        coverUrl: 'https://example.com/run.jpg',
        type: 'variety',
        rating: 6.8
      },
      {
        id: '5',
        title: '流浪地球2',
        coverUrl: 'https://example.com/thewanderingearth2.jpg',
        type: 'movie',
        rating: 8.3,
        duration: 173
      }
    ];
  }

  /**
   * 清理资源 | Clean up resources
   */
  public override dispose(): void {
    super.dispose();
    this.logger.info('MainViewModel disposed');
  }
}
