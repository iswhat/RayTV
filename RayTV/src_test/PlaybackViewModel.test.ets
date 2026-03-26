/**
 * PlaybackViewModel Tests
 * 测试PlaybackViewModel的复杂状态管理和多媒体控制功能
 */

import { describe, it, beforeEach, expect } from '@ohos/hypium';
import { PlaybackViewModel, getPlaybackViewModel } from '../main/ets/viewmodel/PlaybackViewModel';

// ==================== Mock Services ====================

class MockPlaybackService {
  static getInstance(): MockPlaybackService {
    return new MockPlaybackService();
  }
  
  async initialize(config: any): Promise<void> {
    // 模拟初始化
  }
  
  async getPlaybackState(): Promise<any> {
    return {
      isPlaying: true,
      currentTime: 120,
      duration: 3600,
      volume: 0.8
    };
  }
  
  async play(): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
  
  async pause(): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
  
  async seek(time: number): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
  
  async setVolume(volume: number): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
  
  async setPlaybackSpeed(speed: number): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
  
  async getAudioTracks(): Promise<any[]> {
    return [
      { id: '1', name: 'Stereo', language: 'eng' },
      { id: '2', name: '5.1 Surround', language: 'eng' }
    ];
  }
  
  async switchEpisode(episode: any): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
  
  async switchParseLine(line: any): Promise<{ isSuccess: () => boolean }> {
    return { isSuccess: () => true };
  }
}

class MockMediaService {
  static getInstance(): MockMediaService {
    return new MockMediaService();
  }
  
  async getMediaDetail(id: string, siteKey: string, type: string): Promise<any> {
    return {
      isSuccess: () => true,
      data: {
        id: 'test_movie_1',
        title: '测试电影',
        url: 'https://example.com/video.mp4',
        year: '2024',
        episodes: [
          { id: 'ep1', title: '第1集', current: true },
          { id: 'ep2', title: '第2集', current: false }
        ],
        parseLines: [
          { id: 'line1', name: '线路1', isCurrent: true },
          { id: 'line2', name: '线路2', isCurrent: false }
        ]
      }
    };
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
}

class MockSubtitleService {
  static getInstance(): MockSubtitleService {
    return new MockSubtitleService();
  }
  
  async searchSubtitles(query: any): Promise<any[]> {
    return [
      { id: 'sub1', language: 'zh-CN', name: '中文简体' },
      { id: 'sub2', language: 'en', name: 'English' }
    ];
  }
}

// ==================== Test Suite ====================

describe('PlaybackViewModel Tests', () => {
  let viewModel: PlaybackViewModel;
  
  beforeEach(() => {
    // 注入mock服务
    (global as any).PlaybackService = MockPlaybackService;
    (global as any).MediaService = MockMediaService;
    (global as any).CacheService = MockCacheService;
    (global as any).SubtitleService = MockSubtitleService;
    
    // 重置单例
    (global as any).PlaybackViewModelInstance = null;
    viewModel = getPlaybackViewModel();
  });
  
  // ==================== 初始化测试 ====================
  
  it('should initialize with correct default state', () => {
    const snapshot = viewModel.getStateSnapshot();
    
    expect(snapshot.controlState.isLoading).toBe(true);
    expect(snapshot.controlState.isError).toBe(false);
    expect(snapshot.controlState.isPlaying).toBe(true);
    expect(snapshot.controlState.currentTime).toBe(0);
    expect(snapshot.mediaState.info).toBeNull();
    expect(snapshot.uiState.showControls).toBe(true);
  });
  
  it('should initialize playback successfully', async () => {
    const initParams = {
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'movie'
    };
    
    await viewModel.initialize(initParams);
    
    const state = viewModel.getStateSnapshot();
    expect(state.controlState.isLoading).toBe(false);
    expect(state.controlState.isError).toBe(false);
    expect(state.mediaState.info).toBeTruthy();
    expect(state.mediaState.info?.title).toBe('测试电影');
  });
  
  // ==================== 响应式数据绑定测试 ====================
  
  it('should update computed time formats correctly', async () => {
    let currentTimeUpdates = 0;
    let durationUpdates = 0;
    let remainingTimeUpdates = 0;
    
    viewModel.formattedCurrentTime.subscribe(() => currentTimeUpdates++);
    viewModel.formattedDuration.subscribe(() => durationUpdates++);
    viewModel.remainingTime.subscribe(() => remainingTimeUpdates++);
    
    // 模拟时间更新
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      currentTime: 150,
      duration: 300
    };
    
    // 等待异步更新
    await new Promise(resolve => setTimeout(resolve, 10));
    
    expect(currentTimeUpdates).toBeGreaterThan(1);
    expect(durationUpdates).toBeGreaterThan(1);
    expect(remainingTimeUpdates).toBeGreaterThan(1);
    
    // 验证格式化结果
    expect(viewModel.formattedCurrentTime.value).toBe('02:30');
    expect(viewModel.formattedDuration.value).toBe('05:00');
    expect(viewModel.remainingTime.value).toBe('-02:30');
  });
  
  it('should update progress calculation automatically', () => {
    let progressUpdates = 0;
    
    viewModel.controlState.subscribe((state) => {
      if (state.progress !== undefined) {
        progressUpdates++;
      }
    });
    
    // 设置时间和时长
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      currentTime: 300,
      duration: 600
    };
    
    // 验证进度计算
    const currentState = viewModel.getStateSnapshot().controlState;
    expect(currentState.progress).toBe(50); // 300/600 = 50%
    expect(progressUpdates).toBeGreaterThan(1);
  });
  
  // ==================== 播放控制测试 ====================
  
  it('should toggle play/pause correctly', async () => {
    const initialState = viewModel.getStateSnapshot().controlState;
    expect(initialState.isPlaying).toBe(true);
    
    await viewModel.togglePlayPause();
    const afterFirstToggle = viewModel.getStateSnapshot().controlState;
    expect(afterFirstToggle.isPlaying).toBe(false);
    
    await viewModel.togglePlayPause();
    const afterSecondToggle = viewModel.getStateSnapshot().controlState;
    expect(afterSecondToggle.isPlaying).toBe(true);
  });
  
  it('should seek to specific time correctly', async () => {
    await viewModel.initialize({
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'movie'
    });
    
    await viewModel.seekTo(300);
    const state = viewModel.getStateSnapshot().controlState;
    expect(state.currentTime).toBe(300);
    expect(state.isSeeking).toBe(false);
  });
  
  it('should handle fast forward correctly', async () => {
    await viewModel.initialize({
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'movie'
    });
    
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      currentTime: 100,
      duration: 1000
    };
    
    await viewModel.fastForward(30);
    const state = viewModel.getStateSnapshot().controlState;
    expect(state.currentTime).toBe(130);
  });
  
  it('should handle rewind correctly', async () => {
    await viewModel.initialize({
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'movie'
    });
    
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      currentTime: 100
    };
    
    await viewModel.rewind(15);
    const state = viewModel.getStateSnapshot().controlState;
    expect(state.currentTime).toBe(85);
  });
  
  it('should set volume correctly', async () => {
    await viewModel.setVolume(75);
    const state = viewModel.getStateSnapshot().controlState;
    expect(state.volume).toBe(75);
    
    // 测试边界值
    await viewModel.setVolume(150); // 应该被限制在100
    expect(viewModel.getStateSnapshot().controlState.volume).toBe(100);
    
    await viewModel.setVolume(-10); // 应该被限制在0
    expect(viewModel.getStateSnapshot().controlState.volume).toBe(0);
  });
  
  it('should set playback speed correctly', async () => {
    const validSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    
    for (const speed of validSpeeds) {
      await viewModel.setPlaybackSpeed(speed);
      expect(viewModel.getStateSnapshot().controlState.playbackSpeed).toBe(speed);
    }
    
    // 测试近似值
    await viewModel.setPlaybackSpeed(1.1); // 应该四舍五入到1.0
    expect(viewModel.getStateSnapshot().controlState.playbackSpeed).toBe(1.0);
  });
  
  // ==================== 剧集和线路切换测试 ====================
  
  it('should switch episodes correctly', async () => {
    await viewModel.initialize({
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'tv'
    });
    
    const testEpisode = { id: 'ep2', title: '第2集' };
    await viewModel.switchEpisode(testEpisode);
    
    const state = viewModel.getStateSnapshot();
    expect(state.mediaState.selectedEpisode?.id).toBe('ep2');
    expect(state.mediaState.episodes[1].current).toBe(true);
  });
  
  it('should switch parse lines correctly', async () => {
    await viewModel.initialize({
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'movie'
    });
    
    const testLine = { id: 'line2', name: '线路2' };
    await viewModel.switchParseLine(testLine);
    
    const state = viewModel.getStateSnapshot();
    expect(state.mediaState.selectedLine?.id).toBe('line2');
    expect(state.mediaState.parseLines[1].isCurrent).toBe(true);
  });
  
  // ==================== UI控制测试 ====================
  
  it('should toggle controls visibility', () => {
    const initialState = viewModel.getStateSnapshot().uiState;
    expect(initialState.showControls).toBe(true);
    
    viewModel.toggleControls();
    const afterFirstToggle = viewModel.getStateSnapshot().uiState;
    expect(afterFirstToggle.showControls).toBe(false);
    
    viewModel.toggleControls();
    const afterSecondToggle = viewModel.getStateSnapshot().uiState;
    expect(afterSecondToggle.showControls).toBe(true);
  });
  
  it('should update screen information correctly', () => {
    viewModel.updateScreenInfo(1920, 1080);
    
    const state = viewModel.getStateSnapshot().uiState;
    expect(state.screenWidth).toBe(1920);
    expect(state.screenHeight).toBe(1080);
    expect(state.isLandscape).toBe(true);
    expect(state.videoPlayerHeight).toBe(648); // 1080 * 0.6
    
    viewModel.updateScreenInfo(720, 1280);
    const portraitState = viewModel.getStateSnapshot().uiState;
    expect(portraitState.isLandscape).toBe(false);
    expect(portraitState.videoPlayerHeight).toBe(400); // 固定高度
  });
  
  it('should handle control auto-hide timer', async () => {
    viewModel.toggleControls(); // 显示控制栏
    const state1 = viewModel.getStateSnapshot().uiState;
    expect(state1.showControls).toBe(true);
    expect(state1.controlHideTimer).not.toBeNull();
    
    // 等待自动隐藏
    await new Promise(resolve => setTimeout(resolve, 3100));
    
    const state2 = viewModel.getStateSnapshot().uiState;
    expect(state2.showControls).toBe(false);
  });
  
  // ==================== 错误处理测试 ====================
  
  it('should handle initialization errors gracefully', async () => {
    // 模拟服务抛出错误
    const failingMediaService = {
      getMediaDetail: async () => {
        return {
          isSuccess: () => false,
          message: 'Network error'
        };
      }
    };
    
    const originalService = (viewModel as any).mediaService;
    (viewModel as any).mediaService = failingMediaService;
    
    try {
      await viewModel.initialize({
        id: 'invalid_id',
        siteKey: 'invalid_site',
        type: 'movie'
      });
    } catch (error) {
      // 期望捕获到错误
    }
    
    const state = viewModel.getStateSnapshot();
    expect(state.controlState.isError).toBe(true);
    expect(state.controlState.isLoading).toBe(false);
    
    // 恢复原始服务
    (viewModel as any).mediaService = originalService;
  });
  
  // ==================== 性能测试 ====================
  
  it('should handle rapid state changes efficiently', async () => {
    const startTime = performance.now();
    
    // 快速触发多次状态变化
    for (let i = 0; i < 50; i++) {
      (viewModel as any).controlState.value = {
        ...viewModel.getStateSnapshot().controlState,
        currentTime: i * 10,
        duration: 1000
      };
    }
    
    const endTime = performance.now();
    const executionTime = endTime - startTime;
    
    expect(executionTime).toBeLessThan(500); // 500ms内完成
    
    // 验证最终状态正确性
    const finalState = viewModel.getStateSnapshot().controlState;
    expect(finalState.currentTime).toBe(490);
    expect(finalState.progress).toBe(49); // 490/1000 = 49%
  });
  
  it('should maintain consistent state during concurrent operations', async () => {
    await viewModel.initialize({
      id: 'test_movie_1',
      siteKey: 'test_site',
      type: 'movie'
    });
    
    // 并发执行多个操作
    const operations = [
      viewModel.seekTo(300),
      viewModel.setVolume(80),
      viewModel.setPlaybackSpeed(1.5),
      viewModel.fastForward(15)
    ];
    
    await Promise.all(operations);
    
    // 验证状态一致性
    const state = viewModel.getStateSnapshot();
    expect(typeof state.controlState.currentTime).toBe('number');
    expect(typeof state.controlState.volume).toBe('number');
    expect(typeof state.controlState.playbackSpeed).toBe('number');
  });
});

// ==================== 边界条件测试 ====================

describe('PlaybackViewModel Edge Cases', () => {
  let viewModel: PlaybackViewModel;
  
  beforeEach(() => {
    viewModel = getPlaybackViewModel();
  });
  
  it('should handle zero duration gracefully', () => {
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      duration: 0,
      currentTime: 0
    };
    
    const state = viewModel.getStateSnapshot().controlState;
    expect(state.progress).toBe(0);
    expect(viewModel.formattedDuration.value).toBe('00:00');
  });
  
  it('should handle negative time values', () => {
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      currentTime: -50,
      duration: 300
    };
    
    // 应该格式化为00:00而不是负数
    expect(viewModel.formattedCurrentTime.value).toBe('00:00');
  });
  
  it('should handle NaN values gracefully', () => {
    (viewModel as any).controlState.value = {
      ...viewModel.getStateSnapshot().controlState,
      currentTime: NaN,
      duration: NaN
    };
    
    const state = viewModel.getStateSnapshot().controlState;
    expect(state.progress).toBe(0);
    expect(viewModel.formattedCurrentTime.value).toBe('00:00');
    expect(viewModel.formattedDuration.value).toBe('00:00');
  });
  
  it('should handle rapid subscription/unsubscription', () => {
    const callbacks = Array.from({ length: 30 }, (_, i) => {
      return (newValue: any) => {
        // 空回调
      };
    });
    
    const unsubscribes = callbacks.map(cb => 
      viewModel.controlState.subscribe(cb)
    );
    
    // 快速取消订阅
    unsubscribes.forEach(unsub => unsub());
    
    // 触发状态变更不应报错
    expect(() => {
      (viewModel as any).controlState.value = {
        ...viewModel.getStateSnapshot().controlState,
        currentTime: 100
      };
    }).not.toThrow();
  });
});