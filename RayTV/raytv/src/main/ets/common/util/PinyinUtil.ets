// PinyinUtil.ets - 拼音工具�?// 负责中文到拼音的转换，支持全拼和首字母提�?
import Logger from './Logger';

const TAG = 'PinyinUtil';

/**
 * 汉字首字母映射表（常用汉字）
 * 这里只包含部分常用汉字的首字母映射，实际应用中可以扩�? */
const PINYIN_MAP: Record<string, string> = {
  // 声母部分
  'a': 'a', 'o': 'o', 'e': 'e', 'i': 'i', 'u': 'u', 'v': 'v',
  // 部分常用汉字
  '一': 'y', '�?: 'd', '�?: 'q', '�?: 'w', '�?: 's', '�?: 's', '�?: 'x', '�?: 'b', '�?: 'y', '�?: 'c',
  '�?: 'z', '�?: 'q', '�?: 's', '�?: 'b', '�?: 'y', '�?: 'c', '�?: 'd', '�?: 's', '�?: 'c', '�?: 'd',
  '�?: 'l', '�?: 'y', '�?: 's', '�?: 'g', '�?: 'z', '�?: 'f', '�?: 'l', '�?: 'w', '�?: 'd', '�?: 'w',
  '�?: 'z', '�?: 'l', '�?: 'j', '�?: 'n', '�?: 'j', '�?: 'm', '�?: 'y', '�?: 'z', '�?: 'w', '�?: 'z',
  '�?: 'h', '�?: 'f', '�?: 'l', '�?: 'p', '�?: 'p', '�?: 'q', '�?: 'g', '�?: 'c', '�?: 'y', '�?: 'j',
  '�?: 'q', '�?: 'y', '�?: 'x', '�?: 'x', '�?: 's', '�?: 'y', '�?: 'y', '�?: 'h', '�?: 'w', '�?: 'j',
  '�?: 'g', '�?: 'y', '�?: 'w', '�?: 'h', '�?: 'j', '�?: 'y', '�?: 'c', '�?: 'h', '�?: 'm', '�?: 'x',
  '�?: 'j', '�?: 't', '�?: 'l', '�?: 'q', '�?: 'r', '�?: 'r', '�?: 'j', '�?: 'c', '�?: 'l', '�?: 'c',
  '�?: 's', '�?: 't', '�?: 'z', '�?: 'f', '�?: 'x', '�?: 'm', '�?: 'd', '�?: 'l', '�?: 'y', '�?: 'y',
  '�?: 'z', '�?: 'r', '�?: 'y', '�?: 'w', '�?: 'f', '�?: 'f', '�?: 'x', '�?: 'h', '�?: 'w', '�?: 'c',
  '�?: 's', '�?: 's', '�?: 'h', '�?: 'g', '�?: 'y', '�?: 'y', '�?: 'p', '�?: 'h', '�?: 'q', '�?: 'b',
  '�?: 'c', '�?: 'e', '�?: 'q', '�?: 'j', '�?: 'q', '�?: 'l',
  // 数字
  '0': '0', '1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
  // 字母
  'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd', 'E': 'e', 'F': 'f', 'G': 'g', 'H': 'h', 'I': 'i', 'J': 'j',
  'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'O': 'o', 'P': 'p', 'Q': 'q', 'R': 'r', 'S': 's', 'T': 't',
  'U': 'u', 'V': 'v', 'W': 'w', 'X': 'x', 'Y': 'y', 'Z': 'z'
};

/**
 * 拼音工具�? * 提供中文到拼音的转换功能，支持全拼和首字母提�? */
export class PinyinUtil {
  private static instance: PinyinUtil;
  private constructor() {}

  /**
   * 获取拼音工具单例
   */
  public static getInstance(): PinyinUtil {
    if (!PinyinUtil.instance) {
      PinyinUtil.instance = new PinyinUtil();
    }
    return PinyinUtil.instance;
  }

  /**
   * 提取字符串的拼音首字�?   * @param text 输入文本
   * @returns 拼音首字母字符串
   */
  public getFirstLetter(text: string): string {
    if (!text || typeof text !== 'string') {
      Logger.debug(TAG, 'Invalid text parameter in getFirstLetter');
      return '';
    }

    let result = '';
    
    // 遍历字符串中的每个字�?    for (let i = 0; i < text.length; i++) {
      const char = text.charAt(i);
      
      // 如果是英文字母，直接转为小写
      // 避免使用正则表达式，使用字符码范围判�?      const charCode = char.charCodeAt(0);
      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        // 确保是小�?        if (charCode >= 65 && charCode <= 90) {
          result += String.fromCharCode(charCode + 32);
        } else {
          result += char;
        }
      }
      // 如果是数字，直接添加
      else if (charCode >= 48 && charCode <= 57) {
        result += char;
      }
      // 如果是汉字，查找首字�?      else {
        // 避免使用in操作符，通过获取所有键并查�?        let found = false;
        const mapKeys = this.getMapKeys(PINYIN_MAP);
        for (let j = 0; j < mapKeys.length; j++) {
          if (mapKeys[j] === char) {
            result += PINYIN_MAP[char];
            found = true;
            break;
          }
        }
        
        // 对于未找到映射的字符，可以添加默认处理逻辑
        // 例如使用原字符或跳过
        if (!found) {
          // 可选：记录未识别的字符
          Logger.debug(TAG, `Unrecognized character: ${char}`);
        }
      }
    }

    return result;
  }
  
  /**
   * 获取映射表的所有键（兼容ArkTS�?   * @param map 映射�?   * @returns 键数�?   */
  private getMapKeys(map: Record<string, string>): string[] {
    const keys: string[] = [];
    try {
      // 使用Object.keys获取对象的键，这在HarmonyOS环境中是支持�?      const objKeys = Object.keys(map);
      for (let i = 0; i < objKeys.length; i++) {
        keys.push(objKeys[i]);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get map keys: ${error instanceof Error ? error.message : String(error)}`);
    }
    
    return keys;
  }

  /**
   * 检查文本是否包含指定的拼音首字母序�?   * @param text 输入文本
   * @param pinyin 拼音首字母序�?   * @returns 是否匹配
   */
  public containsPinyin(text: string, pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string : new Error(String(pinyin: string instanceof Error ? pinyin: string : new Error(String(pinyin: string))))))): boolean {
    // 参数验证
    if (!text || !pinyin || typeof text !== 'string' || typeof pinyin !== 'string') {
      Logger.debug(TAG, 'Invalid parameters in containsPinyin');
      return false;
    }

    // 获取拼音首字�?    const firstLetters = this.getFirstLetter(text);
    const lowerPinyin = this.toLowercase(pinyin);
    
    // 实现字符串包含检查（不使用内置的includes方法�?    return this.stringContains(firstLetters, lowerPinyin);
  }

  /**
   * 检查文本是否以指定的拼音首字母序列开�?   * @param text 输入文本
   * @param pinyin 拼音首字母序�?   * @returns 是否匹配
   */
  public startsWithPinyin(text: string, pinyin: string): boolean {
    // 参数验证
    if (!text || !pinyin || typeof text !== 'string' || typeof pinyin !== 'string') {
      Logger.debug(TAG, 'Invalid parameters in startsWithPinyin');
      return false;
    }

    // 获取拼音首字�?    const firstLetters = this.getFirstLetter(text);
    const lowerPinyin = this.toLowercase(pinyin);
    
    // 实现字符串开头匹配检查（不使用内置的startsWith方法�?    return this.stringStartsWith(firstLetters, lowerPinyin);
  }
  
  /**
   * 检查字符串是否以指定子字符串开�?   * 兼容ArkTS语法的实�?   */
  private stringStartsWith(str: string, prefix: string): boolean {
    if (!str || !prefix || prefix.length > str.length) {
      return false;
    }
    
    for (let i = 0; i < prefix.length; i++) {
      if (str.charAt(i) !== prefix.charAt(i)) {
        return false;
      }
    }
    return true;
  }
  
  /**
   * 将字符串转换为小�?   * 兼容ArkTS语法的实�?   */
  private toLowercase(str: string): string {
    if (!str || typeof str !== 'string') {
      return str || '';
    }
    
    let result = '';
    for (let i = 0; i < str.length; i++) {
      const char = str.charAt(i);
      const charCode = char.charCodeAt(0);
      // 大写字母A-Z (65-90) 转换为小�?a-z (97-122)
      if (charCode >= 65 && charCode <= 90) {
        result += String.fromCharCode(charCode + 32);
      } else {
        result += char;
      }
    }
    return result;
  }
  
  /**
   * 检查字符串是否包含子字符串
   * 兼容ArkTS语法的实�?   */
  private stringContains(str: string, substr: string): boolean {
    if (!str || !substr || substr.length > str.length) {
      return false;
    }
    
    for (let i = 0; i <= str.length - substr.length; i++) {
      let match = true;
      for (let j = 0; j < substr.length; j++) {
        if (str.charAt(i + j) !== substr.charAt(j)) {
          match = false;
          break;
        }
      }
      if (match) {
        return true;
      }
    }
    return false;
  }
  
  /**
   * 检查字符串是否以指定子字符串开�?   * 兼容ArkTS语法的实�?   */
  private stringStartsWith(str: string, prefix: string): boolean {
    if (!str || !prefix || prefix.length > str.length) {
      return false;
    }
    
    for (let i = 0; i < prefix.length; i++) {
      if (str.charAt(i) !== prefix.charAt(i)) {
        return false;
      }
    }
    return true;
  }

  /**
   * 扩展拼音映射�?   * @param map 要添加的映射
   */
  public extendPinyinMap(map: Record<string, string>): void {
    try {
      // 验证输入参数
      if (!map || typeof map !== 'object') {
        Logger.warn(TAG, 'Invalid map parameter provided to extendPinyinMap');
        return;
      }
      
      let addedCount = 0;
      let updatedCount = 0;
      
      // 使用JSON序列化和健壮的解析逻辑获取对象键值对
      // 这种方法可以避免使用for..in循环和Object.keys，符合ArkTS语法规范
      const mapStr = JSON.stringify(map);
      
      // 健壮的JSON解析逻辑
      let inKey = false;
      let inValue = false;
      let currentKey = '';
      let currentValue = '';
      let isEscaped = false;
      let valueStartIndex = 0;
      
      // 跳过JSON对象的开始大括号
      let i = 1;
      
      while (i < mapStr.length) {
        const char = mapStr[i];
        
        if (isEscaped) {
          // 处理转义字符
          if (inKey) {
            currentKey += char;
          } else if (inValue) {
            currentValue += char;
          }
          isEscaped = false;
        } else if (char === '\\') {
          // 检测转义符�?          isEscaped = true;
        } else if (char === '"' && !inKey && !inValue) {
          // 开始解析键
          inKey = true;
          currentKey = '';
        } else if (char === '"' && inKey) {
          // 键解析结�?          inKey = false;
        } else if (char === ':' && !inKey && !inValue) {
          // 开始解析�?          inValue = true;
          currentValue = '';
          i++;
          valueStartIndex = i;
          
          // 处理值的不同类型：字符串、数字、布尔值等
          if (i < mapStr.length) {
            const nextChar = mapStr[i];
            if (nextChar === '"') {
              // 字符串值，需要处理引�?              i++; // 跳过开始引�?              while (i < mapStr.length) {
                const valueChar = mapStr[i];
                if (valueChar === '\\') {
                  // 转义字符
                  if (i + 1 < mapStr.length) {
                    currentValue += mapStr[i + 1];
                    i += 2;
                  } else {
                    i++;
                  }
                } else if (valueChar === '"') {
                  // 字符串结�?                  i++;
                  break;
                } else {
                  currentValue += valueChar;
                  i++;
                }
              }
              inValue = false;
            } else {
              // 非字符串值（数字、布尔值等�?              while (i < mapStr.length) {
                const valueChar = mapStr[i];
                if (valueChar === ',' || valueChar === '}') {
                  break;
                }
                currentValue += valueChar;
                i++;
              }
              // 去除空格并转换为字符�?              currentValue = currentValue.trim();
              inValue = false;
            }
            
            // 处理当前键值对
            if (currentKey && currentValue) {
              const isUpdate = currentKey in PINYIN_MAP;
              
              // 验证值的有效�?- 确保是单字符拼音（通常是字母）
              // 但也允许特殊情况，如多字符拼音或音调标记
              if (typeof currentValue === 'string' && currentValue.length > 0) {
                // 在ArkTS中安全地设置属�?                const keyToSet = currentKey;
                const valueToSet = currentValue;
                PINYIN_MAP[keyToSet] = valueToSet;
                
                if (isUpdate) {
                  updatedCount++;
                } else {
                  addedCount++;
                }
              }
              
              // 重置键值缓冲区
              currentKey = '';
              currentValue = '';
            }
          }
        } else if (char === ',' && !inKey && !inValue) {
          // 跳过逗号，准备下一个键值对
        } else if (char === '}' && !inKey && !inValue) {
          // 解析结束
          break;
        } else if (inKey) {
          // 构建键字符串
          currentKey += char;
        }
        
        i++;
      }
      
      // 记录操作结果
      Logger.debug(TAG, `Pinyin map extended: ${addedCount} entries added, ${updatedCount} entries updated`);
      
    } catch (error) {
      Logger.error(TAG, `Failed to extend pinyin map: ${error instanceof Error ? error.message : String(error)}`);
      // 可以考虑抛出错误或返回失败状�?      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 搜索过滤函数 - 根据拼音首字母过滤数�?   * @param items 要过滤的数组
   * @param keyword 搜索关键�?   * @param textExtractor 从数组项中提取文本的函数
   * @returns 过滤后的数组
   */
  public filterByPinyin<T>(items: T[], keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T instanceof Error ? keyword: string, textExtractor: (item: T : new Error(String(keyword: string, textExtractor: (item: T))))))) => string): T[] {
    // 参数验证
    if (!items || !Array.isArray(items)) {
      Logger.warn(TAG, 'Invalid items array in filterByPinyin');
      return [];
    }
    
    if (!keyword || typeof keyword !== 'string') {
      Logger.debug(TAG, 'Empty or invalid keyword in filterByPinyin');
      return items;
    }
    
    if (!textExtractor || typeof textExtractor !== 'function') {
      Logger.error(TAG, 'Invalid textExtractor function in filterByPinyin');
      return [];
    }
    
    // 去除关键词前后空�?    const trimmedKeyword = this.trimString(keyword);
    if (trimmedKeyword === '') {
      return items;
    }
    
    const lowerKeyword = this.toLowercase(trimmedKeyword);
    
    // 实现自定义的filter逻辑，避免使用数组的filter方法
    const filteredItems: T[] = [];
    
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      try {
        const text = textExtractor(item);
        if (typeof text === 'string') {
          // 文本直接匹配
          const lowerText = this.toLowercase(text);
          if (this.stringContains(lowerText, lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword : new Error(String(lowerKeyword instanceof Error ? lowerKeyword : new Error(String(lowerKeyword)))))))) {
            filteredItems.push(item);
            continue;
          }
          
          // 拼音首字母匹�?          if (this.containsPinyin(text, lowerKeyword)) {
            filteredItems.push(item);
          }
        }
      } catch (error) {
        // 处理单个项处理失败的情况
        Logger.warn(TAG, `Error processing item in filterByPinyin: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
    
    Logger.debug(TAG, `Filtered array from ${items.length} to ${filteredItems.length} items`);
    return filteredItems;
  }
  
  /**
   * 去除字符串前后空�?   * 兼容ArkTS语法的实�?   */
  private trimString(str: string): string {
    if (!str || typeof str !== 'string') {
      return str || '';
    }
    
    let start = 0;
    let end = str.length;
    
    // 查找起始非空格位�?    while (start < end && this.isWhitespace(str.charAt(start))) {
      start++;
    }
    
    // 查找结束非空格位�?    while (end > start && this.isWhitespace(str.charAt(end - 1))) {
      end--;
    }
    
    return str.substring(start, end);
  }
  
  /**
   * 检查字符是否为空白字符
   */
  private isWhitespace(char: string): boolean {
    const charCode = char.charCodeAt(0);
    // 空格、制表符、换行符、回车符�?    return charCode === 32 || charCode === 9 || charCode === 10 || charCode === 13;
  }
}

// 导出单例
export const pinyinUtil = PinyinUtil.getInstance();
export default pinyinUtil;


