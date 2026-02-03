/**
 * EpisodeList.ets - 剧集列表组件
 * 处理剧集列表相关的功能
 */

import Logger from '../../common/util/Logger';
import { FlexAlign, FlexDirection, TextAlign, ScrollDirection } from '@ohos/arkui';

// 剧集信息接口 | Episode info interface
export interface Episode {
  id: string;
  title: string;
  episode: number;
  duration?: string;
  played?: boolean;
  current?: boolean;
}

// 剧集列表组件参数 | Episode list component parameters
interface EpisodeListParams {
  episodes: Episode[];
  selectedEpisode: Episode | null;
  showEpisodeList: boolean;
  onEpisodeSelect: (episode: Episode) => void;
}

@Component
export struct EpisodeList {
  private readonly TAG: string = 'EpisodeList';
  private scroller: Scroller = new Scroller();
  
  // 参数 | Parameters
  @Prop episodes: Episode[];
  @Prop selectedEpisode: Episode | null;
  @Prop showEpisodeList: boolean;
  
  // 回调函数 | Callback functions
  private onEpisodeSelect: (episode: Episode) => void;
  
  // 构造函数 | Constructor
  constructor(params: EpisodeListParams) {
    this.episodes = params.episodes;
    this.selectedEpisode = params.selectedEpisode;
    this.showEpisodeList = params.showEpisodeList;
    this.onEpisodeSelect = params.onEpisodeSelect;
  }
  
  build() {
    if (this.showEpisodeList && this.episodes.length > 0) {
      Column() {
        Text('选集')
          .fontSize(18)
          .fontColor('#333333')
          .fontWeight(600)
          .margin({ bottom: 15, left: 30, top: 20 })
        
        Scroll(this.scroller) {
          Column() {
            Row() {
              ForEach(this.episodes, (episode: Episode) => {
                Button() {
                  Text(episode.title)
                    .fontSize(14)
                    .fontColor(episode.current ? '#FFFFFF' : '#666666')
                    .fontWeight(episode.current ? 600 : 400)
                    .textAlign(TextAlign.Center)
                }
                .width(120)
                .height(45)
                .backgroundColor(episode.current ? '#4CAF50' : '#F5F5F5')
                .borderRadius(8)
                .margin({ right: 10, bottom: 10 })
                .onClick(() => this.onEpisodeSelect(episode))
                .focusable(true)
                .onFocus(() => {
                  Logger.info(this.TAG, `Episode ${episode.title} focused`);
                })
              })
            }
            .width('100%')
            .padding({ left: 30, right: 30 })
            .flexDirection(FlexDirection.Row)
            .flexWrap(FlexWrap.Wrap)
          }
          .width('100%')
        }
        .width('100%')
        .height(200)
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
      }
      .width('100%')
    }
  }
}
