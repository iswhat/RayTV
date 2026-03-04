# ArkTS违规批量修复计划

## 修复进度

### ✅ 已完成 (第一批 - 37处)
- any类型修复: 30处
- 索引签名修复: 5处
- 索引访问修复: 2处

### 🔄 进行中 (第二批 - 目标100处)
- Record<string, any> → Record<string, Object> (22个文件)
- any类型 → unknown/具体类型 (批量修复)
- 其他P0级别问题

### ⏳ 待处理
- P1级别: 125处
- P2级别: 32处

## 批量修复脚本

由于违规数量庞大，建议使用以下修复策略：

### 策略1: 使用正则表达式批量替换

```bash
# 在IDE中使用正则替换
查找: \bRecord<\s*string\s*,\s*any\s*>
替换: Record<string, Object>

查找: :\s*any\b(?!\s*\[)
替换: : unknown

查找: :\s*any\[\]
替换: : unknown[]
```

### 策略2: 修复Object.keys/values/entries

```typescript
// 导入ObjectUtils
import ObjectUtils from '../common/util/ark/ObjectUtils';

// 替换前
Object.keys(obj).forEach(key => {
  // ...
});

// 替换后
const keys = ObjectUtils.getKeys(obj);
for (let i = 0; i < keys.length; i++) {
  const key = keys[i];
  // ...
}
```

### 策略3: 修复in运算符

```typescript
// 导入ObjectUtils
import ObjectUtils from '../common/util/ark/ObjectUtils';

// 替换前
if (key in obj) {
  // ...
}

// 替换后
if (ObjectUtils.hasProperty(obj, key)) {
  // ...
}
```

## 优先级修复清单

### 高优先级 (核心服务)
1. SearchService.ets
2. HistoryService.ets
3. ConfigSourceService.ets
4. SiteRepository.ets
5. DefaultNetworkRepository.ets
6. HttpService.ets
7. NASProtocolAdapter.ets
8. ArkJarLoader.ets

### 中优先级 (业务逻辑)
9. SearchRepository.ets
10. RecommendationRepository.ets
11. PlaybackRepository.ets
12. SQLiteHelper.ets
13. ConfigRepository.ets

### 低优先级 (辅助功能)
14. UtilityFunctions.ets
15. ObjectUtils.ets
16. TypeSafetyUtil.ets
17. ErrorBoundary.ets
18. BreakpointManager.ts

## 测试检查清单

修复完成后，需要验证：

- [ ] 编译无错误
- [ ] 所有单元测试通过
- [ ] 集成测试通过
- [ ] UI渲染正常
- [ ] 核心功能正常工作

## 注意事项

1. 每次修复后都要测试
2. 保持代码风格一致
3. 不要引入新的问题
4. 记录所有修复内容
5. 更新相关文档
