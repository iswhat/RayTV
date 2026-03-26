/**
 * 测试工具类
 * 提供测试相关的辅助函数和断言方法
 */
export class TestUtils {
  private static instance: TestUtils
  
  private constructor() {}
  
  public static getInstance(): TestUtils {
    if (!TestUtils.instance) {
      TestUtils.instance = new TestUtils()
    }
    return TestUtils.instance
  }
  
  /**
   * 异步等待
   */
  public async waitFor(condition: () => boolean, timeout: number = 5000): Promise<boolean> {
    const startTime = Date.now()
    
    while (Date.now() - startTime < timeout) {
      if (condition()) {
        return true
      }
      await this.sleep(10)
    }
    
    return false
  }
  
  /**
   * 延迟函数
   */
  public sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms))
  }
  
  /**
   * 创建Mock对象
   */
  public createMock<T>(methods: Partial<T> = {}): T {
    return methods as T
  }
  
  /**
   * 捕获控制台输出
   */
  public captureConsoleOutput(callback: () => void): { logs: string[], warns: string[], errors: string[] } {
    const logs: string[] = []
    const warns: string[] = []
    const errors: string[] = []
    
    const originalLog = console.log
    const originalWarn = console.warn
    const originalError = console.error
    
    console.log = (...args) => logs.push(args.join(' '))
    console.warn = (...args) => warns.push(args.join(' '))
    console.error = (...args) => errors.push(args.join(' '))
    
    try {
      callback()
    } finally {
      console.log = originalLog
      console.warn = originalWarn
      console.error = originalError
    }
    
    return { logs, warns, errors }
  }
}

/**
 * 断言类
 */
export class Assert {
  /**
   * 断言相等
   */
  public static equal(actual: any, expected: any, message: string = ''): void {
    if (actual !== expected) {
      throw new Error(`期望 ${expected}，但得到 ${actual}。${message}`)
    }
  }
  
  /**
   * 断言不相等
   */
  public static notEqual(actual: any, expected: any, message: string = ''): void {
    if (actual === expected) {
      throw new Error(`期望不等于 ${expected}，但得到 ${actual}。${message}`)
    }
  }
  
  /**
   * 断言为真
   */
  public static assertTrue(value: boolean, message: string = ''): void {
    if (!value) {
      throw new Error(`期望为真，但得到假。${message}`)
    }
  }
  
  /**
   * 断言为假
   */
  public static assertFalse(value: boolean, message: string = ''): void {
    if (value) {
      throw new Error(`期望为假，但得到真。${message}`)
    }
  }
  
  /**
   * 断言不为空
   */
  public static notNull(value: any, message: string = ''): void {
    if (value === null || value === undefined) {
      throw new Error(`期望不为空，但得到 ${value}。${message}`)
    }
  }
  
  /**
   * 断言为空
   */
  public static isNull(value: any, message: string = ''): void {
    if (value !== null && value !== undefined) {
      throw new Error(`期望为空，但得到 ${value}。${message}`)
    }
  }
  
  /**
   * 断言抛出异常
   */
  public static throws(fn: () => void, expectedError?: string | Function, message: string = ''): void {
    try {
      fn()
      throw new Error(`期望抛出异常，但没有抛出。${message}`)
    } catch (error) {
      if (expectedError) {
        if (typeof expectedError === 'string') {
          if ((error as Error).message !== expectedError) {
            throw new Error(`期望抛出错误 "${expectedError}"，但得到 "${(error as Error).message}"。${message}`)
          }
        } else if (typeof expectedError === 'function') {
          if (!(error instanceof expectedError)) {
            throw new Error(`期望抛出 ${expectedError.name} 类型的错误，但得到 ${(error as Error).constructor.name}。${message}`)
          }
        }
      }
    }
  }
  
  /**
   * 断言接近相等（用于浮点数比较）
   */
  public static closeTo(actual: number, expected: number, delta: number = 0.001, message: string = ''): void {
    if (Math.abs(actual - expected) > delta) {
      throw new Error(`期望 ${expected} ± ${delta}，但得到 ${actual}。${message}`)
    }
  }
}