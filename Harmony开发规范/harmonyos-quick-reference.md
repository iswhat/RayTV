# HarmonyOS 6 ArkTS + ArkUI 专家级快速参考手册

## 🚀 48 小时速成计划

### Day 1 - 上午（0-6 小时）：核心基础突击
- [x] ArkTS 语言核心语法（TypeScript 超集特性）
- [x] 声明式 UI 编程范式理解
- [x] 项目结构深度解析
- [x] 基础组件快速掌握（Text, Button, Column, Row, Stack, List）
- [x] 状态管理核心（@State, @Prop, @Link, @Watch）

### Day 1 - 下午（6-12 小时）：ArkUI 实战
- [ ] 布局系统精通（Flex, Grid, RelativeContainer）
- [ ] 事件处理与交互
- [ ] 页面路由与导航
- [ ] 实战 1：快速完成一个完整页面

### Day 1 - 晚上（12-18 小时）：核心能力突破
- [ ] 网络请求（http 模块）
- [ ] 数据持久化（Preferences, 关系型数据库）
- [ ] 异步编程模型
- [ ] 实战 2：带网络请求的应用

### Day 2 - 上午（18-30 小时）：高级主题
- [ ] 自定义组件封装
- [ ] 动画系统
- [ ] 性能优化要点
- [ ] 常见问题排查技巧
- [ ] 实战 3：优化与调试

### Day 2 - 下午（30-42 小时）：项目实战
- [ ] 完整项目开发
- [ ] 代码审查与优化
- [ ] 最佳实践应用

### Day 2 - 晚上（42-48 小时）：专家级收尾
- [ ] 复杂问题解决方案整理
- [ ] 知识库构建
- [ ] 常见问题 FAQ 整理
- [ ] 准备接手实际项目

---

## 一、ArkTS 核心语法

### 1.1 装饰器系统

```typescript
// 组件装饰器
@Entry          // 标记为应用入口页面
@Component      // 声明为自定义组件
@Builder        // 声明自定义构建函数

// 状态管理装饰器
@State          // 组件内部私有状态
@Prop           // 父子单向同步（深拷贝）
@Link           // 父子双向同步（引用传递）
@Watch          // 状态变化监听
@Provide/@Consume // 跨层级状态共享
@Observed       // 观察类实例
@ObjectLink     // 嵌套对象观察

// 生命周期装饰器
aboutToAppear()  // 组件创建后执行
aboutToDisappear() // 组件销毁前执行
```

### 1.2 状态管理对比表

| 装饰器 | 数据流向 | 初始化要求 | 传递方式 | 使用场景 |
|--------|----------|------------|----------|----------|
| @State | 组件内部 | 必须本地初始化 | - | 组件私有状态 |
| @Prop | 父→子（单向） | 可选本地初始化 | 深拷贝 | 父传子，子不需回传 |
| @Link | 父↔子（双向） | 禁止本地初始化 | 引用传递 | 父子双向同步 |
| @Watch | 监听回调 | 配合其他装饰器 | - | 状态变化时执行额外逻辑 |

### 1.3 状态管理示例

```typescript
// @State - 组件内部状态
@Entry
@Component
struct Counter {
  @State count: number = 0;
  
  build() {
    Column() {
      Text(`计数：${this.count}`)
      Button('增加')
        .onClick(() => {
          this.count++; // 触发 UI 刷新
        })
    }
  }
}

// @Prop - 父子单向同步
@Component
struct Child {
  @Prop value: number = 0; // 可本地初始化
  
  build() {
    Text(`子组件：${this.value}`)
  }
}

@Entry
@Component
struct Parent {
  @State parentValue: number = 10;
  
  build() {
    Column() {
      Child({ value: this.parentValue }) // 父传子
    }
  }
}

// @Link - 父子双向同步
@Component
struct LinkChild {
  @Link value: number; // 禁止本地初始化！
  
  build() {
    Button('修改')
      .onClick(() => {
        this.value++; // 父组件同步更新
      })
  }
}

@Entry
@Component
struct LinkParent {
  @State value: number = 0;
  
  build() {
    Column() {
      LinkChild({ value: $value }) // 必须加 $ 传递引用
    }
  }
}

// @Watch - 状态变化监听
@Entry
@Component
struct WatchDemo {
  @State @Watch('onCountChange') count: number = 0;
  @State log: string = '';
  
  onCountChange() {
    this.log = `计数变为：${this.count}`;
    // 禁止：this.count++ （会无限循环）
  }
  
  build() {
    Column() {
      Text(this.log)
      Button('增加')
        .onClick(() => {
          this.count++;
        })
    }
  }
}
```

---

## 二、ArkUI 基础组件

### 2.1 布局容器

```typescript
// Column - 垂直布局
Column({ space: 10 }) {
  Text('Item 1')
  Text('Item 2')
}
.width('100%')
.justifyContent(FlexAlign.Center) // 主轴对齐
.alignItems(HorizontalAlign.Center) // 交叉轴对齐

// Row - 水平布局
Row({ space: 20 }) {
  Text('Left')
  Text('Right')
}
.justifyContent(FlexAlign.SpaceBetween)

// Stack - 层叠布局
Stack() {
  Image($r('app.media.bg'))
  Text('覆盖文字')
    .position({ x: 50, y: 50 })
}

// Flex - 弹性布局
Flex({ direction: FlexDirection.Row, wrap: FlexWrap.Wrap }) {
  ForEach(items, (item) => {
    Text(item)
  })
}

// List - 列表
List() {
  ForEach(data, (item) => {
    ListItem() {
      Text(item.name)
    }
  })
}
.divider({ strokeWidth: 1, color: '#CCCCCC' })

// Grid - 网格
Grid() {
  ForEach(items, (item) => {
    GridItem() {
      Text(item)
    }
  })
}
.columnsTemplate('1fr 1fr 1fr') // 3 列
```

### 2.2 常用组件

```typescript
// Text - 文本
Text('Hello')
  .fontSize(20)
  .fontWeight(FontWeight.Bold)
  .fontColor('#333333')
  .maxLines(2)
  .overflow(TextOverflow.Ellipsis)

// Button - 按钮
Button('点击')
  .width(120)
  .height(50)
  .backgroundColor('#007DFF')
  .fontColor('#FFFFFF')
  .onClick(() => {
    // 点击处理
  })

// TextField - 输入框
TextField({ placeholder: '请输入' })
  .onChange((value) => {
    this.inputValue = value;
  })
  .type(InputType.Password)

// Image - 图片
Image($r('app.media.icon'))
  .width(100)
  .height(100)
  .objectFit(ImageFit.Cover)
  .borderRadius(10)

// Switch - 开关
Switch({ isOn: this.isOn })
  .onChange((isOn) => {
    this.isOn = isOn;
  })

// Checkbox - 复选框
Checkbox({ name: '选项', group: 'group1' })
  .select(this.isChecked)
  .onChange((isChecked) => {
    this.isChecked = isChecked;
  })

// Progress - 进度条
Progress({ value: this.progress, total: 100 })
  .color('#007DFF')

// Slider - 滑块
Slider({ value: this.sliderValue, min: 0, max: 100 })
  .onChange((value) => {
    this.sliderValue = value;
  })
```

---

## 三、页面路由与导航

```typescript
import router from '@ohos.router';

// 跳转到新页面
router.pushUrl({
  url: 'pages/DetailPage',
  params: { id: 123, name: '测试' }
});

// 返回上一页
router.back();

// 替换当前页面
router.replaceUrl({
  url: 'pages/HomePage'
});

// 接收参数
@Entry
@Component
struct DetailPage {
  @Link id: number = 0;
  @Link name: string = '';
  
  aboutToAppear() {
    const params = router.getParams() as Record<string, any>;
    this.id = params['id'] || 0;
    this.name = params['name'] || '';
  }
  
  build() {
    Column() {
      Text(`ID: ${this.id}`)
      Text(`名称：${this.name}`)
    }
  }
}
```

---

## 四、网络请求

```typescript
import http from '@ohos.net.http';

// HTTP GET 请求
async function fetchData() {
  let httpRequest = http.createHttp();
  
  let requestOptions = {
    method: http.RequestMethod.GET,
    readTimeout: 60000,
    connectTimeout: 60000,
    header: {
      'Content-Type': 'application/json'
    }
  };
  
  try {
    const response = await httpRequest.request(
      'https://api.example.com/data',
      requestOptions
    );
    
    if (response.responseCode === 200) {
      const data = JSON.parse(response.result.toString());
      return data;
    }
  } catch (err) {
    console.error('请求失败:', err);
  } finally {
    httpRequest.destroy();
  }
}

// HTTP POST 请求
async function postData(data: any) {
  let httpRequest = http.createHttp();
  
  let requestOptions = {
    method: http.RequestMethod.POST,
    readTimeout: 60000,
    connectTimeout: 60000,
    header: {
      'Content-Type': 'application/json'
    },
    extraData: {
      body: JSON.stringify(data)
    }
  };
  
  const response = await httpRequest.request(
    'https://api.example.com/submit',
    requestOptions
  );
  
  return JSON.parse(response.result.toString());
}
```

---

## 五、数据持久化

### 5.1 Preferences（轻量级存储）

```typescript
import dataPreferences from '@ohos.data.preferences';

// 获取 Preferences 实例
async function getPreferences() {
  const context = getContext();
  const preferences = await dataPreferences.getPreferences(context, 'my_prefs');
  return preferences;
}

// 存储数据
async function saveData(key: string, value: any) {
  const prefs = await getPreferences();
  await prefs.put(key, value);
  await prefs.flush();
}

// 读取数据
async function loadData(key: string) {
  const prefs = await getPreferences();
  const value = await prefs.get(key, null);
  return value;
}

// 删除数据
async function removeData(key: string) {
  const prefs = await getPreferences();
  await prefs.delete(key);
  await prefs.flush();
}
```

### 5.2 关系型数据库

```typescript
import relationalStore from '@ohos.data.relationalStore';

// 数据库配置
const STORE_CONFIG = {
  name: 'MyDatabase.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

// 创建数据库
async function createDatabase() {
  const context = getContext();
  const rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
  
  // 创建表
  const CREATE_TABLE_SQL = `
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      age INTEGER,
      email TEXT
    )
  `;
  
  await rdbStore.executeSql(CREATE_TABLE_SQL);
  return rdbStore;
}

// 插入数据
async function insertUser(rdbStore, user: any) {
  await rdbStore.insert('users', {
    name: user.name,
    age: user.age,
    email: user.email
  });
}

// 查询数据
async function queryUsers(rdbStore) {
  const result = await rdbStore.query('users', {
    columns: ['id', 'name', 'age', 'email'],
    predicates: {
      whereArgs: [],
      where: 'age > ?',
      whereArgs: ['18']
    }
  });
  
  const users = [];
  while (result.goToNextRow()) {
    users.push({
      id: result.getLong(result.getColumnIndex('id')),
      name: result.getString(result.getColumnIndex('name')),
      age: result.getLong(result.getColumnIndex('age')),
      email: result.getString(result.getColumnIndex('email'))
    });
  }
  
  return users;
}
```

---

## 六、自定义组件

```typescript
// 可复用按钮组件
@Component
export struct CustomButton {
  @Link text: string;
  @Link onClick: () => void;
  @Link backgroundColor: string = '#007DFF';
  
  build() {
    Button(this.text)
      .width('100%')
      .height(50)
      .backgroundColor(this.backgroundColor)
      .fontColor('#FFFFFF')
      .fontSize(16)
      .onClick(() => {
        this.onClick();
      })
  }
}

// 卡片组件
@Component
export struct Card {
  @Link title: string;
  @Link content: string;
  @Link imageSource: ResourceStr;
  
  build() {
    Stack() {
      Rectangle()
        .width('100%')
        .height(200)
        .radius(10)
        .fill('#FFFFFF')
        .shadow({
          offsetX: 2,
          offsetY: 2,
          blurRadius: 10,
          color: '#888888'
        })
      
      Column() {
        Image(this.imageSource)
          .width('100%')
          .height(120)
          .objectFit(ImageFit.Cover)
          .borderRadius({ topLeft: 10, topRight: 10 })
        
        Text(this.title)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 10, left: 10 })
        
        Text(this.content)
          .fontSize(14)
          .margin({ top: 5, left: 10 })
      }
    }
  }
}

// 使用自定义组件
@Entry
@Component
struct HomePage {
  @State count: number = 0;
  
  build() {
    Column() {
      CustomButton({
        text: '点击增加',
        backgroundColor: '#4CAF50',
        onClick: () => {
          this.count++;
        }
      })
      
      Card({
        title: '新闻标题',
        content: '新闻内容摘要...',
        imageSource: $r('app.media.sample')
      })
    }
  }
}
```

---

## 七、动画系统

```typescript
// 基础动画
Button('动画按钮')
  .width(100)
  .height(50)
  .onClick(() => {
    animateTo({
      duration: 300,
      curve: Curve.EaseInOut
    }, () => {
      this.scale = 1.2;
      this.rotation = 360;
    });
  })

// 属性动画
@Entry
@Component
struct AnimationDemo {
  @State scale: number = 1;
  @State rotation: number = 0;
  @State opacity: number = 1;
  
  build() {
    Column() {
      Image($r('app.media.icon'))
        .width(100)
        .height(100)
        .scale(this.scale)
        .rotate(this.rotation)
        .opacity(this.opacity)
      
      Button('播放动画')
        .onClick(() => {
          animateTo({
            duration: 500,
            curve: Curve.EaseOut,
            delay: 0,
            iterations: 1,
            playMode: PlayMode.Normal,
            fillMode: FillMode.Forwards
          }, () => {
            this.scale = 1.5;
            this.rotation = 360;
            this.opacity = 0.5;
          });
        })
    }
  }
}

// 转场动画
router.pushUrl({
  url: 'pages/DetailPage',
  animation: {
    duration: 300,
    curve: Curve.EaseInOut
  }
});
```

---

## 八、性能优化要点

### 8.1 列表优化

```typescript
// 使用 LazyForEach 替代 ForEach（大数据量）
List() {
  LazyForEach(dataSource, (item) => {
    ListItem() {
      Text(item.name)
    }
  }, (item) => item.id) // 必须提供唯一 key
}

// 数据源实现
class DataSource implements IDataSource {
  private data: Array<any> = [];
  
  getData(): Array<any> {
    return this.data;
  }
  
  totalCount(): number {
    return this.data.length;
  }
}
```

### 8.2 状态管理优化

```typescript
// 避免不必要的状态变量
@Entry
@Component
struct OptimizedComponent {
  @State count: number = 0;
  regularValue: number = 0; // 不触发 UI 刷新，用于计算
  
  // 计算属性
  get doubleCount(): number {
    return this.count * 2;
  }
  
  build() {
    Column() {
      Text(`计数：${this.count}`)
      Text(`双倍：${this.doubleCount}`)
    }
  }
}
```

### 8.3 组件复用

```typescript
// 提取可复用组件
@Component
struct ReusableItem {
  @Link item: any;
  
  build() {
    Row() {
      Image($r('app.media.icon'))
      Text(this.item.name)
    }
  }
}

// 使用
List() {
  ForEach(items, (item) => {
    ListItem() {
      ReusableItem({ item: item })
    }
  })
}
```

---

## 九、常见问题与解决方案

### 9.1 状态不更新

**问题**: 修改了状态变量但 UI 不刷新

**原因**:
1. 使用了常规变量而非 @State 装饰
2. 修改了嵌套对象的属性（浅观察限制）
3. @Link 传递时没有加 $

**解决方案**:
```typescript
// 错误示例
@State user: User = new User();
user.name = 'New Name'; // 不触发刷新

// 正确示例
this.user = new User('New Name'); // 重新赋值整个对象
```

### 9.2 组件间通信失效

**问题**: 父子组件数据不同步

**原因**:
1. @Prop 期望双向同步（实际是单向）
2. @Link 初始化时加了默认值
3. 传递方式错误

**解决方案**:
```typescript
// @Prop - 单向同步，子修改不回传
@Prop value: number = 0;

// @Link - 双向同步，禁止本地初始化
@Link value: number; // 正确
@Link value: number = 0; // 错误！

// 父组件传递
Child({ value: this.parentValue }) // @Prop
Child({ value: $parentValue }) // @Link，必须加$
```

### 9.3 页面跳转参数丢失

**问题**: 跳转后接收不到参数

**解决方案**:
```typescript
// 发送参数
router.pushUrl({
  url: 'pages/Detail',
  params: { id: 123 }
});

// 接收参数
@Entry
@Component
struct Detail {
  @Link id: number = 0;
  
  aboutToAppear() {
    const params = router.getParams() as Record<string, any>;
    if (params) {
      this.id = params['id'] || 0;
    }
  }
}
```

### 9.4 网络请求失败

**问题**: HTTP 请求报错或无响应

**解决方案**:
```typescript
// 1. 检查网络权限（module.json5）
"requestPermissions": [
  {
    "name": "ohos.permission.INTERNET"
  }
]

// 2. 正确处理异步
async function fetchData() {
  try {
    const response = await httpRequest.request(url, options);
    if (response.responseCode === 200) {
      return JSON.parse(response.result.toString());
    }
  } catch (err) {
    console.error('请求失败:', err);
  } finally {
    httpRequest.destroy();
  }
}
```

---

## 十、调试技巧

### 10.1 日志输出

```typescript
// 不同级别日志
console.debug('调试信息');
console.info('普通信息');
console.warn('警告信息');
console.error('错误信息');
console.fatal('致命错误');

// 查看日志
// DevEco Studio -> View -> Tool Windows -> Logcat
```

### 10.2 断点调试

1. 在代码行号左侧点击设置断点
2. 右键点击项目 -> Debug 'entry'
3. 使用调试工具栏：Step Over, Step Into, Resume

### 10.3 性能分析

1. DevEco Studio -> Tools -> Profiler
2. 查看 CPU、内存、网络使用情况
3. 识别性能瓶颈

---

## 十一、项目结构最佳实践

```
MyProject/
├── AppScope/
│   └── app.json5           # 应用全局配置
├── entry/
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/
│       │   │   └── EntryAbility.ets
│       │   ├── pages/              # 页面
│       │   │   ├── Index.ets
│       │   │   └── Detail.ets
│       │   ├── components/         # 可复用组件
│       │   │   ├── CustomButton.ets
│       │   │   └── Card.ets
│       │   ├── model/              # 数据模型
│       │   │   └── User.ets
│       │   ├── utils/              # 工具函数
│       │   │   ├── HttpUtil.ets
│       │   │   └── StorageUtil.ets
│       │   └── common/             # 公共资源
│       │       └── Constants.ets
│       └── resources/
│           └── base/
│               ├── element/
│               ├── media/
│               └── profile/
└── oh-package.json5
```

---

## 十二、快速上手模板

```typescript
// pages/Index.ets
import router from '@ohos.router';
import http from '@ohos.net.http';

@Entry
@Component
struct Index {
  @State title: string = '我的应用';
  @State dataList: Array<string> = [];
  @State isLoading: boolean = false;
  
  aboutToAppear() {
    this.loadData();
  }
  
  async loadData() {
    this.isLoading = true;
    try {
      // 网络请求示例
      const data = await this.fetchData();
      this.dataList = data;
    } catch (err) {
      console.error('加载失败:', err);
    } finally {
      this.isLoading = false;
    }
  }
  
  async fetchData(): Promise<Array<string>> {
    // 实现数据获取逻辑
    return ['Item 1', 'Item 2', 'Item 3'];
  }
  
  build() {
    Column() {
      Text(this.title)
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50 })
      
      if (this.isLoading) {
        Text('加载中...')
      } else {
        List() {
          ForEach(this.dataList, (item) => {
            ListItem() {
              Text(item)
                .fontSize(20)
                .padding(10)
            }
          })
        }
      }
      
      Button('跳转')
        .margin({ top: 20 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/Detail',
            params: { data: this.dataList }
          });
        })
    }
    .width('100%')
    .height('100%')
  }
}
```

---

## 十三、常见错误与解决方案速查

### 13.1 UI 状态管理问题

| 问题 | 症状 | 解决方案 |
|------|------|----------|
| @Builder 参数传递导致状态不更新 | 按钮点击后选中状态不更新 | 直接在@Builder 中访问@State 变量，不要传递布尔参数 |
| 状态变量未添加装饰器 | 修改变量后界面不更新 | 添加 @State/@Prop/@Link 装饰器 |
| 数组/对象修改后 UI 不更新 | 列表不刷新 | 创建新数组/使用@Observed+@ObjectLink |

```typescript
// ❌ 错误：直接修改数组元素
this.items[0].name = '新名称'

// ✅ 正确：创建新数组
this.items = this.items.map((item, index) =>
  index === 0 ? { ...item, name: '新名称' } : item
)
```

### 13.2 组件通信问题

| 问题 | 解决方案 |
|------|----------|
| @Link 传递没加 $ | 父组件传递必须加 $：`Child({ value: $myValue })` |
| @Link 本地初始化 | 禁止：`@Link value: number = 0` 正确：`@Link value: number` |
| @Prop 期望双向同步 | @Prop 是单向的，需要双向用@Link |

### 13.3 路由问题

```typescript
// ❌ 错误：参数类型不安全
const params = router.getParams()
const id = params.id

// ✅ 正确：类型转换和校验
const params = router.getParams() as Record<string, number | string>
if (params && params.id) {
  const id = typeof params.id === 'string' ? parseInt(params.id) : params.id
}
```

### 13.4 列表性能优化

```typescript
// ❌ 错误：没有 key 或使用索引
ForEach(this.items, (item) => { this.buildItem(item) })

// ✅ 正确：使用唯一 ID
ForEach(this.items, (item) => {
  this.buildItem(item)
}, (item) => item.id)

// ✅ 大列表使用 LazyForEach
LazyForEach(this.dataSource, (item) => {
  this.buildItem(item)
}, (item) => item.id)
```

### 13.5 异步操作最佳实践

```typescript
@Component
struct MyPage {
  @State data: Data | null = null
  @State isLoading: boolean = true
  
  async aboutToAppear() {
    try {
      await this.loadData()
    } catch (error) {
      console.error('加载失败:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  build() {
    if (this.isLoading) {
      Text('加载中...')
    } else if (this.data) {
      Text(this.data.name)
    } else {
      Text('暂无数据')
    }
  }
}
```

### 13.6 批量更新避免卡顿

```typescript
// ❌ 错误：循环中频繁更新状态
for (let i = 0; i < 1000; i++) {
  this.items.push(newItem) // 每次都触发 UI 更新
}

// ✅ 正确：批量更新
const newItems = []
for (let i = 0; i < 1000; i++) {
  newItems.push(newItem)
}
this.items = [...this.items, ...newItems] // 只触发一次更新
```

### 13.7 调试工具类

```typescript
import hilog from '@ohos.hilog'

export class Logger {
  private static domain: number = 0xFF00
  private static prefix: string = 'MyApp'
  
  static debug(tag: string, message: string, ...args: any[]) {
    hilog.debug(this.domain, `${this.prefix}-${tag}`, message, args)
  }
  
  static info(tag: string, message: string, ...args: any[]) {
    hilog.info(this.domain, `${this.prefix}-${tag}`, message, args)
  }
  
  static error(tag: string, message: string, error?: Error) {
    hilog.error(this.domain, `${this.prefix}-${tag}`, message, error?.stack || '')
  }
}

// 使用
Logger.debug('MyComponent', `count 变化：${this.count}`)
```

---

## 十四、开发检查清单

### 编译前检查
- [ ] 所有状态变量都有正确的装饰器（@State/@Prop/@Link）
- [ ] ForEach 提供了唯一 key 生成函数
- [ ] 箭头函数有明确的类型标注
- [ ] 没有在 @Builder 中传递布尔状态参数
- [ ] 异步操作有错误处理（try-catch）

### UI 问题排查
- [ ] 检查状态变量是否正确更新
- [ ] 验证条件渲染的逻辑是否正确
- [ ] 确认深色模式适配是否完整
- [ ] 测试不同屏幕尺寸的显示效果
- [ ] 检查是否有硬编码的颜色值

### 性能优化检查
- [ ] 大列表使用 LazyForEach
- [ ] 避免在 build 方法中进行复杂计算
- [ ] 图片资源是否过大
- [ ] 是否有不必要的状态更新
- [ ] 数据库查询是否优化（索引、分页）

### 数据流检查
- [ ] 路由参数类型转换是否正确
- [ ] 数据库初始化时机是否正确
- [ ] 父子组件数据传递是否符合规范
- [ ] 异步操作的时序是否正确
- [ ] 状态同步是否会造成循环更新

---

## 学习资源

- **官方文档**: https://developer.huawei.com/consumer/cn/doc/
- **DevEco Studio**: https://developer.harmonyos.com/cn/develop/deveco-studio
- **开发者社区**: https://developer.harmonyos.com/cn/community
- **CSDN 鸿蒙专栏**: https://blog.csdn.net/
- **掘金 HarmonyOS**: https://juejin.cn/tag/HarmonyOS

---

*最后更新：2026-03-12*
*目标：48 小时成为 HarmonyOS 6 开发专家*
