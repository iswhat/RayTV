# HarmonyOS 6 实战项目模板

## 项目结构

```
MyHarmonyApp/
├── AppScope/
│   ├── app.json5              # 应用全局配置
│   └── resources/
│       └── base/
│           ├── element/
│           │   └── string.json
│           └── media/
│               └── app_icon.png
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── entryability/
│   │   │   │   └── EntryAbility.ets
│   │   │   ├── pages/
│   │   │   │   ├── Index.ets           # 首页
│   │   │   │   ├── Detail.ets          # 详情页
│   │   │   │   └── Settings.ets        # 设置页
│   │   │   ├── components/
│   │   │   │   ├── CustomButton.ets    # 自定义按钮
│   │   │   │   ├── Card.ets            # 卡片组件
│   │   │   │   └── LoadingView.ets     # 加载组件
│   │   │   ├── model/
│   │   │   │   ├── User.ets            # 用户模型
│   │   │   │   └── Article.ets         # 文章模型
│   │   │   ├── utils/
│   │   │   │   ├── HttpUtil.ets        # 网络工具
│   │   │   │   ├── StorageUtil.ets     # 存储工具
│   │   │   │   └── Logger.ets          # 日志工具
│   │   │   └── common/
│   │   │       └── Constants.ets       # 常量定义
│   │   ├── resources/
│   │   │   └── base/
│   │   │       ├── element/
│   │   │       │   ├── string.json
│   │   │       │   └── color.json
│   │   │       ├── media/
│   │   │       └── profile/
│   │   │           └── main_pages.json
│   │   └── module.json5
│   └── oh-package.json5
└── oh-package.json5
```

---

## 核心文件模板

### 1. 应用入口 (EntryAbility.ets)

```typescript
import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import Want from '@ohos.app.ability.Want';
import window from '@ohos.window';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    console.info('[EntryAbility] onCreate');
  }

  onDestroy(): void {
    console.info('[EntryAbility] onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    console.info('[EntryAbility] onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        console.error('[EntryAbility] loadContent failed:', JSON.stringify(err));
        return;
      }
      console.info('[EntryAbility] loadContent success');
    });
  }

  onWindowStageDestroy(): void {
    console.info('[EntryAbility] onWindowStageDestroy');
  }

  onForeground(): void {
    console.info('[EntryAbility] onForeground');
  }

  onBackground(): void {
    console.info('[EntryAbility] onBackground');
  }
}
```

### 2. 首页模板 (Index.ets)

```typescript
import router from '@ohos.router';
import { Logger } from '../utils/Logger';
import { HttpUtil } from '../utils/HttpUtil';
import { CustomButton } from '../components/CustomButton';
import { Card } from '../components/Card';
import { Article } from '../model/Article';

@Entry
@Component
struct Index {
  @State title: string = 'HarmonyOS 应用';
  @State articles: Article[] = [];
  @State isLoading: boolean = false;
  @State errorMessage: string = '';
  @State refreshCount: number = 0;

  aboutToAppear() {
    Logger.info('Index', '页面加载');
    this.loadArticles();
  }

  async loadArticles() {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 模拟网络请求
      await this.fetchArticles();
    } catch (error) {
      Logger.error('Index', '加载失败', error as Error);
      this.errorMessage = '加载失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  async fetchArticles() {
    // 模拟延迟
    await new Promise(resolve => setTimeout(resolve, 1000));
    
    // 模拟数据
    this.articles = [
      { id: 1, title: 'HarmonyOS 6 新特性', content: '探索最新的 HarmonyOS 6...', author: '开发者', createTime: Date.now() },
      { id: 2, title: 'ArkTS 开发指南', content: 'ArkTS 语言快速入门...', author: '专家', createTime: Date.now() },
      { id: 3, title: 'ArkUI 组件详解', content: '常用组件使用教程...', author: '讲师', createTime: Date.now() }
    ];
    
    this.refreshCount++;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text(this.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)

      // 刷新按钮
      CustomButton({
        text: `刷新 (${this.refreshCount})`,
        backgroundColor: '#007DFF',
        onClick: () => {
          this.loadArticles();
        }
      })
      .margin({ top: 20 })

      // 加载状态
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }

      // 错误状态
      if (this.errorMessage) {
        Column() {
          Text(this.errorMessage)
            .fontSize(16)
            .fontColor('#FF0000')
          CustomButton({
            text: '重试',
            backgroundColor: '#4CAF50',
            onClick: () => {
              this.loadArticles();
            }
          })
          .margin({ top: 10 })
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }

      // 文章列表
      if (!this.isLoading && !this.errorMessage && this.articles.length > 0) {
        List() {
          ForEach(this.articles, (article: Article) => {
            ListItem() {
              Card({
                title: article.title,
                content: article.content,
                author: article.author,
                onClick: () => {
                  router.pushUrl({
                    url: 'pages/Detail',
                    params: { articleId: article.id }
                  });
                }
              })
            }
          }, (article: Article) => article.id.toString())
        }
        .width('100%')
        .padding(10)
      }

      // 空状态
      if (!this.isLoading && !this.errorMessage && this.articles.length === 0) {
        Column() {
          Text('暂无文章')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
```

### 3. 自定义按钮组件 (CustomButton.ets)

```typescript
@Component
export struct CustomButton {
  @Link text: string;
  @Link onClick: () => void;
  @Link backgroundColor: string = '#007DFF';
  @Link width: string = '80%';
  @Link height: number = 50;

  build() {
    Button(this.text)
      .width(this.width)
      .height(this.height)
      .backgroundColor(this.backgroundColor)
      .fontColor('#FFFFFF')
      .fontSize(16)
      .borderRadius(8)
      .onClick(() => {
        try {
          this.onClick();
        } catch (error) {
          console.error('[CustomButton] 点击错误:', error);
        }
      })
      .stateEffect(true)
      .hoverEffect(true)
  }
}
```

### 4. 卡片组件 (Card.ets)

```typescript
import { Logger } from '../utils/Logger';

@Component
export struct Card {
  @Link title: string;
  @Link content: string;
  @Link author?: string;
  @Link onClick?: () => void;

  build() {
    Stack() {
      // 卡片背景
      Rectangle()
        .width('100%')
        .height('auto')
        .radius(12)
        .fill('#FFFFFF')
        .shadow({
          offsetX: 0,
          offsetY: 2,
          blurRadius: 8,
          color: 'rgba(0, 0, 0, 0.1)'
        })

      // 卡片内容
      Column() {
        // 标题
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .width('100%')
          .maxLines(1)
          .overflow(TextOverflow.Ellipsis)

        // 内容
        Text(this.content)
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')
          .margin({ top: 8 })
          .maxLines(2)
          .overflow(TextOverflow.Ellipsis)
          .lineHeight(20)

        // 作者信息
        if (this.author) {
          Row() {
            Text(`作者：${this.author}`)
              .fontSize(12)
              .fontColor('#999999')
          }
          .width('100%')
          .margin({ top: 12 })
          .justifyContent(FlexAlign.End)
        }
      }
      .width('100%')
      .padding(16)
      .onClick(() => {
        Logger.info('Card', '卡片点击');
        if (this.onClick) {
          this.onClick();
        }
      })
    }
    .width('100%')
    .margin({ bottom: 12 })
  }
}
```

### 5. 数据模型 (Article.ets)

```typescript
export class Article {
  id: number;
  title: string;
  content: string;
  author: string;
  createTime: number;
  updateTime?: number;
  tags?: string[];
  imageUrl?: string;

  constructor(
    id: number,
    title: string,
    content: string,
    author: string,
    createTime: number
  ) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.author = author;
    this.createTime = createTime;
  }

  // 格式化创建时间
  getFormattedCreateTime(): string {
    const date = new Date(this.createTime);
    return `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;
  }

  // 从 JSON 创建实例
  static fromJson(json: Record<string, any>): Article {
    return new Article(
      json.id,
      json.title,
      json.content,
      json.author,
      json.createTime
    );
  }

  // 转换为 JSON
  toJson(): Record<string, any> {
    return {
      id: this.id,
      title: this.title,
      content: this.content,
      author: this.author,
      createTime: this.createTime
    };
  }
}
```

### 6. 网络工具类 (HttpUtil.ets)

```typescript
import http from '@ohos.net.http';
import { Logger } from './Logger';

export enum HttpMethod {
  GET = 'GET',
  POST = 'POST',
  PUT = 'PUT',
  DELETE = 'DELETE'
}

export interface HttpResponse<T> {
  code: number;
  data: T;
  message: string;
}

export class HttpUtil {
  private static readonly BASE_URL = 'https://api.example.com';
  private static readonly TIMEOUT = 30000; // 30 秒

  /**
   * GET 请求
   */
  static async get<T>(url: string, params?: Record<string, string>): Promise<HttpResponse<T>> {
    return this.request<T>(HttpMethod.GET, url, params);
  }

  /**
   * POST 请求
   */
  static async post<T>(url: string, data?: Record<string, any>): Promise<HttpResponse<T>> {
    return this.request<T>(HttpMethod.POST, url, undefined, data);
  }

  /**
   * 通用请求方法
   */
  private static async request<T>(
    method: HttpMethod,
    url: string,
    params?: Record<string, string>,
    body?: Record<string, any>
  ): Promise<HttpResponse<T>> {
    const httpRequest = http.createHttp();
    const fullUrl = params ? `${url}?${this.buildQueryString(params)}` : url;

    const requestOptions = {
      method: method as http.RequestMethod,
      readTimeout: this.TIMEOUT,
      connectTimeout: this.TIMEOUT,
      header: {
        'Content-Type': 'application/json'
      },
      extraData: body ? {
        body: JSON.stringify(body)
      } : undefined
    };

    try {
      Logger.info('HttpUtil', `请求：${method} ${fullUrl}`);
      
      const response = await httpRequest.request(
        this.BASE_URL + fullUrl,
        requestOptions
      );

      if (response.responseCode === 200) {
        const result = JSON.parse(response.result.toString()) as HttpResponse<T>;
        Logger.info('HttpUtil', `响应成功：${JSON.stringify(result)}`);
        return result;
      } else {
        Logger.error('HttpUtil', `请求失败：${response.responseCode}`);
        throw new Error(`HTTP Error: ${response.responseCode}`);
      }
    } catch (error) {
      Logger.error('HttpUtil', '请求异常', error as Error);
      throw error;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 构建查询字符串
   */
  private static buildQueryString(params: Record<string, string>): string {
    return Object.entries(params)
      .map(([key, value]) => `${encodeURIComponent(key)}=${encodeURIComponent(value)}`)
      .join('&');
  }
}
```

### 7. 日志工具类 (Logger.ets)

```typescript
import hilog from '@ohos.hilog';

export class Logger {
  private static readonly DOMAIN = 0xFF00;
  private static readonly PREFIX = 'MyApp';
  private static readonly ENABLE_DEBUG = true; // 生产环境设为 false

  static debug(tag: string, message: string, ...args: any[]): void {
    if (this.ENABLE_DEBUG) {
      hilog.debug(this.DOMAIN, `${this.PREFIX}-${tag}`, message, args);
    }
  }

  static info(tag: string, message: string, ...args: any[]): void {
    hilog.info(this.DOMAIN, `${this.PREFIX}-${tag}`, message, args);
  }

  static warn(tag: string, message: string, ...args: any[]): void {
    hilog.warn(this.DOMAIN, `${this.PREFIX}-${tag}`, message, args);
  }

  static error(tag: string, message: string, error?: Error): void {
    const errorMsg = error ? `${message} - ${error.message}\n${error.stack || ''}` : message;
    hilog.error(this.DOMAIN, `${this.PREFIX}-${tag}`, errorMsg);
  }

  static performance(tag: string, startTime: number, action: string): void {
    const duration = Date.now() - startTime;
    this.info(tag, `${action} 耗时：${duration}ms`);
  }
}
```

### 8. 存储工具类 (StorageUtil.ets)

```typescript
import dataPreferences from '@ohos.data.preferences';
import { Logger } from './Logger';

export class StorageUtil {
  private static readonly PREFS_NAME = 'app_preferences';
  private static prefs: dataPreferences.Preferences | null = null;

  /**
   * 初始化 Preferences
   */
  private static async initPrefs(context: any): Promise<void> {
    if (!this.prefs) {
      this.prefs = await dataPreferences.getPreferences(context, this.PREFS_NAME);
    }
  }

  /**
   * 存储字符串
   */
  static async setString(context: any, key: string, value: string): Promise<void> {
    await this.initPrefs(context);
    if (this.prefs) {
      await this.prefs.put(key, value);
      await this.prefs.flush();
      Logger.info('StorageUtil', `存储字符串：${key}`);
    }
  }

  /**
   * 获取字符串
   */
  static async getString(context: any, key: string, defaultValue: string = ''): Promise<string> {
    await this.initPrefs(context);
    if (this.prefs) {
      const value = await this.prefs.get(key, defaultValue) as string;
      return value;
    }
    return defaultValue;
  }

  /**
   * 存储对象（序列化）
   */
  static async setObject<T>(context: any, key: string, value: T): Promise<void> {
    await this.setString(context, key, JSON.stringify(value));
  }

  /**
   * 获取对象（反序列化）
   */
  static async getObject<T>(context: any, key: string, defaultValue: T): Promise<T> {
    const json = await this.getString(context, key, '');
    if (json) {
      try {
        return JSON.parse(json) as T;
      } catch (error) {
        Logger.error('StorageUtil', '解析对象失败', error as Error);
      }
    }
    return defaultValue;
  }

  /**
   * 删除键
   */
  static async remove(context: any, key: string): Promise<void> {
    await this.initPrefs(context);
    if (this.prefs) {
      await this.prefs.delete(key);
      await this.prefs.flush();
      Logger.info('StorageUtil', `删除键：${key}`);
    }
  }

  /**
   * 清空所有
   */
  static async clear(context: any): Promise<void> {
    await this.initPrefs(context);
    if (this.prefs) {
      await this.prefs.clear();
      await this.prefs.flush();
      Logger.info('StorageUtil', '清空所有存储');
    }
  }
}
```

### 9. 常量定义 (Constants.ets)

```typescript
export class Constants {
  // API 相关
  static readonly API_BASE_URL = 'https://api.example.com';
  static readonly API_VERSION = 'v1';
  static readonly API_TIMEOUT = 30000;

  // 存储键
  static readonly STORAGE_KEY_TOKEN = 'token';
  static readonly STORAGE_KEY_USER = 'user';
  static readonly STORAGE_KEY_THEME = 'theme';

  // 路由
  static readonly ROUTE_INDEX = 'pages/Index';
  static readonly ROUTE_DETAIL = 'pages/Detail';
  static readonly ROUTE_SETTINGS = 'pages/Settings';

  // 颜色
  static readonly COLOR_PRIMARY = '#007DFF';
  static readonly COLOR_SUCCESS = '#4CAF50';
  static readonly COLOR_WARNING = '#FF9800';
  static readonly COLOR_ERROR = '#F44336';
  static readonly COLOR_TEXT_PRIMARY = '#333333';
  static readonly COLOR_TEXT_SECONDARY = '#666666';

  // 尺寸
  static readonly SIZE_PADDING_SMALL = 8;
  static readonly SIZE_PADDING_NORMAL = 16;
  static readonly SIZE_PADDING_LARGE = 24;
  static readonly SIZE_BORDER_RADIUS = 8;

  // 分页
  static readonly PAGE_SIZE = 20;
  static readonly PAGE_INITIAL = 1;
}
```

---

## 使用说明

### 1. 创建项目

```bash
# 在 DevEco Studio 中
File -> New -> New Project -> Empty Ability
# 项目名称：MyHarmonyApp
# 语言：ArkTS
# API 版本：API 12+
```

### 2. 复制模板文件

将上述文件复制到对应目录

### 3. 修改配置

- `module.json5` - 修改应用包名、权限等
- `app.json5` - 修改应用名称、版本等
- `HttpUtil.ets` - 修改 API 基础 URL

### 4. 运行项目

```bash
# 连接模拟器或真机
# 点击 Run 按钮
```

---

## 下一步扩展

- [ ] 添加用户登录模块
- [ ] 添加数据库支持
- [ ] 添加图片上传功能
- [ ] 添加推送通知
- [ ] 添加深色模式支持
- [ ] 添加国际化支持

---

*创建时间：2026-03-12*
*版本：1.0.0*
