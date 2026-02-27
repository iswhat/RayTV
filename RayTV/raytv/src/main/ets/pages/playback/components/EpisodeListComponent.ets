import { Component, FlexAlign, FlexDirection, FlexWrap, ScrollDirection, Text, Row, Column, Button, Scroll, BarState, VerticalAlign, Scroller } from '@ohos/arkui';
import { Episode } from '../types/PlaybackTypes';
import Logger from '../../../common/util/Logger';

interface EpisodeListComponentProps {
  episodes: Episode[];
  isLandscape: boolean;
  onEpisodeSelect: (episode: Episode) => void;
  onOtherLineSearch: () => void;
}

/**
 * 剧集列表组件 | Episode list component
 * 展示剧集列表和其他线路搜索功能
 */
@Component
export struct EpisodeListComponent {
  private readonly TAG: string = 'EpisodeListComponent';
  private episodeScroller: Scroller = new Scroller();
  
  props: EpisodeListComponentProps;
  
  build() {
    if (this.props.episodes.length > 0) {
      Column() {
        Row() {
          Text('剧集列表')
            .fontSize(20)
            .fontWeight(700)
            .fontColor('#333333')
            .margin({ left: this.props.isLandscape ? 40 : 30 })
          
          Button() {
            Text('其他线路搜索')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(500)
          }
          .width(150)
          .height(50)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .margin({ right: this.props.isLandscape ? 40 : 30 })
          .onClick(() => this.props.onOtherLineSearch())
          .focusable(true)
          .onFocus(() => {
            Logger.info(this.TAG, 'Other lines button focused');
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 20 })
        
        Scroll(this.episodeScroller) {
          Row() {
            ForEach(this.props.episodes, (episode: Episode) => {
              Button() {
                Text(`第${episode.episode}集`)
                  .fontSize(14)
                  .fontColor(episode.current ? '#FFFFFF' : episode.played ? '#4CAF50' : '#333333')
                  .fontWeight(episode.current ? 600 : 400)
              }
              .width(90)
              .height(45)
              .backgroundColor(episode.current ? '#4CAF50' : episode.played ? '#E8F5E9' : '#F5F5F5')
              .borderRadius(8)
              .margin({ left: this.props.isLandscape ? 40 : 30, right: 12, bottom: 15 })
              .onClick(() => this.props.onEpisodeSelect(episode))
              .focusable(true)
              .onFocus(() => {
                Logger.info(this.TAG, `Episode ${episode.episode} focused`);
              })
            })
          }
          .width('100%')
          .padding({ bottom: 40 })
          .flexWrap(FlexWrap.Wrap)
        }
        .scrollBar(BarState.Auto)
        .flexGrow(1)
      }
      .width('100%')
      .padding({ top: 25 })
      .backgroundColor('#F5F5F5')
    }
  }
}
