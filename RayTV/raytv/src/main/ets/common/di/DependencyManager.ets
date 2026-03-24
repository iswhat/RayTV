/**
 * 依赖管理器 | Dependency Manager
 * 提供依赖关系的集中管理和监控 | Provides centralized management and monitoring of dependencies
 */
import { DIContainer } from './Container';
import DependencyInjector from './DependencyInjector';
import Logger from '../util/Logger';

/**
 * 依赖关系 | Dependency relationship
 */
export interface DependencyRelation {
  token: string;
  dependsOn: string[];
  dependents: string[];
}

/**
 * 依赖图 | Dependency graph
 */
export interface DependencyGraph {
  nodes: string[];
  edges: DependencyRelation[];
}

/**
 * 依赖状态 | Dependency status
 */
export interface DependencyStatus {
  token: string;
  isHealthy: boolean;
  lastResolved: number;
  resolveCount: number;
  errors: string[];
}

/**
 * 依赖管理器类 | Dependency Manager class
 */
export class DependencyManager {
  private static instance: DependencyManager | null = null;
  private container: DIContainer;
  private logger: Logger;
  private dependencyMap: Map<string, string[]> = new Map();
  private reverseDependencyMap: Map<string, string[]> = new Map();
  private statusMap: Map<string, DependencyStatus> = new Map();

  /**
   * 获取单例实例 | Get singleton instance
   */
  public static getInstance(): DependencyManager {
    if (!DependencyManager.instance) {
      DependencyManager.instance = new DependencyManager();
    }
    return DependencyManager.instance;
  }

  /**
   * 私有构造函数 | Private constructor
   */
  private constructor() {
    this.container = DIContainer.getInstance();
    this.logger = new Logger('DependencyManager');
  }

  /**
   * 注册依赖关系 | Register dependency relationship
   */
  public registerDependency(token: string, dependsOn: string[]): void {
    // 存储正向依赖
    this.dependencyMap.set(token, dependsOn);
    
    // 构建反向依赖
    for (const dep of dependsOn) {
      const dependents = this.reverseDependencyMap.get(dep) ?? [];
      if (!dependents.includes(token)) {
        dependents.push(token);
        this.reverseDependencyMap.set(dep, dependents);
      }
    }
    
    // 初始化状态
    this.statusMap.set(token, {
      token: token,
      isHealthy: true,
      lastResolved: 0,
      resolveCount: 0,
      errors: []
    });
    
    this.logger.info('Registered dependency: ' + token + ' depends on [' + dependsOn.join(', ') + ']');
  }

  /**
   * 获取依赖关系 | Get dependency relationship
   */
  public getDependencies(token: string): string[] {
    return this.dependencyMap.get(token) ?? [];
  }

  /**
   * 获取反向依赖 | Get reverse dependencies
   */
  public getDependents(token: string): string[] {
    return this.reverseDependencyMap.get(token) ?? [];
  }

  /**
   * 构建依赖图 | Build dependency graph
   */
  public buildDependencyGraph(): DependencyGraph {
    const nodes = this.container.getAllTokens();
    const edges: DependencyRelation[] = [];
    
    for (const token of nodes) {
      edges.push({
        token: token,
        dependsOn: this.getDependencies(token),
        dependents: this.getDependents(token)
      });
    }
    
    return {
      nodes: nodes,
      edges: edges
    };
  }

  /**
   * 检测循环依赖 | Detect circular dependencies
   */
  public detectCircularDependencies(): string[][] {
    const cycles: string[][] = [];
    const visited = new Set<string>();
    const recursionStack = new Set<string>();
    
    const dfs = (token: string, path: string[]): boolean => {
      visited.add(token);
      recursionStack.add(token);
      
      const deps = this.getDependencies(token);
      for (const dep of deps) {
        if (!visited.has(dep)) {
          if (dfs(dep, [...path, dep])) {
            return true;
          }
        } else if (recursionStack.has(dep)) {
          const cycleStart = path.indexOf(dep);
          const cycle = path.slice(cycleStart);
          cycles.push(cycle);
          return true;
        }
      }
      
      recursionStack.delete(token);
      return false;
    };
    
    for (const token of this.dependencyMap.keys()) {
      if (!visited.has(token)) {
        dfs(token, [token]);
      }
    }
    
    return cycles;
  }

  /**
   * 获取依赖状态 | Get dependency status
   */
  public getStatus(token: string): DependencyStatus | null {
    return this.statusMap.get(token) ?? null;
  }

  /**
   * 更新依赖状态 | Update dependency status
   */
  public updateStatus(token: string, success: boolean, error?: string): void {
    const status = this.statusMap.get(token);
    if (status) {
      status.lastResolved = Date.now();
      status.resolveCount++;
      status.isHealthy = success;
      
      if (error) {
        status.errors.push(error);
        if (status.errors.length > 10) {
          status.errors.shift();
        }
      }
      
      this.statusMap.set(token, status);
    }
  }

  /**
   * 获取所有不健康的依赖 | Get all unhealthy dependencies
   */
  public getUnhealthyDependencies(): DependencyStatus[] {
    const unhealthy: DependencyStatus[] = [];
    
    this.statusMap.forEach((status: DependencyStatus) => {
      if (!status.isHealthy) {
        unhealthy.push(status);
      }
    });
    
    return unhealthy;
  }

  /**
   * 重置所有状态 | Reset all status
   */
  public resetAllStatus(): void {
    this.statusMap.forEach((status: DependencyStatus, token: string) => {
      status.isHealthy = true;
      status.errors = [];
      this.statusMap.set(token, status);
    });
    this.logger.info('All dependency status reset');
  }

  /**
   * 验证依赖完整性 | Validate dependency integrity
   */
  public validateIntegrity(): boolean {
    const tokens = this.container.getAllTokens();
    let allValid = true;
    
    for (const token of tokens) {
      const deps = this.getDependencies(token);
      for (const dep of deps) {
        if (!this.container.has(dep)) {
          this.logger.error('Missing dependency: ' + token + ' -> ' + dep);
          allValid = false;
        }
      }
    }
    
    return allValid;
  }

  /**
   * 获取依赖统计 | Get dependency statistics
   */
  public getStatistics(): object {
    const stats = {
      totalDependencies: this.dependencyMap.size,
      totalTokens: this.container.getAllTokens().length,
      unhealthyCount: this.getUnhealthyDependencies().length,
      circularDependencies: this.detectCircularDependencies().length
    };
    return stats;
  }

  /**
   * 清除所有依赖关系 | Clear all dependencies
   */
  public clearAll(): void {
    this.dependencyMap.clear();
    this.reverseDependencyMap.clear();
    this.statusMap.clear();
    this.logger.info('All dependencies cleared');
  }

  /**
   * 销毁管理器 | Destroy manager
   */
  public destroy(): void {
    this.clearAll();
    this.logger.info('DependencyManager destroyed');
  }
}

// 导出单例实例 | Export singleton instance
export default DependencyManager.getInstance();
