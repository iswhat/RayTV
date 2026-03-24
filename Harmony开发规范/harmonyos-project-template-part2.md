# HarmonyOS 6 实战项目模板（续）

## 补充文件模板

### 10. 详情页 (Detail.ets)

```typescript
import router from '@ohos.router';
import { Logger } from '../utils/Logger';
import { Article } from '../model/Article';

@Entry
@Component
struct Detail {
  @State articleId: number = 0;
  @State article: Article | null = null;
  @State isLoading: boolean = true;
  @State errorMessage: string = '';
  @State isLiked: boolean = false;
  @State likeCount: number = 0;

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, any>;
    if (params && params.articleId) {
      this.articleId = typeof params.articleId === 'string' 
        ? parseInt(params.articleId) 
        : params.articleId;
      Logger.info('Detail', `文章 ID: ${this.articleId}`);
      this.loadArticle();
    } else {
      this.errorMessage = '未找到文章信息';
      this.isLoading = false;
    }
  }

  async loadArticle() {
    this.isLoading = true;
    this.errorMessage = '';
    
    try {
      // 模拟网络请求
      await new Promise(resolve => setTimeout(resolve, 800));
      
      // 模拟数据
      this.article = {
        id: this.articleId,
        title: `HarmonyOS 6 新特性详解 - ${this.articleId}`,
        content: 'HarmonyOS 6 带来了众多新特性，包括更流畅的动画效果、更强大的分布式能力、更智能的 AI 功能等。本文将详细介绍这些新特性的使用方法和最佳实践...',
        author: '技术专家',
        createTime: Date.now(),
        tags: ['HarmonyOS', 'ArkTS', '开发教程']
      };
      
      this.likeCount = Math.floor(Math.random() * 1000);
    } catch (error) {
      Logger.error('Detail', '加载失败', error as Error);
      this.errorMessage = '加载失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  toggleLike() {
    this.isLiked = !this.isLiked;
    this.likeCount += this.isLiked ? 1 : -1;
    Logger.info('Detail', `点赞状态：${this.isLiked}, 数量：${this.likeCount}`);
  }

  build() {
    Column() {
      // 导航栏
      Row() {
        Button() {
          Text('‹')
            .fontSize(30)
            .fontColor('#333333')
        }
        .width(50)
        .height(50)
        .backgroundColor('transparent')
        .onClick(() => {
          router.back();
        })

        Text('文章详情')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()

        Button() {
          Text('⋯')
            .fontSize(24)
            .fontColor('#333333')
        }
        .width(50)
        .height(50)
        .backgroundColor('transparent')
      }
      .width('100%')
      .height(60)
      .padding({ left: 10, right: 10 })
      .backgroundColor('#FFFFFF')
      .justifyContent(FlexAlign.Center)
      .border({ width: { bottom: 1 }, color: '#EEEEEE' })

      // 内容区域
      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(16)
            .fontColor('#666666')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        Column() {
          Text(this.errorMessage)
            .fontSize(16)
            .fontColor('#FF0000')
          Button('重试')
            .margin({ top: 20 })
            .onClick(() => {
              this.loadArticle();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.article) {
        Scroll() {
          Column() {
            // 文章标题
            Text(this.article.title)
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 20, right: 20, top: 20 })

            // 作者信息
            Row() {
              Text(this.article.author)
                .fontSize(14)
                .fontColor('#666666')
              
              Text(' · ')
                .fontSize(14)
                .fontColor('#999999')
              
              Text(new Date(this.article.createTime).toLocaleDateString())
                .fontSize(14)
                .fontColor('#999999')
            }
            .width('100%')
            .padding({ left: 20, right: 20, top: 12 })

            // 标签
            if (this.article.tags) {
              Row({ space: 8 }) {
                ForEach(this.article.tags, (tag: string) => {
                  Text(`#${tag}`)
                    .fontSize(12)
                    .fontColor('#007DFF')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('#E6F0FF')
                    .borderRadius(4)
                }, (tag: string) => tag)
              }
              .width('100%')
              .padding({ left: 20, right: 20, top: 12 })
            }

            // 文章内容
            Text(this.article.content)
              .fontSize(16)
              .fontColor('#333333')
              .width('100%')
              .padding({ left: 20, right: 20, top: 20 })
              .lineHeight(28)

            // 点赞区域
            Row() {
              Blank()
              
              Row({ space: 8 }) {
                Text(this.isLiked ? '❤️' : '🤍')
                  .fontSize(24)
                
                Text(`${this.likeCount}`)
                  .fontSize(16)
                  .fontColor('#666666')
              }
              .padding({ left: 20, right: 20, top: 16, bottom: 16 })
              .onClick(() => {
                this.toggleLike();
              })
            }
            .width('100%')
            .border({ width: { top: 1 }, color: '#EEEEEE' })
          }
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
```

### 11. 设置页 (Settings.ets)

```typescript
import router from '@ohos.router';
import { Logger } from '../utils/Logger';
import { StorageUtil } from '../utils/StorageUtil';
import { Constants } from '../common/Constants';

interface SettingItem {
  id: string;
  title: string;
  subtitle?: string;
  type: 'link' | 'switch' | 'select';
  value?: any;
  onClick?: () => void;
  onToggle?: (isOn: boolean) => void;
}

@Entry
@Component
struct Settings {
  @State darkMode: boolean = false;
  @State notifications: boolean = true;
  @State autoPlay: boolean = false;
  @State cacheSize: string = '128 MB';
  
  private settingGroups: Array<{
    title: string;
    items: SettingItem[];
  }> = [];

  aboutToAppear() {
    this.loadSettings();
    this.initSettingGroups();
  }

  async loadSettings() {
    try {
      const context = getContext();
      this.darkMode = await StorageUtil.getString(context, Constants.STORAGE_KEY_THEME, 'light') === 'dark';
      this.notifications = await StorageUtil.getObject(context, 'notifications', true);
      this.autoPlay = await StorageUtil.getObject(context, 'auto_play', false);
    } catch (error) {
      Logger.error('Settings', '加载设置失败', error as Error);
    }
  }

  async saveSetting(key: string, value: any) {
    try {
      const context = getContext();
      if (typeof value === 'string') {
        await StorageUtil.setString(context, key, value);
      } else {
        await StorageUtil.setObject(context, key, value);
      }
      Logger.info('Settings', `保存设置：${key} = ${value}`);
    } catch (error) {
      Logger.error('Settings', '保存设置失败', error as Error);
    }
  }

  initSettingGroups() {
    this.settingGroups = [
      {
        title: '通用',
        items: [
          {
            id: 'dark_mode',
            title: '深色模式',
            type: 'switch',
            value: this.darkMode,
            onToggle: (isOn: boolean) => {
              this.darkMode = isOn;
              this.saveSetting(Constants.STORAGE_KEY_THEME, isOn ? 'dark' : 'light');
            }
          },
          {
            id: 'notifications',
            title: '消息通知',
            subtitle: '接收推送通知',
            type: 'switch',
            value: this.notifications,
            onToggle: (isOn: boolean) => {
              this.notifications = isOn;
              this.saveSetting('notifications', isOn);
            }
          },
          {
            id: 'auto_play',
            title: '自动播放',
            subtitle: 'Wi-Fi 环境下自动播放视频',
            type: 'switch',
            value: this.autoPlay,
            onToggle: (isOn: boolean) => {
              this.autoPlay = isOn;
              this.saveSetting('auto_play', isOn);
            }
          }
        ]
      },
      {
        title: '存储',
        items: [
          {
            id: 'cache',
            title: '清除缓存',
            subtitle: `当前缓存：${this.cacheSize}`,
            type: 'link',
            onClick: () => {
              Logger.info('Settings', '清除缓存');
              // 实现清除缓存逻辑
            }
          }
        ]
      },
      {
        title: '关于',
        items: [
          {
            id: 'version',
            title: '版本号',
            subtitle: 'v1.0.0',
            type: 'link'
          },
          {
            id: 'privacy',
            title: '隐私政策',
            type: 'link',
            onClick: () => {
              Logger.info('Settings', '查看隐私政策');
            }
          },
          {
            id: 'terms',
            title: '用户协议',
            type: 'link',
            onClick: () => {
              Logger.info('Settings', '查看用户协议');
            }
          }
        ]
      }
    ];
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('‹')
            .fontSize(30)
            .fontColor('#333333')
        }
        .width(50)
        .height(50)
        .backgroundColor('transparent')
        .onClick(() => {
          router.back();
        })

        Text('设置')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')

        Blank()
      }
      .width('100%')
      .height(60)
      .padding({ left: 10, right: 10 })
      .backgroundColor('#F5F5F5')
      .justifyContent(FlexAlign.Center)

      // 设置列表
      Scroll() {
        Column() {
          ForEach(this.settingGroups, (group, groupIndex) => {
            Column() {
              // 组标题
              Text(group.title)
                .fontSize(14)
                .fontColor('#999999')
                .width('100%')
                .padding({ left: 20, top: 16, bottom: 8 })

              // 设置项
              ForEach(group.items, (item: SettingItem) => {
                Row() {
                  Column() {
                    Text(item.title)
                      .fontSize(16)
                      .fontColor('#333333')
                    
                    if (item.subtitle) {
                      Text(item.subtitle)
                        .fontSize(13)
                        .fontColor('#999999')
                        .margin({ top: 4 })
                    }
                  }
                  .alignItems(HorizontalAlign.Start)
                  
                  Blank()
                  
                  // 根据类型显示不同控件
                  if (item.type === 'switch') {
                    Switch({ isOn: item.value })
                      .onChange((isOn: boolean) => {
                        if (item.onToggle) {
                          item.onToggle(isOn);
                        }
                      })
                  } else if (item.type === 'link') {
                    Row() {
                      Text('›')
                        .fontSize(24)
                        .fontColor('#CCCCCC')
                    }
                    .onClick(() => {
                      if (item.onClick) {
                        item.onClick();
                      }
                    })
                  }
                }
                .width('100%')
                .height(70)
                .padding({ left: 20, right: 20 })
                .backgroundColor('#FFFFFF')
                .onClick(() => {
                  if (item.type === 'link' && item.onClick) {
                    item.onClick();
                  }
                })
              }, (item: SettingItem) => item.id)
            }
            .width('100%')
            .backgroundColor('#F5F5F5')
          }, (group, index) => group.title)

          // 底部间距
          Blank()
            .height(40)
        }
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
```

### 12. 加载组件 (LoadingView.ets)

```typescript
@Component
export struct LoadingView {
  @Link text: string = '加载中...';
  @Link color: string = '#007DFF';
  @Link size: number = 40;

  @State rotation: number = 0;

  aboutToAppear() {
    // 启动旋转动画
    this.startAnimation();
  }

  async startAnimation() {
    while (true) {
      await new Promise(resolve => setTimeout(resolve, 16));
      this.rotation = (this.rotation + 10) % 360;
    }
  }

  build() {
    Column() {
      // 自定义加载动画
      Stack() {
        ForEach([0, 1, 2, 3, 4, 5], (i: number) => {
          Rectangle()
            .width(4)
            .height(12)
            .fill(this.color)
            .opacity(1 - i * 0.15)
            .rotate(this.rotation + i * 60)
            .position({
              x: Math.cos((this.rotation + i * 60) * Math.PI / 180) * (this.size / 2),
              y: Math.sin((this.rotation + i * 60) * Math.PI / 180) * (this.size / 2)
            })
        })
      }
      .width(this.size * 2)
      .height(this.size * 2)

      Text(this.text)
        .fontSize(14)
        .fontColor('#666666')
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
```

### 13. 用户模型 (User.ets)

```typescript
export class User {
  id: number;
  username: string;
  email: string;
  avatar?: string;
  phone?: string;
  createdAt: number;
  updatedAt?: number;

  constructor(
    id: number,
    username: string,
    email: string,
    createdAt: number
  ) {
    this.id = id;
    this.username = username;
    this.email = email;
    this.createdAt = createdAt;
  }

  // 获取显示名称
  getDisplayName(): string {
    return this.username || this.email.split('@')[0];
  }

  // 获取头像 URL
  getAvatarUrl(): string {
    return this.avatar || '';
  }

  // 从 JSON 创建实例
  static fromJson(json: Record<string, any>): User {
    return new User(
      json.id,
      json.username,
      json.email,
      json.createdAt
    );
  }

  // 转换为 JSON
  toJson(): Record<string, any> {
    return {
      id: this.id,
      username: this.username,
      email: this.email,
      avatar: this.avatar,
      phone: this.phone,
      createdAt: this.createdAt
    };
  }

  // 检查是否已登录
  isLoggedIn(): boolean {
    return this.id > 0;
  }
}
```

---

## 配置文件模板

### 14. 应用配置 (app.json5)

```json5
{
  "app": {
    "bundleName": "com.example.myharmonyapp",
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:app_icon",
    "label": "$string:app_name"
  }
}
```

### 15. 模块配置 (module.json5)

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "description": "$string:module_desc",
    "mainElement": "EntryAbility",
    "deviceTypes": [
      "phone",
      "tablet"
    ],
    "deliveryWithInstall": true,
    "installationFree": false,
    "pages": "$profile:main_pages",
    "abilities": [
      {
        "name": "EntryAbility",
        "srcEntry": "./ets/entryability/EntryAbility.ets",
        "description": "$string:EntryAbility_desc",
        "icon": "$media:icon",
        "label": "$string:EntryAbility_label",
        "startWindowIcon": "$media:icon",
        "startWindowBackground": "$color:start_window_background",
        "exported": true,
        "skills": [
          {
            "entities": [
              "entity.system.home"
            ],
            "actions": [
              "action.system.home"
            ]
          }
        ]
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

### 16. 页面路由配置 (main_pages.json)

```json
{
  "src": [
    "pages/Index",
    "pages/Detail",
    "pages/Settings"
  ]
}
```

### 17. 字符串资源 (string.json)

```json5
{
  "string": [
    {
      "name": "app_name",
      "value": "我的 Harmony 应用"
    },
    {
      "name": "module_desc",
      "value": "应用主模块"
    },
    {
      "name": "EntryAbility_desc",
      "value": "应用入口"
    },
    {
      "name": "EntryAbility_label",
      "value": "我的应用"
    }
  ]
}
```

### 18. 颜色资源 (color.json)

```json5
{
  "color": [
    {
      "name": "start_window_background",
      "value": "#FFFFFF"
    },
    {
      "name": "primary_color",
      "value": "#007DFF"
    },
    {
      "name": "text_primary",
      "value": "#333333"
    },
    {
      "name": "text_secondary",
      "value": "#666666"
    },
    {
      "name": "background",
      "value": "#F5F5F5"
    }
  ]
}
```

---

## 快速开始指南

### 步骤 1: 创建项目

1. 打开 DevEco Studio
2. File → New → New Project
3. 选择 "Empty Ability"
4. 填写项目信息：
   - Project name: MyHarmonyApp
   - Language: ArkTS
   - API version: API 12+
   - Model: Stage

### 步骤 2: 复制模板文件

将上述文件复制到项目对应目录

### 步骤 3: 修改配置

1. 修改 `app.json5` 中的 bundleName
2. 修改 `string.json` 中的应用名称
3. 修改 `HttpUtil.ets` 中的 API 地址

### 步骤 4: 运行项目

1. 连接模拟器或真机
2. 点击 Run 按钮
3. 查看应用运行效果

---

## 常用命令

### 构建项目
```bash
# 在 DevEco Studio 中
Build → Build Hap(s) / APP(s) → Build Hap(s)
```

### 签名配置
```bash
# 在 DevEco Studio 中
File → Project Structure → Signing Configs
```

### 打包发布
```bash
# 在 DevEco Studio 中
Build → Build Hap(s) / APP(s) → Build APP(s)
```

---

*创建时间：2026-03-12*
*更新时间：2026-03-13*
*版本：1.1.0*
