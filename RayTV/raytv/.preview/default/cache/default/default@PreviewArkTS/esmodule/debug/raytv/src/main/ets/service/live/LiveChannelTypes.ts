/**
 * 直播频道数据结构统一定义
 * Live Channel Data Structure Unified Definition
 *
 * 统一所有直播频道相关的接口定义，避免重复和不一致
 */
// ========================================
// 核心直播频道接口（推荐使用）
// ========================================
/**
 * 带来源标识的直播频道（核心接口）
 * Live channel with source identifier (Core interface)
 *
 * 这是RayTV项目中推荐的直播频道数据结构
 * 包含来源追踪和完整的频道元数据
 */
export interface LiveChannelWithSource {
    // 基本标识 | Basic identifiers
    id: string; // 频道ID | Channel ID
    name: string; // 频道名称 | Channel name
    url: string; // 播放URL | Playback URL
    group: string; // 分组名称 | Group name
    // 来源标识 | Source identifier
    sourceId: string; // 源ID | Source ID
    sourceName: string; // 源名称 | Source name
    // 频道元数据 | Channel metadata
    logo?: string; // 频道logo | Channel logo
    epgUrl?: string; // EPG URL | EPG URL
}
// ========================================
// 扩展接口（可选字段）
// ========================================
/**
 * 扩展的直播频道接口
 * Extended live channel interface with optional fields
 *
 * 在LiveChannelWithSource基础上添加更多可选字段
 * 用于需要更丰富信息的场景
 */
export interface ExtendedLiveChannelWithSource extends LiveChannelWithSource {
    description?: string; // 频道描述 | Channel description
    country?: string; // 国家/地区 | Country/region
    language?: string; // 语言 | Language
    tags?: string[]; // 标签 | Tags
    isFavorite?: boolean; // 是否收藏 | Whether favorite
    viewCount?: number; // 观看人数 | View count
    // EPG信息 | EPG information
    currentProgram?: LiveProgramInfo;
    nextProgram?: LiveProgramInfo;
}
/**
 * 直播分类接口
 * Live category interface
 */
export interface LiveCategory {
    id: string; // 分类ID | Category ID
    name: string; // 分类名称 | Category name
    icon?: string; // 分类图标 | Category icon
    order?: number; // 排序 | Order
    channelCount?: number; // 频道数量 | Channel count
}
/**
 * 直播节目信息
 * Live program information
 */
export interface LiveProgramInfo {
    id: string; // 节目ID | Program ID
    title: string; // 节目标题 | Program title
    startTime: number; // 开始时间（时间戳）| Start time (timestamp)
    endTime: number; // 结束时间（时间戳）| End time (timestamp)
    description?: string; // 节目描述 | Program description
}
// ========================================
// 类型转换和适配器
// ========================================
/**
 * 从旧版LiveChannel转换为LiveChannelWithSource
 * Convert from legacy LiveChannel to LiveChannelWithSource
 *
 * @param legacy 旧版LiveChannel对象 | Legacy LiveChannel object
 * @param sourceId 源ID | Source ID
 * @param sourceName 源名称 | Source name
 * @returns LiveChannelWithSource对象 | LiveChannelWithSource object
 */
export function toLiveChannelWithSource(legacy: Record<string, string | undefined>, sourceId: string, sourceName: string): LiveChannelWithSource {
    return {
        id: legacy['id'] || legacy['channelId'] || '',
        name: legacy['name'] || legacy['channelName'] || '',
        url: legacy['url'] || legacy['playUrl'] || '',
        group: legacy['groupId'] || legacy['categoryId'] || legacy['categoryName'] || '默认',
        sourceId: sourceId,
        sourceName: sourceName,
        logo: legacy['logo'] || legacy['logoUrl'],
        epgUrl: legacy['epg'] || legacy['epgUrl']
    };
}
/**
 * 从LiveChannelWithSource转换为扩展版本
 * Convert from LiveChannelWithSource to extended version
 *
 * @param channel LiveChannelWithSource对象 | LiveChannelWithSource object
 * @param extended 扩展字段 | Extended fields
 * @returns ExtendedLiveChannelWithSource对象 | ExtendedLiveChannelWithSource object
 */
export function extendLiveChannel(channel: LiveChannelWithSource, extended?: Partial<ExtendedLiveChannelWithSource>): ExtendedLiveChannelWithSource {
    const result: ExtendedLiveChannelWithSource = {
        id: channel.id,
        name: channel.name,
        url: channel.url,
        group: channel.group,
        sourceId: channel.sourceId,
        sourceName: channel.sourceName,
        logo: channel.logo,
        epgUrl: channel.epgUrl,
        description: extended?.description,
        country: extended?.country,
        language: extended?.language,
        isFavorite: extended?.isFavorite,
        viewCount: extended?.viewCount,
        currentProgram: extended?.currentProgram,
        nextProgram: extended?.nextProgram
    };
    return result;
}
/**
 * 验证LiveChannelWithSource数据是否有效
 * Validate if LiveChannelWithSource data is valid
 *
 * @param channel 待验证的频道对象 | Channel object to validate
 * @returns 是否有效 | Whether valid
 */
export function isValidLiveChannel(channel: LiveChannelWithSource | null | undefined): boolean {
    if (!channel) {
        return false;
    }
    const isValid: boolean = (typeof channel.id === 'string' && channel.id.length > 0 &&
        typeof channel.name === 'string' && channel.name.length > 0 &&
        typeof channel.url === 'string' && channel.url.length > 0 &&
        typeof channel.group === 'string' &&
        typeof channel.sourceId === 'string' &&
        typeof channel.sourceName === 'string');
    return isValid;
}
/**
 * 创建LiveChannelWithSource对象
 * Create LiveChannelWithSource object
 *
 * @param params 参数 | Parameters
 * @returns LiveChannelWithSource对象 | LiveChannelWithSource object
 */
export function createLiveChannelWithSource(params: Partial<LiveChannelWithSource>): LiveChannelWithSource {
    return {
        id: params.id || '',
        name: params.name || '',
        url: params.url || '',
        group: params.group || '默认',
        sourceId: params.sourceId || '',
        sourceName: params.sourceName || '',
        logo: params.logo,
        epgUrl: params.epgUrl
    };
}
