// MediaDetailPage.ets
// 媒体详情页面组件

import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';
import { Vod } from '../data/bean/Vod';

// 播放源接口
export interface PlaySource {
  name: string;
  quality?: string;
}

// 剧集接口
export interface Episode {
  id: string;
  name: string;
  url: string;
}

// 相关媒体项接口
export interface MediaItem {
  title: string;
  cover: string;
  url: string;
}

@Entry
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';
  @State media: Vod = {
    id: '',
    name: '',
    type: '',
    area: '',
    lang: '',
    year: '',
    score: '0',
    status: '',
    desc: '',
    cover: '',
    tag: '',
    url: '',
    sourceKey: '',
    createdAt: Date.now(),
    updatedAt: Date.now()
  };
  @State episodes: Episode[] = [];
  @State filteredSources: PlaySource[] = [];
  @State relatedMedia: MediaItem[] = [];
  @State activeTab: string = 'info';

  aboutToAppear() {
    // 模拟加载媒体详情
    this.loadMediaDetail();
    this.loadEpisodes();
    this.loadSources();
    this.loadRelatedMedia();
  }

  /**
   * 加载媒体详情
   */
  private loadMediaDetail(): void {
    // 模拟加载媒体详情数据
    this.media = {
      id: '1',
      name: '示例影片',
      type: '电影',
      area: '中国',
      lang: '普通话',
      year: '2023',
      score: '8.5',
      status: '已完结',
      desc: '这是一部示例影片，用于展示媒体详情页面。',
      cover: '',
      tag: '动作,剧情',
      url: '',
      sourceKey: 'test',
      createdAt: Date.now(),
      updatedAt: Date.now()
    };
  }

  /**
   * 加载剧集列表
   */
  private loadEpisodes(): void {
    // 模拟加载剧集数据
    this.episodes = [
      { id: '1', name: '第1集', url: '' },
      { id: '2', name: '第2集', url: '' },
      { id: '3', name: '第3集', url: '' }
    ];
  }

  /**
   * 加载播放源
   */
  private loadSources(): void {
    // 模拟加载播放源数据
    this.filteredSources = [
      { name: '播放源1', quality: '1080P' },
      { name: '播放源2', quality: '720P' }
    ];
  }

  /**
   * 加载相关推荐
   */
  private loadRelatedMedia(): void {
    // 模拟加载相关推荐数据
    this.relatedMedia = [
      { title: '相关影片1', cover: '', url: '' },
      { title: '相关影片2', cover: '', url: '' },
      { title: '相关影片3', cover: '', url: '' }
    ];
  }

  /**
   * 渲染剧集列表
   */
  @Builder
  private renderEpisodes(): void {
    // 剧集网格布局
    Grid() {
      ForEach(this.episodes, (episode: Episode, index: number) => {
        GridItem() {
          Button(episode.name || `${index + 1}`)
            .backgroundColor('#66BB6A')
            .fontColor('#FFFFFF')
            .padding(15)
            .borderRadius(8)
            .fontSize(16)
            .onClick(() => {
              this.handleEpisodeClick(episode);
            })
        }
      });
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
    .width('100%')
    .height('auto');
  }

  /**
   * 渲染播放源
   */
  @Builder
  private renderPlaySources(): void {
    if (this.filteredSources?.length === 0) {
      Column() {
        Text("暂无播放源或没有匹配的片源")
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(20);
    } else {
        Column() {
          ForEach(this.filteredSources, (source: PlaySource) => {
            Button() {
              Row() {
                Column() {
                  Text(source.name || "")
                    .fontSize(20)
                    .fontColor('#FFFFFF');
                  Text(source.quality || "")
                    .fontSize(16)
                    .fontColor('#FFFFFF');
                }
                .alignItems(HorizontalAlign.Start);

                Text("播")
                  .fontSize(24)
                  .fontColor('#FFFFFF');
              }
              .justifyContent(FlexAlign.SpaceBetween)
              .alignItems(VerticalAlign.Center)
              .width('100%');
            }
            .backgroundColor('#66BB6A')
            .padding(15)
            .borderRadius(10)
            .onClick(() => this.handlePlayClick(this.episodes[0] || { id: '', name: '', url: '' }, source));
          });
        }
      }
  }

  /**
   * 渲染相关推荐
   */
  @Builder
  private renderRelatedMedia(): void {
    Column() {
      Text("相关推荐")
        .fontSize(22)
        .fontColor('#FFFFFF')
        .fontWeight(600)
        .margin({ bottom: 15 });
      
      // 横向滚动的相关推荐列表
      Scroll() {
        Row() {
          ForEach(this.relatedMedia, (media: MediaItem) => {
            Column() {
              // 相关推荐封面
              Column() {
                Text("封面")
                  .fontSize(16)
                  .fontColor('#666666');
              }
              .width(150)
              .height(200)
              .backgroundColor('#E0E0E0')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center);
              
              // 相关推荐标题
              Text(media.title || "")
                .fontSize(16)
                .fontColor('#FFFFFF')
                .maxLines(2)
                .width(150);
            }
            .width(150)
            .margin({ right: 15 })
            .onClick(() => this.handleRelatedMediaClick(media));
          });
        }
      }
      .scrollable(ScrollDirection.Horizontal);
    }
  }

  /**
   * 处理剧集点击
   */
  private handleEpisodeClick(episode: Episode): void {
    Logger.info(this.TAG, `Clicked episode: ${episode.name}`);
    // 处理剧集点击逻辑
  }

  /**
   * 处理播放点击
   */
  private handlePlayClick(episode: Episode, source: PlaySource): void {
    Logger.info(this.TAG, `Playing episode ${episode.name} from ${source.name}`);
    // 处理播放点击逻辑
  }

  /**
   * 处理相关媒体点击
   */
  private handleRelatedMediaClick(media: MediaItem): void {
    Logger.info(this.TAG, `Clicked related media: ${media.title}`);
    // 处理相关媒体点击逻辑
  }

  build() {
    Column() {
      // 页面标题
      Text(this.media.name || "")
        .fontSize(24)
        .fontColor('#FFFFFF')
        .fontWeight(600)
        .margin({ top: 20, bottom: 20 });
      
      // 标签栏
      Row() {
        Button() {
          Text('剧集')
            .fontSize(18)
            .fontColor(this.activeTab === 'episodes' ? '#FFFFFF' : '#666666');
        }
        .backgroundColor(this.activeTab === 'episodes' ? '#4CAF50' : 'transparent')
        .onClick(() => {
          this.activeTab = 'episodes';
        });
        
        Button() {
          Text('播放源')
            .fontSize(18)
            .fontColor(this.activeTab === 'sources' ? '#FFFFFF' : '#666666');
        }
        .backgroundColor(this.activeTab === 'sources' ? '#4CAF50' : 'transparent')
        .onClick(() => {
          this.activeTab = 'sources';
        });
      }
      .margin({ bottom: 20 });
      
      // 内容区域
      Column() {
        if (this.activeTab === 'episodes') {
          this.renderEpisodes();
        } else if (this.activeTab === 'sources') {
          this.renderPlaySources();
        }
        
        // 相关推荐
        this.renderRelatedMedia();
      }
    }
    .backgroundColor('#121212')
    .padding(20)
    .width('100%')
    .height('100%');
  }
}