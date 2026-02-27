/**
 * EnhancedDIContainer 单元测试 | Unit tests for EnhancedDIContainer
 * 测试增强型依赖注入容器的各项功能
 * Tests various functions of the enhanced dependency injection container
 */
import { EnhancedDIContainer } from '../common/di/EnhancedContainer';
import { ServiceLifecycle, LifecycleState } from '../common/di/ServiceLifecycle';

// 测试用的模拟服务类 | Test mock service classes
class TestServiceA {
  constructor(public value: string = 'A') {}
  
  getValue(): string {
    return this.value;
  }
}

class TestServiceB {
  constructor(private serviceA: TestServiceA) {}
  
  getCombinedValue(): string {
    return `B -> ${this.serviceA.getValue()}`;
  }
}

class TestServiceC {
  constructor(private serviceB: TestServiceB, private serviceA: TestServiceA) {}
  
  getComplexValue(): string {
    return `C -> ${this.serviceB.getCombinedValue()} -> ${this.serviceA.getValue()}`;
  }
}

// 测试生命周期管理器 | Test lifecycle manager
class TestLifecycleService implements ServiceLifecycle {
  public initialized: boolean = false;
  public destroyed: boolean = false;
  public activated: boolean = false;
  public deactivated: boolean = false;
  
  async onInitialize(): Promise<void> {
    this.initialized = true;
  }
  
  async onDestroy(): Promise<void> {
    this.destroyed = true;
  }
  
  onActivate(): void {
    this.activated = true;
  }
  
  onDeactivate(): void {
    this.deactivated = true;
  }
}

describe('EnhancedDIContainer', () => {
  let container: EnhancedDIContainer;
  
  beforeEach(() => {
    container = EnhancedDIContainer.getInstance();
  });
  
  afterEach(async () => {
    await container.destroy();
  });
  
  describe('基础注册和解析功能', () => {
    it('应该能够注册和解析简单的服务', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA('test'));
      
      // Act
      const service = container.resolve<TestServiceA>('serviceA');
      
      // Assert
      expect(service).toBeInstanceOf(TestServiceA);
      expect(service.getValue()).toBe('test');
    });
    
    it('应该支持单例模式', () => {
      // Arrange
      let creationCount = 0;
      container.register<TestServiceA>('serviceA', () => {
        creationCount++;
        return new TestServiceA(`instance-${creationCount}`);
      }, true);
      
      // Act
      const service1 = container.resolve<TestServiceA>('serviceA');
      const service2 = container.resolve<TestServiceA>('serviceA');
      
      // Assert
      expect(creationCount).toBe(1);
      expect(service1).toBe(service2);
      expect(service1.getValue()).toBe('instance-1');
    });
    
    it('应该支持多例模式', () => {
      // Arrange
      let creationCount = 0;
      container.register<TestServiceA>('serviceA', () => {
        creationCount++;
        return new TestServiceA(`instance-${creationCount}`);
      }, false);
      
      // Act
      const service1 = container.resolve<TestServiceA>('serviceA');
      const service2 = container.resolve<TestServiceA>('serviceA');
      
      // Assert
      expect(creationCount).toBe(2);
      expect(service1).not.toBe(service2);
      expect(service1.getValue()).toBe('instance-1');
      expect(service2.getValue()).toBe('instance-2');
    });
    
    it('应该能够检查服务是否存在', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA());
      
      // Act & Assert
      expect(container.has('serviceA')).toBe(true);
      expect(container.has('nonExistentService')).toBe(false);
    });
  });
  
  describe('依赖解析功能', () => {
    it('应该能够解析带依赖的服务', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA('dependency'));
      container.register<TestServiceB>('serviceB', (serviceA: TestServiceA) => new TestServiceB(serviceA), true, ['serviceA']);
      
      // Act
      const serviceB = container.resolve<TestServiceB>('serviceB');
      
      // Assert
      expect(serviceB).toBeInstanceOf(TestServiceB);
      expect(serviceB.getCombinedValue()).toBe('B -> dependency');
    });
    
    it('应该能够解析复杂的依赖链', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA('root'));
      container.register<TestServiceB>('serviceB', (serviceA: TestServiceA) => new TestServiceB(serviceA), true, ['serviceA']);
      container.register<TestServiceC>('serviceC', (serviceB: TestServiceB, serviceA: TestServiceA) => 
        new TestServiceC(serviceB, serviceA), true, ['serviceB', 'serviceA']);
      
      // Act
      const serviceC = container.resolve<TestServiceC>('serviceC');
      
      // Assert
      expect(serviceC).toBeInstanceOf(TestServiceC);
      expect(serviceC.getComplexValue()).toBe('C -> B -> root -> root');
    });
  });
  
  describe('循环依赖检测', () => {
    it('应该能够检测直接循环依赖', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA(), true, ['serviceB']);
      container.register<TestServiceB>('serviceB', () => new TestServiceB(), true, ['serviceA']);
      
      // Act & Assert
      expect(() => container.resolve<TestServiceA>('serviceA')).toThrow(/Circular dependency detected/);
    });
    
    it('应该能够检测间接循环依赖', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA(), true, ['serviceB']);
      container.register<TestServiceB>('serviceB', () => new TestServiceB(), true, ['serviceC']);
      container.register<TestServiceC>('serviceC', () => new TestServiceC(), true, ['serviceA']);
      
      // Act & Assert
      expect(() => container.resolve<TestServiceA>('serviceA')).toThrow(/Circular dependency detected/);
    });
    
    it('应该返回正确的循环依赖路径', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA(), true, ['serviceB']);
      container.register<TestServiceB>('serviceB', () => new TestServiceB(), true, ['serviceC']);
      container.register<TestServiceC>('serviceC', () => new TestServiceC(), true, ['serviceA']);
      
      // Act
      const cycleResult = container.findCircularPath('serviceA');
      
      // Assert
      expect(cycleResult.hasCircular).toBe(true);
      expect(cycleResult.cyclePath).toEqual(['serviceA', 'serviceB', 'serviceC', 'serviceA']);
    });
  });
  
  describe('延迟解析功能', () => {
    it('应该能够注册和解析延迟服务', async () => {
      // Arrange
      let resolved = false;
      container.registerLazy<TestServiceA>('lazyService', async () => {
        resolved = true;
        return new TestServiceA('lazy-loaded');
      });
      
      // Act
      const service = await container.resolveAsync<TestServiceA>('lazyService');
      
      // Assert
      expect(resolved).toBe(true);
      expect(service.getValue()).toBe('lazy-loaded');
    });
    
    it('应该能够在同步解析时处理延迟服务', () => {
      // Arrange
      container.registerLazy<TestServiceA>('lazyService', async () => new TestServiceA('lazy'));
      
      // Act & Assert
      expect(() => container.resolve<TestServiceA>('lazyService'))
        .toThrow(/Lazy resolver found/);
    });
  });
  
  describe('批量注册功能', () => {
    it('应该能够批量注册多个服务', () => {
      // Arrange
      const services = [
        {
          token: 'serviceA',
          factory: () => new TestServiceA('batch-A')
        },
        {
          token: 'serviceB',
          factory: (serviceA: TestServiceA) => new TestServiceB(serviceA),
          dependencies: ['serviceA']
        }
      ];
      
      // Act
      container.registerBatch(services);
      
      // Assert
      const serviceB = container.resolve<TestServiceB>('serviceB');
      expect(serviceB.getCombinedValue()).toBe('B -> batch-A');
    });
  });
  
  describe('生命周期管理', () => {
    it('应该能够注册和管理服务生命周期', async () => {
      // Arrange
      const lifecycleService = new TestLifecycleService();
      container.register<TestServiceA>('lifecycleService', () => new TestServiceA('lifecycle'), true);
      container.registerLifecycle('lifecycleService', lifecycleService);
      
      // Act
      await container.getLifecycle('lifecycleService')?.onInitialize?.();
      
      // Assert
      expect(lifecycleService.initialized).toBe(true);
      expect(lifecycleService.destroyed).toBe(false);
    });
    
    it('应该能够获取服务状态', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA());
      
      // Act
      const tokens = container.getAllTokens();
      const hasService = container.has('serviceA');
      
      // Assert
      expect(tokens).toContain('serviceA');
      expect(hasService).toBe(true);
    });
  });
  
  describe('元数据和监控', () => {
    it('应该能够记录服务解析元数据', () => {
      // Arrange
      container.register<TestServiceA>('serviceA', () => new TestServiceA());
      
      // Act
      container.resolve<TestServiceA>('serviceA');
      const metadata = container.getServiceMetadata('serviceA');
      
      // Assert
      expect(metadata).toBeDefined();
      expect(metadata?.resolveCount).toBe(1);
      expect(metadata?.lastResolved).toBeGreaterThan(0);
    });
    
    it('应该正确统计解析次数', () => {
      // Arrange
      let creationCount = 0;
      container.register<TestServiceA>('serviceA', () => {
        creationCount++;
        return new TestServiceA(`call-${creationCount}`);
      }, false);
      
      // Act
      container.resolve<TestServiceA>('serviceA');
      container.resolve<TestServiceA>('serviceA');
      const metadata = container.getServiceMetadata('serviceA');
      
      // Assert
      expect(creationCount).toBe(2);
      expect(metadata?.resolveCount).toBe(2);
    });
  });
  
  describe('错误处理', () => {
    it('应该在解析不存在的服务时抛出错误', () => {
      // Act & Assert
      expect(() => container.resolve<TestServiceA>('nonExistent'))
        .toThrow(/Service nonExistent not registered/);
    });
    
    it('应该在依赖缺失时抛出错误', () => {
      // Arrange
      container.register<TestServiceB>('serviceB', (serviceA: TestServiceA) => new TestServiceB(serviceA), true, ['missingService']);
      
      // Act & Assert
      expect(() => container.resolve<TestServiceB>('serviceB'))
        .toThrow(/Missing dependency: missingService/);
    });
    
    it('应该在工厂函数抛出错误时正确处理', () => {
      // Arrange
      container.register<TestServiceA>('failingService', () => {
        throw new Error('Factory failed');
      });
      
      // Act & Assert
      expect(() => container.resolve<TestServiceA>('failingService'))
        .toThrow(/Failed to resolve service failingService/);
    });
  });
  
  describe('容器清理功能', () => {
    it('应该能够清除单例实例', () => {
      // Arrange
      let creationCount = 0;
      container.register<TestServiceA>('serviceA', () => {
        creationCount++;
        return new TestServiceA(`instance-${creationCount}`);
      }, true);
      
      const service1 = container.resolve<TestServiceA>('serviceA');
      
      // Act
      container.clearSingleton('serviceA');
      const service2 = container.resolve<TestServiceA>('serviceA');
      
      // Assert
      expect(creationCount).toBe(2);
      expect(service1).not.toBe(service2);
    });
    
    it('应该能够销毁整个容器', async () => {
      // Arrange
      const lifecycleService = new TestLifecycleService();
      container.register<TestServiceA>('serviceA', () => new TestServiceA());
      container.registerLifecycle('serviceA', lifecycleService);
      
      // Act
      await container.destroy();
      
      // Assert
      expect(() => container.resolve<TestServiceA>('serviceA'))
        .toThrow(/Service serviceA not registered/);
    });
  });
});

// 性能基准测试 | Performance benchmark tests
describe('Performance Tests', () => {
  let container: EnhancedDIContainer;
  
  beforeEach(() => {
    container = EnhancedDIContainer.getInstance();
  });
  
  afterEach(async () => {
    await container.destroy();
  });
  
  it('应该在合理时间内完成大量服务注册', () => {
    // Arrange
    const serviceCount = 1000;
    const services = [];
    
    // Act
    const startTime = performance.now();
    
    for (let i = 0; i < serviceCount; i++) {
      services.push({
        token: `service${i}`,
        factory: () => ({ id: i, name: `Service ${i}` })
      });
    }
    
    container.registerBatch(services);
    
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    // Assert
    expect(duration).toBeLessThan(100); // 100ms以内完成
    expect(container.getAllTokens().length).toBe(serviceCount);
  });
  
  it('应该在合理时间内完成服务解析', () => {
    // Arrange
    container.register<TestServiceA>('serviceA', () => new TestServiceA('perf-test'));
    
    // Act
    const startTime = performance.now();
    
    for (let i = 0; i < 1000; i++) {
      container.resolve<TestServiceA>('serviceA');
    }
    
    const endTime = performance.now();
    const duration = endTime - startTime;
    
    // Assert
    expect(duration).toBeLessThan(50); // 50ms以内完成1000次解析
  });
});