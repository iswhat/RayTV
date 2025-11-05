# HarmonyOS API 迁移指南

## 概述

本文档记录了RayTV项目从旧版HarmonyOS API迁移到新版API的完整过程，包括已弃用API的替代方案、代码修改示例和最佳实践。

## 已修复的API迁移问题

### 1. 数据库访问层迁移

**问题**: 使用已弃用的`@ohos.data.rdb` API

**解决方案**: 迁移到现代化的数据库访问层

**修改文件**: 
- `SQLiteDatabaseRepository.ets` - 已创建现代化数据库访问层
- `ModernDatabaseService.ets` - 新的数据库服务实现

**关键变更**:
- 使用`@ohos.data.relationalStore`替代`@ohos.data.rdb`
- 实现异步数据操作
- 添加事务支持
- 改进错误处理机制

### 2. 分布式数据API迁移

**问题**: 使用已弃用的`@ohos.data.distributedData` API

**解决方案**: 迁移到`@ohos.data.distributedKVStore`

**修改文件**:
- `DistributedDataService.ets` - 已修复弃用API
- `ModernDistributedDataService.ets` - 新的分布式数据服务实现

**关键变更**:
- 使用`distributedKVStore.getKVStore()`替代`distributedData.getKVStore()`
- 更新同步配置接口
- 改进设备间数据同步机制

### 3. 网络权限管理

**问题**: 缺少必要的网络权限申请

**解决方案**: 添加权限申请逻辑

**修改文件**:
- `NetworkUtil.ets` - 添加上下文管理和权限申请
- `HttpService.ets` - 在请求方法中添加权限检查

**关键变更**:
- 添加上下文管理功能
- 在HTTP请求前检查网络权限
- 实现权限申请失败的错误处理

## 依赖配置更新

### 新增依赖

```json5
"@ohos.data.distributedKVStore": "^9.0.0",
"@ohos.data.relationalStore": "^9.0.0",
"@ohos.abilityAccessCtrl": "^9.0.0",
"@ohos.app.ability.common": "^9.0.0",
"@ohos.security.cryptoFramework": "^9.0.0"
```

### 权限配置更新

在`app.json5`中添加：
```json
{
  "name": "ohos.permission.DISTRIBUTED_DATASYNC"
},
{
  "name": "ohos.permission.ACCESS_DISTRIBUTED_SERVICE"
}
```

## 代码规范

### 1. 上下文管理规范

**要求**: 所有需要访问系统资源的服务类必须实现上下文管理

**示例**:
```typescript
private context: common.Context | null = null;

public setContext(ctx: common.Context): void {
  this.context = ctx;
}

private getContext(): common.Context {
  if (!this.context) {
    throw new Error('Context not initialized. Call setContext() first.');
  }
  return this.context;
}
```

### 2. 权限申请规范

**要求**: 在执行需要权限的操作前必须检查并申请权限

**示例**:
```typescript
private async checkNetworkPermission(): Promise<void> {
  try {
    const atManager = abilityAccessCtrl.createAtManager();
    const context = this.getContext();
    
    await atManager.requestPermissionsFromUser(context, [
      'ohos.permission.INTERNET'
    ]);
  } catch (error) {
    console.error('Failed to request network permission:', error);
  }
}
```

### 3. 异步操作规范

**要求**: 所有I/O操作必须使用异步方式

**示例**:
```typescript
public async queryData<T>(query: string, params: any[] = []): Promise<T[]> {
  try {
    const resultSet = await this.rdbStore.query(query, params);
    return this.processResultSet<T>(resultSet);
  } catch (error) {
    console.error('Database query failed:', error);
    throw error;
  }
}
```

## 迁移检查清单

### 已完成的项目

- [x] 修复SQLiteDatabaseRepository.ets中的弃用API
- [x] 修复MainAbility.ts中的异常处理
- [x] 为NetworkUtil.ets和HttpService.ets添加权限申请
- [x] 修复DistributedDataService.ets中的弃用API
- [x] 创建现代化数据库访问层
- [x] 更新项目依赖配置
- [x] 添加必要的权限配置

### 建议的后续改进

- [ ] 实现数据加密存储
- [ ] 添加性能监控
- [ ] 实现离线数据同步
- [ ] 添加单元测试覆盖

## 常见问题解答

### Q: 如何判断API是否已弃用？
A: 参考HarmonyOS官方文档，检查API的@deprecated注解，或查看编译警告信息。

### Q: 迁移过程中遇到兼容性问题怎么办？
A: 建议逐步迁移，先创建新的服务类，然后逐步替换旧代码，确保功能正常后再删除旧实现。

### Q: 如何测试迁移后的功能？
A: 建议使用单元测试和集成测试，确保数据操作、网络请求和分布式同步等功能正常工作。

## 版本兼容性

- **目标API版本**: 9.0.0
- **最低API版本**: 9.0.0
- **测试设备**: phone, tablet, 2in1, tv

## 联系方式

如有问题或建议，请联系开发团队。

---

*文档版本: 1.0*  
*最后更新: 2024年*  
*维护者: RayTV开发团队*