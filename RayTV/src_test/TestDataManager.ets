// TestDataManager.ets - 测试数据管理文件 // Test data management file
// 管理测试过程中使用的模拟数据 // Manages mock data used in test process

/**
 * 测试数据管理器 // Test data manager
 */
export class TestDataManager {
  private static instance: TestDataManager;
  private testData: Map<string, any> = new Map();

  private constructor() {
  }

  /**
   * 获取单例实例 // Get singleton instance
   */
  public static getInstance(): TestDataManager {
    if (!TestDataManager.instance) {
      TestDataManager.instance = new TestDataManager();
    }
    return TestDataManager.instance;
  }

  /**
   * 设置测试数据 // Set test data
   * @param key 数据键名 // Data key
   * @param data 测试数据 // Test data
   */
  public setTestData(key: string, data: any): void {
    this.testData.set(key, data);
  }

  /**
   * 获取测试数据 // Get test data
   * @param key 数据键名 // Data key
   * @returns 测试数据 // Test data
   */
  public getTestData(key: string): any {
    return this.testData.get(key);
  }

  /**
   * 移除测试数据 // Remove test data
   * @param key 数据键名 // Data key
   */
  public removeTestData(key: string): void {
    this.testData.delete(key);
  }

  /**
   * 清空所有测试数据 // Clear all test data
   */
  public clearAllTestData(): void {
    this.testData.clear();
  }

  /**
   * 获取模拟的配置数据 // Get mock config data
   */
  public getMockConfigData(): any {
    return {
      appName: 'RayTV',
      version: '1.0.0',
      debug: true,
      apiBaseUrl: 'https://api.example.com',
      timeout: 30000,
      retryCount: 3
    };
  }

  /**
   * 获取模拟的站点数据 // Get mock sites data
   */
  public getMockSitesData(): any[] {
    return [
      {
        id: 'site1',
        name: '测试站点1',
        url: 'https://test1.example.com',
        enabled: true,
        priority: 1,
        type: 'video',
        categories: ['movie', 'tv'],
        headers: {},
        cookies: {},
        searchUrl: 'https://test1.example.com/search',
        detailUrl: 'https://test1.example.com/detail'
      },
      {
        id: 'site2',
        name: '测试站点2',
        url: 'https://test2.example.com',
        enabled: false,
        priority: 2,
        type: 'video',
        categories: ['movie'],
        headers: {},
        cookies: {},
        searchUrl: 'https://test2.example.com/search',
        detailUrl: 'https://test2.example.com/detail'
      }
    ];
  }

  /**
   * 获取模拟的直播数据 // Get mock lives data
   */
  public getMockLivesData(): any[] {
    return [
      {
        id: 'live1',
        name: '测试直播1',
        url: 'https://live1.example.com',
        enabled: true,
        category: 'sports',
        logo: 'https://live1.example.com/logo.png',
        source: 'test'
      },
      {
        id: 'live2',
        name: '测试直播2',
        url: 'https://live2.example.com',
        enabled: true,
        category: 'news',
        logo: 'https://live2.example.com/logo.png',
        source: 'test'
      }
    ];
  }

  /**
   * 获取模拟的媒体数据 // Get mock media data
   */
  public getMockMediaData(): any {
    return {
      id: 'media1',
      title: '测试视频',
      url: 'https://example.com/test.mp4',
      cover: 'https://example.com/cover.jpg',
      duration: 3600,
      size: 1024 * 1024 * 100, // 100MB
      quality: '1080p',
      format: 'mp4',
      mimeType: 'video/mp4',
      sources: [
        {
          id: 'source1',
          name: '源1',
          url: 'https://example.com/test.mp4'
        },
        {
          id: 'source2',
          name: '源2',
          url: 'https://example.com/test2.mp4'
        }
      ],
      subtitles: [
        {
          id: 'sub1',
          name: '中文字幕',
          url: 'https://example.com/subtitle.zh.srt',
          language: 'zh'
        },
        {
          id: 'sub2',
          name: '英文字幕',
          url: 'https://example.com/subtitle.en.srt',
          language: 'en'
        }
      ],
      audioTracks: [
        {
          id: 'audio1',
          name: '中文配音',
          language: 'zh'
        },
        {
          id: 'audio2',
          name: '英文配音',
          language: 'en'
        }
      ]
    };
  }

  /**
   * 获取模拟的HTTP响应数据 // Get mock HTTP response data
   */
  public getMockHttpResponseData(): any {
    return {
      status: 200,
      data: {
        success: true,
        message: '操作成功',
        data: {}
      },
      headers: {
        'content-type': 'application/json',
        'content-length': '100',
        'date': new Date().toUTCString()
      },
      url: 'https://example.com/api'
    };
  }

  /**
   * 获取模拟的错误响应数据 // Get mock error response data
   */
  public getMockErrorResponseData(): any {
    return {
      status: 400,
      data: {
        success: false,
        message: '操作失败',
        error: {
          code: 'ERROR_CODE',
          message: '错误信息'
        }
      },
      headers: {
        'content-type': 'application/json',
        'content-length': '100',
        'date': new Date().toUTCString()
      },
      url: 'https://example.com/api'
    };
  }

  /**
   * 获取模拟的数据库记录数据 // Get mock database record data
   */
  public getMockDatabaseRecordData(): any {
    return {
      id: 1,
      name: '测试记录',
      value: '测试值',
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    };
  }

  /**
   * 获取模拟的缓存项数据 // Get mock cache item data
   */
  public getMockCacheItemData(): any {
    return {
      id: 'cache1',
      url: 'https://example.com/test.mp4',
      filePath: '/cache/media/test.mp4',
      fileName: 'test.mp4',
      size: 1024 * 1024 * 100, // 100MB
      downloadedSize: 1024 * 1024 * 100, // 100MB
      duration: 3600,
      format: 'mp4',
      quality: '1080p',
      mimeType: 'video/mp4',
      status: 'cached',
      lastAccessTime: Date.now(),
      creationTime: Date.now(),
      accessCount: 1,
      sourceId: 'source1',
      sourceName: '测试源',
      metadata: {
        title: '测试视频',
        cover: 'https://example.com/cover.jpg'
      }
    };
  }

  /**
   * 获取模拟的播放历史数据 // Get mock playback history data
   */
  public getMockPlaybackHistoryData(): any {
    return {
      id: 'history1',
      mediaId: 'media1',
      mediaTitle: '测试视频',
      currentTime: 600, // 10分钟
      totalTime: 3600, // 1小时
      lastPlayed: new Date().toISOString(),
      playbackCount: 1,
      sourceId: 'source1',
      sourceName: '测试源'
    };
  }

  /**
   * 获取模拟的用户数据 // Get mock user data
   */
  public getMockUserData(): any {
    return {
      id: 'user1',
      username: 'testuser',
      email: 'test@example.com',
      nickname: '测试用户',
      avatar: 'https://example.com/avatar.jpg',
      createdAt: new Date().toISOString(),
      lastLogin: new Date().toISOString(),
      preferences: {
        theme: 'light',
        language: 'zh',
        playbackSpeed: 1.0,
        subtitlesEnabled: true
      }
    };
  }
}

/**
 * 获取测试数据管理器实例 // Get test data manager instance
 */
export function getTestDataManager(): TestDataManager {
  return TestDataManager.getInstance();
}

/**
 * 生成随机字符串 // Generate random string
 * @param length 字符串长度 // String length
 */
export function generateRandomString(length: number = 10): string {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

/**
 * 生成随机数字 // Generate random number
 * @param min 最小值 // Minimum value
 * @param max 最大值 // Maximum value
 */
export function generateRandomNumber(min: number = 0, max: number = 100): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/**
 * 生成随机布尔值 // Generate random boolean
 */
export function generateRandomBoolean(): boolean {
  return Math.random() > 0.5;
}

/**
 * 生成随机日期 // Generate random date
 * @param days 天数范围 // Days range
 */
export function generateRandomDate(days: number = 30): Date {
  const date = new Date();
  const randomDays = Math.floor(Math.random() * days);
  date.setDate(date.getDate() - randomDays);
  return date;
}

/**
 * 生成模拟的错误对象 // Generate mock error object
 * @param message 错误信息 // Error message
 * @param code 错误代码 // Error code
 */
export function generateMockError(message: string = '测试错误', code: string = 'TEST_ERROR'): Error {
  const error = new Error(message);
  (error as any).code = code;
  return error;
}
