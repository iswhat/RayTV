/**
 * NavigationGuard 单元测试 | Unit tests for NavigationGuard
 * 测试导航守卫系统的各项功能
 * Tests various functions of the navigation guard system
 */
import { NavigationGuardManager, NavigationGuard, NavigationGuardConfig } from '../navigation/NavigationGuard';
import { RouteDefinition, NavigationOptions } from '../navigation/RouteManager';
import { AppState } from '../common/state/AppState';

// 模拟路由定义 | Mock route definition
const mockRoute: RouteDefinition = {
  name: 'test-route',
  path: '/test',
  component: 'TestComponent',
  meta: {
    requiresAuth: false,
    title: 'Test Page'
  }
};

const protectedRoute: RouteDefinition = {
  name: 'protected-route',
  path: '/protected',
  component: 'ProtectedComponent',
  meta: {
    requiresAuth: true,
    title: 'Protected Page'
  }
};

const cachedRoute: RouteDefinition = {
  name: 'cached-route',
  path: '/cached',
  component: 'CachedComponent',
  meta: {
    cacheable: true,
    title: 'Cached Page'
  }
};

const deviceCapabilityRoute: RouteDefinition = {
  name: 'device-capability-route',
  path: '/device',
  component: 'DeviceComponent',
  meta: {
    requiredCapabilities: ['video', 'audio'],
    title: 'Device Capability Page'
  }
};

// 模拟导航选项 | Mock navigation options
const mockOptions: NavigationOptions = {
  animated: true,
  replace: false,
  params: {}
};

describe('NavigationGuardManager', () => {
  let guardManager: NavigationGuardManager;
  
  beforeEach(() => {
    guardManager = NavigationGuardManager.getInstance();
    // 重置守卫管理器，确保每次测试都是干净的状态
    guardManager.reset();
  });
  
  afterEach(() => {
    // 清理状态
    AppState.rateLimits = {};
  });
  
  describe('基础功能测试', () => {
    it('应该能够获取单例实例', () => {
      // Act
      const instance1 = NavigationGuardManager.getInstance();
      const instance2 = NavigationGuardManager.getInstance();
      
      // Assert
      expect(instance1).toBe(instance2);
    });
    
    it('应该能够添加和获取守卫', () => {
      // Arrange
      const testGuard: NavigationGuard = (to, from, options) => true;
      const guardConfig: NavigationGuardConfig = {
        name: 'test-guard',
        guard: testGuard,
        priority: 50
      };
      
      // Act
      guardManager.addGuard(guardConfig);
      const retrievedGuard = guardManager.getGuard('test-guard');
      
      // Assert
      expect(retrievedGuard).toBeDefined();
      expect(retrievedGuard?.name).toBe('test-guard');
      expect(retrievedGuard?.priority).toBe(50);
    });
    
    it('应该能够移除守卫', () => {
      // Arrange
      const testGuard: NavigationGuard = (to, from, options) => true;
      const guardConfig: NavigationGuardConfig = {
        name: 'test-guard',
        guard: testGuard,
        priority: 50
      };
      guardManager.addGuard(guardConfig);
      
      // Act
      guardManager.removeGuard('test-guard');
      const retrievedGuard = guardManager.getGuard('test-guard');
      
      // Assert
      expect(retrievedGuard).toBeUndefined();
    });
    
    it('应该能够清除所有守卫', () => {
      // Arrange
      const testGuard1: NavigationGuard = (to, from, options) => true;
      const testGuard2: NavigationGuard = (to, from, options) => true;
      guardManager.addGuard({ name: 'guard1', guard: testGuard1, priority: 50 });
      guardManager.addGuard({ name: 'guard2', guard: testGuard2, priority: 60 });
      
      // Act
      guardManager.clearGuards();
      const guards = guardManager.getGuards();
      
      // Assert
      expect(guards.length).toBe(0);
    });
    
    it('应该能够更新守卫配置', () => {
      // Arrange
      const initialGuard: NavigationGuard = (to, from, options) => true;
      const updatedGuard: NavigationGuard = (to, from, options) => false;
      guardManager.addGuard({ name: 'test-guard', guard: initialGuard, priority: 50 });
      
      // Act
      guardManager.updateGuard('test-guard', { priority: 70, guard: updatedGuard });
      const updatedConfig = guardManager.getGuard('test-guard');
      
      // Assert
      expect(updatedConfig?.priority).toBe(70);
      // 验证守卫函数是否更新
      const result = updatedConfig?.guard(mockRoute, null, mockOptions);
      expect(result).toBe(false);
    });
  });
  
  describe('守卫执行测试', () => {
    it('应该能够执行多个守卫并返回正确结果', async () => {
      // Arrange
      let guard1Called = false;
      let guard2Called = false;
      
      const guard1: NavigationGuard = (to, from, options) => {
        guard1Called = true;
        return true;
      };
      
      const guard2: NavigationGuard = (to, from, options) => {
        guard2Called = true;
        return true;
      };
      
      guardManager.addGuard({ name: 'guard1', guard: guard1, priority: 50 });
      guardManager.addGuard({ name: 'guard2', guard: guard2, priority: 60 });
      
      // Act
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(true);
      expect(guard1Called).toBe(true);
      expect(guard2Called).toBe(true);
    });
    
    it('应该在某个守卫返回false时阻止导航', async () => {
      // Arrange
      let guard1Called = false;
      let guard2Called = false;
      
      const guard1: NavigationGuard = (to, from, options) => {
        guard1Called = true;
        return true;
      };
      
      const guard2: NavigationGuard = (to, from, options) => {
        guard2Called = true;
        return false;
      };
      
      const guard3: NavigationGuard = (to, from, options) => {
        // 这个守卫不应该被调用
        throw new Error('Guard3 should not be called');
      };
      
      guardManager.addGuard({ name: 'guard1', guard: guard1, priority: 50 });
      guardManager.addGuard({ name: 'guard2', guard: guard2, priority: 60 });
      guardManager.addGuard({ name: 'guard3', guard: guard3, priority: 40 });
      
      // Act
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(false);
      expect(guard1Called).toBe(true);
      expect(guard2Called).toBe(true);
    });
    
    it('应该按优先级顺序执行守卫', async () => {
      // Arrange
      const executionOrder: string[] = [];
      
      const guard1: NavigationGuard = (to, from, options) => {
        executionOrder.push('guard1');
        return true;
      };
      
      const guard2: NavigationGuard = (to, from, options) => {
        executionOrder.push('guard2');
        return true;
      };
      
      const guard3: NavigationGuard = (to, from, options) => {
        executionOrder.push('guard3');
        return true;
      };
      
      // 优先级：guard2 > guard1 > guard3
      guardManager.addGuard({ name: 'guard1', guard: guard1, priority: 50 });
      guardManager.addGuard({ name: 'guard2', guard: guard2, priority: 100 });
      guardManager.addGuard({ name: 'guard3', guard: guard3, priority: 10 });
      
      // Act
      await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(executionOrder).toEqual(['guard2', 'guard1', 'guard3']);
    });
    
    it('应该处理守卫执行过程中的错误', async () => {
      // Arrange
      const errorGuard: NavigationGuard = (to, from, options) => {
        throw new Error('Guard error');
      };
      
      guardManager.addGuard({ name: 'error-guard', guard: errorGuard, priority: 50 });
      
      // Act & Assert
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      expect(result).toBe(false);
    });
  });
  
  describe('默认守卫测试', () => {
    it('认证守卫应该允许访问无需认证的路由', async () => {
      // Act
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(true);
    });
    
    it('认证守卫应该阻止访问需要认证的路由', async () => {
      // Arrange
      // 确保用户未认证
      AppState.logout();
      
      // Act
      const result = await guardManager.canActivate(protectedRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(false);
    });
    
    it('网络状态守卫应该在网络连接时允许导航', async () => {
      // Arrange
      // 设置网络状态为已连接
      AppState.setNetworkStatus(true, 'wifi');
      
      // Act
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(true);
    });
    
    it('网络状态守卫应该在网络断开时阻止导航', async () => {
      // Arrange
      // 设置网络状态为断开
      AppState.setNetworkStatus(false, 'unknown');
      
      // Act
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(false);
    });
    
    it('速率限制守卫应该允许首次访问', async () => {
      // Act
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(true);
    });
    
    it('速率限制守卫应该在短时间内多次访问时阻止导航', async () => {
      // Arrange
      // 首次访问，应该允许
      await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Act - 立即再次访问，应该被限制
      const result = await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(false);
    });
    
    it('缓存守卫应该正确处理可缓存的路由', async () => {
      // Act
      const result = await guardManager.canActivate(cachedRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(true);
    });
    
    it('设备能力守卫应该正确处理需要特定能力的路由', async () => {
      // Act
      const result = await guardManager.canActivate(deviceCapabilityRoute, null, mockOptions);
      
      // Assert
      expect(result).toBe(true);
    });
  });
  
  describe('路由特定守卫测试', () => {
    it('应该只对指定路由执行特定守卫', async () => {
      // Arrange
      let testRouteGuardCalled = false;
      let otherRouteGuardCalled = false;
      
      const testRouteGuard: NavigationGuard = (to, from, options) => {
        testRouteGuardCalled = true;
        return true;
      };
      
      const otherRouteGuard: NavigationGuard = (to, from, options) => {
        otherRouteGuardCalled = true;
        return true;
      };
      
      // 只对test-route执行
      guardManager.addGuard({ 
        name: 'test-route-guard', 
        guard: testRouteGuard, 
        priority: 50,
        routes: ['test-route']
      });
      
      // 只对other-route执行
      guardManager.addGuard({ 
        name: 'other-route-guard', 
        guard: otherRouteGuard, 
        priority: 50,
        routes: ['other-route']
      });
      
      // Act
      await guardManager.canActivate(mockRoute, null, mockOptions);
      
      // Assert
      expect(testRouteGuardCalled).toBe(true);
      expect(otherRouteGuardCalled).toBe(false);
    });
  });
  
  describe('重置功能测试', () => {
    it('应该能够重置守卫管理器到默认状态', () => {
      // Arrange
      const customGuard: NavigationGuard = (to, from, options) => true;
      guardManager.addGuard({ name: 'custom-guard', guard: customGuard, priority: 50 });
      
      // 验证自定义守卫已添加
      expect(guardManager.getGuard('custom-guard')).toBeDefined();
      
      // Act
      guardManager.reset();
      
      // Assert
      expect(guardManager.getGuard('custom-guard')).toBeUndefined();
      // 验证默认守卫已重新添加
      expect(guardManager.getGuard('auth')).toBeDefined();
      expect(guardManager.getGuard('network')).toBeDefined();
      expect(guardManager.getGuard('permission')).toBeDefined();
    });
  });
  
  describe('销毁功能测试', () => {
    it('应该能够销毁守卫管理器', () => {
      // Arrange
      const customGuard: NavigationGuard = (to, from, options) => true;
      guardManager.addGuard({ name: 'custom-guard', guard: customGuard, priority: 50 });
      
      // Act
      guardManager.destroy();
      
      // Assert
      expect(guardManager.getGuards().length).toBe(0);
    });
  });
});
