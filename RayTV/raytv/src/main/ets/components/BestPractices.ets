/*
 * ArkTS组件最佳实践示�? * 提供标准化的组件使用模板
 */

import { ListItem, Text, Button, ProgressBar, Flex, Image } from '@kit.ArkUI';
import { MediaItem, HistoryItem } from '../model/DataModel';

/**
 * ListItem组件最佳实践示�? */
@Component
export struct ListItemBestPractice {
  @Prop item: MediaItem;
  @Prop onItemClick: (item: MediaItem) => void;

  build() {
    ListItem()
      .onClick(() => {
        this.onItemClick(this.item);
      })
    {
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        // 左侧图标
        Image(this.item.cover || $r('app.media.default_cover'))
          .width(48)
          .height(48)
          .borderRadius(8)
          .objectFit(ImageFit.Cover)

        // 主要内容区域
        Flex({ direction: FlexDirection.Column, justifyContent: FlexAlign.Center }) {
          Text(this.item.title || '未知标题')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(this.item.subtitle || '')
            .fontSize(14)
            .fontColor(Color.Gray)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1)
        .margin({ left: 12 })

        // 右侧操作区域
        Button('播放')
          .fontSize(12)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      }
      .padding(12)
      .width('100%')
    }
  }
}

/**
 * ProgressBar组件最佳实践示�? */
@Component
export struct ProgressBarBestPractice {
  @Prop currentTime: number = 0;
  @Prop duration: number = 0;
  @Prop showLabel: boolean = true;

  private getProgressPercent(): number {
    // 零除保护
    return this.duration > 0 ? (this.currentTime / this.duration) * 100 : 0;
  }

  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      if (this.showLabel) {
        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
          Text(this.formatTime(this.currentTime))
            .fontSize(12)
            .fontColor(Color.Gray)

          Text(this.formatTime(this.duration))
            .fontSize(12)
            .fontColor(Color.Gray)
        }
        .width('100%')
        .margin({ bottom: 4 })
      }

      ProgressBar({
        value: this.currentTime,
        total: this.duration
      })
        .strokeWidth(4)
        .color('#FF4500')
        .width('100%')
    }
    .width('100%')
  }
}

/**
 * 媒体卡片组件最佳实�? */
@Component
export struct MediaCardBestPractice {
  @Prop mediaItem: MediaItem;
  @Prop onPlay: (item: MediaItem) => void;
  @Prop onFavorite: (item: MediaItem) => void;

  build() {
    Column() {
      // 封面图片
      Image(this.mediaItem.cover || $r('app.media.default_cover'))
        .width('100%')
        .aspectRatio(16/9)
        .objectFit(ImageFit.Cover)
        .borderRadius(8)

      // 内容信息
      Column() {
        Text(this.mediaItem.title || '未知标题')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 4 })

        Text(this.mediaItem.description || '')
          .fontSize(12)
          .fontColor(Color.Gray)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 操作按钮
        Flex({ justifyContent: FlexAlign.SpaceBetween }) {
          Button('播放')
            .fontSize(12)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .onClick(() => {
              this.onPlay(this.mediaItem);
            })

          Button(this.mediaItem.isFavorite ? '取消收藏' : '收藏')
            .fontSize(12)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .backgroundColor(this.mediaItem.isFavorite ? '#FF6B6B' : '#F0F0F0')
            .onClick(() => {
              this.onFavorite(this.mediaItem);
            })
        }
        .margin({ top: 8 })
      }
      .padding(8)
      .width('100%')
    }
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 2 })
    .width('100%')
    .onClick(() => {
      this.onPlay(this.mediaItem);
    })
  }
}

/**
 * 加载状态组件最佳实�? */
@Component
export struct LoadingBestPractice {
  @Prop message: string = '加载�?..';
  @Prop size: number = 32;

  build() {
    Column() {
      ProgressBar()
        .strokeWidth(4)
        .color('#007AFF')
        .width(this.size)
        .height(this.size)

      Text(this.message)
        .fontSize(14)
        .fontColor(Color.Gray)
        .margin({ top: 12 })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height(120)
  }
}

/**
 * 空状态组件最佳实�? */
@Component
export struct EmptyStateBestPractice {
  @Prop title: string = '暂无数据';
  @Prop description: string = '当前没有可显示的内容';
  @Prop actionText: string = '刷新';
  @Prop onAction: () => void;

  build() {
    Column() {
      Image($r('app.media.empty_state'))
        .width(120)
        .height(120)
        .margin({ bottom: 16 })

      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 8 })

      Text(this.description)
        .fontSize(14)
        .fontColor(Color.Gray)
        .textAlign(TextAlign.Center)
        .margin({ bottom: 20 })

      if (this.onAction) {
        Button(this.actionText)
          .fontSize(14)
          .padding({ left: 24, right: 24, top: 8, bottom: 8 })
          .onClick(() => {
            this.onAction();
          })
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .height(300)
  }
}
