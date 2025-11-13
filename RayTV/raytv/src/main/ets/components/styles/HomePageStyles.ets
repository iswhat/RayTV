// HomePage样式文件
// 定义首页UI布局所需的所有样式

// 定义样式对象类型
export interface HomePageStylesType {
  homePage: {
    flexDirection: string;
    backgroundColor: string;
  };
  greenHeader: {
    backgroundColor: string;
    paddingTop: number;
    paddingBottom: number;
    minHeight: number;
  };
  navBar: {
    flexDirection: string;
    justifyContent: number;
    paddingHorizontal: number;
    marginBottom: number;
    flexWrap: boolean;
  };
  navItem: {
    fontSize: number;
    color: string;
    paddingHorizontal: number;
    paddingVertical: number;
    borderRadius: number;
    backgroundColor: string;
    marginHorizontal: number;
    marginBottom: number;
  };
  navItemActive: {
    color: string;
    backgroundColor: string;
    fontWeight: number;
  };
  functionButtons: {
    flexDirection: string;
    justifyContent: number;
    paddingHorizontal: number;
    marginBottom: number;
  };
  functionButton: {
    fontSize: number;
    color: string;
    backgroundColor: string;
    paddingHorizontal: number;
    paddingVertical: number;
    borderRadius: number;
    marginLeft: number;
    height: number;
    minWidth: number;
  };
  timeDisplay: {
    fontSize: number;
    color: string;
    textAlign: string;
    paddingRight: number;
    marginBottom: number;
  };
  contentScroll: {
    flex: number;
    padding: number;
  };
  mainMediaGrid: {
    columnGap: number;
    rowGap: number;
    width: string;
  };
  mediaCard: {
    flexDirection: string;
    width: string;
    aspectRatio: number;
  };
  mediaCover: {
    width: string;
    aspectRatio: number;
    borderRadius: number;
    objectFit: number;
    backgroundColor: string;
  };
  mediaInfo: {
    marginTop: number;
    alignItems: number;
  };
  mediaTitle: {
    fontSize: number;
    color: string;
    fontWeight: number;
    numberOfLines: number;
    height: number;
    textAlign: string;
  };
  mediaScore: {
    fontSize: number;
    color: string;
    fontWeight: number;
    marginBottom: number;
  };
  mediaYear: {
    fontSize: number;
    color: string;
    marginTop: number;
  };
  loadingContainer: {
    flex: number;
    justifyContent: number;
    alignItems: number;
  };
  loadingProgress: {
    width: number;
    height: number;
    color: string;
  };
  loadingText: {
    fontSize: number;
    color: string;
    marginTop: number;
  };
  errorContainer: {
    flex: number;
    justifyContent: number;
    alignItems: number;
  };
  errorIcon: {
    fontSize: number;
    marginBottom: number;
  };
  errorMessage: {
    fontSize: number;
    color: string;
    textAlign: string;
    marginBottom: number;
  };
  retryButton: {
    fontSize: number;
    paddingHorizontal: number;
    paddingVertical: number;
    backgroundColor: string;
    color: string;
    borderRadius: number;
  };
  bottomSpace: {
    height: number;
  };
}

// 使用ArkTS支持的样式定义方式
export const homePageStyles: HomePageStylesType = {
  // 主页面容器
  homePage: {
    flexDirection: 'column',
    backgroundColor: '#F5F5F5'
  },
  
  // 绿色顶部导航栏 - 使用固定的绿色背景色
  greenHeader: {
    backgroundColor: '#4CAF50',
    paddingTop: 20,
    paddingBottom: 10,
    minHeight: 160
  },
  
  // 分类导航栏
  navBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 10,
    marginBottom: 10,
    flexWrap: true
  },
  
  // 导航项 - 未选中状态
  navItem: {
    fontSize: 24,
    color: '#FFFFFF',
    paddingHorizontal: 15,
    paddingVertical: 8,
    borderRadius: 15,
    backgroundColor: 'transparent',
    marginHorizontal: 5,
    marginBottom: 5
  },
  
  // 激活状态的导航项（通过代码直接设置）
  navItemActive: {
    color: '#4CAF50',
    backgroundColor: '#FFFFFF',
    fontWeight: 700
  },
  
  // 功能按钮区域
  functionButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 20,
    marginBottom: 10
  },
  
  // 功能按钮 - 绿色背景，白色文字
  functionButton: {
    fontSize: 24,
    color: '#FFFFFF',
    backgroundColor: '#8FBC8F',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    marginLeft: 15,
    height: 50,
    minWidth: 80
  },
  
  // 时间显示
  timeDisplay: {
    fontSize: 24,
    color: '#FFFFFF',
    textAlign: 'right',
    paddingRight: 20,
    marginBottom: 10
  },
  
  // 内容滚动区域
  contentScroll: {
    flex: 1,
    padding: 20
  },
  
  // 主要媒体网格 - 优化布局
  mainMediaGrid: {
    columnGap: 20,
    rowGap: 30,
    width: '100%'
  },
  
  // 媒体卡片 - 调整宽高比
  mediaCard: {
    flexDirection: 'column',
    width: '100%',
    aspectRatio: 0.66 // 接近标准电影海报比例
  },
  
  // 媒体封面图 - 圆角优化
  mediaCover: {
    width: '100%',
    aspectRatio: 0.66,
    borderRadius: 4,
    objectFit: 'cover',
    backgroundColor: '#E0E0E0'
  },
  
  // 媒体信息区域 - 居中显示
  mediaInfo: {
    marginTop: 8,
    alignItems: 'center'
  },
  
  // 媒体标题 - 调整字号和行高
  mediaTitle: {
    fontSize: 22,
    color: '#333333',
    fontWeight: 500,
    numberOfLines: 2,
    height: 60,
    textAlign: 'center'
  },
  
  // 媒体评分 - 突出显示
  mediaScore: {
    fontSize: 24,
    color: '#FF5722',
    fontWeight: 700,
    marginBottom: 5
  },
  
  // 媒体年份
  mediaYear: {
    fontSize: 20,
    color: '#757575',
    marginTop: 3
  },
  
  // 加载容器
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  
  // 加载进度
  loadingProgress: {
    width: 100,
    height: 100,
    color: '#4CAF50'
  },
  
  // 加载文本
  loadingText: {
    fontSize: 32,
    color: '#333333',
    marginTop: 30
  },
  
  // 错误容器
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  
  // 错误图标
  errorIcon: {
    fontSize: 100,
    marginBottom: 30
  },
  
  // 错误消息
  errorMessage: {
    fontSize: 32,
    color: '#333333',
    textAlign: 'center',
    marginBottom: 30
  },
  
  // 重试按钮
  retryButton: {
    fontSize: 28,
    paddingHorizontal: 40,
    paddingVertical: 15,
    backgroundColor: '#4CAF50',
    color: '#FFFFFF',
    borderRadius: 10
  },
  
  // 底部空间
  bottomSpace: {
    height: 50
  }
};

export default homePageStyles;