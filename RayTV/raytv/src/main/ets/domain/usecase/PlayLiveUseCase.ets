// PlayLiveUseCase - 播放直播用例
import Logger from '../../common/util/Logger';
import { Live } from '../../data/bean/Live';
import { History } from '../../data/bean/History';
import { LiveRepository } from '../../data/repository/LiveRepository';
import { HistoryRepository } from '../../data/repository/HistoryRepository';
import { CollectionRepository } from '../../data/repository/CollectionRepository';
import { LiveStreamRepository } from '../../data/repository/LiveStreamRepository';

const TAG = 'PlayLiveUseCase';

/**
 * 播放直播内容的业务用例
 */
export class PlayLiveUseCase {
  private liveRepository: LiveRepository;
  private historyRepository: HistoryRepository;
  private collectionRepository: CollectionRepository;
  private liveStreamRepository: LiveStreamRepository;
  
  constructor(
    liveRepository: LiveRepository,
    historyRepository: HistoryRepository,
    collectionRepository: CollectionRepository,
    liveStreamRepository: LiveStreamRepository
  ) {
    this.liveRepository = liveRepository;
    this.historyRepository = historyRepository;
    this.collectionRepository = collectionRepository;
    this.liveStreamRepository = liveStreamRepository;
  }
  
  /**
   * 获取直播频道分组列表
   * @returns 直播频道分组列表
   */
  public async getLiveGroups(): Promise<{ name: string; count: number }[]> {
    try {
      Logger.info(TAG, 'Loading live channel groups');
      const groups = await this.liveRepository.getLiveGroups();
      
      // 统计每个分组的频道数量
      const groupStats = await Promise.all(
        groups.map(async (groupName) => {
          const channels = await this.liveRepository.getLiveChannelsByGroup(groupName);
          return {
            name: groupName,
            count: channels.length
          };
        })
      );
      
      return groupStats;
    } catch (error) {
    Logger.error(TAG, `Failed to load live groups: ${error}`);
    throw error;
  }
  }
  
  /**
   * 获取指定分组的直播频道
   * @param groupName 分组名称
   * @returns 直播频道列表
   */
  public async getLiveChannelsByGroup(groupName: string): Promise<Live[]> {
    try {
      Logger.info(TAG, `Loading live channels for group: ${groupName}`);
      const channels = await this.liveRepository.getLiveChannelsByGroup(groupName);
      
      // 并行检查每个频道的收藏状态
      const channelsWithCollectionStatus = await Promise.all(
        channels.map(async (channel) => {
          const isCollected = await this.collectionRepository.isCollected(
            channel.id,
            channel.sourceKey
          );
          return {
            ...channel,
            isCollected
          };
        })
      );
      
      return channelsWithCollectionStatus;
    } catch (error) {
    Logger.error(TAG, `Failed to load live channels: ${error}`);
    throw error;
  }
  }
  
  /**
   * 搜索直播频道
   * @param keyword 搜索关键词
   * @returns 匹配的直播频道列表
   */
  public async searchLiveChannels(keyword: string): Promise<Live[]> {
    try {
      Logger.info(TAG, `Searching live channels with keyword: ${keyword}`);
      return await this.liveRepository.searchLiveChannels(keyword);
    } catch (error) {
    Logger.error(TAG, `Failed to search live channels: ${error}`);
    return [];
  }
  }
  
  /**
   * 准备播放直播
   * @param liveChannel 直播频道
   * @returns 准备好的直播频道信息
   */
  public async prepareLivePlayback(liveChannel: Live): Promise<Live> {
    try {
      Logger.info(TAG, `Preparing to play live channel: ${liveChannel.name}`);
      
      // 检查并解析直播流URL
      let resolvedLive = { ...liveChannel };
      
      // 如果URL需要解析或刷新
      if (!liveChannel.url || this.needsUrlResolution(liveChannel.url)) {
        const resolvedUrl = await this.liveStreamRepository.resolveLiveStreamUrl(
          liveChannel.url,
          liveChannel.headers
        );
        resolvedLive.url = resolvedUrl;
      }
      
      // 记录观看历史
      const history: History = {
        id: liveChannel.id,
        contentId: liveChannel.id,
        contentName: liveChannel.name,
        type: 'live',
        cover: liveChannel.logo,
        sourceKey: liveChannel.sourceKey,
        position: Date.now(), // 对于直播，记录开始观看时间
        duration: 0,
        lastPlayedAt: Date.now(),
        createdAt: Date.now()
      };
      
      await this.historyRepository.saveHistory(history);
      
      // 更新频道观看次数（如果有这个功能）
      await this.liveRepository.incrementWatchCount(liveChannel.id, liveChannel.sourceKey);
      
      return resolvedLive;
    } catch (error) {
    Logger.error(TAG, `Failed to prepare live playback: ${error}`);
    throw error;
  }
  }
  
  /**
   * 获取直播EPG（电子节目单）
   * @param channelId 频道ID
   * @param date 日期，默认为今天
   * @returns 节目单信息
   */
  public async getEpgForChannel(
    channelId: string,
    date: Date = new Date()
  ): Promise<Array<{ title: string; startTime: Date; endTime: Date; current?: boolean }>> {
    try {
      Logger.info(TAG, `Loading EPG for channel: ${channelId}, date: ${date.toDateString()}`);
      return await this.liveStreamRepository.getEpgForChannel(channelId, date);
    } catch (error) {
    Logger.error(TAG, `Failed to load EPG: ${error}`);
    return [];
  }
  }
  
  /**
   * 收藏/取消收藏直播频道
   * @param liveChannel 直播频道
   * @returns 收藏状态
   */
  public async toggleCollection(liveChannel: Live): Promise<boolean> {
    try {
      const isCurrentlyCollected = await this.collectionRepository.isCollected(
        liveChannel.id,
        liveChannel.sourceKey
      );
      
      if (isCurrentlyCollected) {
        await this.collectionRepository.removeCollection(
          liveChannel.id,
          liveChannel.sourceKey
        );
        Logger.info(TAG, `Uncollected live channel: ${liveChannel.name}`);
        return false;
      } else {
        await this.collectionRepository.addCollection({
          id: liveChannel.id,
          name: liveChannel.name,
          type: 'live',
          cover: liveChannel.logo,
          sourceKey: liveChannel.sourceKey,
          addedAt: Date.now()
        });
        Logger.info(TAG, `Collected live channel: ${liveChannel.name}`);
        return true;
      }
    } catch (error) {
    Logger.error(TAG, `Failed to toggle live channel collection: ${error}`);
    throw error;
  }
  }
  
  /**
   * 刷新直播源
   * @param liveChannel 直播频道
   * @returns 刷新后的直播频道
   */
  public async refreshLiveSource(liveChannel: Live): Promise<Live> {
    try {
      Logger.info(TAG, `Refreshing live source for: ${liveChannel.name}`);
      
      const refreshedUrl = await this.liveStreamRepository.refreshLiveStreamUrl(
        liveChannel.url,
        liveChannel.headers
      );
      
      const refreshedChannel = {
        ...liveChannel,
        url: refreshedUrl
      };
      
      // 更新本地缓存
      await this.liveRepository.updateLiveChannel(refreshedChannel);
      
      return refreshedChannel;
    } catch (error) {
    Logger.error(TAG, `Failed to refresh live source: ${error}`);
    throw error;
  }
  }
  
  /**
   * 检查URL是否需要解析
   * @param url 原始URL
   * @returns 是否需要解析
   */
  private needsUrlResolution(url: string): boolean {
    // 简单判断逻辑，可以根据实际需求扩展
    return !url.startsWith('http') || url.includes('placeholder') || url.includes('resolve');
  }
}