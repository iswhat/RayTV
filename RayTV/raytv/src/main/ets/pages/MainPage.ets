import { Button, Text, Image, List, ListItem, Row, Column, Flex } from '@arkui/native';
import { Router } from '@ohos.router';
import Logger from '../common/util/Logger';
import { mediaService } from '../service/media/MediaService';
import { configService } from '../service/config/ConfigService';
import Logger from '../common/util/Logger';

/**
 * 应用主页面
 * 作为应用的入口页面，显示主要功能区域
 */
@Entry
@Component
struct MainPage {
  private readonly TAG: string = 'MainPage';
  
  // 状态管理
  @State featuredMedia: Array<any> = [];
  @State isLoading: boolean = true;
  
  // 生命周期
  aboutToAppear() {
    this.loadFeaturedContent();
  }
  
  // 加载推荐内容
  private loadFeaturedContent() {
    Logger.info(this.TAG, 'Loading featured content');
    
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
    Router.push({ url: 'pages/CategoryPage' });
  }
  
  // 跳转到搜索页面
  private navigateToSearch() {
    Router.push({ url: 'pages/SearchPage' });
  }
  
  // 跳转到设置页面
  private navigateToSettings() {
    Router.push({ url: 'pages/SettingsPage' });
  }
  
  // 渲染媒体项
  @Builder
  renderMediaItem(media: any) {
    return (
      <ListItem onClick={() => Router.push({ url: `pages/MediaDetailPage?id=${media.id}` })}>
        <Column padding={10}>
          <Image
            src={media.cover}
            width={150}
            height={200}
            objectFit={ImageFit.Cover}
            borderRadius={8}
            alt={media.title}
          ></Image>
          <Text marginTop={8} fontSize={14} maxLines={2}>{media.title}</Text>
        </Column>
      </ListItem>
    );
  }
  
  build() {
    return (
      <Flex direction={FlexDirection.Column} padding={20}>
        {/* 标题栏 */}
        <Row justifyContent={FlexAlign.SpaceBetween} alignItems={ItemAlign.Center} marginBottom={20}>
          <Text fontSize={24} fontWeight={FontWeight.Bold}>RayTV</Text>
          <Row>
            <Button onClick={this.navigateToSearch} marginRight={10}>
              搜索
            </Button>
            <Button onClick={this.navigateToSettings}>
              设置
            </Button>
          </Row>
        </Row>
        
        {/* 分类入口 */}
        <Button 
          onClick={this.navigateToCategory}
          backgroundColor="#007AFF"
          color="white"
          width="100%"
          padding={12}
          fontSize={16}
          marginBottom={20}
        >
          浏览分类
        </Button>
        
        {/* 推荐内容 */}
        <Text fontSize={20} fontWeight={FontWeight.Bold} marginBottom={15}>推荐内容</Text>
        
        {this.isLoading ? (
          <Text>加载中...</Text>
        ) : (
          <List
            scroller={new Scroller()}
            horizontal={true}
            itemGenerator={(index) => this.renderMediaItem(this.featuredMedia[index])}
            data={this.featuredMedia}
            height={250}
          />
        )}
        
        {/* 底部提示 */}
        <Text fontSize={12} color="#888888" marginTop={20} textAlign={TextAlign.Center}>
          请确保已配置视频源以获得最佳体验
        </Text>
      </Flex>
    );
  }
}
