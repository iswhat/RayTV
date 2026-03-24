# HarmonyOS 6 实战案例集

> 本文档提供完整的实战案例代码，涵盖常见功能模块，可直接复制使用或修改适配。

---

## 目录

1. [用户登录模块](#一用户登录模块)
2. [列表分页加载](#二列表分页加载)
3. [图片上传功能](#三图片上传功能)
4. [搜索功能](#四搜索功能)
5. [下拉刷新](#五下拉刷新)
6. [轮播图组件](#六轮播图组件)
7. [底部导航栏](#七底部导航栏)
8. [消息通知](#八消息通知)

---

## 一、用户登录模块

### 1.1 登录页面 (Login.ets)

```typescript
import router from '@ohos.router';
import { Logger } from '../utils/Logger';
import { StorageUtil } from '../utils/StorageUtil';
import { HttpUtil } from '../utils/HttpUtil';
import { Constants } from '../common/Constants';

interface LoginResponse {
  code: number;
  data: {
    token: string;
    user: {
      id: number;
      username: string;
      email: string;
    };
  };
  message: string;
}

@Entry
@Component
struct Login {
  @State username: string = '';
  @State password: string = '';
  @State rememberMe: boolean = false;
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State isPasswordVisible: boolean = false;

  aboutToAppear() {
    this.loadSavedCredentials();
  }

  async loadSavedCredentials() {
    try {
      const context = getContext();
      const savedUsername = await StorageUtil.getString(context, 'saved_username', '');
      const savedPassword = await StorageUtil.getString(context, 'saved_password', '');
      
      if (savedUsername) {
        this.username = savedUsername;
        this.password = savedPassword;
        this.rememberMe = true;
      }
    } catch (error) {
      Logger.error('Login', '加载保存的凭证失败', error as Error);
    }
  }

  async handleLogin() {
    // 验证输入
    if (!this.username.trim()) {
      this.errorMessage = '请输入用户名';
      return;
    }
    
    if (!this.password) {
      this.errorMessage = '请输入密码';
      return;
    }

    this.isLoading = true;
    this.errorMessage = '';

    try {
      // 发送登录请求
      const response = await HttpUtil.post<LoginResponse>('/api/auth/login', {
        username: this.username.trim(),
        password: this.password
      });

      if (response.code === 200) {
        // 保存 token
        const context = getContext();
        await StorageUtil.setString(context, Constants.STORAGE_KEY_TOKEN, response.data.token);
        await StorageUtil.setObject(context, Constants.STORAGE_KEY_USER, response.data.user);

        // 记住密码
        if (this.rememberMe) {
          await StorageUtil.setString(context, 'saved_username', this.username);
          await StorageUtil.setString(context, 'saved_password', this.password);
        } else {
          await StorageUtil.remove(context, 'saved_username');
          await StorageUtil.remove(context, 'saved_password');
        }

        Logger.info('Login', '登录成功');
        
        // 跳转到首页
        router.replaceUrl({
          url: Constants.ROUTE_INDEX
        });
      } else {
        this.errorMessage = response.message || '登录失败';
      }
    } catch (error) {
      Logger.error('Login', '登录异常', error as Error);
      this.errorMessage = '网络错误，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  build() {
    Column() {
      // Logo 区域
      Column() {
        Image($r('app.media.logo'))
          .width(100)
          .height(100)
        
        Text('HarmonyOS 应用')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .margin({ top: 20 })
      }
      .width('100%')
      .padding({ top: 60, bottom: 40 })
      .justifyContent(FlexAlign.Center)

      // 表单区域
      Column({ space: 20 }) {
        // 用户名输入框
        Column() {
          Text('用户名')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 4 })
          
          TextInput({ placeholder: '请输入用户名', text: this.username })
            .onChange((value: string) => {
              this.username = value;
              this.errorMessage = '';
            })
            .width('100%')
            .height(50)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .fontSize(16)
        }
        .width('90%')

        // 密码输入框
        Column() {
          Text('密码')
            .fontSize(14)
            .fontColor('#666666')
            .width('100%')
            .padding({ left: 4 })
          
          Row() {
            TextInput({ 
              placeholder: '请输入密码', 
              text: this.password,
              type: this.isPasswordVisible ? InputType.Normal : InputType.Password
            })
            .onChange((value: string) => {
              this.password = value;
              this.errorMessage = '';
            })
            .layoutWeight(1)
            .height(50)
            .padding({ left: 12, right: 12 })
            .backgroundColor('#F5F5F5')
            .borderRadius(8)
            .fontSize(16)

            Button(this.isPasswordVisible ? '👁️' : '👁️‍🗨️')
              .width(50)
              .height(50)
              .backgroundColor('transparent')
              .fontColor('#666666')
              .fontSize(20)
              .onClick(() => {
                this.isPasswordVisible = !this.isPasswordVisible;
              })
          }
          .width('100%')
        }
        .width('90%')

        // 记住密码
        Row() {
          Checkbox({ name: 'remember', group: 'login' })
            .select(this.rememberMe)
            .onChange((isChecked: boolean) => {
              this.rememberMe = isChecked;
            })
          
          Text('记住密码')
            .fontSize(14)
            .fontColor('#666666')
            .margin({ left: 8 })
          
          Blank()
          
          Text('忘记密码？')
            .fontSize(14)
            .fontColor('#007DFF')
            .onClick(() => {
              Logger.info('Login', '点击忘记密码');
            })
        }
        .width('90%')
        .padding({ top: 10 })

        // 错误提示
        if (this.errorMessage) {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#F44336')
            .width('90%')
            .padding({ left: 4 })
        }

        // 登录按钮
        Button(this.isLoading ? '登录中...' : '登录')
          .width('90%')
          .height(50)
          .backgroundColor(this.isLoading ? '#CCCCCC' : Constants.COLOR_PRIMARY)
          .fontColor('#FFFFFF')
          .fontSize(18)
          .borderRadius(8)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.handleLogin();
          })

        // 注册链接
        Row() {
          Text('还没有账号？')
            .fontSize(14)
            .fontColor('#666666')
          
          Text('立即注册')
            .fontSize(14)
            .fontColor('#007DFF')
            .onClick(() => {
              Logger.info('Login', '点击注册');
            })
        }
        .width('90%')
        .padding({ top: 20 })
        .justifyContent(FlexAlign.Center)
      }

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
```

### 1.2 拦截器 (AuthInterceptor.ets)

```typescript
import { Logger } from './Logger';
import { StorageUtil } from './StorageUtil';

export class AuthInterceptor {
  private static token: string | null = null;

  /**
   * 初始化 token
   */
  static async initToken(): Promise<void> {
    try {
      const context = getContext();
      this.token = await StorageUtil.getString(context, 'token', '');
    } catch (error) {
      Logger.error('AuthInterceptor', '初始化 token 失败', error as Error);
    }
  }

  /**
   * 获取 token
   */
  static getToken(): string | null {
    return this.token;
  }

  /**
   * 清除 token（登出时调用）
   */
  static async clearToken(): Promise<void> {
    this.token = null;
    try {
      const context = getContext();
      await StorageUtil.remove(context, 'token');
      await StorageUtil.remove(context, 'user');
    } catch (error) {
      Logger.error('AuthInterceptor', '清除 token 失败', error as Error);
    }
  }

  /**
   * 检查是否已登录
   */
  static isLoggedIn(): boolean {
    return !!this.token;
  }
}
```

---

## 二、列表分页加载

### 2.1 分页数据源 (PagedDataSource.ets)

```typescript
import { Logger } from '../utils/Logger';
import { HttpUtil } from '../utils/HttpUtil';

export interface PageResult<T> {
  list: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

export class PagedDataSource<T> {
  private data: T[] = [];
  private currentPage: number = 1;
  private pageSize: number = 20;
  private total: number = 0;
  private isLoading: boolean = false;
  private hasMore: boolean = true;
  private onLoad: ((data: T[]) => void) | null = null;

  constructor(
    private fetchFunction: (page: number, pageSize: number) => Promise<PageResult<T>>
  ) {}

  /**
   * 设置数据加载回调
   */
  setOnLoadCallback(callback: (data: T[]) => void): void {
    this.onLoad = callback;
  }

  /**
   * 刷新（重新加载第一页）
   */
  async refresh(): Promise<void> {
    if (this.isLoading) return;
    
    this.currentPage = 1;
    this.hasMore = true;
    await this.loadMore();
  }

  /**
   * 加载更多
   */
  async loadMore(): Promise<void> {
    if (this.isLoading || !this.hasMore) return;

    this.isLoading = true;

    try {
      const result = await this.fetchFunction(this.currentPage, this.pageSize);
      
      if (this.currentPage === 1) {
        this.data = result.list;
      } else {
        this.data = [...this.data, ...result.list];
      }

      this.total = result.total;
      this.hasMore = result.hasMore;
      this.currentPage++;

      if (this.onLoad) {
        this.onLoad(this.data);
      }

      Logger.info('PagedDataSource', `加载成功，总数：${this.total}`);
    } catch (error) {
      Logger.error('PagedDataSource', '加载失败', error as Error);
      throw error;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 获取所有数据
   */
  getData(): T[] {
    return this.data;
  }

  /**
   * 获取当前页码
   */
  getCurrentPage(): number {
    return this.currentPage;
  }

  /**
   * 是否正在加载
   */
  isDataLoading(): boolean {
    return this.isLoading;
  }

  /**
   * 是否还有更多数据
   */
  hasMoreData(): boolean {
    return this.hasMore;
  }
}
```

### 2.2 分页列表示例 (PagedList.ets)

```typescript
import { Logger } from '../utils/Logger';
import { PagedDataSource, PageResult } from './PagedDataSource';
import { Article } from '../model/Article';
import { HttpUtil } from '../utils/HttpUtil';

interface ArticleListResponse {
  code: number;
  data: PageResult<Article>;
  message: string;
}

@Entry
@Component
struct PagedList {
  @State articles: Article[] = [];
  @State isLoading: boolean = false;
  @State isLoadingMore: boolean = false;
  @State isRefreshing: boolean = false;
  @State errorMessage: string = '';
  @State hasMore: boolean = true;

  private dataSource: PagedDataSource<Article> | null = null;

  aboutToAppear() {
    this.initDataSource();
    this.refresh();
  }

  initDataSource() {
    this.dataSource = new PagedDataSource<Article>(
      async (page: number, pageSize: number) => {
        const response = await HttpUtil.get<ArticleListResponse>('/api/articles', {
          page: page.toString(),
          pageSize: pageSize.toString()
        });
        
        return response.data;
      }
    );

    this.dataSource.setOnLoadCallback((data: Article[]) => {
      this.articles = data;
      this.hasMore = this.dataSource?.hasMoreData() || false;
    });
  }

  async refresh() {
    if (!this.dataSource) return;

    this.isRefreshing = true;
    this.errorMessage = '';

    try {
      await this.dataSource.refresh();
      Logger.info('PagedList', '刷新成功');
    } catch (error) {
      Logger.error('PagedList', '刷新失败', error as Error);
      this.errorMessage = '加载失败，请重试';
    } finally {
      this.isRefreshing = false;
    }
  }

  async loadMore() {
    if (!this.dataSource || this.isLoadingMore || !this.hasMore) return;

    this.isLoadingMore = true;

    try {
      await this.dataSource.loadMore();
      Logger.info('PagedList', '加载更多成功');
    } catch (error) {
      Logger.error('PagedList', '加载更多失败', error as Error);
    } finally {
      this.isLoadingMore = false;
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('文章列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
      }
      .width('100%')
      .height(60)
      .padding({ left: 20 })
      .backgroundColor('#F5F5F5')

      // 刷新组件
      Refresh({ refreshing: this.isRefreshing }) {
        List() {
          ForEach(this.articles, (article: Article) => {
            ListItem() {
              Column() {
                Text(article.title)
                  .fontSize(18)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#333333')
                  .width('100%')
                  .maxLines(1)
                  .overflow(TextOverflow.Ellipsis)

                Text(article.content)
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .margin({ top: 8 })
                  .maxLines(2)
                  .overflow(TextOverflow.Ellipsis)

                Row() {
                  Text(article.author)
                    .fontSize(12)
                    .fontColor('#999999')
                  
                  Text(' · ')
                    .fontSize(12)
                    .fontColor('#999999')
                  
                  Text(new Date(article.createTime).toLocaleDateString())
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .width('100%')
                .margin({ top: 12 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
            }
          }, (article: Article) => article.id.toString())

          // 加载更多提示
          if (this.isLoadingMore) {
            ListItem() {
              Row() {
                Text('加载中...')
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .height(50)
              .justifyContent(FlexAlign.Center)
            }
          }

          // 没有更多数据
          if (!this.hasMore && this.articles.length > 0) {
            ListItem() {
              Row() {
                Text('没有更多了')
                  .fontSize(14)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .height(50)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .divider({ strokeWidth: 1, color: '#EEEEEE' })
      }
      .onRefreshing(() => {
        this.refresh();
      })
      .onReachEnd(() => {
        this.loadMore();
      })

      // 错误提示
      if (this.errorMessage && this.articles.length === 0) {
        Column() {
          Text(this.errorMessage)
            .fontSize(16)
            .fontColor('#F44336')
          
          Button('重试')
            .margin({ top: 20 })
            .onClick(() => {
              this.refresh();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
```

---

## 三、搜索功能

### 3.1 搜索页面 (Search.ets)

```typescript
import router from '@ohos.router';
import { Logger } from '../utils/Logger';
import { HttpUtil } from '../utils/HttpUtil';
import { Article } from '../model/Article';

@Entry
@Component
struct Search {
  @State searchQuery: string = '';
  @State searchResults: Article[] = [];
  @State isSearching: boolean = false;
  @State searchHistory: string[] = [];
  @State showHistory: boolean = true;

  private searchTimer: number = -1;

  aboutToAppear() {
    this.loadSearchHistory();
  }

  aboutToDisappear() {
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }
  }

  async loadSearchHistory() {
    try {
      const context = getContext();
      const history = await StorageUtil.getObject(context, 'search_history', []);
      this.searchHistory = history;
    } catch (error) {
      Logger.error('Search', '加载搜索历史失败', error as Error);
    }
  }

  async saveSearchHistory(query: string) {
    try {
      // 移除重复项
      this.searchHistory = this.searchHistory.filter(item => item !== query);
      // 添加到开头
      this.searchHistory = [query, ...this.searchHistory].slice(0, 10);
      
      const context = getContext();
      await StorageUtil.setObject(context, 'search_history', this.searchHistory);
    } catch (error) {
      Logger.error('Search', '保存搜索历史失败', error as Error);
    }
  }

  async clearSearchHistory() {
    try {
      this.searchHistory = [];
      const context = getContext();
      await StorageUtil.remove(context, 'search_history');
    } catch (error) {
      Logger.error('Search', '清除搜索历史失败', error as Error);
    }
  }

  onSearchInput(query: string) {
    this.searchQuery = query;
    this.showHistory = true;

    // 防抖：停止之前的定时器
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }

    // 延迟搜索
    if (query.trim()) {
      this.searchTimer = setTimeout(() => {
        this.performSearch(query);
      }, 500) as unknown as number;
    } else {
      this.searchResults = [];
    }
  }

  async performSearch(query: string) {
    this.isSearching = true;

    try {
      const response = await HttpUtil.get<{ code: number; data: Article[] }>('/api/search', {
        q: query
      });

      if (response.code === 200) {
        this.searchResults = response.data;
        this.saveSearchHistory(query);
      }
    } catch (error) {
      Logger.error('Search', '搜索失败', error as Error);
    } finally {
      this.isSearching = false;
    }
  }

  build() {
    Column() {
      // 搜索栏
      Row() {
        Button() {
          Text('‹')
            .fontSize(28)
            .fontColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor('transparent')
        .onClick(() => {
          router.back();
        })

        TextInput({ 
          placeholder: '搜索文章...', 
          text: this.searchQuery,
          backgroundColor: '#F5F5F5'
        })
        .onChange((value: string) => {
          this.onSearchInput(value);
        })
        .layoutWeight(1)
        .height(40)
        .padding({ left: 12, right: 12 })
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .margin({ left: 10, right: 10 })

        if (this.searchQuery) {
          Button('✕')
            .width(30)
            .height(30)
            .backgroundColor('transparent')
            .fontColor('#999999')
            .onClick(() => {
              this.searchQuery = '';
              this.searchResults = [];
            })
        }
      }
      .width('100%')
      .height(60)
      .padding({ left: 10, right: 10 })
      .backgroundColor('#FFFFFF')
      .border({ width: { bottom: 1 }, color: '#EEEEEE' })

      // 搜索结果
      if (this.searchQuery && !this.showHistory) {
        if (this.isSearching) {
          Column() {
            Text('搜索中...')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.searchResults.length > 0) {
          List() {
            ForEach(this.searchResults, (article: Article) => {
              ListItem() {
                Column() {
                  Text(article.title)
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                  
                  Text(article.content)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ top: 8 })
                }
                .width('100%')
                .padding(16)
                .onClick(() => {
                  router.pushUrl({
                    url: 'pages/Detail',
                    params: { articleId: article.id }
                  });
                })
              }
            }, (article: Article) => article.id.toString())
          }
          .width('100%')
        } else {
          Column() {
            Text('未找到相关结果')
              .fontSize(16)
              .fontColor('#999999')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        }
      }

      // 搜索历史
      if (this.showHistory && !this.searchQuery) {
        Column() {
          Row() {
            Text('搜索历史')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            
            Blank()
            
            Text('清除')
              .fontSize(14)
              .fontColor('#999999')
              .onClick(() => {
                this.clearSearchHistory();
              })
          }
          .width('100%')
          .padding(16)

          if (this.searchHistory.length > 0) {
            Flex({ wrap: FlexWrap.Wrap, space: 10 }) {
              ForEach(this.searchHistory, (item: string) => {
                Text(item)
                  .fontSize(14)
                  .fontColor('#666666')
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .backgroundColor('#F5F5F5')
                  .borderRadius(16)
                  .onClick(() => {
                    this.onSearchInput(item);
                  })
              }, (item: string) => item)
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
          } else {
            Text('暂无搜索历史')
              .fontSize(14)
              .fontColor('#CCCCCC')
              .width('100%')
              .padding({ left: 16 })
          }
        }
        .width('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
```

---

## 四、图片上传功能

### 4.1 图片选择器 (ImagePicker.ets)

```typescript
import { Logger } from '../utils/Logger';
import { HttpUtil } from '../utils/HttpUtil';
import photoAccessHelper from '@ohos.multimedia.photoAccessHelper';

@Entry
@Component
struct ImagePicker {
  @State selectedImages: string[] = [];
  @State isUploading: boolean = false;
  @State uploadProgress: number = 0;

  private photoHelper: photoAccessHelper.PhotoViewContext | null = null;

  aboutToAppear() {
    this.initPhotoHelper();
  }

  async initPhotoHelper() {
    try {
      this.photoHelper = photoAccessHelper.getPhotoViewContext();
    } catch (error) {
      Logger.error('ImagePicker', '初始化相册失败', error as Error);
    }
  }

  async selectImages() {
    if (!this.photoHelper) {
      Logger.error('ImagePicker', '相册未初始化');
      return;
    }

    try {
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions();
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 9;

      const photoSelectResult = await this.photoHelper.select(photoSelectOptions);
      
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        this.selectedImages = photoSelectResult.photoUris;
        Logger.info('ImagePicker', `选择了${this.selectedImages.length}张图片`);
      }
    } catch (error) {
      Logger.error('ImagePicker', '选择图片失败', error as Error);
    }
  }

  async uploadImages() {
    if (this.selectedImages.length === 0) {
      Logger.warn('ImagePicker', '没有选择图片');
      return;
    }

    this.isUploading = true;
    this.uploadProgress = 0;

    try {
      // 实现图片上传逻辑
      // 这里需要根据实际 API 调整
      for (let i = 0; i < this.selectedImages.length; i++) {
        // 读取图片文件
        // 上传到服务器
        this.uploadProgress = ((i + 1) / this.selectedImages.length) * 100;
      }

      Logger.info('ImagePicker', '上传成功');
    } catch (error) {
      Logger.error('ImagePicker', '上传失败', error as Error);
    } finally {
      this.isUploading = false;
    }
  }

  build() {
    Column() {
      // 图片预览区域
      Flex({ wrap: FlexWrap.Wrap, space: 10 }) {
        ForEach(this.selectedImages, (uri: string, index: number) => {
          Stack() {
            Image(uri)
              .width(100)
              .height(100)
              .objectFit(ImageFit.Cover)
              .borderRadius(8)

            Button('✕')
              .width(24)
              .height(24)
              .backgroundColor('rgba(0, 0, 0, 0.5)')
              .fontColor('#FFFFFF')
              .fontSize(12)
              .position({ x: 80, y: 0 })
              .onClick(() => {
                this.selectedImages.splice(index, 1);
                this.selectedImages = [...this.selectedImages];
              })
          }
          .width(100)
          .height(100)
        }, (uri: string) => uri)

        // 添加按钮
        if (this.selectedImages.length < 9) {
          Button('+')
            .width(100)
            .height(100)
            .backgroundColor('#F5F5F5')
            .fontColor('#999999')
            .fontSize(40)
            .onClick(() => {
              this.selectImages();
            })
        }
      }
      .width('100%')
      .padding(20)

      // 上传进度
      if (this.isUploading) {
        Column() {
          Text(`上传中：${Math.round(this.uploadProgress)}%`)
            .fontSize(14)
            .fontColor('#666666')
          
          Progress({ value: this.uploadProgress, total: 100 })
            .width('100%')
            .height(8)
            .margin({ top: 10 })
        }
        .width('90%')
        .padding(20)
      }

      // 上传按钮
      Button(this.selectedImages.length > 0 ? `上传 (${this.selectedImages.length})` : '选择图片')
        .width('90%')
        .height(50)
        .backgroundColor(this.selectedImages.length > 0 ? '#007DFF' : '#CCCCCC')
        .fontColor('#FFFFFF')
        .fontSize(18)
        .borderRadius(8)
        .enabled(this.selectedImages.length > 0 && !this.isUploading)
        .onClick(() => {
          this.uploadImages();
        })
        .margin({ top: 20 })

      Blank()
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
```

---

*创建时间：2026-03-13*
*版本：1.0.0*
*持续更新中...*
