import { Stack, Flex, Grid, ScrollView, Image, Text, Button, Blank, LoadingProgress, ImageFit, Color, FlexAlign } from '@ohos.arkui';
import Router from '@ohos.router';
import Logger from '../common/util/Logger';
import homePageStyles from '../components/styles/HomePageStyles';

// 类型定义
export interface MediaItem {
  id: string;
  siteKey: string;
  title: string;
  cover: string;
  coverUrl?: string; // 添加coverUrl属性以兼容现有代码
  type?: string;
  score?: string;
  year?: string;
  status?: string;
  genres: string[];
  actors: string[];
  description?: string; // 添加description属性以兼容轮播图渲染
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

/**
 * 首页组件
 * 应用的主界面，展示推荐内容、分类、最近播放等
 */
@Component
struct HomePage {
  private readonly TAG: string = 'HomePage';
  
  // 状态管理
  @State isLoading: boolean = false;
  @State featuredMedia: MediaItem[] = [];
  @State errorMessage: string = '';
  @State sourceName: string = '加载视频源....'; // 默认值，后续从配置获取
  
  // 初始化页面
  aboutToAppear(): void {
    Logger.info(this.TAG, 'HomePage mounted');
    this.initializePage();
    
    // 初始化模拟数据
    this.initMockData();
  }
    
  // 清理资源
  aboutToDisappear(): void {
    Logger.info(this.TAG, 'HomePage unmounted');
  }
  
  /**
   * 初始化模拟数据
   */
  private initMockData(): void {
    // 模拟媒体数据
    this.featuredMedia = [
      {
        id: '1',
        siteKey: 'site1',
        title: '天地剑心',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=天地剑心',
        score: '7.5',
        year: '2025',
        genres: ['古装', '武侠'],
        actors: []
      },
      {
        id: '2',
        siteKey: 'site1',
        title: '毕正明的证明',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=毕正明的证明',
        score: '7.2',
        year: '2025',
        genres: ['剧情'],
        actors: []
      },
      {
        id: '3',
        siteKey: 'site1',
        title: '命悬一生',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=命悬一生',
        score: '7.6',
        year: '2025',
        genres: ['悬疑', '惊悚'],
        actors: []
      },
      {
        id: '4',
        siteKey: 'site1',
        title: '花漾少女杀人事件',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=花漾少女杀人事件',
        score: '7.4',
        year: '2025',
        genres: ['犯罪', '悬疑'],
        actors: []
      },
      {
        id: '5',
        siteKey: 'site1',
        title: '许我耀眼',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=许我耀眼',
        score: '6.5',
        year: '2025',
        genres: ['爱情'],
        actors: []
      },
      {
        id: '6',
        siteKey: 'site1',
        title: '笑傲江湖',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=笑傲江湖',
        score: '8.1',
        year: '2025',
        genres: ['古装', '武侠'],
        actors: []
      },
      {
        id: '7',
        siteKey: 'site1',
        title: '御龙在天',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=御龙在天',
        score: '7.8',
        year: '2025',
        genres: ['奇幻', '冒险'],
        actors: []
      },
      {
        id: '8',
        siteKey: 'site1',
        title: '星际穿越',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=星际穿越',
        score: '8.9',
        year: '2025',
        genres: ['科幻'],
        actors: []
      },
      {
        id: '9',
        siteKey: 'site1',
        title: '封神榜',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=封神榜',
        score: '8.2',
        year: '2025',
        genres: ['古装', '神话'],
        actors: []
      },
      {
        id: '10',
        siteKey: 'site1',
        title: '黑暗世界',
        cover: '',
        coverUrl: 'https://via.placeholder.com/300x450?text=黑暗世界',
        score: '7.9',
        year: '2025',
        genres: ['恐怖', '奇幻'],
        actors: []
      }
    ];
  }
  
  /**
   * 初始化页面
   */
  private initializePage(): void {
    try {
      this.isLoading = false;
      // 尝试从配置服务获取视频源名称
      // 由于我们没有实际的配置服务实现，暂时使用默认值
      // 如果有配置服务，可以取消下面的注释
      /*
      configService.getSourceName().then(name => {
        this.sourceName = name || this.sourceName;
      }).catch(err => {
        Logger.info(this.TAG, 'Failed to get source name: ' + err);
      });
      */
    } catch (error) {
      Logger.info(this.TAG, 'Failed to initialize page: ' + error);
      this.errorMessage = '页面初始化失败，请稍后重试';
    }
  }
  
  /**
   * 处理搜索
   */
  private handleSearch(): void {
    Logger.info(this.TAG, 'Search button clicked');
    // 跳转到搜索页面
    Router.pushUrl({
      url: 'pages/SearchPage'
    });
  }
  
  /**
   * 处理媒体项点击
   */
  private handleMediaItemClick(mediaItem: MediaItem): void {
    Logger.info(this.TAG, `Media item clicked: ${mediaItem.title}`);
    // 跳转到详情页
    Router.pushUrl({
      url: 'pages/MediaDetailPage',
      params: { mediaId: mediaItem.id, siteKey: mediaItem.siteKey }
    });
  }
  
  /**
   * 跳转到设置页面
   */
  private navigateToSettings(): void {
    Logger.info(this.TAG, 'Navigating to settings');
    Router.pushUrl({
      url: 'pages/SettingsPage'
    });
  }
  
  /**
   * 跳转到历史记录页面
   */
  private navigateToHistory(): void {
    Logger.info(this.TAG, 'Navigating to history');
    Router.pushUrl({
      url: 'pages/HistoryPage'
    });
  }
  

  
  /**
   * 渲染媒体卡片
   */
  @Builder
  private renderMediaCard(media: MediaItem) {
    Stack({
      onClick: () => this.handleMediaItemClick(media)
    }) {
      Image({
        src: media.coverUrl || "https://via.placeholder.com/300x450?text=No+Image",
        objectFit: ImageFit.Cover
      })
      .width('100%')
      .height('100%')
      
      Stack() {
        if (media.score) {
          Text(media.score)
            .fontSize(20vp)
            .fontWeight(700)
            .color(Color.White)
            .backgroundColor(Color.Red)
            .padding(5vp)
            .borderRadius(5vp)
            .position({ x: 10vp, y: 10vp })
        }
        Text(media.title)
          .fontSize(18vp)
          .fontWeight(700)
          .color(Color.White)
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .padding(10vp)
          .numberOfLines(2)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .aspectRatio(0.66)
    .padding(10vp)
  }
  

  
  /**
   * 渲染加载状态
   */
  @Builder
  private renderLoading() {
    Stack() {
      LoadingProgress()
        .width(50vp)
        .height(50vp)
        .color(Color.Green)
      Text("加载中...")
        .fontSize(24vp)
        .color(Color.Gray)
        .marginTop(20vp)
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(Alignment.Center)
    .width('100%')
    .height('100%')
  }
  
  /**
   * 渲染错误状态
   */
  @Builder
  private renderError() {
    Stack() {
      Text("⚠️")
        .fontSize(60vp)
      Text(this.errorMessage)
        .fontSize(24vp)
        .color(Color.Red)
        .marginTop(20vp)
      Button("重试")
        .fontSize(20vp)
        .backgroundColor(Color.Green)
        .fontColor(Color.White)
        .paddingHorizontal(30vp)
        .paddingVertical(10vp)
        .marginTop(20vp)
        .onClick(() => this.initializePage())
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(Alignment.Center)
    .width('100%')
    .height('100%')
  }
  
  /**
   * 获取当前时间
   */
  private getCurrentTime(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    return `${year}年${month}月${day}日 ${hours}:${minutes}:${seconds}`;
  }
  
  /**
   * 导航到直播页面
   */
  private navigateToLive(): void {
    Router.pushUrl({ url: 'pages/LivePage' });
  }
  
  /**
   * 导航到线路页面
   */
  private navigateToRoute(): void {
    Router.pushUrl({ url: 'pages/RoutePage' });
  }
  
  /**
   * 渲染内容部分
   */
  @Builder
  private renderContent() {
    ScrollView() {
      Column() {
        // 主要内容区域 - 使用网格展示媒体
        Grid({
          columnsTemplate: 'repeat(5, 1fr)',
          rowsTemplate: 'repeat(auto-fill, 1fr)',
          itemTemplate: this.renderMediaCard,
          data: this.featuredMedia
        })
        .onClick(() => {})
        
        Blank()
          .height(30)
      }
    }
    .scrollBar(ScrollBar.Auto)
  }
  
  /**
   * 组件渲染
   */
  build() {
    Stack() {
      // 顶部绿色导航栏
      Stack() {
        // 类型标题和时间
        Flex() {
          Text(this.sourceName)
            .fontSize(32vp)
            .fontWeight(700)
            .color(Color.White)
            .paddingLeft(20vp)
          
          Text(this.getCurrentTime())
            .fontSize(20vp)
            .color(Color.White)
            .paddingRight(20vp)
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('100%')
        .paddingBottom(10vp)
        
        // 分类导航
        Flex() {
          Button("首页")
          .backgroundColor(Color.White)
          .fontColor(Color.Green)
          .fontWeight(700)
          .fontSize(24vp)
          .paddingHorizontal(20vp)
          .paddingVertical(10vp)
          .borderRadius(15vp)
          .onClick(() => {})
          
          Button("电影")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=电影' }))
          
          Button("电视剧")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=电视剧' }))
          
          Button("综艺")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=综艺' }))
          
          Button("动漫")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=动漫' }))
          
          Button("日韩剧")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=日韩剧' }))
          
          Button("国产剧")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=国产剧' }))
          
          Button("欧美剧")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=欧美剧' }))
          
          Button("港台剧")
          .fontColor(Color.White)
          .fontSize(24)
          .paddingHorizontal(20)
          .paddingVertical(10)
          .borderRadius(15)
          .onClick(() => Router.pushUrl({ url: 'pages/CategoryPage?category=港台剧' }))
        }
        .wrap(true)
        .paddingHorizontal(10vp)
        .paddingBottom(10vp)
        
        // 功能按钮
        Flex() {
          Button("历史")
          .backgroundColor(Color.Green)
          .fontColor(Color.White)
          .fontSize(20vp)
          .paddingHorizontal(15vp)
          .paddingVertical(8vp)
          .borderRadius(10vp)
          .onClick(this.navigateToHistory)
          
          Button("直播")
          .backgroundColor(Color.Green)
          .fontColor(Color.White)
          .fontSize(20vp)
          .paddingHorizontal(15vp)
          .paddingVertical(8vp)
          .borderRadius(10vp)
          .onClick(this.navigateToLive)
          
          Button("搜索")
          .backgroundColor(Color.Green)
          .fontColor(Color.White)
          .fontSize(20vp)
          .paddingHorizontal(15vp)
          .paddingVertical(8vp)
          .borderRadius(10vp)
          .onClick(this.handleSearch)
          
          Button("线路")
          .backgroundColor(Color.Green)
          .fontColor(Color.White)
          .fontSize(20vp)
          .paddingHorizontal(15vp)
          .paddingVertical(8vp)
          .borderRadius(10vp)
          .onClick(this.navigateToRoute)
          
          Button("设置")
          .backgroundColor(Color.Green)
          .fontColor(Color.White)
          .fontSize(20vp)
          .paddingHorizontal(15vp)
          .paddingVertical(8vp)
          .borderRadius(10vp)
          .onClick(this.navigateToSettings)
        }
        .wrap(true)
        .paddingHorizontal(10vp)
      }
      .backgroundColor('#4CAF50')
      .height(160vp)
      .paddingTop(10vp)
      
      // 主内容区域
      if (this.isLoading) {
        this.renderLoading();
      } else if (this.errorMessage) {
        this.renderError();
      } else {
        this.renderContent();
      }
    }
    .backgroundColor('#F5F5F5')
    .width('100%')
    .height('100%')
  }
}

export default HomePage;