import { Component, FlexAlign, FlexDirection, FlexWrap, ScrollDirection, Text, Row, Column, Image, Button, Scroll, BarState, VerticalAlign, Scroller, ImageFit } from '@ohos/arkui';
import { MediaInfo as MediaInfoType, ParseLine } from '../types/PlaybackTypes';
import Logger from '../../../common/util/Logger';

interface MediaInfoComponentProps {
  mediaInfo: MediaInfoType | null;
  parseLines: ParseLine[];
  isLandscape: boolean;
  onLineSelect: (line: ParseLine) => void;
  focusStyle: any;
}

/**
 * 媒体信息组件 | Media info component
 * 展示媒体基本信息和解析线路选择
 */
@Component
export struct MediaInfoComponent {
  private readonly TAG: string = 'MediaInfoComponent';
  private scroller: Scroller = new Scroller();
  
  props: MediaInfoComponentProps;
  
  build() {
    if (this.props.mediaInfo) {
      Column() {
        Row() {
          // 封面 | Cover
          Image(this.props.mediaInfo.cover || 'https://via.placeholder.com/200x300?text=No+Image')
            .width(this.props.isLandscape ? 200 : 150)
            .height(this.props.isLandscape ? 300 : 200)
            .objectFit(ImageFit.Cover)
            .borderRadius(12)
            .backgroundColor('#F5F5F5')
            .margin({ left: this.props.isLandscape ? 40 : 30, right: 25 })
          
          // 信息 | Info
          Column() {
            Text(this.props.mediaInfo.title)
              .fontSize(this.props.isLandscape ? 28 : 24)
              .fontWeight(700)
              .fontColor('#333333')
              .margin({ bottom: 15 })
            
            Text(this.props.mediaInfo.description || '暂无简介')
              .fontSize(16)
              .fontColor('#666666')
              .maxLines(this.props.isLandscape ? 4 : 3)
              .margin({ bottom: 15 })
            
            Row() {
              Text(`类型: ${this.props.mediaInfo.type || '未知'}`)
                .fontSize(16)
                .fontColor('#666666')
                .margin({ right: 25 })
              Text(`评分: ${this.props.mediaInfo.rating || '暂无'}`)
                .fontSize(16)
                .fontColor('#FF9800')
                .fontWeight(500)
            }
            
            // 解析线路选择 | Parse line selection
            Row() {
              Text('解析线路:')
                .fontSize(18)
                .fontColor('#333333')
                .fontWeight(500)
                .margin({ right: 15, top: 20 })
              
              Scroll(this.scroller) {
                Row() {
                  ForEach(this.props.parseLines, (line: ParseLine) => {
                    Button() {
                      Text(line.name)
                        .fontSize(14)
                        .fontColor(line.selected ? '#FFFFFF' : '#333333')
                        .fontWeight(line.selected ? 600 : 400)
                    }
                    .padding({ left: 20, right: 20, top: 10, bottom: 10 })
                    .backgroundColor(line.selected ? '#4CAF50' : '#F5F5F5')
                    .borderRadius(20)
                    .margin({ right: 12, top: 20 })
                    .onClick(() => this.props.onLineSelect(line))
                    .focusable(true)
                    .onFocus(() => {
                      Logger.info(this.TAG, `Parse line focused: ${line.name}`);
                    })
                  })
                }
                .width('100%')
                .flexWrap(FlexWrap.Wrap)
              }
              .scrollDirection(ScrollDirection.Horizontal)
              .scrollBar(BarState.Auto)
              .flexGrow(1)
            }
          }
          .flexGrow(1)
          .margin({ right: this.props.isLandscape ? 40 : 30 })
        }
        .width('100%')
        .padding({ top: 25, bottom: 25 })
        .backgroundColor('#FFFFFF')
      }
    }
  }
}
