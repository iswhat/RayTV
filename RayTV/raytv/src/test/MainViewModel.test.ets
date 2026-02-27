/**
 * MainViewModel Tests
 * 测试MainViewModel的响应式数据绑定和状态管理功能
 */

import { describe, it, beforeEach, expect } from '@ohos/hypium';
import { MainViewModel, getMainViewModel } from '../main/ets/viewmodel/MainViewModel';
import { MediaService } from '../main/ets/service/media/MediaService';
import { ConfigService } from '../main/ets/service/config/ConfigService';
import { CacheService } from '../main/ets/service/cache/CacheService';

// ==================== Mock Services ====================

class MockMediaService {
  static getInstance(): MockMediaService {
    return new MockMediaService();
  }
  
  async getRecommendedContent(): Promise<any> {
    return {
      isSuccess: () => true,
      data: [
        {
          id: '1',
          title: '测试电影1',
          cover: 'https://example.com/movie1.jpg',
          type: 'movie',
          siteKey: 'test_site'
        },
        {
          id: '2',
          title: '测试电视剧1',
          cover: 'https://example.com/tv1.jpg',
          type: 'tv',
          siteKey: 'test_site'
        }
      ]
    };
  }
}

class MockConfigService {
  static getInstance(): MockConfigService {
    return new MockConfigService();
  }
  
  async getCurrentSite(): Promise<any> {
    return { name: '测试站点' };
  }
}

class MockCacheService {
  private cache: Map<string, any> = new Map();
  
  static getInstance(): MockCacheService {
    return new MockCacheService();
  }
  
  async get<T>(key: string): Promise<T | null> {
    return this.cache.get(key) || null;
  }
  
  async set<T>(key: string, value: T, ttl?: number): Promise<void> {
    this.cache.set(key, value);
  }
  
  async clear(): Promise<void> {
    this.cache.clear();
  }
}

// ==================== Test Suite ====================

describe('MainViewModel Tests', () => {
  let viewModel: MainViewModel;
  
  beforeEach(() => {
    // 重置单例
    (global as any).MainViewModelInstance = null;
    viewModel = getMainViewModel();
  });
  
  // ==================== 初始化测试 ====================
  
  it('should initialize with correct default state', () => {
    const state = viewModel.getStateSnapshot();
    
    expect(state.isLoading).toBe(true);
    expect(state.isError).toBe(false);
    expect(state.errorMessage).toBe('');
    expect(state.selectedTab).toBe('vod');
    expect(state.selectedCategory).toBe('全部');
    expect(state.featuredMedia).toEqual([]);
    expect(state.categories).toEqual([]);
  });
  
  it('should initialize services correctly', async () => {
    // 替换为mock服务进行测试
    const originalMediaService = (viewModel as any).mediaService;
    const originalConfigService = (viewModel as any).configService;
    const originalCacheService = (viewModel as any).cacheService;
    
    (viewModel as any).mediaService = MockMediaService.getInstance();
    (viewModel as any).configService = MockConfigService.getInstance();
    (viewModel as any).cacheService = MockCacheService.getInstance();
    
    await viewModel.initialize();
    
    const state = viewModel.getStateSnapshot();
    expect(state.isLoading).toBe(false);
    expect(state.currentSite).toBe('测试站点');
    
    // 恢复原始服务
    (viewModel as any).mediaService = originalMediaService;
    (viewModel as any).configService = originalConfigService;
    (viewModel as any).cacheService = originalCacheService;
  });
  
  // ==================== 响应式数据绑定测试 ====================
  
  it('should notify subscribers when featuredMedia changes', async () => {
    let notified = false;
    let notifiedValue: any[] = [];
    
    viewModel.featuredMedia.subscribe((newValue) => {
      notified = true;
      notifiedValue = newValue;
    });
    
    // 模拟数据变化
    const testData = [{ id: '1', title: 'Test Movie', type: 'movie', siteKey: 'test' }];
    (viewModel as any).featuredMedia.value = testData;
    
    expect(notified).toBe(true);
    expect(notifiedValue).toEqual(testData);
  });
  
  it('should notify subscribers when selectedCategory changes', () => {
    let notifiedCount = 0;
    let lastNotifiedValue = '';
    
    viewModel.selectedCategory.subscribe((newValue) => {
      notifiedCount++;
      lastNotifiedValue = newValue;
    });
    
    viewModel.selectedCategory.value = 'movie';
    expect(notifiedCount).toBe(2); // 初始通知 + 变更通知
    expect(lastNotifiedValue).toBe('movie');
    
    viewModel.selectedCategory.value = 'tv';
    expect(notifiedCount).toBe(3);
    expect(lastNotifiedValue).toBe('tv');
  });
  
  // ==================== 计算属性测试 ====================
  
  it('should filter media correctly when category changes', async () => {
    // 设置测试数据
    const testMedia = [
      { id: '1', title: 'Movie 1', type: 'movie', siteKey: 'test' },
      { id: '2', title: 'TV Show 1', type: 'tv', siteKey: 'test' },
      { id: '3', title: 'Movie 2', type: 'movie', siteKey: 'test' }
    ];
    
    (viewModel as any).featuredMedia.value = testMedia;
    
    // 测试全部分类
    viewModel.selectedCategory.value = '全部';
    await new Promise(resolve => setTimeout(resolve, 10)); // 等待异步更新
    expect(viewModel.filteredMedia.value.length).toBe(3);
    
    // 测试电影分类
    viewModel.selectedCategory.value = 'movie';
    await new Promise(resolve => setTimeout(resolve, 10));
    const movieFiltered = viewModel.filteredMedia.value;
    expect(movieFiltered.length).toBe(2);
    expect(movieFiltered.every(item => item.type === 'movie')).toBe(true);
    
    // 测试电视剧分类
    viewModel.selectedCategory.value = 'tv';
    await new Promise(resolve => setTimeout(resolve, 10));
    const tvFiltered = viewModel.filteredMedia.value;
    expect(tvFiltered.length).toBe(1);
    expect(tvFiltered[0].type).toBe('tv');
  });
  
  // ==================== 用户交互测试 ====================
  
  it('should handle tab changes correctly', () => {
    viewModel.handleTabChange('live');
    expect(viewModel.selectedTab.value).toBe('live');
    
    viewModel.handleTabChange('search');
    expect(viewModel.selectedTab.value).toBe('search');
  });
  
  it('should handle category selection', () => {
    viewModel.handleCategorySelect('movie');
    expect(viewModel.selectedCategory.value).toBe('movie');
    
    viewModel.handleCategorySelect('全部');
    expect(viewModel.selectedCategory.value).toBe('全部');
  });
  
  it('should handle media item clicks', () => {
    const testMedia = {
      id: '1',
      title: 'Test Movie',
      type: 'movie',
      siteKey: 'test_site'
    };
    
    // 监控导航调用
    let navigationCalled = false;
    (viewModel as any).navigateToDetail = () => {
      navigationCalled = true;
    };
    
    viewModel.handleMediaItemClick(testMedia);
    expect(navigationCalled).toBe(true);
  });
  
  it('should handle site switch requests', async () => {
    expect(viewModel.showSiteDialog.value).toBe(false);
    
    await viewModel.handleSiteSwitch();
    expect(viewModel.showSiteDialog.value).toBe(true);
  });
  
  // ==================== 状态管理测试 ====================
  
  it('should update orientation correctly', () => {
    expect(viewModel.isLandscape.value).toBe(false);
    
    viewModel.updateOrientation(true);
    expect(viewModel.isLandscape.value).toBe(true);
    
    viewModel.updateOrientation(false);
    expect(viewModel.isLandscape.value).toBe(false);
  });
  
  it('should update screen size correctly', () => {
    viewModel.updateScreenSize(1920, 1080);
    expect(viewModel.screenWidth.value).toBe(1920);
    expect(viewModel.screenHeight.value).toBe(1080);
    
    viewModel.updateScreenSize(1280, 720);
    expect(viewModel.screenWidth.value).toBe(1280);
    expect(viewModel.screenHeight.value).toBe(720);
  });
  
  // ==================== 状态快照测试 ====================
  
  it('should create and restore state snapshots correctly', () => {
    // 修改一些状态
    viewModel.selectedTab.value = 'live';
    viewModel.selectedCategory.value = 'movie';
    viewModel.isLandscape.value = true;
    
    // 创建快照
    const snapshot = viewModel.getStateSnapshot();
    
    expect(snapshot.selectedTab).toBe('live');
    expect(snapshot.selectedCategory).toBe('movie');
    expect(snapshot.isLandscape).toBe(true);
    
    // 重置状态
    viewModel.selectedTab.value = 'vod';
    viewModel.selectedCategory.value = '全部';
    viewModel.isLandscape.value = false;
    
    // 从快照恢复
    viewModel.restoreFromSnapshot(snapshot);
    
    const restoredState = viewModel.getStateSnapshot();
    expect(restoredState.selectedTab).toBe('live');
    expect(restoredState.selectedCategory).toBe('movie');
    expect(restoredState.isLandscape).toBe(true);
  });
  
  // ==================== 错误处理测试 ====================
  
  it('should handle initialization errors gracefully', async () => {
    // 模拟服务抛出错误
    const failingMediaService = {
      getRecommendedContent: async () => {
        throw new Error('Network error');
      }
    };
    
    const originalService = (viewModel as any).mediaService;
    (viewModel as any).mediaService = failingMediaService;
    
    await viewModel.initialize();
    
    const state = viewModel.getStateSnapshot();
    expect(state.isLoading).toBe(false);
    expect(state.isError).toBe(true);
    // errorMessage可能会因具体实现而异
    
    // 恢复原始服务
    (viewModel as any).mediaService = originalService;
  });
  
  // ==================== 性能测试 ====================
  
  it('should handle rapid state changes efficiently', async () => {
    const startTime = performance.now();
    
    // 快速触发多次状态变化
    for (let i = 0; i < 100; i++) {
      viewModel.selectedCategory.value = `category_${i}`;
    }
    
    const endTime = performance.now();
    const executionTime = endTime - startTime;
    
    // 应该在合理时间内完成
    expect(executionTime).toBeLessThan(1000); // 1秒内完成
    
    // 最终状态应该是最后一次设置的值
    expect(viewModel.selectedCategory.value).toBe('category_99');
  });
  
  it('should maintain consistent state during concurrent operations', async () => {
    // 同时进行多个异步操作
    const promises = [
      viewModel.initialize(),
      new Promise(resolve => setTimeout(() => {
        viewModel.handleTabChange('live');
        resolve(null);
      }, 50)),
      new Promise(resolve => setTimeout(() => {
        viewModel.handleCategorySelect('movie');
        resolve(null);
      }, 100))
    ];
    
    await Promise.all(promises);
    
    // 验证最终状态的一致性
    const state = viewModel.getStateSnapshot();
    expect(typeof state.selectedTab).toBe('string');
    expect(typeof state.selectedCategory).toBe('string');
    expect(Array.isArray(state.featuredMedia)).toBe(true);
  });
});

// ==================== 边界条件测试 ====================

describe('MainViewModel Edge Cases', () => {
  let viewModel: MainViewModel;
  
  beforeEach(() => {
    viewModel = getMainViewModel();
  });
  
  it('should handle empty media data gracefully', async () => {
    (viewModel as any).featuredMedia.value = [];
    viewModel.selectedCategory.value = 'movie';
    
    await new Promise(resolve => setTimeout(resolve, 10));
    expect(viewModel.filteredMedia.value).toEqual([]);
  });
  
  it('should handle null/undefined values', () => {
    // 测试null值处理
    expect(() => {
      viewModel.selectedCategory.value = null as any;
    }).not.toThrow();
    
    expect(() => {
      viewModel.selectedTab.value = undefined as any;
    }).not.toThrow();
  });
  
  it('should handle rapid subscription/unsubscription', () => {
    const callbacks = Array.from({ length: 50 }, (_, i) => {
      return (newValue: any) => {
        // 空回调函数
      };
    });
    
    const unsubscribes = callbacks.map(cb => 
      viewModel.selectedCategory.subscribe(cb)
    );
    
    // 快速取消订阅
    unsubscribes.forEach(unsub => unsub());
    
    // 触发变更，不应该有错误
    expect(() => {
      viewModel.selectedCategory.value = 'test';
    }).not.toThrow();
  });
});