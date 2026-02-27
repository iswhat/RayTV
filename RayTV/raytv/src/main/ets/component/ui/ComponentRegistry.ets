/**
 * 组件注册文件
 * 负责注册所有可用的UI组件到组件管理系统
 */
import { componentManager } from '../core/ComponentManager'
import { ButtonComponent, ButtonProps } from './ButtonComponent'
import { CardComponent, CardProps } from './CardComponent'

/**
 * 注册所有UI组件
 */
export function registerAllComponents(): void {
  // 注册按钮组件
  componentManager.registerComponent<ButtonProps>({
    name: 'Button',
    component: ButtonComponent,
    defaultProps: {
      type: 'primary',
      size: 'medium',
      shape: 'rect',
      disabled: false,
      loading: false
    },
    category: 'input',
    description: '通用按钮组件，支持多种样式和交互状态'
  })
  
  // 注册卡片组件
  componentManager.registerComponent<CardProps>({
    name: 'Card',
    component: CardComponent,
    defaultProps: {
      variant: 'elevated',
      elevation: 1,
      padding: '16px',
      margin: '8px',
      borderRadius: '12px'
    },
    category: 'container',
    description: '通用卡片容器组件，支持阴影、边框和各种样式'
  })
  
  console.log('All UI components registered successfully')
}

/**
 * 获取已注册的组件统计信息
 */
export function getComponentStatistics() {
  return componentManager.getStatistics()
}

/**
 * 创建按钮组件实例
 */
export function createButton(props: ButtonProps) {
  return componentManager.createComponent('Button', props)
}

/**
 * 创建卡片组件实例
 */
export function createCard(props: CardProps) {
  return componentManager.createComponent('Card', props)
}

// 在模块加载时自动注册组件
registerAllComponents()