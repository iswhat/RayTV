# ArkTS开发规范与实践指南

## 1. 语言基础规范

### 1.1 类型系统规范

#### 1.1.1 基础类型使用
- **boolean类型**：用于逻辑判断，必须明确初始化为true或false
- **number类型**：用于数值计算，支持整数和浮点数
- **string类型**：用于文本处理，支持模板字符串
- **null/undefined**：明确区分空值和未定义值

#### 1.1.2 类型声明规范
```typescript
// 正确示例：明确类型声明
let isActive: boolean = true;
let count: number = 0;
let message: string = "Hello";

// 错误示例：避免使用any和unknown
let data: any; // 禁止使用
let unknownData: unknown; // 禁止使用
```

#### 1.1.3 联合类型使用
```typescript
// 正确使用联合类型
let status: 'active' | 'inactive' | 'pending' = 'active';
let value: number | string = 42;

// 类型保护
if (typeof value === 'string') {
    console.log(value.length);
}
```

### 1.2 变量声明规范

#### 1.2.1 变量作用域
- **局部变量**：使用`let`声明，限制在最小作用域内
- **常量**：使用`const`声明，确保不可变性
- **类属性**：明确访问修饰符（private/protected/public）

#### 1.2.2 命名规范
```typescript
// 变量命名：camelCase
let userName: string = "John";
let itemCount: number = 10;

// 常量命名：UPPER_CASE
const MAX_COUNT: number = 100;
const DEFAULT_TIMEOUT: number = 5000;

// 类命名：PascalCase
class UserService {
    // 类属性命名：camelCase
    private userData: User;
    
    // 方法命名：camelCase
    public getUserInfo(): User {
        return this.userData;
    }
}
```

## 2. 类与对象规范

### 2.1 类定义规范

#### 2.1.1 类结构
```typescript
// 正确类定义
class User {
    // 属性声明
    private id: number;
    private name: string;
    
    // 构造函数
    constructor(id: number, name: string) {
        this.id = id;
        this.name = name;
    }
    
    // 方法定义
    public getName(): string {
        return this.name;
    }
    
    // 静态方法
    public static createDefault(): User {
        return new User(0, "Default User");
    }
}
```

#### 2.1.2 类实例化规范
```typescript
// 正确实例化：使用局部变量
const user = new User(1, "Alice");

// 错误实例化：避免类名直接作为对象
// User.instance = new User(); // 禁止使用

// 正确单例模式实现
class ParserService {
    private static _instance: ParserService;
    
    public static getInstance(): ParserService {
        if (!ParserService._instance) {
            const instance = new ParserService(); // 使用局部变量
            ParserService._instance = instance;
        }
        return ParserService._instance;
    }
}
```

### 2.2 接口与抽象类

#### 2.2.1 接口定义
```typescript
// 接口定义
interface IUserService {
    getUser(id: number): User;
    saveUser(user: User): boolean;
}

// 接口实现
class UserService implements IUserService {
    public getUser(id: number): User {
        // 实现逻辑
        return new User(id, "User Name");
    }
    
    public saveUser(user: User): boolean {
        // 实现逻辑
        return true;
    }
}
```

#### 2.2.2 抽象类使用
```typescript
// 抽象类定义
abstract class BaseService {
    protected abstract initialize(): void;
    
    public start(): void {
        this.initialize();
        console.log("Service started");
    }
}

// 具体实现
class UserService extends BaseService {
    protected initialize(): void {
        console.log("User service initialized");
    }
}
```

## 3. 函数与方法规范

### 3.1 函数定义规范

#### 3.1.1 参数类型声明
```typescript
// 明确参数类型
function calculateTotal(price: number, quantity: number): number {
    return price * quantity;
}

// 可选参数
function createUser(name: string, age?: number): User {
    return new User(0, name, age || 0);
}

// 默认参数
function createMessage(text: string, type: string = "info"): string {
    return `[${type}] ${text}`;
}
```

#### 3.1.2 箭头函数使用
```typescript
// 箭头函数
const multiply = (a: number, b: number): number => a * b;

// 回调函数
const numbers = [1, 2, 3, 4, 5];
const doubled = numbers.map((num: number): number => num * 2);
```

### 3.2 方法设计规范

#### 3.2.1 方法职责单一
```typescript
class UserManager {
    // 单一职责方法
    public validateUser(user: User): boolean {
        return user.name.length > 0 && user.age >= 0;
    }
    
    // 明确返回值类型
    public formatUserName(user: User): string {
        return `${user.name} (${user.age})`;
    }
}
```

#### 3.2.2 错误处理规范
```typescript
class DataService {
    public async fetchData(url: string): Promise<any> {
        try {
            const response = await fetch(url);
            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }
            return await response.json();
        } catch (error) {
            console.error("Fetch data error:", error);
            throw error;
        }
    }
}
```

## 4. 装饰器使用规范

### 4.1 状态管理装饰器

#### 4.1.1 @State装饰器
```typescript
@Component
struct UserComponent {
    // 正确使用@State装饰器
    @State private userName: string = "";
    @State private isActive: boolean = false;
    @State private userCount: number = 0;
    
    // 错误使用：未初始化或类型不匹配
    // @State private user: User; // 禁止使用
    
    build() {
        Column() {
            Text(this.userName)
            Toggle({ isOn: $isActive })
            Text(`Count: ${this.userCount}`)
        }
    }
}
```

#### 4.1.2 @Prop和@Link装饰器
```typescript
// 父组件
@Component
struct ParentComponent {
    @State private message: string = "Hello";
    
    build() {
        Column() {
            ChildComponent({ content: this.message })
            Button('Change Message')
                .onClick(() => {
                    this.message = "Updated Message";
                })
        }
    }
}

// 子组件
@Component
struct ChildComponent {
    @Prop content: string; // 单向数据流
    
    build() {
        Text(this.content)
    }
}
```

### 4.2 生命周期装饰器

#### 4.2.1 @Entry和@Component
```typescript
// 入口组件
@Entry
@Component
struct MainPage {
    build() {
        Column() {
            Text('Main Page')
                .fontSize(30)
        }
    }
}
```

#### 4.2.2 自定义装饰器
```typescript
// 日志装饰器
function logMethod(target: any, propertyName: string, descriptor: PropertyDescriptor) {
    const originalMethod = descriptor.value;
    
    descriptor.value = function(...args: any[]) {
        console.log(`Calling ${propertyName} with args:`, args);
        const result = originalMethod.apply(this, args);
        console.log(`Method ${propertyName} returned:`, result);
        return result;
    };
    
    return descriptor;
}

class Calculator {
    @logMethod
    public add(a: number, b: number): number {
        return a + b;
    }
}
```

## 5. 模块与导入规范

### 5.1 模块组织规范

#### 5.1.1 文件结构
```
src/
├── components/          # 组件模块
│   ├── common/         # 通用组件
│   ├── business/       # 业务组件
│   └── layout/         # 布局组件
├── services/           # 服务模块
│   ├── api/            # API服务
│   ├── storage/        # 存储服务
│   └── utils/          # 工具服务
├── models/             # 数据模型
├── pages/              # 页面模块
└── app.ets             # 应用入口
```

#### 5.1.2 导入导出规范
```typescript
// services/UserService.ets
export class UserService {
    public getUser(id: number): User {
        // 实现逻辑
    }
}

// 在其他文件中导入
import { UserService } from '../services/UserService';

// 默认导出
export default class ConfigService {
    // 类实现
}

// 导入默认导出
import ConfigService from '../services/ConfigService';
```

### 5.2 依赖管理规范

#### 5.2.1 循环依赖避免
```typescript
// 错误示例：循环依赖
// ServiceA.ts
import { ServiceB } from './ServiceB';

// ServiceB.ts  
import { ServiceA } from './ServiceA'; // 循环依赖

// 正确解决方案：使用接口或依赖注入
interface IServiceB {
    doSomething(): void;
}

class ServiceA {
    constructor(private serviceB: IServiceB) {}
}
```

#### 5.2.2 模块边界清晰
```typescript
// 明确模块职责边界
// services/ 模块：数据处理和业务逻辑
// components/ 模块：UI展示和用户交互
// models/ 模块：数据结构和类型定义
```

## 6. 异步编程规范

### 6.1 Promise使用规范

#### 6.1.1 Promise链式调用
```typescript
class ApiService {
    public async fetchUserData(userId: number): Promise<User> {
        return fetch(`/api/users/${userId}`)
            .then(response => {
                if (!response.ok) {
                    throw new Error('Network response was not ok');
                }
                return response.json();
            })
            .then(data => new User(data))
            .catch(error => {
                console.error('Error fetching user data:', error);
                throw error;
            });
    }
}
```

#### 6.1.2 async/await使用
```typescript
class DataProcessor {
    public async processUserData(userId: number): Promise<ProcessResult> {
        try {
            const user = await this.apiService.fetchUserData(userId);
            const processedData = await this.processData(user);
            return this.formatResult(processedData);
        } catch (error) {
            console.error('Data processing failed:', error);
            throw new Error('Data processing failed');
        }
    }
}
```

### 6.2 错误处理规范

#### 6.2.1 统一错误处理
```typescript
// 自定义错误类
class AppError extends Error {
    constructor(
        message: string,
        public code: string,
        public details?: any
    ) {
        super(message);
        this.name = 'AppError';
    }
}

// 错误处理中间件
class ErrorHandler {
    public static handleError(error: Error): void {
        if (error instanceof AppError) {
            console.error(`AppError [${error.code}]: ${error.message}`);
        } else {
            console.error('Unexpected error:', error);
        }
    }
}
```

## 7. 性能优化规范

### 7.1 内存管理规范

#### 7.1.1 对象生命周期管理
```typescript
class ResourceManager {
    private resources: Map<string, any> = new Map();
    
    public setResource(key: string, resource: any): void {
        this.resources.set(key, resource);
    }
    
    public getResource(key: string): any {
        return this.resources.get(key);
    }
    
    public clearResource(key: string): void {
        const resource = this.resources.get(key);
        if (resource && typeof resource.dispose === 'function') {
            resource.dispose();
        }
        this.resources.delete(key);
    }
    
    public dispose(): void {
        this.resources.forEach((resource, key) => {
            this.clearResource(key);
        });
        this.resources.clear();
    }
}
```

#### 7.1.2 避免内存泄漏
```typescript
// 正确的事件监听管理
class EventManager {
    private listeners: Map<string, Function[]> = new Map();
    
    public addListener(event: string, callback: Function): void {
        if (!this.listeners.has(event)) {
            this.listeners.set(event, []);
        }
        this.listeners.get(event)!.push(callback);
    }
    
    public removeListener(event: string, callback: Function): void {
        const callbacks = this.listeners.get(event);
        if (callbacks) {
            const index = callbacks.indexOf(callback);
            if (index > -1) {
                callbacks.splice(index, 1);
            }
        }
    }
    
    public clearListeners(event?: string): void {
        if (event) {
            this.listeners.delete(event);
        } else {
            this.listeners.clear();
        }
    }
}
```

### 7.2 渲染性能优化

#### 7.2.1 组件优化
```typescript
@Component
struct OptimizedList {
    @State private items: string[] = [];
    
    build() {
        List() {
            ForEach(this.items, (item: string) => {
                ListItem() {
                    Text(item)
                        .fontSize(16)
                }
            }, (item: string) => item)
        }
        .cachedCount(5) // 缓存列表项提升性能
    }
}
```

#### 7.2.2 状态更新优化
```typescript
@Component
struct OptimizedComponent {
    @State private data: LargeData;
    
    // 避免不必要的状态更新
    private shouldUpdate(newData: LargeData): boolean {
        return JSON.stringify(this.data) !== JSON.stringify(newData);
    }
    
    public updateData(newData: LargeData): void {
        if (this.shouldUpdate(newData)) {
            this.data = newData;
        }
    }
}
```

## 8. 测试规范

### 8.1 单元测试规范

#### 8.1.1 测试用例结构
```typescript
// 测试工具类
class Calculator {
    public add(a: number, b: number): number {
        return a + b;
    }
    
    public multiply(a: number, b: number): number {
        return a * b;
    }
}

// 测试用例
describe('Calculator', () => {
    let calculator: Calculator;
    
    beforeEach(() => {
        calculator = new Calculator();
    });
    
    it('should add two numbers correctly', () => {
        const result = calculator.add(2, 3);
        expect(result).toBe(5);
    });
    
    it('should multiply two numbers correctly', () => {
        const result = calculator.multiply(4, 5);
        expect(result).toBe(20);
    });
});
```

#### 8.1.2 异步测试
```typescript
describe('ApiService', () => {
    it('should fetch user data successfully', async () => {
        const apiService = new ApiService();
        const user = await apiService.fetchUserData(1);
        
        expect(user).toBeDefined();
        expect(user.id).toBe(1);
        expect(user.name).toBe('Test User');
    });
    
    it('should handle fetch errors', async () => {
        const apiService = new ApiService();
        
        await expect(apiService.fetchUserData(-1))
            .rejects.toThrow('User not found');
    });
});
```

### 8.2 集成测试规范

#### 8.2.1 组件测试
```typescript
describe('UserComponent', () => {
    it('should display user information correctly', () => {
        const user = new User(1, 'John Doe', 30);
        
        const component = new UserComponent();
        component.user = user;
        
        // 模拟组件渲染和断言
        expect(component.getDisplayText()).toBe('John Doe (30)');
    });
});
```

## 9. 代码质量规范

### 9.1 代码审查规范

#### 9.1.1 审查要点
- **类型安全**：确保没有使用any和unknown类型
- **性能考虑**：检查潜在的性能问题
- **错误处理**：验证错误处理逻辑的完整性
- **代码复用**：评估代码的可复用性

#### 9.1.2 审查清单
```typescript
// 代码审查清单示例
class CodeReviewChecklist {
    public static checkTypeSafety(code: string): boolean {
        return !code.includes(': any') && !code.includes(': unknown');
    }
    
    public static checkErrorHandling(code: string): boolean {
        return code.includes('try') && code.includes('catch');
    }
    
    public static checkPerformance(code: string): boolean {
        return !code.includes('JSON.stringify') || 
               code.includes('cachedCount');
    }
}
```

### 9.2 文档规范

#### 9.2.1 代码注释
```typescript
/**
 * 用户服务类
 * 提供用户相关的业务逻辑处理
 */
class UserService {
    /**
     * 根据用户ID获取用户信息
     * @param userId - 用户ID
     * @returns 用户对象
     * @throws 当用户不存在时抛出错误
     */
    public getUser(userId: number): User {
        // 实现逻辑
    }
}
```

#### 9.2.2 API文档
```typescript
/**
 * @interface IUserService
 * 用户服务接口定义
 */
interface IUserService {
    /**
     * 创建新用户
     * @param userData - 用户数据
     * @returns 创建的用户ID
     */
    createUser(userData: UserData): number;
}
```

## 10. 最佳实践总结

### 10.1 开发原则
- **类型安全优先**：始终使用明确的类型声明
- **单一职责**：每个函数/类只负责一个明确的功能
- **错误处理完备**：对所有可能出错的情况进行处理
- **性能意识**：在开发过程中始终考虑性能影响

### 10.2 代码风格
- **一致性**：保持团队内的代码风格一致
- **可读性**：编写易于理解和维护的代码
- **模块化**：将功能拆分为独立的模块
- **测试驱动**：优先编写测试用例

### 10.3 持续改进
- **代码审查**：定期进行代码审查和改进
- **性能监控**：持续监控应用性能指标
- **技术债务**：及时处理技术债务
- **知识分享**：促进团队技术成长和知识传承

此规范文档为ArkTS开发提供了全面的指导，开发团队应严格遵守这些规范，确保代码质量和项目可维护性。