// VideoCard.ets - 通用视频卡片组件
import { VideoType } from '../../data/model/Movie';

interface VideoCardProps {
  id: string;
  title: string;
  coverUrl: string;
  type: VideoType;
  year?: string;
  rating?: number;
  isNew?: boolean;
  isFavorite?: boolean;
  onPress: () => void;
  onLongPress?: () => void;
  onFavorite?: () => void;
  width?: number;
  aspectRatio?: number;
}

@Component
export default struct VideoCard {
  @State isHover: boolean = false;
  @State isPressed: boolean = false;
  
  private props: VideoCardProps = {} as VideoCardProps;
  private defaultWidth: number = 220;
  private defaultAspectRatio: number = 0.5625; // 16:9
  
  constructor(props: VideoCardProps) {
    this.props = props;
  }
  
  private getTypeLabel(type: VideoType): string {
    // 直接比较枚举值，避免使用toString()方法可能导致的类型错误
    return type === VideoType.MOVIE ? '电影' : '剧集';
  }
  
  build() {
    Column() {
      Stack() {
        // 封面图
        Image(this.props.coverUrl)
          .width('100%')
          .aspectRatio(this.props.aspectRatio || this.defaultAspectRatio)
          .objectFit(ImageFit.Cover)
          .borderRadius(8)
          .backgroundColor('#2c2c2c')
          
        // 悬浮效果
        if (this.isHover) {
          Stack() {
            // 渐变遮罩
            LinearGradient()
              .colors(["rgba(0,0,0,0)", "rgba(0,0,0,0.7)"])
              .direction(GradientDirection.Bottom)
              .width('100%')
              .height('100%')
              .borderRadius(8)
            
            // 评分
            if (this.props.rating) {
              Row() {
                Text('⭐')
                  .fontSize(14)
                Text(`${this.props.rating.toFixed(1)}`)
                  .fontSize(14)
                  .fontWeight(FontWeight.Bold)
                  .marginLeft(2)
              }
              .padding(8)
              .position({ x: 8, y: 8 })
              .backgroundColor('rgba(0,0,0,0.6)')
              .borderRadius(4)
            }
            
            // 收藏按钮
            if (this.props.onFavorite) {
              Button() {
                Text(this.props.isFavorite ? '❤️' : '🤍')
                  .fontSize(18)
              }
              .width(36)
              .height(36)
              .position({ x: '100%', y: '100%', offsetX: -8, offsetY: -8 })
              .backgroundColor('rgba(0,0,0,0.6)')
              .borderRadius(18)
              .onClick(() => {
                this.props.onFavorite!();
              })
            }
            
            // 类型标识
            Text(this.getTypeLabel(this.props.type))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .position({ x: '100%', y: 8, offsetX: -8 })
              .fontSize(12)
              .backgroundColor('#37a2da')
              .borderRadius(4)
              .fontWeight(FontWeight.Bold)
          }
        }
        
        // 新内容标识
        if (this.props.isNew) {
          Text('新')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .position({ x: 8, y: 8 })
            .fontSize(12)
            .backgroundColor('#ff4757')
            .borderRadius(4)
            .fontWeight(FontWeight.Bold)
        }
      }
      .width(this.props.width || this.defaultWidth)
      .onHover(() => {
        this.isHover = true;
      })
      .onHoverExit(() => {
        this.isHover = false;
      })
      
      // 标题
      Text(this.props.title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .marginTop(8)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        
      // 年份
      if (this.props.year) {
        Text(this.props.year)
          .fontSize(14)
          .color('#888')
          .marginTop(4)
      }
    }
    .onClick(() => {
      this.props.onPress();
    })
    .onLongPress(() => {
      if (this.props.onLongPress) {
        this.props.onLongPress();
      }
    })
    .transition({
      type: TransitionType.Insert,
      opacity: 0,
      scale: { x: 0.9, y: 0.9 },
      duration: 300
    })
  }
}