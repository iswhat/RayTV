// HomePage.ets - 主页面组件
import VideoCard from '../view/VideoCard';
import CategoryNavigation from '../view/CategoryNavigation';
import { VideoType } from '../../data/model/Movie';
import { PlaybackStatus } from '../../service/player/PlayerService';
import PlayerController from '../view/PlayerController';

interface MovieData {
  id: string;
  title: string;
  coverUrl: string;
  type: VideoType;
  year: string;
  rating: number;
  isNew?: boolean;
  isFavorite?: boolean;
}

@Component
export default struct HomePage {
  @State selectedCategory: string = 'recommend';
  @State showPlayerController: boolean = false;
  @State currentTime: number = 0;
  @State totalTime: number = 3600;
  @State volume: number = 0.8;
  @State isMuted: boolean = false;
  @State isFullscreen: boolean = false;
  @State isBuffering: boolean = false;
  @State playbackStatus: PlaybackStatus = PlaybackStatus.PAUSED;
  
  // 模拟分类数据
  categories: any[] = [
    { id: 'recommend', name: '推荐', icon: '🌟' },
    { id: 'movie', name: '电影', icon: '🎬' },
    { id: 'tv', name: '剧集', icon: '📺' },
    { id: 'variety', name: '综艺', icon: '🎭' },
    { id: 'anime', name: '动漫', icon: '🤖' },
    { id: 'documentary', name: '纪录片', icon: '📹' },
    { id: 'kids', name: '儿童', icon: '👶' },
    { id: 'sports', name: '体育', icon: '⚽' }
  ];
  
  // 模拟视频数据
  featuredMovies: MovieData[] = [
    {
      id: '1',
      title: '星际穿越',
      coverUrl: 'https://example.com/interstellar.jpg',
      type: VideoType.MOVIE,
      year: '2014',
      rating: 9.3,
      isNew: false,
      isFavorite: true
    },
    {
      id: '2',
      title: '流浪地球2',
      coverUrl: 'https://example.com/the_wandering_earth_2.jpg',
      type: VideoType.MOVIE,
      year: '2023',
      rating: 8.7,
      isNew: true,
      isFavorite: false
    },
    {
      id: '3',
      title: '三体',
      coverUrl: 'https://example.com/three_body.jpg',
      type: VideoType.TV,
      year: '2023',
      rating: 8.4,
      isNew: false,
      isFavorite: false
    },
    {
      id: '4',
      title: '狂飙',
      coverUrl: 'https://example.com/the_knockout.jpg',
      type: VideoType.TV,
      year: '2023',
      rating: 9.1,
      isNew: false,
      isFavorite: true
    },
    {
      id: '5',
      title: '满江红',
      coverUrl: 'https://example.com/full_river_red.jpg',
      type: VideoType.MOVIE,
      year: '2023',
      rating: 7.8,
      isNew: true,
      isFavorite: false
    },
    {
      id: '6',
      title: '漫长的季节',
      coverUrl: 'https://example.com/long_season.jpg',
      type: VideoType.TV,
      year: '2023',
      rating: 9.5,
      isNew: false,
      isFavorite: true
    }
  ];
  
  // 处理分类切换
  handleCategoryChange(categoryId: string) {
    this.selectedCategory = categoryId;
    // TODO: 加载对应分类的内容
  }
  
  // 处理视频点击
  handleVideoPress(movie: MovieData) {
    console.log(`播放视频: ${movie.title}`);
    // 显示播放器控制界面
    this.showPlayerController = true;
    this.playbackStatus = PlaybackStatus.PLAYING;
    // TODO: 调用播放器服务播放视频
  }
  
  // 处理收藏按钮点击
  handleFavoritePress(movieId: string) {
    console.log(`收藏/取消收藏: ${movieId}`);
    // TODO: 调用收藏服务更新收藏状态
  }
  
  // 处理播放/暂停
  handlePlayPause() {
    this.playbackStatus = this.playbackStatus === PlaybackStatus.PLAYING 
      ? PlaybackStatus.PAUSED 
      : PlaybackStatus.PLAYING;
    // TODO: 调用播放器服务控制播放状态
  }
  
  // 处理进度条拖动
  handleSeek(time: number) {
    this.currentTime = time;
    // TODO: 调用播放器服务更新播放进度
  }
  
  // 处理音量变化
  handleVolumeChange(volume: number) {
    this.volume = volume;
    if (volume > 0 && this.isMuted) {
      this.isMuted = false;
    }
    // TODO: 调用播放器服务更新音量
  }
  
  // 处理静音切换
  handleToggleMute() {
    this.isMuted = !this.isMuted;
    // TODO: 调用播放器服务切换静音状态
  }
  
  // 处理全屏切换
  handleToggleFullscreen() {
    this.isFullscreen = !this.isFullscreen;
    // TODO: 调用播放器服务切换全屏状态
  }
  
  // 处理返回按钮
  handleBack() {
    this.showPlayerController = false;
    // TODO: 处理返回逻辑
  }
  
  build() {
    Stack() {
      Column() {
        // 顶部导航栏
        Row() {
          Text('RayTV')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .marginLeft(20)
            .marginTop(10)
          
          Row() {
            Button() {
              Text('🔍')
                .fontSize(20)
            }
            .width(48)
            .height(48)
            .marginRight(16)
            
            Button() {
              Text('⭐')
                .fontSize(20)
            }
            .width(48)
            .height(48)
            .marginRight(20)
          }
          .marginLeft('auto')
        }
        .width('100%')
        .height(60)
        .alignItems(VerticalAlign.Center)
        .backgroundColor('#1a1a1a')
        
        // 分类导航
        CategoryNavigation({
          categories: this.categories,
          selectedCategoryId: this.selectedCategory,
          onCategoryChange: this.handleCategoryChange.bind(this),
          showScrollButtons: true
        })
        
        // 内容区域
        Scroll() {
          Column() {
            // 精选内容标题
            Text('精选推荐')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .marginTop(20)
              .marginLeft(20)
              .marginBottom(16)
            
            // 精选内容横向滚动
            Scroll() {
              Row() {
                ForEach(this.featuredMovies, (movie) => {
                  VideoCard({
                    id: movie.id,
                    title: movie.title,
                    coverUrl: movie.coverUrl,
                    type: movie.type,
                    year: movie.year,
                    rating: movie.rating,
                    isNew: movie.isNew,
                    isFavorite: movie.isFavorite,
                    onPress: () => this.handleVideoPress(movie),
                    onFavorite: () => this.handleFavoritePress(movie.id),
                    width: 300,
                    aspectRatio: 0.5625
                  })
                  .marginRight(16)
                })
              }
              .paddingLeft(20)
              .paddingRight(20)
              .paddingBottom(20)
            }
            .scrollable(ScrollDirection.Horizontal)
            .scrollBar(BarState.Auto)
            
            // 其他内容区块可以在这里继续添加...
            Text('热门电影')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .marginTop(20)
              .marginLeft(20)
              .marginBottom(16)
            
            // 热门电影网格布局
            Grid() {
              ForEach(this.featuredMovies.filter(m => m.type === VideoType.MOVIE), (movie) => {
                GridItem() {
                  VideoCard({
                    id: movie.id,
                    title: movie.title,
                    coverUrl: movie.coverUrl,
                    type: movie.type,
                    year: movie.year,
                    rating: movie.rating,
                    isNew: movie.isNew,
                    isFavorite: movie.isFavorite,
                    onPress: () => this.handleVideoPress(movie),
                    onFavorite: () => this.handleFavoritePress(movie.id),
                    width: '100%',
                    aspectRatio: 0.75
                  })
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr 1fr')
            .columnsGap(16)
            .rowsGap(20)
            .paddingLeft(20)
            .paddingRight(20)
            .paddingBottom(20)
          }
          .width('100%')
        }
        .scrollable(ScrollDirection.Vertical)
        .scrollBar(BarState.Auto)
        .flexGrow(1)
        .backgroundColor('#121212')
      }
      .width('100%')
      .height('100%')
      
      // 播放器控制界面
      if (this.showPlayerController) {
        PlayerController({
          status: this.playbackStatus,
          currentTime: this.currentTime,
          totalTime: this.totalTime,
          volume: this.volume,
          isMuted: this.isMuted,
          isFullscreen: this.isFullscreen,
          isBuffering: this.isBuffering,
          title: '当前播放',
          subtitle: '精彩内容正在播放',
          onPlayPause: this.handlePlayPause.bind(this),
          onSeek: this.handleSeek.bind(this),
          onVolumeChange: this.handleVolumeChange.bind(this),
          onToggleMute: this.handleToggleMute.bind(this),
          onToggleFullscreen: this.handleToggleFullscreen.bind(this),
          onBack: this.handleBack.bind(this),
          showController: this.showPlayerController
        })
      }
    }
    .width('100%')
    .height('100%')
  }
}