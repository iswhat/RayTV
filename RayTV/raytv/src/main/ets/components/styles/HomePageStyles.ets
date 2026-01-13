// HomePage样式文件 // HomePage Style File
// 定义首页UI布局所需的所有样式 // Define all styles needed for home page UI layout

// 定义样式对象类型 // Define style object type
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

// 使用ArkTS支持的样式定义方式 // Use ArkTS-supported style definition method
export const homePageStyles: HomePageStylesType = {
  // 主页面容器 // Main page container
  homePage: {
    flexDirection: 'column',
    backgroundColor: '#F5F5F5'
  },
  
  // 绿色顶部导航栏 - 使用固定的绿色背景色 // Green top navigation bar - Use fixed green background color
  greenHeader: {
    backgroundColor: '#4CAF50',
    paddingTop: 20,
    paddingBottom: 10,
    minHeight: 160
  },
  
  // 分类导航栏 // Category navigation bar
  navBar: {
    flexDirection: 'row',
    justifyContent: 'space-around',
    paddingHorizontal: 10,
    marginBottom: 10,
    flexWrap: true
  },
  
  // 导航项 - 未选中状态 // Navigation item - Unselected state
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
  
  // 激活状态的导航项(通过代码直接设置) // Active navigation item (set directly through code)
  navItemActive: {
    color: '#4CAF50',
    backgroundColor: '#FFFFFF',
    fontWeight: 700
  },
  
  // 功能按钮区域 // Function button area
  functionButtons: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    paddingHorizontal: 20,
    marginBottom: 10
  },
  
  // 功能按钮 - 绿色背景，白色文字 // Function button - Green background, white text
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
  
  // 时间显示 // Time display
  timeDisplay: {
    fontSize: 24,
    color: '#FFFFFF',
    textAlign: 'right',
    paddingRight: 20,
    marginBottom: 10
  },
  
  // 内容滚动区域 // Content scroll area
  contentScroll: {
    flex: 1,
    padding: 20
  },
  
  // 主要媒体网格 - 优化布局 // Main media grid - Optimized layout
  mainMediaGrid: {
    columnGap: 20,
    rowGap: 30,
    width: '100%'
  },
  
  // 媒体卡片 - 调整宽高比例 // Media card - Adjust width-height ratio
  mediaCard: {
    flexDirection: 'column',
    width: '100%',
    aspectRatio: 0.66 // 接近标准电影海报比例 // Close to standard movie poster ratio
  },
  
  // 媒体封面图 - 圆角优化 // Media cover image - Rounded corner optimization
  mediaCover: {
    width: '100%',
    aspectRatio: 0.66,
    borderRadius: 4,
    objectFit: 'cover',
    backgroundColor: '#E0E0E0'
  },
  
  // 媒体信息区域 - 居中显示 // Media information area - Centered display
  mediaInfo: {
    marginTop: 8,
    alignItems: 'center'
  },
  
  // 媒体标题 - 调整字号和行高 // Media title - Adjust font size and line height
  mediaTitle: {
    fontSize: 22,
    color: '#333333',
    fontWeight: 500,
    numberOfLines: 2,
    height: 60,
    textAlign: 'center'
  },
  
  // 媒体评分 - 突出显示 // Media score - Highlighted display
  mediaScore: {
    fontSize: 24,
    color: '#FF5722',
    fontWeight: 700,
    marginBottom: 5
  },
  
  // 媒体年份 // Media year
  mediaYear: {
    fontSize: 20,
    color: '#757575',
    marginTop: 3
  },
  
  // 加载容器 // Loading container
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  
  // 加载进度 // Loading progress
  loadingProgress: {
    width: 100,
    height: 100,
    color: '#4CAF50'
  },
  
  // 加载文本 // Loading text
  loadingText: {
    fontSize: 32,
    color: '#333333',
    marginTop: 30
  },
  
  // 错误容器 // Error container
  errorContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center'
  },
  
  // 错误图标 // Error icon
  errorIcon: {
    fontSize: 100,
    marginBottom: 30
  },
  
  // 错误消息 // Error message
  errorMessage: {
    fontSize: 32,
    color: '#333333',
    textAlign: 'center',
    marginBottom: 30
  },
  
  // 重试按钮 // Retry button
  retryButton: {
    fontSize: 28,
    paddingHorizontal: 40,
    paddingVertical: 15,
    backgroundColor: '#4CAF50',
    color: '#FFFFFF',
    borderRadius: 10
  },
  
  // 底部空间 // Bottom space
  bottomSpace: {
    height: 50
  }
};

export default homePageStyles;
