/**
 * Media item data type | 媒体项数据类型
 * Media item interface definition | 媒体项接口定义
 */
export interface MediaItem {
  id: string;            // Media item ID | 媒体项ID
  title: string;         // Title | 标题
  coverUrl?: string;     // Cover URL | 封面URL
  description?: string;  // Description | 描述
  year?: string;         // Year | 年份
  region?: string;       // Region | 地区
  score?: string;        // Score | 评分
  actors?: string[];     // Actor list | 演员列表
  siteKey: string;       // Site identifier | 站点标识
}
