
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
 * 媒体详情页组�?
 * 展示媒体详细信息、集数列表和操作按钮
 */
@Entry
@Component
struct MediaDetailPage {
  private readonly TAG: string = 'MediaDetailPage';
  
  // 路由参数
  private mediaId: string = '';
  private siteKey: string = '';
  
  // 状态管�?
  @State mediaDetail: MediaDetail | null = null;
  @State episodes: Episode[] = [];
  @State playSources: PlaySource[] = [];
  @State filteredSources: PlaySource[] = [];
  @State relatedMedia: MediaItem[] = [];
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State activeTab: string = 'episodes';
  @State seasons: Array<{ season: number; episodes: Episode[] }> = [];
  @State selectedSeason: number = 1;
  @State searchKeyword: string = '';
  @State isFavorite: boolean = false;
  @State watchHistory: WatchHistory | null = null;
  
  // 生命周期钩子
  onPageShow() {
    Logger.info(this.TAG, 'onPageShow');
    this.loadMediaDetail();
  }
  
  /**
   * 加载媒体详情
   */
  private async loadMediaDetail() {
    try {
      this.isLoading = true;
      this.errorMessage = '';
      
      // 模拟加载延迟
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // 模拟数据
      this.mediaDetail = {
        id: this.mediaId,
        siteKey: this.siteKey,
        title: '测试影片',
        coverUrl: 'https://via.placeholder.com/150x200?text=Cover',
        description: '这是一部测试影片，用于展示媒体详情页的功能�?,
        score: '8.5',
        year: '2024',
        type: '电影',
        status: '已完�?,
        directors: ['导演A', '导演B'],
        actors: ['演员A', '演员B', '演员C'],
        genres: ['动作', '冒险'],
        regions: ['中国', '美国']
      };
      
      // 模拟剧集数据
      this.episodes = Array.from({ length: 20 }, (_, index) => ({
        id: `episode_${index + 1}`,
        name: `�?{index + 1}集`,
        season: 1,
        episode: index + 1
      }));
      
      // 模拟季数�?
      this.seasons = [{ season: 1, episodes: this.episodes }];
      
      // 模拟播放源数�?
      this.playSources = Array.from({ length: 5 }, (_, index) => ({
        id: `source_${index + 1}`,
        name: `播放�?{index + 1}`,
        quality: index % 2 === 0 ? '1080P' : '720P',
        url: `https://example.com/play/${index + 1}`
      }));
      
      this.filteredSources = this.playSources;
      
      // 模拟相关推荐数据
      this.relatedMedia = Array.from({ length: 10 }, (_, index) => ({
        id: `related_${index + 1}`,
        siteKey: this.siteKey,
        title: `相关影片${index + 1}`,
        coverUrl: `https://via.placeholder.com/150x200?text=Related+${index + 1}`,
        type: '电影',
        score: `${Math.floor(Math.random() * 2) + 7}.${Math.floor(Math.random() * 10)}`
      }));
      
      // 模拟收藏状�?
      this.isFavorite = false;
      
      // 模拟观看历史
      this.watchHistory = {
        mediaId: this.mediaId,
        episodeId: 'episode_5',
        position: 300000, // 5分钟
        lastWatchTime: Date.now() - 3600000 // 1小时�?
      };
    } catch (error) {
      Logger.error(this.TAG, `Failed to load media detail: ${JSON.stringify(error)}`, error as Error);
      this.errorMessage = '加载失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }
  
  /**
   * 返回上一�?
   */
  private async handleBack() {
    await AppNavigator.getInstance().navigateToBack();
  }
  
  /**
   * 处理相关媒体点击
   */
  private async handleRelatedMediaClick(media: MediaItem) {
    await AppNavigator.getInstance().navigateToDetail({
      id: media.id,
      siteKey: media.siteKey,
      type: 'vod'
    });
  }
  
  /**
   * 处理播放点击
   */
  private async handlePlayClick(episode: Episode, source: PlaySource) {
    Logger.info(this.TAG, `Play episode ${episode.name} with source ${source.name}`);
    // 跳转到播放页
    await AppNavigator.getInstance().navigateToVideoPlay({
      videoId: this.mediaId,
      siteKey: this.siteKey,
      episodeName: episode.name,
      position: this.watchHistory?.position || 0
    });
  }
  
  /**
   * 处理收藏点击
   */
  private async handleFavoriteClick() {
    try {
      this.isFavorite = !this.isFavorite;
      if (this.isFavorite) {
        // 保存收藏
        Logger.info(this.TAG, `Add to favorite: ${this.mediaDetail?.title}`);
      } else {
        // 取消收藏
        Logger.info(this.TAG, `Remove from favorite: ${this.mediaDetail?.title}`);
      }
    } catch (error) {
      Logger.error(this.TAG, `Failed to toggle favorite: ${JSON.stringify(error)}`, error as Error);
      // 恢复原始状�?
      this.isFavorite = !this.isFavorite;
    }
  }
  
  /**
   * 渲染加载状�?
   */
  @Builder
  private renderLoading(): void {
    Column({
      style: {
        width: '100%',
        height: '100%',
        backgroundColor: '#4CAF50',
        justifyContent: 'center',
        alignItems: 'center'
      }
    }) {
      // 加载指示�? 使用简单的旋转动画
      Column({
        style: {
          width: 50,
          height: 50,
          backgroundColor: '#FFFFFF',
          borderRadius: 25,
          justifyContent: 'center',
          alignItems: 'center'
        }
      }) {
        Text("�?)
          .fontSize(20)
          .fontColor('#4CAF50')
      }
      Text("加载�?.")
        .fontSize(24)
        .fontColor('#FFFFFF')
        .margin({ top: 20 })
    }
  }
  
  /**
   * 渲染错误状�?
   */
  @Builder
  private renderError(): void {
    Column({
      style: {
        width: '100%',
        height: '100%',
        backgroundColor: '#4CAF50',
        justifyContent: 'center',
        alignItems: 'center',
        padding: 20
      }
    }) {
      Text("⚠️")
        .fontSize(48)
        .margin({ bottom: 20 })
      Text(this.errorMessage)
        .fontSize(24)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 30 })
      Button({
        style: {
          backgroundColor: '#FFFFFF',
          paddingHorizontal: 40,
          paddingVertical: 15,
          borderRadius: 25
        },
        onClick: () => this.loadMediaDetail()
      }) {
        Text("重试")
          .fontSize(24)
          .fontColor('#4CAF50')
          .fontWeight(700)
      }
    }
  }
  
  /**
   * 渲染头部信息
   */
  @Builder
  private renderHeader(): void {
    Column({
      style: {
        padding: 20
      }
    }) {
      // 媒体封面和基本信�?
      Row({
        style: {
          alignItems: 'flex-start'
        }
      }) {
        // 媒体封面
        Column({
          style: {
            width: 150,
            height: 200,
            backgroundColor: '#E0E0E0',
            borderRadius: 8,
            justifyContent: 'center',
            alignItems: 'center'
          }
        }) {
          Text("封面")
            .fontSize(16)
            .fontColor('#666666')
        }
        
        Column({
          style: {
            marginLeft: 20,
            flex: 1
          }
        }) {
          // 标题
          Text(this.mediaDetail?.title || "")
            .fontSize(28)
            .fontColor('#FFFFFF')
            .fontWeight(700)
            .margin({ bottom: 10 })
          
          // 评分
          Row({
            style: {
              alignItems: 'center',
              marginBottom: 10
            }
          }) {
            Text("�?)
              .fontSize(18)
              .marginRight(5)
            Text(this.mediaDetail?.score || "0.0")
              .fontSize(18)
              .fontColor('#FFFFFF')
              .marginRight(20)
            
            // 年份和类�?
            Text(`${this.mediaDetail?.year || ""} · ${this.mediaDetail?.type || ""}`)
              .fontSize(18)
              .fontColor('#FFFFFF')
          }
          
          // 状�?
          Text(this.mediaDetail?.status || "")
            .fontSize(18)
            .fontColor('#FFFFFF')
            .margin({ bottom: 15 })
          
          // 导演和演�?
          Column({
            style: {
              marginBottom: 15
            }
          }) {
            Row({
              style: {
                alignItems: 'center'
              }
            }) {
              Text("导演�?)
                .fontSize(18)
                .fontColor('#FFFFFF')
                .marginRight(10)
              Text(this.mediaDetail?.directors?.join("�?) || "")
                .fontSize(18)
                .fontColor('#FFFFFF')
            }
            
            Row({
              style: {
                alignItems: 'center',
                marginTop: 5
              }
            }) {
              Text("演员�?)
                .fontSize(18)
                .fontColor('#FFFFFF')
                .marginRight(10)
              Text(this.mediaDetail?.actors?.join("�?) || "")
                .fontSize(18)
                .fontColor('#FFFFFF')
            }
          }
          
          // 类型和地�?
          Row({
            style: {
              alignItems: 'center',
              flexWrap: 'wrap',
              marginBottom: 20
            }
          }) {
            ForEach(this.mediaDetail?.genres || [], (genre: string) => {
              Column({
                style: {
                  padding: { left: 10, right: 10, top: 5, bottom: 5 },
                  backgroundColor: '#66BB6A',
                  borderRadius: 15,
                  marginRight: 10,
                  marginBottom: 10
                }
              }) {
                Text(genre)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
            })
            
            ForEach(this.mediaDetail?.regions || [], (region: string) => {
              Column({
                style: {
                  padding: { left: 10, right: 10, top: 5, bottom: 5 },
                  backgroundColor: '#66BB6A',
                  borderRadius: 15,
                  marginRight: 10,
                  marginBottom: 10
                }
              }) {
                Text(region)
                  .fontSize(16)
                  .fontColor('#FFFFFF')
              }
            })
          }
        }
      }
      
      // 操作按钮
      Row({
        style: {
          justifyContent: 'space-between',
          alignItems: 'center',
          marginBottom: 20
        }
      }) {
        // 播放按钮
        Button({
          style: {
            backgroundColor: '#FFFFFF',
            paddingHorizontal: 50,
            paddingVertical: 15,
            borderRadius: 25,
            flex: 1
          },
          onClick: () => this.handlePlayClick(this.episodes[0] || { id: '', name: '' }, this.playSources[0] || {})
        }) {
          Text("播放")
            .fontSize(24)
            .fontColor('#4CAF50')
            .fontWeight(700)
        }
        
        // 收藏按钮
        Button({
          style: {
            backgroundColor: this.isFavorite ? '#FF5722' : '#66BB6A',
            paddingHorizontal: 50,
            paddingVertical: 15,
            borderRadius: 25,
            marginLeft: 20
          },
          onClick: () => this.handleFavoriteClick()
        }) {
          Text(this.isFavorite ? "取消收藏" : "收藏")
            .fontSize(24)
            .fontColor('#FFFFFF')
            .fontWeight(700)
        }
      }
      
      // 剧情简�?
      Column({
        style: {
          marginBottom: 20
        }
      }) {
        Text("剧情简�?)
          .fontSize(22)
          .fontColor('#FFFFFF')
          .fontWeight(600)
          .margin({ bottom: 10 })
        Text(this.mediaDetail?.description || "")
          .fontSize(18)
          .fontColor('#FFFFFF')
          .lineHeight(28)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(3)
      }
    }
  }
  
  /**
   * 渲染标签页切换栏
   */
  @Builder
  private renderTabBar(): void {
    Row({
      style: {
        backgroundColor: '#4CAF50',
        padding: { left: 20, right: 20, top: 10, bottom: 10 },
        gap: 10
      }
    }) {
      Button({
        style: {
          backgroundColor: this.activeTab === 'episodes' ? '#FFFFFF' : '#66BB6A',
          padding: { left: 25, right: 25, top: 10, bottom: 10 },
          borderRadius: 20,
          minWidth: 100
        },
        onClick: () => this.activeTab = 'episodes'
      }) {
        Text("剧集列表")
          .fontSize(24)
          .fontColor(this.activeTab === 'episodes' ? '#4CAF50' : '#FFFFFF')
          .fontWeight(700)
      }
      
      Button({
        style: {
          backgroundColor: this.activeTab === 'sources' ? '#FFFFFF' : '#66BB6A',
          padding: { left: 25, right: 25, top: 10, bottom: 10 },
          borderRadius: 20,
          minWidth: 100
        },
        onClick: () => this.activeTab = 'sources'
      }) {
        Text("播放�?)
          .fontSize(24)
          .fontColor(this.activeTab === 'sources' ? '#4CAF50' : '#FFFFFF')
          .fontWeight(700)
      }
    }
  }
  
  /**
   * 渲染季选择�?
   */
  @Builder
  private renderSeasonSelector(): void {
    // 季选择�?
    if (this.seasons?.length === 0) {
      Column({
        style: {
          justifyContent: 'center',
          alignItems: 'center',
          backgroundColor: '#4CAF50',
          padding: 20
        }
      }) {
        Text("暂无季信�?)
          .fontSize(24)
          .fontColor('#FFFFFF')
      }
    } else {
      Row({
        style: {
          flexWrap: 'wrap',
          gap: 10,
          marginBottom: 20
        }
      }) {
        ForEach(this.seasons, (seasonItem) => {
          Button({
            style: {
              backgroundColor: this.selectedSeason === seasonItem.season ? '#FFFFFF' : '#66BB6A',
              paddingHorizontal: 20,
              paddingVertical: 10,
              borderRadius: 15
            },
            onClick: () => this.selectedSeason = seasonItem.season
          }) {
            Text(`�?{seasonItem.season}季`)
              .fontSize(18)
              .fontColor(this.selectedSeason === seasonItem.season ? '#4CAF50' : '#FFFFFF')
          }
        })
      }
    }
  }
  
  /**
   * 渲染剧集列表
   */
  @Builder
  private renderEpisodes(): void {
    Column({
      style: {
        marginBottom: 20
      }
    }) {
      // 季选择�?
      this.renderSeasonSelector();
      
      // 剧集列表
      Column({
        style: {
          gap: 10
        }
      }) {
        ForEach(this.episodes, (episode: Episode) => {
          // 只显示当前季的剧�?
          if (episode.season === this.selectedSeason) {
            Button({
              style: {
                backgroundColor: '#66BB6A',
                padding: 15,
                borderRadius: 10,
                width: '100%',
                justifyContent: 'space-between',
                alignItems: 'center'
              },
              onClick: () => this.handlePlayClick(episode, this.playSources[0] || {})
            }) {
              Row({
                style: {
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  width: '100%'
                }
              }) {
                Text(episode.name)
                  .fontSize(20)
                  .fontColor('#FFFFFF')
                
                if (this.watchHistory?.episodeId === episode.id) {
                  Row({
                    style: {
                      alignItems: 'center'
                    }
                  }) {
                    Text("⏱️")
                      .fontSize(16)
                      .marginRight(5)
                    Text("已观�?)
                      .fontSize(16)
                      .fontColor('#FFFFFF')
                  }
                }
              }
            }
          }
        })
      }
    }
  }
  
  /**
   * 渲染播放源列�?
   */
  @Builder
  private renderPlaySources(): void {
    Column({
      style: {
        marginBottom: 20
      }
    }) {
      // 搜索�?
      Row({
        style: {
          alignItems: 'center',
          marginBottom: 20
        }
      }) {
        TextInput({
          type: InputType.Text,
          placeholder: "搜索播放�?,
          style: {
            flex: 1,
            backgroundColor: '#FFFFFF',
            borderRadius: 25,
            paddingHorizontal: 20,
            paddingVertical: 15,
            fontSize: 18
          }
        })
        .onChange((value: string) => {
          this.searchKeyword = value;
          this.filteredSources = this.playSources.filter(source =>
            source.name?.includes(value) || source.quality?.includes(value)
          );
        })
      }
      
      // 播放源列�?
      if (this.filteredSources?.length === 0) {
        Column({
          style: {
            justifyContent: 'center',
            alignItems: 'center',
            padding: 20
          }
        }) {
          Text("暂无播放源或没有匹配的片�?)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      } else {
        Column({
          style: {
            gap: 10
          }
        }) {
          ForEach(this.filteredSources, (source: PlaySource) => {
            Button({
              style: {
                backgroundColor: '#66BB6A',
                padding: 15,
                borderRadius: 10,
                width: '100%',
                justifyContent: 'space-between',
                alignItems: 'center'
              },
              onClick: () => this.handlePlayClick(this.episodes[0] || { id: '', name: '' }, source)
            }) {
              Row({
                style: {
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  width: '100%'
                }
              }) {
                Column({
                  style: {
                    alignItems: 'flex-start'
                  }
                }) {
                  Text(source.name || "")
                    .fontSize(20)
                    .fontColor('#FFFFFF')
                  Text(source.quality || "")
                    .fontSize(16)
                    .fontColor('#FFFFFF')
                }
                
                Text("�?)
                  .fontSize(24)
                  .fontColor('#FFFFFF')
              }
            }
          })
        }
      }
    }
  }
  
  /**
   * 渲染相关推荐
   */
  @Builder
  private renderRelatedMedia(): void {
    if (this.relatedMedia?.length === 0) return;
    
    Column({
      style: {
        marginBottom: 20
      }
    }) {
      Text("相关推荐")
        .fontSize(22)
        .fontColor('#FFFFFF')
        .fontWeight(600)
        .margin({ bottom: 15 })
      
      // 横向滚动的相关推荐列�?
      Scroller({
        style: {
          height: 250
        },
        scrollBar: BarState.Off
      }) {
        Row({
          style: {
            alignItems: 'flex-start',
            gap: 15
          }
        }) {
          ForEach(this.relatedMedia, (media: MediaItem) => {
            Column({
              style: {
                width: 150,
                marginRight: 15
              },
              onClick: () => this.handleRelatedMediaClick(media)
            }) {
              // 相关推荐封面
              Column({
                style: {
                  width: 150,
                  height: 200,
                  backgroundColor: '#E0E0E0',
                  borderRadius: 8,
                  justifyContent: 'center',
                  alignItems: 'center'
                }
              }) {
                Text("封面")
                  .fontSize(16)
                  .fontColor('#666666')
              }
              
              // 相关推荐标题
              Text(media.title || "")
                .fontSize(16)
                .fontColor('#FFFFFF')
                .margin({ top: 10, bottom: 5 })
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              
              // 相关推荐评分
              Row({
                style: {
                  alignItems: 'center'
                }
              }) {
                Text("�?)
                  .fontSize(14)
                  .marginRight(5)
                Text(media.score || "0.0")
                  .fontSize(14)
                  .fontColor('#FFFFFF')
              }
            }
          })
        }
      }
    }
  }
  
  build() {
    Column({
      style: {
        flex: 1,
        backgroundColor: '#4CAF50'
      }
    }) {
      // 顶部导航�?
      Row({
        style: {
          backgroundColor: '#388E3C',
          alignItems: 'center',
          justifyContent: 'space-between',
          paddingHorizontal: 20,
          paddingVertical: 15,
          width: '100%'
        }
      }) {
        Button({
          style: {
            backgroundColor: 'transparent'
          },
          onClick: this.handleBack
        }) {
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
      
      // 主内容区�?
      if (this.isLoading) {
        // 加载状�?
        Column({
          style: {
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center'
          }
        }) {
          Text("加载�?.")
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      } else if (this.errorMessage) {
        // 错误状�?
        Column({
          style: {
            flex: 1,
            justifyContent: 'center',
            alignItems: 'center'
          }
        }) {
          Text(this.errorMessage)
            .fontSize(24)
            .fontColor('#FFFFFF')
        }
      } else {
        Scroller({
          style: {
            flex: 1,
            backgroundColor: '#4CAF50'
          }
        }) {
          // 添加顶部间距，避免被导航栏遮�?
          Blank()
            .height(60)
          
          // 媒体头部信息
          if (this.mediaDetail) {
            this.renderHeader();
          }
          
          // 标签页切换栏
          this.renderTabBar();
          
          // 内容区域
          Column({
            style: {
              padding: { left: 20, right: 20, top: 20, bottom: 20 }
            }
          }) {
            if (this.activeTab === 'episodes') {
              this.renderEpisodes();
            } else {
              this.renderPlaySources();
            }
          }
          
          // 相关推荐
          if (this.relatedMedia?.length > 0) {
            this.renderRelatedMedia();
          }
        }
      }
    }
  }
}
