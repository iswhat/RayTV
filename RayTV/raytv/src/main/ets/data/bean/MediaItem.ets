// MediaItem.ets - 媒体项数据模型

/**
 * 媒体项接口定义
 */
export interface MediaItem {
  id: string;
  title: string;
  coverUrl?: string;
  description?: string;
  year?: string;
  region?: string;
  score?: string;
  actors?: string[];
  siteKey: string;
}
