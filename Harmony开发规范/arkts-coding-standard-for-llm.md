# ArkTS + ArkUI 开发编码规范（大模型学习专用版）

> ⚠️ **重要说明**：本文档专门针对 AI 大模型学习 ArkTS 开发规范，重点标注 **ArkTS 特有限制**和**其他语言可用但 ArkTS 禁止**的用法，避免生成不符合 ArkTS 规范的代码。

---

## 目录

1. [核心原则](#一核心原则)
2. [类型系统规范](#二类型系统规范)
3. [状态管理规范](#三状态管理规范)
4. [组件开发规范](#四组件开发规范)
5. [异步编程规范](#五异步编程规范)
6. [数据操作规范](#六数据操作规范)
7. [UI 渲染规范](#七 ui 渲染规范)
8. [模块导入导出规范](#八模块导入导出规范)
9. [常见错误对照表](#九常见错误对照表)
10. [代码审查清单](#十代码审查清单)

---

## 一、核心原则

### 1.1 ArkTS 设计哲学

```
ArkTS = TypeScript 超集 + 静态类型约束 + AOT 编译优化
```

**核心限制原因**：
- ArkTS 使用 **AOT (Ahead-Of-Time)** 编译，需要编译时确定类型
- 运行时动态类型特性会破坏编译优化
- 声明式 UI 依赖响应式状态系统

### 1.2 三大禁止原则

| 原则 | 说明 | 违反后果 |
|------|------|----------|
| 🚫 禁止动态类型 | 不能用 any/unknown | 编译失败 |
| 🚫 禁止原型修改 | 不能动态添加对象属性 | 运行时错误 |
| 🚫 禁止任意 this | 箭头函数 this 绑定受限 | 逻辑错误 |

---

## 二、类型系统规范

### 2.1 禁止使用的类型

#### ❌ 禁止：any 类型

```typescript
// ❌ 错误：ArkTS 禁止使用 any
function processData(data: any): void {
  console.log(data.value);
}

// ❌ 错误：隐式 any
let value = getValue(); // 没有返回值类型推断

// ❌ 错误：any 数组
let items: any[] = [1, 'text', true];
```

#### ✅ 正确：使用明确类型

```typescript
// ✅ 正确：定义接口
interface DataItem {
  id: number;
  name: string;
  value: number;
}

function processData(data: DataItem): void {
  console.log(data.value);
}

// ✅ 正确：明确类型标注
let value: number = getValue();

// ✅ 正确：联合类型
let items: (number | string | boolean)[] = [1, 'text', true];

// ✅ 正确：使用泛型约束
function processArray<T extends { id: number }>(items: T[]): void {
  items.forEach(item => console.log(item.id));
}
```

#### ❌ 禁止：unknown 类型

```typescript
// ❌ 错误：ArkTS 不支持 unknown
function handleUnknown(value: unknown): void {
  if (typeof value === 'string') {
    console.log(value.length);
  }
}
```

#### ✅ 正确：使用联合类型或接口

```typescript
// ✅ 正确：联合类型
type ValueType = string | number | boolean;

function handleValue(value: ValueType): void {
  if (typeof value === 'string') {
    console.log(value.length);
  }
}

// ✅ 正确：使用 Object 作为顶层类型（谨慎使用）
function handleObject(value: Object): void {
  // 只能访问 Object 原型方法
}
```

### 2.2 类型推断规则

#### ❌ 错误：依赖复杂类型推断

```typescript
// ❌ 错误：reduce 类型推断可能失败
const result = items.reduce((sum, item) => sum + item.value, 0);

// ❌ 错误：链式调用类型推断失败
const names = items
  .filter(item => item.active)
  .map(item => item.name);
```

#### ✅ 正确：显式类型标注

```typescript
// ✅ 正确：显式标注参数和返回类型
const result = items.reduce((sum: number, item: DataItem): number => 
  sum + item.value, 0
);

// ✅ 正确：链式调用显式标注
const names: string[] = items
  .filter((item: DataItem): boolean => item.active)
  .map((item: DataItem): string => item.name);
```

### 2.3 类与对象规范

#### ❌ 禁止：动态添加属性

```typescript
// ❌ 错误：运行时动态添加属性
class User {
  name: string = '';
  age: number = 0;
}

const user = new User();
user.email = 'test@example.com'; // ❌ ArkTS 禁止

// ❌ 错误：使用索引签名动态访问
user['email'] = 'test@example.com'; // ❌ 禁止
```

#### ✅ 正确：预先定义所有属性

```typescript
// ✅ 正确：在类中定义所有属性
class User {
  name: string = '';
  age: number = 0;
  email: string = '';
}

const user = new User();
user.email = 'test@example.com'; // ✅ 正确

// ✅ 正确：使用可选属性
class User {
  name: string = '';
  age: number = 0;
  email?: string; // 可选属性
}

// ✅ 正确：使用 Map 存储动态键值对
class UserData {
  private data: Map<string, string> = new Map();
  
  set(key: string, value: string): void {
    this.data.set(key, value);
  }
  
  get(key: string): string | undefined {
    return this.data.get(key);
  }
}
```

#### ❌ 禁止：Proxy 和 Reflect

```typescript
// ❌ 错误：ArkTS 不支持 Proxy
const proxy = new Proxy(target, handler);

// ❌ 错误：ArkTS 不支持 Reflect
Reflect.get(target, propertyKey);
```

### 2.4 函数规范

#### ❌ 禁止：省略返回类型（复杂函数）

```typescript
// ❌ 错误：复杂返回值需要显式标注
function createUser(name: string, age: number) {
  return { name, age, id: Date.now() };
}
```

#### ✅ 正确：显式返回类型

```typescript
// ✅ 正确：显式标注返回类型
interface User {
  name: string;
  age: number;
  id: number;
}

function createUser(name: string, age: number): User {
  return { name, age, id: Date.now() };
}
```

#### ❌ 禁止：arguments 对象

```typescript
// ❌ 错误：ArkTS 不支持 arguments
function sum() {
  let total = 0;
  for (let arg of arguments) { // ❌ 不支持
    total += arg;
  }
  return total;
}
```

#### ✅ 正确：使用剩余参数

```typescript
// ✅ 正确：使用剩余参数语法
function sum(...values: number[]): number {
  let total = 0;
  for (const value of values) {
    total += value;
  }
  return total;
}
```

---

## 三、状态管理规范

### 3.1 装饰器使用规则

#### ❌ 错误：状态变量未初始化

```typescript
@Component
struct MyComponent {
  @State count: number; // ❌ 错误：@State 必须初始化
  @Link value: number = 0; // ❌ 错误：@Link 禁止初始化
}
```

#### ✅ 正确：按规则初始化

```typescript
@Component
struct MyComponent {
  @State count: number = 0; // ✅ @State 必须本地初始化
  @Prop value: number = 0; // ✅ @Prop 可选初始化
  @Link value: number; // ✅ @Link 禁止初始化，由父组件传递
}
```

#### ❌ 错误：@Link 传递不加 $

```typescript
// 父组件
@Entry
@Component
struct Parent {
  @State value: number = 0;
  
  build() {
    Column() {
      // ❌ 错误：@Link 传递必须加 $
      Child({ value: this.value });
      
      // ✅ 正确
      Child({ value: $value });
    }
  }
}
```

### 3.2 状态更新规范

#### ❌ 错误：直接修改嵌套对象属性

```typescript
@Entry
@Component
struct MyComponent {
  @State user: User = new User('John', 25);
  
  build() {
    Column() {
      Text(this.user.name);
      Button('修改')
        .onClick(() => {
          // ❌ 错误：修改嵌套属性不触发 UI 更新
          this.user.name = 'Jane';
          
          // ❌ 错误：修改深层嵌套属性
          this.user.profile.age = 26;
        });
    }
  }
}
```

#### ✅ 正确：重新赋值整个对象

```typescript
@Entry
@Component
struct MyComponent {
  @State user: User = new User('John', 25);
  
  build() {
    Column() {
      Text(this.user.name);
      Button('修改')
        .onClick(() => {
          // ✅ 正确：重新赋值整个对象
          this.user = new User('Jane', 25);
          
          // ✅ 正确：使用扩展运算符创建新对象
          this.user = { ...this.user, name: 'Jane' };
        });
    }
  }
}
```

#### ❌ 错误：数组直接修改

```typescript
@State items: string[] = ['A', 'B', 'C'];

// ❌ 错误：直接修改数组元素
this.items[0] = 'X';

// ❌ 错误：push 后不触发更新（某些情况）
this.items.push('D');

// ❌ 错误：splice 修改
this.items.splice(1, 1);
```

#### ✅ 正确：创建新数组

```typescript
@State items: string[] = ['A', 'B', 'C'];

// ✅ 正确：创建新数组
this.items = [...this.items];

// ✅ 正确：扩展运算符添加
this.items = [...this.items, 'D'];

// ✅ 正确：map 创建新数组
this.items = this.items.map((item, index) => 
  index === 0 ? 'X' : item
);

// ✅ 正确：filter 创建新数组
this.items = this.items.filter(item => item !== 'B');
```

### 3.3 @Watch 使用规范

#### ❌ 错误：@Watch 回调修改自身变量

```typescript
@Entry
@Component
struct MyComponent {
  @State @Watch('onCountChange') count: number = 0;
  
  onCountChange() {
    // ❌ 错误：修改自身会导致无限循环
    this.count++;
  }
}
```

#### ✅ 正确：@Watch 只读或修改其他变量

```typescript
@Entry
@Component
struct MyComponent {
  @State @Watch('onCountChange') count: number = 0;
  @State log: string = '';
  
  onCountChange() {
    // ✅ 正确：只读操作
    console.log(`count 变为：${this.count}`);
    
    // ✅ 正确：修改其他变量
    this.log = `count: ${this.count}`;
  }
}
```

### 3.4 状态装饰器选择指南

| 场景 | 推荐装饰器 | 说明 |
|------|------------|------|
| 组件内部私有状态 | `@State` | 最基础的状态装饰器 |
| 父传子，子不需回传 | `@Prop` | 单向同步，深拷贝 |
| 父子双向同步 | `@Link` | 引用传递，必须加$ |
| 状态变化执行逻辑 | `@Watch` | 配合其他装饰器使用 |
| 跨层级状态共享 | `@Provide`/`@Consume` | 祖先-后代组件 |
| 应用级全局状态 | `@StorageLink` | 与 AppStorage 同步 |

---

## 四、组件开发规范

### 4.1 组件结构规范

#### ❌ 错误：@Entry 和@Component 混用

```typescript
// ❌ 错误：同时使用@Entry 和@Component
@Entry
@Component
struct MyComponent { }

// ❌ 错误：只有@Component 没有@Entry（作为页面时）
@Component
struct Index { }
```

#### ✅ 正确：区分页面组件和普通组件

```typescript
// ✅ 正确：页面组件（入口）
@Entry
@Component
struct Index { }

// ✅ 正确：普通组件（复用）
@Component
struct CustomButton { }
```

### 4.2 @Builder 使用规范

#### ❌ 错误：@Builder 传递布尔状态参数

```typescript
@Component
struct MyComponent {
  @State isSelected: boolean = false;
  
  @Builder
  buildButton(isSelected: boolean) {
    // ❌ 错误：参数在初始化时确定，不响应状态变化
    Button('点击')
      .backgroundColor(isSelected ? '#FF0000' : '#FFFFFF');
  }
  
  build() {
    Column() {
      this.buildButton(this.isSelected);
      Button('切换')
        .onClick(() => {
          this.isSelected = !this.isSelected;
        });
    }
  }
}
```

#### ✅ 正确：@Builder 直接访问状态变量

```typescript
@Component
struct MyComponent {
  @State isSelected: boolean = false;
  
  @Builder
  buildButton() {
    // ✅ 正确：直接访问@State 变量
    Button('点击')
      .backgroundColor(this.isSelected ? '#FF0000' : '#FFFFFF');
  }
  
  build() {
    Column() {
      this.buildButton();
      Button('切换')
        .onClick(() => {
          this.isSelected = !this.isSelected;
        });
    }
  }
}
```

### 4.3 组件生命周期规范

#### ❌ 错误：异步操作不处理组件卸载

```typescript
@Component
struct MyComponent {
  @State data: Data | null = null;
  
  aboutToAppear() {
    // ❌ 错误：组件可能已卸载，数据还在加载
    this.loadData();
  }
  
  async loadData() {
    const result = await fetchData();
    this.data = result; // 可能组件已销毁
  }
}
```

#### ✅ 正确：处理异步和卸载

```typescript
@Component
struct MyComponent {
  @State data: Data | null = null;
  @State isLoading: boolean = true;
  private isDestroyed: boolean = false;
  
  aboutToAppear() {
    this.loadData();
  }
  
  aboutToDisappear() {
    this.isDestroyed = true;
  }
  
  async loadData() {
    try {
      const result = await fetchData();
      if (!this.isDestroyed) {
        this.data = result;
      }
    } catch (error) {
      console.error('加载失败:', error);
    } finally {
      if (!this.isDestroyed) {
        this.isLoading = false;
      }
    }
  }
}
```

### 4.4 组件通信规范

#### ❌ 错误：子组件直接修改@Prop

```typescript
@Component
struct Child {
  @Prop value: number = 0;
  
  build() {
    Button('增加')
      .onClick(() => {
        // ❌ 错误：@Prop 是单向的，子修改不回传
        this.value++;
      });
  }
}
```

#### ✅ 正确：使用回调或@Link

```typescript
// ✅ 方案 1：使用回调函数
@Component
struct Child {
  @Prop value: number = 0;
  @Prop onValueChange: (newValue: number) => void = () => {};
  
  build() {
    Button('增加')
      .onClick(() => {
        this.onValueChange(this.value + 1);
      });
  }
}

// ✅ 方案 2：使用@Link 双向同步
@Component
struct Child {
  @Link value: number;
  
  build() {
    Button('增加')
      .onClick(() => {
        this.value++; // 父组件同步更新
      });
  }
}
```

---

## 五、异步编程规范

### 5.1 async/await 规范

#### ❌ 错误：async 函数不处理错误

```typescript
// ❌ 错误：没有 try-catch
async loadData() {
  const data = await fetchData();
  this.data = data;
}
```

#### ✅ 正确：完整的错误处理

```typescript
// ✅ 正确：try-catch-finally
async loadData() {
  this.isLoading = true;
  try {
    const data = await fetchData();
    this.data = data;
  } catch (error) {
    console.error('加载失败:', error);
    this.errorMessage = '加载失败，请重试';
  } finally {
    this.isLoading = false;
  }
}
```

### 5.2 Promise 规范

#### ❌ 禁止：Promise 构造函数反模式

```typescript
// ❌ 错误：不必要的 Promise 包装
async function getData(): Promise<Data> {
  return await fetchData(); // ❌ 冗余的 await
}

// ❌ 错误：Promise 构造函数反模式
function loadData(): Promise<Data> {
  return new Promise((resolve, reject) => {
    fetchData()
      .then(resolve)
      .catch(reject);
  });
}
```

#### ✅ 正确：直接返回

```typescript
// ✅ 正确：直接返回 Promise
function getData(): Promise<Data> {
  return fetchData();
}

// ✅ 正确：async 函数直接返回
async function loadData(): Promise<void> {
  this.data = await fetchData();
}
```

### 5.3 并发请求规范

#### ❌ 错误：串行执行独立请求

```typescript
// ❌ 错误：独立请求串行执行，浪费时间
async loadData() {
  const users = await fetchUsers(); // 等待完成
  const posts = await fetchPosts(); // 再等待完成
  const comments = await fetchComments(); // 再等待完成
}
```

#### ✅ 正确：并行执行独立请求

```typescript
// ✅ 正确：使用 Promise.all 并行执行
async loadData() {
  const [users, posts, comments] = await Promise.all([
    fetchUsers(),
    fetchPosts(),
    fetchComments()
  ]);
}

// ✅ 正确：处理部分失败
async loadData() {
  const results = await Promise.allSettled([
    fetchUsers(),
    fetchPosts(),
    fetchComments()
  ]);
  
  results.forEach((result, index) => {
    if (result.status === 'fulfilled') {
      console.log(`请求${index}成功`, result.value);
    } else {
      console.error(`请求${index}失败`, result.reason);
    }
  });
}
```

---

## 六、数据操作规范

### 6.1 数组操作规范

#### ❌ 禁止：修改原数组的方法

```typescript
@State items: number[] = [1, 2, 3];

// ❌ 禁止：直接修改原数组
items.push(4);
items.pop();
items.shift();
items.unshift(0);
items.splice(1, 1);
items.reverse();
items.sort();
```

#### ✅ 正确：创建新数组

```typescript
@State items: number[] = [1, 2, 3];

// ✅ 正确：创建新数组
this.items = [...this.items, 4]; // push
this.items = this.items.slice(0, -1); // pop
this.items = this.items.slice(1); // shift
this.items = [0, ...this.items]; // unshift
this.items = this.items.filter((_, i) => i !== 1); // splice
this.items = [...this.items].reverse(); // reverse
this.items = [...this.items].sort((a, b) => a - b); // sort
```

### 6.2 对象操作规范

#### ❌ 禁止：delete 操作符

```typescript
// ❌ 禁止：使用 delete
const obj = { a: 1, b: 2, c: 3 };
delete obj.b;
```

#### ✅ 正确：解构排除

```typescript
// ✅ 正确：使用解构创建新对象
const obj = { a: 1, b: 2, c: 3 };
const { b, ...newObj } = obj; // newObj = { a: 1, c: 3 }
```

### 6.3 JSON 使用规范

#### ❌ 错误：JSON.parse 不处理异常

```typescript
// ❌ 错误：可能抛出异常
const data = JSON.parse(jsonString);
```

#### ✅ 正确：异常处理

```typescript
// ✅ 正确：try-catch 处理
try {
  const data = JSON.parse(jsonString);
} catch (error) {
  console.error('JSON 解析失败:', error);
}

// ✅ 正确：封装安全解析
function safeJsonParse<T>(json: string, defaultValue: T): T {
  try {
    return JSON.parse(json) as T;
  } catch {
    return defaultValue;
  }
}
```

---

## 七、UI 渲染规范

### 7.1 ForEach 使用规范

#### ❌ 错误：ForEach 缺少 key 生成函数

```typescript
// ❌ 错误：没有 key 生成函数
ForEach(this.items, (item) => {
  ListItem() {
    Text(item.name);
  }
});

// ❌ 错误：使用索引作为 key
ForEach(this.items, (item, index) => {
  ListItem() {
    Text(item.name);
  }
}, (item, index) => index.toString());
```

#### ✅ 正确：使用唯一 ID

```typescript
// ✅ 正确：使用唯一 ID 作为 key
ForEach(this.items, (item) => {
  ListItem() {
    Text(item.name);
  }
}, (item) => item.id);

// ✅ 正确：大列表使用 LazyForEach
LazyForEach(this.dataSource, (item) => {
  ListItem() {
    Text(item.name);
  }
}, (item) => item.id);
```

### 7.2 条件渲染规范

#### ❌ 错误：三元表达式嵌套过深

```typescript
// ❌ 错误：嵌套过深，难以维护
Column() {
  this.isLoading 
    ? LoadingProgress() 
    : this.errorMessage 
      ? Text(this.errorMessage)
      : this.data 
        ? this.renderData()
        : Text('暂无数据')
}
```

#### ✅ 正确：使用 if 语句拆分

```typescript
// ✅ 正确：使用独立的条件块
build() {
  Column() {
    if (this.isLoading) {
      LoadingProgress()
    } else if (this.errorMessage) {
      Text(this.errorMessage)
    } else if (this.data) {
      this.renderData()
    } else {
      Text('暂无数据')
    }
  }
}
```

### 7.3 样式规范

#### ❌ 错误：硬编码颜色值

```typescript
// ❌ 错误：硬编码，不支持深色模式
Text('标题')
  .fontColor('#000000')
  .backgroundColor('#FFFFFF')
```

#### ✅ 正确：使用资源引用或主题

```typescript
// ✅ 正确：使用资源引用
Text('标题')
  .fontColor($r('app.color.text_primary'))
  .backgroundColor($r('app.color.background'))

// ✅ 正确：根据主题动态设置
@StorageProp('currentColorMode') currentMode: number = 0;

get isDarkMode(): boolean {
  return this.currentMode === ColorMode.COLOR_MODE_DARK;
}

Text('标题')
  .fontColor(this.isDarkMode ? '#FFFFFF' : '#000000')
```

---

## 八、模块导入导出规范

### 8.1 导入规范

#### ❌ 错误：循环依赖

```typescript
// fileA.ets
import { funcB } from './fileB';
export function funcA() { funcB(); }

// fileB.ets
import { funcA } from './fileA'; // ❌ 循环依赖
export function funcB() { funcA(); }
```

#### ✅ 正确：提取公共模块

```typescript
// common.ets
export function commonFunc() { }

// fileA.ets
import { commonFunc } from './common';
export function funcA() { commonFunc(); }

// fileB.ets
import { commonFunc } from './common';
export function funcB() { commonFunc(); }
```

### 8.2 导出规范

#### ❌ 错误：默认导出和命名导出混用

```typescript
// ❌ 不推荐：混用导出方式
export default class User { }
export function helper() { }
```

#### ✅ 正确：统一使用命名导出

```typescript
// ✅ 正确：统一命名导出
export class User { }
export function helper() { }

// 导入
import { User, helper } from './module';
```

---

## 九、常见错误对照表

### 9.1 类型系统错误

| 错误类型 | TypeScript 可用 | ArkTS 禁止 | 正确做法 |
|----------|----------------|------------|----------|
| any 类型 | ✅ | ❌ | 使用接口/联合类型 |
| unknown 类型 | ✅ | ❌ | 使用联合类型 |
| 类型推断失败 | ⚠️ | ❌ | 显式类型标注 |
| 动态添加属性 | ✅ | ❌ | 预定义所有属性 |
| Proxy/Reflect | ✅ | ❌ | 使用类封装 |
| arguments 对象 | ✅ | ❌ | 使用剩余参数 |

### 9.2 状态管理错误

| 错误类型 | 现象 | 正确做法 |
|----------|------|----------|
| @State 未初始化 | 编译错误 | 必须本地初始化 |
| @Link 本地初始化 | 编译错误 | 禁止初始化 |
| @Link 传递不加$ | 编译错误 | 必须加$传递引用 |
| 修改嵌套对象属性 | UI 不更新 | 重新赋值整个对象 |
| 直接修改数组 | UI 不更新 | 创建新数组 |
| @Watch 修改自身 | 无限循环 | 只读或修改其他变量 |

### 9.3 组件开发错误

| 错误类型 | 现象 | 正确做法 |
|----------|------|----------|
| @Builder 传布尔参数 | 状态不更新 | 直接访问@State |
| ForEach 无 key | 性能差/渲染错误 | 使用唯一 ID |
| 索引作为 key | 列表渲染错误 | 使用业务 ID |
| 异步不处理卸载 | 内存泄漏 | 标记销毁状态 |
| 子修改@Prop | 数据不同步 | 使用回调或@Link |

### 9.4 异步编程错误

| 错误类型 | 风险 | 正确做法 |
|----------|------|----------|
| async 无 try-catch | 未处理错误 | 完整错误处理 |
| Promise.all 不处理失败 | 部分失败丢失 | Promise.allSettled |
| 串行执行独立请求 | 性能差 | 并行执行 |
| 冗余 await | 性能损耗 | 直接返回 Promise |

---

## 十、代码审查清单

### 10.1 编译前必查

- [ ] 没有使用 `any` 或 `unknown` 类型
- [ ] 所有函数有明确的参数和返回类型
- [ ] 没有动态添加对象属性
- [ ] 没有使用 `Proxy`、`Reflect`、`arguments`
- [ ] 所有 `@State` 变量已本地初始化
- [ ] 所有 `@Link` 变量未初始化
- [ ] `ForEach` 提供了唯一 key 生成函数

### 10.2 状态管理检查

- [ ] 状态更新创建新对象/数组，不修改原值
- [ ] `@Link` 传递使用了 `$` 符号
- [ ] `@Watch` 回调没有修改自身监听变量
- [ ] 嵌套对象修改使用重新赋值方式
- [ ] 选择了正确的状态装饰器

### 10.3 组件开发检查

- [ ] 页面组件使用 `@Entry`
- [ ] 复用组件使用 `@Component`
- [ ] `@Builder` 没有传递布尔状态参数
- [ ] 异步操作处理了组件卸载
- [ ] 组件通信方式正确（@Prop/@Link/回调）

### 10.4 性能优化检查

- [ ] 大列表使用 `LazyForEach`
- [ ] 没有使用索引作为 key
- [ ] 避免在 `build` 中进行复杂计算
- [ ] 批量更新状态，避免频繁触发
- [ ] 图片资源使用合适尺寸

### 10.5 错误处理检查

- [ ] 异步操作有 `try-catch`
- [ ] JSON 解析有异常处理
- [ ] 网络请求有超时和重试
- [ ] 用户输入有校验
- [ ] 边界情况有空值处理

---

## 附录：ArkTS 限制完整列表

### A.1 完全禁止的 JavaScript/TypeScript 特性

```
❌ any 类型
❌ unknown 类型
❌ Proxy 对象
❌ Reflect API
❌ arguments 对象
❌ 原型链修改（__proto__）
❌ 动态添加对象属性
❌ delete 操作符
❌ eval() 函数
❌ Function 构造函数
❌ 运行时类型检查（typeof 用于类型守卫除外）
```

### A.2 受限使用的特性

```
⚠️ 数组修改方法（push/pop/shift/unshift/splice/reverse/sort）
   → 必须创建新数组

⚠️ 对象修改（直接赋值属性）
   → @State 装饰的对象需重新赋值

⚠️ 箭头函数 this 绑定
   → 组件方法中需注意 this 指向

⚠️ 继承
   → 支持但有限制，不能动态修改原型

⚠️ 泛型
   → 支持但需要类型约束
```

### A.3 推荐使用的替代方案

| 禁止特性 | 替代方案 |
|----------|----------|
| any | 接口/联合类型/泛型约束 |
| unknown | 联合类型 |
| Proxy | 类封装 + 装饰器 |
| arguments | 剩余参数 (...args) |
| 动态属性 | Map/预定义属性 |
| delete | 解构排除 |
| 数组修改方法 | 创建新数组 |

---

## 版本信息

- **文档版本**: 1.0.0
- **适用 ArkTS 版本**: API 12+ (HarmonyOS 6+)
- **最后更新**: 2026-03-12
- **维护者**: AI 开发助手

---

## 参考资源

- [ArkTS 官方文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides)
- [ArkTS 语言约束](https://developer.huawei.com/consumer/cn/doc/arkts-guides)
- [ArkUI 开发指南](https://developer.huawei.com/consumer/cn/doc/arkui-guides)
- [DevEco Studio 下载](https://developer.harmonyos.com/cn/develop/deveco-studio)
