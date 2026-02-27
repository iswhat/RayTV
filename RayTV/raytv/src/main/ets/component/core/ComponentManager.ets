/**
 * 组件管理器
 * 负责组件的注册、查找、实例化和生命周期管理
 */
import { BaseComponent, ComponentProps } from './BaseComponent'

export interface ComponentDefinition<T extends ComponentProps = ComponentProps> {
  name: string
  component: new (props: T) => BaseComponent<T>
  defaultProps?: Partial<T>
  category?: string
  description?: string
}

export interface ComponentInstanceInfo {
  id: string
  name: string
  instance: BaseComponent
  createdAt: number
  parentId?: string
}

export class ComponentManager {
  private static instance: ComponentManager
  private components: Map<string, ComponentDefinition> = new Map()
  private instances: Map<string, ComponentInstanceInfo> = new Map()
  private categories: Map<string, string[]> = new Map()
  
  private constructor() {}
  
  /**
   * 获取单例实例
   */
  public static getInstance(): ComponentManager {
    if (!ComponentManager.instance) {
      ComponentManager.instance = new ComponentManager()
    }
    return ComponentManager.instance
  }
  
  /**
   * 注册组件
   */
  public registerComponent<T extends ComponentProps>(
    definition: ComponentDefinition<T>
  ): void {
    const { name, component, category = 'general' } = definition
    
    // 检查组件是否已注册
    if (this.components.has(name)) {
      console.warn(`Component '${name}' is already registered`)
      return
    }
    
    // 注册组件
    this.components.set(name, definition)
    
    // 按类别分类
    if (!this.categories.has(category)) {
      this.categories.set(category, [])
    }
    this.categories.get(category)!.push(name)
    
    console.log(`Component '${name}' registered successfully`)
  }
  
  /**
   * 注销组件
   */
  public unregisterComponent(name: string): boolean {
    const definition = this.components.get(name)
    if (!definition) {
      console.warn(`Component '${name}' not found`)
      return false
    }
    
    // 从组件映射中删除
    this.components.delete(name)
    
    // 从类别分类中删除
    if (definition.category) {
      const categoryComponents = this.categories.get(definition.category)
      if (categoryComponents) {
        const index = categoryComponents.indexOf(name)
        if (index > -1) {
          categoryComponents.splice(index, 1)
        }
      }
    }
    
    // 销毁所有实例
    this.destroyComponentInstances(name)
    
    console.log(`Component '${name}' unregistered successfully`)
    return true
  }
  
  /**
   * 创建组件实例
   */
  public createComponent<T extends ComponentProps>(
    name: string,
    props: T,
    parentId?: string
  ): BaseComponent<T> | null {
    const definition = this.components.get(name)
    if (!definition) {
      console.error(`Component '${name}' not found`)
      return null
    }
    
    try {
      // 合并默认属性
      const mergedProps = {
        ...(definition.defaultProps || {}),
        ...props
      } as T
      
      // 创建实例
      const instance = new definition.component(mergedProps)
      
      // 记录实例信息
      const instanceInfo: ComponentInstanceInfo = {
        id: instance['componentId'],
        name,
        instance,
        createdAt: Date.now(),
        parentId
      }
      
      this.instances.set(instanceInfo.id, instanceInfo)
      
      console.log(`Component instance '${name}' created with ID: ${instanceInfo.id}`)
      return instance
      
    } catch (error) {
      console.error(`Failed to create component '${name}':`, error)
      return null
    }
  }
  
  /**
   * 销毁组件实例
   */
  public destroyComponentInstance(instanceId: string): boolean {
    const instanceInfo = this.instances.get(instanceId)
    if (!instanceInfo) {
      console.warn(`Component instance '${instanceId}' not found`)
      return false
    }
    
    try {
      // 调用组件销毁方法
      instanceInfo.instance['onBeforeDestroy']()
      instanceInfo.instance['onDestroyed']()
      
      // 从实例映射中删除
      this.instances.delete(instanceId)
      
      console.log(`Component instance '${instanceId}' destroyed successfully`)
      return true
      
    } catch (error) {
      console.error(`Failed to destroy component instance '${instanceId}':`, error)
      return false
    }
  }
  
  /**
   * 销毁指定组件的所有实例
   */
  public destroyComponentInstances(componentName: string): void {
    const instancesToDelete = Array.from(this.instances.values())
      .filter(info => info.name === componentName)
      .map(info => info.id)
    
    instancesToDelete.forEach(id => this.destroyComponentInstance(id))
  }
  
  /**
   * 获取组件定义
   */
  public getComponentDefinition(name: string): ComponentDefinition | undefined {
    return this.components.get(name)
  }
  
  /**
   * 获取所有组件名称
   */
  public getComponentNames(): string[] {
    return Array.from(this.components.keys())
  }
  
  /**
   * 按类别获取组件名称
   */
  public getComponentsByCategory(category: string): string[] {
    return this.categories.get(category) || []
  }
  
  /**
   * 获取所有类别
   */
  public getCategories(): string[] {
    return Array.from(this.categories.keys())
  }
  
  /**
   * 获取组件实例信息
   */
  public getComponentInstance(instanceId: string): ComponentInstanceInfo | undefined {
    return this.instances.get(instanceId)
  }
  
  /**
   * 获取指定组件的所有实例
   */
  public getComponentInstances(componentName: string): ComponentInstanceInfo[] {
    return Array.from(this.instances.values())
      .filter(info => info.name === componentName)
  }
  
  /**
   * 获取所有实例信息
   */
  public getAllInstances(): ComponentInstanceInfo[] {
    return Array.from(this.instances.values())
  }
  
  /**
   * 清理所有组件和实例
   */
  public clear(): void {
    // 销毁所有实例
    Array.from(this.instances.keys()).forEach(id => {
      this.destroyComponentInstance(id)
    })
    
    // 清空映射
    this.components.clear()
    this.instances.clear()
    this.categories.clear()
    
    console.log('ComponentManager cleared successfully')
  }
  
  /**
   * 获取组件统计信息
   */
  public getStatistics(): {
    totalComponents: number
    totalInstances: number
    categories: number
    componentList: { name: string; instances: number; category?: string }[]
  } {
    const componentList = Array.from(this.components.entries()).map(([name, def]) => ({
      name,
      instances: this.getComponentInstances(name).length,
      category: def.category
    }))
    
    return {
      totalComponents: this.components.size,
      totalInstances: this.instances.size,
      categories: this.categories.size,
      componentList
    }
  }
}

// 全局组件管理器实例
export const componentManager = ComponentManager.getInstance()