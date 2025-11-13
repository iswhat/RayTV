# ArkTS开发规范指南

## 1. 组件导入规范

### 1.1 标准导入方式
```typescript
// ✅ 正确方式
import { ListItem, Text, Button } from '@arkui/native';

// ❌ 错误方式
import { ListItem as ListItemComponent } from '@arkui/native';
```

### 1.2 导入规则
- 禁止使用组件别名导入
- 保持组件名称与官方文档一致
- 按功能模块分组导入

## 2. 组件属性语法规范

### 2.1 属性设置方式
```typescript
// ✅ 正确方式
<ProgressBar 
  strokeWidth={4}
  color="#FF4500"
  percent={progressValue}
/>

// ❌ 错误方式
<ProgressBar style={{ strokeWidth: 4, color: '#FF4500' }} />
```

### 2.2 属性设置规则
- 使用独立属性而非style对象
- 数值属性使用花括号包裹
- 字符串属性使用引号包裹

## 3. 组件使用最佳实践

### 3.1 ListItem组件
```typescript
// ✅ 正确使用
ListItem() {
  Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
    Image($r('app.media.icon'))
      .width(40)
      .height(40)
    
    Text(item.title)
      .fontSize(16)
      .fontWeight(FontWeight.Medium)
  }
  .padding(12)
}
```

### 3.2 ProgressBar组件
```typescript
// ✅ 正确使用
ProgressBar({
  value: currentProgress,
  total: totalValue
})
.strokeWidth(4)
.color('#FF4500')
.width('100%')
```

## 4. 状态管理规范

### 4.1 状态声明
```typescript
@State progressValue: number = 0;
@State mediaList: MediaItem[] = [];
@State isLoading: boolean = false;
```

### 4.2 状态更新
```typescript
// ✅ 正确方式
this.progressValue = newValue;
this.mediaList = updatedList;

// ❌ 错误方式
// 避免直接修改数组或对象内部属性
```

## 5. 事件处理规范

### 5.1 点击事件
```typescript
.onClick(() => {
  this.handleItemClick(item);
})
```

### 5.2 生命周期事件
```typescript
aboutToAppear() {
  this.loadInitialData();
}

aboutToDisappear() {
  this.cleanupResources();
}
```

## 6. 代码组织结构

### 6.1 页面结构
```typescript
@Component
struct HomePage {
  // 1. 状态声明
  @State data: any[] = [];
  
  // 2. 生命周期方法
  aboutToAppear() {
    // 初始化逻辑
  }
  
  // 3. 业务方法
  private loadData() {
    // 数据加载逻辑
  }
  
  // 4. 渲染方法
  private renderItem(item: any) {
    // 组件渲染逻辑
  }
  
  // 5. 构建方法
  build() {
    // 页面布局
  }
}
```

## 7. 错误处理规范

### 7.1 零除保护
```typescript
// ✅ 正确方式
const progressPercent = duration > 0 ? (currentTime / duration) * 100 : 0;

// ❌ 错误方式
const progressPercent = (currentTime / duration) * 100; // 可能除零
```

### 7.2 空值检查
```typescript
// ✅ 正确方式
if (item && item.title) {
  Text(item.title)
}

// 或者使用安全访问
Text(item?.title || '默认标题')
```

## 8. 性能优化建议

### 8.1 列表渲染优化
- 使用ForEach渲染大型列表
- 为列表项设置唯一key
- 避免在渲染函数中进行复杂计算

### 8.2 状态更新优化
- 批量更新相关状态
- 使用@Link进行组件间通信
- 避免不必要的重新渲染

## 9. 兼容性要求

### 9.1 API版本兼容
- 确保使用HarmonyOS API 9兼容的组件
- 检查组件属性在不同API版本的可用性
- 使用条件编译处理版本差异

### 9.2 设备适配
- 考虑不同屏幕尺寸的布局适配
- 处理横竖屏切换
- 适配不同设备的能力差异

## 10. 代码审查要点

### 10.1 语法检查
- [ ] 组件导入方式正确
- [ ] 属性语法符合规范
- [ ] 没有使用已废弃的API

### 10.2 功能检查
- [ ] 事件处理逻辑正确
- [ ] 状态管理合理
- [ ] 错误处理完善

### 10.3 性能检查
- [ ] 没有内存泄漏风险
- [ ] 渲染性能优化
- [ ] 资源使用合理

---

**最后更新：2024年**  
**适用版本：HarmonyOS ArkTS API 9+**