import { AppNavigator } from '../navigation/AppNavigator';
import Logger from '../common/util/Logger';

// 类型定义
export interface MediaItem {
  id: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  type?: string;
  score?: string;
  year?: string;
  status?: string;
}

export interface MediaDetail {
  id: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  description?: string;
  score?: string;
  year?: string;
  type?: string;
  status?: string;
  episodes?: Episode[];
  directors?: string[];
  actors?: string[];
  genres?: string[];
  regions?: string[];
}

export interface Episode {
  id: string;
  name: string;
  season?: number;
  episode?: number;
}

export interface PlaySource {
  id?: string;
  name?: string;
  quality?: string;
  url?: string;
  description?: string;
}

export interface FavoriteItem {
  id: string;
  mediaId: string;
  siteKey: string;
  title: string;
  coverUrl: string;
  type?: string;
  favoriteTime: number;
}

export interface HistoryItem {
  id: string;
  mediaId: string;
  siteKey: string;
  episodeId: string;
  title: string;
  coverUrl: string;
  episodeName: string;
  currentTime: number;
  duration: number;
  lastPlayTime: number;
}

export interface WatchHistory {
  mediaId: string;
  episodeId: string;
  position: number;
  lastWatchTime: number;
}

/**
 * 媒体详情页组件
 * 显示媒体详细信息、剧集列表和播放源
 */
@Entry
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';

  // 路由参数
  private mediaId: string = '';
  private siteKey: string = '';

  // 状态管理
  @State mediaDetail: MediaDetail | null = null;
  @State episodes: Episode[] = [];
  @State playSources: PlaySource[] = [];
  @State filteredSources: PlaySource[] = [];
  @State relatedMedia: MediaItem[] = [];
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State activeTab: string = 'episodes';

  /**
   * 返回上一页
   */
  private handleBack(): void {
    // 实现返回逻辑
  }

  /**
   * 显示内容简介
   */
  private showContentIntro(): void {
    // 实现显示内容简介逻辑
  }

  /**
   * 处理剧集点击
   */
  private handleEpisodeClick(episode: Episode): void {
    // 实现处理剧集点击逻辑
  }

  /**
   * 处理播放点击
   */
  private handlePlayClick(episode: Episode, source: PlaySource): void {
    // 实现处理播放点击逻辑
  }

  /**
   * 切换线路
   */
  private switchLine(lineId: string): void {
    // 实现切换线路逻辑
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button()
          .backgroundColor('transparent')
          .onClick(() => this.handleBack())
        {
          Text("返回")
            .fontSize(24)
            .fontColor('#FFFFFF')
        }

        Text("详情")
          .fontSize(26)
          .fontColor('#FFFFFF')
          .fontWeight(700)

        Blank()
          .width(80)
      }
      .backgroundColor('#388E3C')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 20, right: 20 })
      .padding({ top: 15, bottom: 15 })
      .width('100%')

      // 内容区域
      if (this.isLoading) {
        // 加载状态
        Column() {
          Text("加载中...")
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .flexGrow(1)
      } else if (this.errorMessage) {
        // 错误状态
        Column() {
          Text(this.errorMessage)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .flexGrow(1)
      } else {
        Scroll() {
          Column() {
            // 添加顶部间距，防止被导航栏遮挡
            Column() {
              Blank()
                .height(60)
            }

            // 媒体顶部信息
            if (this.mediaDetail) {
              this.renderHeader();
            }

            // 标签页切换栏
            this.renderTabBar();

            // 内容区域
            Column() {
              if (this.activeTab === 'episodes') {
                this.renderEpisodes();
              } else {
                this.renderPlaySources();
              }
            }
            .padding({ left: 20, right: 20, top: 20, bottom: 20 })

            // 相关推荐
            if (this.relatedMedia?.length > 0) {
              this.renderRelatedMedia();
            }
          }
        }
        .flexGrow(1)
        .backgroundColor('#4CAF50')
      }
    }
    .flexGrow(1)
    .backgroundColor('#4CAF50')
  }

  /**
   * 渲染媒体顶部信息
   */
  @Builder
  private renderHeader() {
    Column() {
      // 封面图和标题信息
      Row() {
        // 封面图
        Image(this.mediaDetail.coverUrl)
          .width(200)
          .height(280)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .margin({ right: 20 })
        
        // 标题信息
        Column() {
          Text(this.mediaDetail.title)
            .fontSize(24)
            .fontColor('#FFFFFF')
            .fontWeight(700)
            .margin({ bottom: 10 })
          
          // 来源信息
          Text(`来源: ${this.mediaDetail.siteKey}`)
            .fontSize(16)
            .fontColor('#FFFFFF')
            .margin({ bottom: 10 })
          
          // 年份信息
          if (this.mediaDetail.year) {
            Text(`年份: ${this.mediaDetail.year}`)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .margin({ bottom: 10 })
          }
          
          // 导演和演员信息
          if (this.mediaDetail.directors && this.mediaDetail.directors.length > 0) {
            Text(`导演: ${this.mediaDetail.directors.join('、')}`)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .margin({ bottom: 5 })
          }
          
          if (this.mediaDetail.actors && this.mediaDetail.actors.length > 0) {
            Text(`演员: ${this.mediaDetail.actors.slice(0, 5).join('、')}${this.mediaDetail.actors.length > 5 ? '...' : ''}`)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .margin({ bottom: 15 })
          }
          
          // 播放地址
          Text(`播放地址: ${this.mediaDetail.siteKey}_${this.mediaDetail.id}`)
            .fontSize(14)
            .fontColor('#FFFFFF')
            .margin({ bottom: 15 })
          
          // 内容简介按钮
            Button('内容简介')
              .backgroundColor('#2196F3')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .padding({ left: 16, right: 16, top: 8, bottom: 8 })
              .fontSize(14)
              .onClick(() => {
                this.showContentIntro();
              })
        }
        .flexGrow(1)
      }
      .padding({ left: 20, right: 20, top: 15 })
      
      // 功能按钮
      Row() {
        Button('快速搜索')
          .backgroundColor('#FF9800')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .fontSize(16)
          .margin({ right: 10 })
          
        Button('倒序')
          .backgroundColor('#9C27B0')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .fontSize(16)
          .margin({ right: 10 })
          
        Button('加入收藏')
          .backgroundColor('#4CAF50')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .fontSize(16)
          .margin({ right: 10 })
          
        Button('内容简介')
          .backgroundColor('#2196F3')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .fontSize(16)
      }
      .padding({ left: 20, right: 20, top: 20 })
      
      // 线路切换
      Row() {
        Text('线路二(点击换线)')
          .backgroundColor('#66BB6A')
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(8)
          .margin({ right: 10 })
          .fontSize(16)
          .onClick(() => {
            this.switchLine('line2');
          })
          
        Text('线路四(点击换线)')
          .backgroundColor('#66BB6A')
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(8)
          .margin({ right: 10 })
          .fontSize(16)
          .onClick(() => {
            this.switchLine('line4');
          })
          
        Text('线路三(点击换线)')
          .backgroundColor('#66BB6A')
          .fontColor('#FFFFFF')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
          .borderRadius(8)
          .fontSize(16)
          .onClick(() => {
            this.switchLine('line3');
          })
      }
      .padding({ left: 20, right: 20, top: 15, bottom: 15 })
    }
  }

  /**
   * 渲染标签页切换栏
   */
  @Builder
  private renderTabBar(): void {
    Row() {
      Button('剧集列表')
        .backgroundColor(this.activeTab === 'episodes' ? '#66BB6A' : '#4CAF50')
        .fontColor('#FFFFFF')
        .padding({ left: 24, right: 24, top: 12, bottom: 12 })
        .borderRadius(0)
        .fontSize(18)
        .onClick(() => {
          this.activeTab = 'episodes';
        })
      
      Button('播放源')
        .backgroundColor(this.activeTab === 'sources' ? '#66BB6A' : '#4CAF50')
        .fontColor('#FFFFFF')
        .padding({ left: 24, right: 24, top: 12, bottom: 12 })
        .borderRadius(0)
        .fontSize(18)
        .onClick(() => {
          this.activeTab = 'sources';
        })
    }
  }

  /**
   * 渲染剧集列表
   */
  @Builder
  private renderEpisodes() {
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
        })
      })
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr 1fr')
    .columnsGap(10)
    .rowsGap(10)
    .width('100%')
    .height('auto')
  }

  /**
   * 渲染播放源
   */
  @Builder
  private renderPlaySources() {
    if (this.filteredSources?.length === 0) {
      Column() {
        Text("暂无播放源或没有匹配的片源")
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding(20)
    } else {
      Column() {
        ForEach(this.filteredSources, (source: PlaySource) => {
          Button() {
            Row() {
              Column() {
                Text(source.name || "")
                  .fontSize(20)
                  .fontColor('#FFFFFF')
                Text(source.quality || "")
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
              .alignItems(HorizontalAlign.Start)

              Text("播")
                .fontSize(24)
                .fontColor('#FFFFFF')
            }
            .justifyContent(FlexAlign.SpaceBetween)
            .alignItems(VerticalAlign.Center)
            .width('100%')
          }
          .backgroundColor('#66BB6A')
          .padding(15)
          .borderRadius(10)
          .onClick(() => this.handlePlayClick(this.episodes[0] || { id: '', name: '' }, source))
        })
      }

    }
  }

  /**
   * 渲染相关推荐
   */
  @Builder
  private renderRelatedMedia() {
    Column() {
      Text("相关推荐")
        .fontSize(22)
        .fontColor('#FFFFFF')
        .fontWeight(600)
        .margin({ bottom: 15 })
      
      // 横向滚动的相关推荐列表
      Scroll() {
        Row() {
          ForEach(this.relatedMedia, (media: MediaItem) => {
            Column() {
              // 相关推荐封面
              Column() {
                Text("封面")
                  .fontSize(16)
                  .fontColor('#666666')
              }
              .width(150)
              .height(200)
              .backgroundColor('#E0E0E0')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              
              // 相关推荐标题
              Text(media.title || "")
                .fontSize(16)
                .fontColor('#FFFFFF')
                .maxLines(2)
                .width(150)
            }
            .width(150)
            .margin({ right: 15 })
            .onClick(() => this.handleRelatedMediaClick(media))
          })
        }
      }
      .scrollable(ScrollDirection.Horizontal)
    }
  }

  /**
   * 处理返回按钮点击
   */
  private handleBack(): void {
    // 这里应该实现返回按钮的点击逻辑
  }

  /**
   * 处理播放点击
   */
  private handlePlayClick(episode: Episode, source: PlaySource): void {
    // 实现播放点击的逻辑
    Logger.info(this.TAG, `Playing episode ${episode.name} with source ${source.name}`);
  }

  /**
   * 处理相关媒体点击
   */
  private handleRelatedMediaClick(media: MediaItem): void {
    // 实现相关媒体点击的逻辑
    Logger.info(this.TAG, `Clicked related media: ${media.title}`);
  }
  
  /**
   * 处理返回按钮点击
   */
  private handleBack(): void {
    AppNavigator.getInstance().navigateBack();
  }
  
  /**
   * 显示内容简介
   */
  private showContentIntro(): void {
    if (!this.mediaDetail?.description) {
      Logger.info(this.TAG, 'No description available');
      return;
    }
    Logger.info(this.TAG, `Showing content intro: ${this.mediaDetail.description}`);
  }
  
  /**
   * 切换线路
   */
  private switchLine(lineId: string): void {
    Logger.info(this.TAG, `Switching to line: ${lineId}`);
  }
  
  /**
   * 处理剧集点击
   */
  private handleEpisodeClick(episode: Episode): void {
    Logger.info(this.TAG, `Clicked episode: ${episode.name}`);
  }
}