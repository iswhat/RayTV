import Button from '@ohos.widget.Button';
import Text from '@ohos.widget.Text';
import Image from '@ohos.widget.Image';
import List from '@ohos.widget.List';
import ListItem from '@ohos.widget.ListItem';
import Row from '@ohos.widget.Row';
import Column from '@ohos.widget.Column';
import Flex from '@ohos.widget.Flex';
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import { FlexDirection, ItemAlign, FlexAlign, TextAlign, ImageFit, FontWeight } from '@kit.ArkUI';

/**
 * 应用主页面
 * 作为应用的入口页面，显示主要功能区域
 */
interface FeaturedMediaItem {
  id: string;
  title: string;
  cover: string;
  type: string;
}

@Entry
@Component
struct MainPage {
  private readonly TAG: string = 'MainPage';
  private scroller: Scroller = new Scroller();
  
  // 状态管理
  @State featuredMedia: FeaturedMediaItem[] = [];
  @State isLoading: boolean = true;
  
  // 生命周期
  aboutToAppear() {
    this.loadFeaturedContent();
  }
  
  // 加载推荐内容
  private loadFeaturedContent() {
    Logger.info(`${this.TAG}: Loading featured content`);
    
    // 模拟加载推荐内容
    setTimeout(() => {
      this.featuredMedia = [
        {
          id: '1',
          title: '热门电影推荐',
          cover: 'https://example.com/cover1.jpg',
          type: 'movie'
        },
        {
          id: '2',
          title: '最新剧集更新',
          cover: 'https://example.com/cover2.jpg',
          type: 'series'
        },
        {
          id: '3',
          title: '精选纪录片',
          cover: 'https://example.com/cover3.jpg',
          type: 'documentary'
        }
      ];
      this.isLoading = false;
    }, 1000);
  }
  
  // 跳转到分类页面
  private navigateToCategory() {
    Router.pushUrl({ url: 'pages/CategoryPage' });
  }
  
  // 跳转到搜索页面
  private navigateToSearch() {
    Router.pushUrl({ url: 'pages/SearchPage' });
  }
  
  // 跳转到设置页面
  private navigateToSettings() {
    Router.pushUrl({ url: 'pages/SettingsPage' });
  }
  
  // 渲染媒体项
  @Builder
  renderMediaItem(media: unknown) {
    ListItem() {
      Column({ padding: 10 }) {
        Image(media.cover)
          .width(150)
          .height(200)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
        Text(media.title)
          .fontSize(14)
          .maxLines(2)
          .marginTop(8)
      }
    }
    .onClick(() => Router.pushUrl({ url: `pages/MediaDetailPage?id=${media.id}` }))
  }
  
  build() {
    Flex({
      direction: FlexDirection.Column,
      padding: 20
    }) {
      // 标题栏
      Row({
        justifyContent: FlexAlign.SpaceBetween,
        alignItems: ItemAlign.Center,
        marginBottom: 20
      }) {
        Text("RayTV")
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
        Row() {
          Button("搜索")
            .onClick(() => this.navigateToSearch())
            .marginRight(10)
          Button("设置")
            .onClick(() => this.navigateToSettings())
        }
      }
      
      // 分类入口
      Button("浏览分类")
        .onClick(() => this.navigateToCategory())
        .backgroundColor("#007AFF")
        .fontColor("white")
        .width("100%")
        .padding(12)
        .fontSize(16)
        .marginBottom(20)
      
      // 推荐内容
      Text("推荐内容")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .marginBottom(15)
      
      if (this.isLoading) {
        Text("加载中...")
      } else {
        List() {
          ForEach(this.featuredMedia, (item) => {
            this.renderMediaItem(item)
          }, item => item.id)
        }
        .scroller(this.scroller)
        .orientation("horizontal")
        .height(250)
      }
      
      // 底部提示
      Text("请确保已配置视频源以获得最佳体验")
        .fontSize(12)
        .fontColor("#888888")
        .marginTop(20)
        .textAlign(TextAlign.Center)
    }
  }
}