// PinyinUtil.ets - 拼音工具类 Pinyin utility class
// 支持中文到拼音的转换，支持全拼和首字母提取 Supports Chinese to pinyin conversion, supports full pinyin and first letter extraction
import Logger from './Logger';

const TAG = 'PinyinUtil';

/**
 * 汉字首字母映射表（常用汉字）Chinese character first letter mapping table (common characters)
 * 这里只包含部分常用汉字的首字母映射，实际应用中可以扩展 Only includes first letter mapping for some common Chinese characters, can be extended in actual application
 */
const PINYIN_MAP: Record<string, string> = {
  // 字母部分
  'a': 'a', 'o': 'o', 'e': 'e', 'i': 'i', 'u': 'u', 'v': 'v',
  // 部分常用汉字
  '一': 'y', '二': 'e', '三': 's', '四': 's', '五': 'w', '六': 'l', '七': 'q', '八': 'b', '九': 'j', '十': 's',
  '百': 'b', '千': 'q', '万': 'w', '亿': 'y', '零': 'l', '壹': 'y', '贰': 'e', '叁': 's', '肆': 's', '伍': 'w',
  '陆': 'l', '柒': 'q', '捌': 'b', '玖': 'j', '拾': 's',
  // 数字
  '0': '0', '1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
  // 字母
  'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd', 'E': 'e', 'F': 'f', 'G': 'g', 'H': 'h', 'I': 'i', 'J': 'j',
  'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'O': 'o', 'P': 'p', 'Q': 'q', 'R': 'r', 'S': 's', 'T': 't',
  'U': 'u', 'V': 'v', 'W': 'w', 'X': 'x', 'Y': 'y', 'Z': 'z'
};

/**
 * 拼音工具类 Pinyin utility class
 * 提供中文到拼音的转换功能，支持全拼和首字母提取 Provides Chinese to pinyin conversion functionality, supports full pinyin and first letter extraction
 */
export class PinyinUtil {
  private static instance: PinyinUtil;
  private constructor() {}

  /**
   * 获取拼音工具类单例 Gets pinyin utility class singleton
   */
  public static getInstance(): PinyinUtil {
    if (!PinyinUtil.instance) {
      PinyinUtil.instance = new PinyinUtil();
    }
    return PinyinUtil.instance;
  }

  /**
   * 提取字符串的拼音首字母 Extracts pinyin first letters from string
   * @param text 输入文本 Input text
   * @returns 拼音首字母字符串 Pinyin first letters string
   */
  public getFirstLetter(text: string): string {
    if (!text || typeof text !== 'string') {
      Logger.debug(TAG, 'Invalid text parameter in getFirstLetter');
      return '';
    }

    let result = '';
    
    // 遍历字符串中的每个字符 Iterates through each character in the string
    for (let i = 0; i < text.length; i++) {
      const char = text.charAt(i);
      
      // 如果是英文字母，直接转换为小写 If it's an English letter, directly convert to lowercase
      // 避免使用正则表达式，使用字符码范围判断 Avoids using regular expressions, uses character code range judgment
      const charCode = char.charCodeAt(0);
      if ((charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122)) {
        // 确保是小写 Ensures lowercase
        if (charCode >= 65 && charCode <= 90) {
          result += String.fromCharCode(charCode + 32);
        } else {
          result += char;
        }
      }
      // 如果是数字，直接添加 If it's a number, directly add
      else if (charCode >= 48 && charCode <= 57) {
        result += char;
      }
      // 如果是汉字，查找首字母 If it's a Chinese character, finds first letter
      else {
        // 避免使用in操作符，通过获取所有键并查找 Avoids using in operator, gets all keys and searches
        let found = false;
        const mapKeys = this.getMapKeys(PINYIN_MAP);
        for (let j = 0; j < mapKeys.length; j++) {
          if (mapKeys[j] === char) {
            result += PINYIN_MAP[char];
            found = true;
            break;
          }
        }
        
        // 对于未找到映射的字符，可以添加默认处理逻辑 For characters not found in mapping, can add default processing logic
        // 例如使用原字符或跳过 For example, use original character or skip
        if (!found) {
          // 可选：记录未识别的字符 Optional: records unrecognized characters
          Logger.debug(TAG, `Unrecognized character: ${char}`);
        }
      }
    }

    return result;
  }
  
  /**
   * 获取映射表的所有键（适配ArkTS） Gets all keys of mapping table (adapts to ArkTS)
   * @param map 映射表 Mapping table
   * @returns 键数组 Key array
   */
  private getMapKeys(map: Record<string, string>): string[] {
    const keys: string[] = [];
    try {
      // 使用Object.keys获取对象的键，这在HarmonyOS环境中是支持的 Uses Object.keys to get object keys, this is supported in HarmonyOS environment
      const objKeys = Object.keys(map);
      for (let i = 0; i < objKeys.length; i++) {
        keys.push(objKeys[i]);
      }
    } catch (error) {
      Logger.error(TAG, `Failed to get map keys: ${error instanceof Error ? error.message : String(error)}`);
    }
    
    return keys;
  }

  /**
   * 检查文本是否包含指定的拼音首字母序列 Checks if text contains specified pinyin first letter sequence
   * @param text 输入文本 Input text
   * @param pinyin 拼音首字母序列 Pinyin first letter sequence
   * @returns 是否匹配 Whether it matches
   */
  public containsPinyin(text: string, pinyin: string): boolean {
    // 参数验证 Parameter validation
    if (!text || !pinyin || typeof text !== 'string' || typeof pinyin !== 'string') {
      Logger.debug(TAG, 'Invalid parameters in containsPinyin');
      return false;
    }

    // 获取拼音首字母 Gets pinyin first letters
    const firstLetters = this.getFirstLetter(text);
    const lowerPinyin = this.toLowercase(pinyin);
    
    // 实现字符串包含检查（不使用内置的includes方法） Implements string contains check (not using built-in includes method)
    return this.stringContains(firstLetters, lowerPinyin);
  }

  /**
   * 检查文本是否以指定的拼音首字母序列开头 Checks if text starts with specified pinyin first letter sequence
   * @param text 输入文本 Input text
   * @param pinyin 拼音首字母序列 Pinyin first letter sequence
   * @returns 是否匹配 Whether it matches
   */
  public startsWithPinyin(text: string, pinyin: string): boolean {
    // 参数验证 Parameter validation
    if (!text || !pinyin || typeof text !== 'string' || typeof pinyin !== 'string') {
      Logger.debug(TAG, 'Invalid parameters in startsWithPinyin');
      return false;
    }

    // 获取拼音首字母 Gets pinyin first letters
    const firstLetters = this.getFirstLetter(text);
    const lowerPinyin = this.toLowercase(pinyin);
    
    // 实现字符串开头匹配检查（不使用内置的startsWith方法） Implements string starts with check (not using built-in startsWith method)
    return this.stringStartsWith(firstLetters, lowerPinyin);
  }
  
  /**
   * 检查字符串是否以指定子字符串开头 Checks if string starts with specified substring
   * 兼容ArkTS语法的实现 ArkTS syntax compatible implementation
   */
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
   * 将字符串转换为小写 Converts string to lowercase
   * 兼容ArkTS语法的实现 ArkTS syntax compatible implementation
   */
  private toLowercase(str: string): string {
    if (!str || typeof str !== 'string') {
      return str || '';
    }
    
    let result = '';
    for (let i = 0; i < str.length; i++) {
      const char = str.charAt(i);
      const charCode = char.charCodeAt(0);
      // 大写字母A-Z (65-90) 转换为小写a-z (97-122)
      if (charCode >= 65 && charCode <= 90) {
        result += String.fromCharCode(charCode + 32);
      } else {
        result += char;
      }
    }
    return result;
  }
  
  /**
   * 检查字符串是否包含子字符串 Checks if string contains substring
   * 兼容ArkTS语法的实现 ArkTS syntax compatible implementation
   */
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
   * 扩展拼音映射表 Extends pinyin mapping table
   * @param map 要添加的映射 Mapping to add
   */
  public extendPinyinMap(map: Record<string, string>): void {
    try {
      // 验证输入参数 Validates input parameters
      if (!map || typeof map !== 'object') {
        Logger.warn(TAG, 'Invalid map parameter provided to extendPinyinMap');
        return;
      }
      
      let addedCount = 0;
      let updatedCount = 0;
      
      // 使用Object.keys获取对象键 Uses Object.keys to get object keys
      const keys = Object.keys(map);
      
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = map[key];
        
        if (key && value && typeof value === 'string' && value.length > 0) {
          // 检查是否是更新 Check if it's an update
          const isUpdate = PINYIN_MAP[key] !== undefined;
          
          // 设置映射 Sets mapping
          PINYIN_MAP[key] = value;
          
          if (isUpdate) {
            updatedCount++;
          } else {
            addedCount++;
          }
        }
      }
      
      // 记录操作结果 Records operation result
      Logger.debug(TAG, `Pinyin map extended: ${addedCount} entries added, ${updatedCount} entries updated`);
      
    } catch (error) {
      Logger.error(TAG, `Failed to extend pinyin map: ${error instanceof Error ? error.message : String(error)}`);
      // 可以考虑抛出错误或返回失败状态 Can consider throwing error or returning failure status
      throw error instanceof Error ? error : new Error(String(error));
    }
  }

  /**
   * 搜索过滤函数 - 根据拼音首字母过滤数据 Search filter function - filters data based on pinyin first letters
   * @param items 要过滤的数组 Array to filter
   * @param keyword 搜索关键字 Search keyword
   * @param textExtractor 从数组项中提取文本的函数 Function to extract text from array items
   * @returns 过滤后的数组 Filtered array
   */
  public filterByPinyin<T>(items: T[], keyword: string, textExtractor: (item: T) => string): T[] {
    // 参数验证 Parameter validation
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
    
    // 删除关键字前后空格 Removes spaces around keyword
    const trimmedKeyword = this.trimString(keyword);
    if (trimmedKeyword === '') {
      return items;
    }
    
    const lowerKeyword = this.toLowercase(trimmedKeyword);
    
    // 实现自定义的filter逻辑，避免使用数组的filter方法 Implements custom filter logic, avoids using array's filter method
    const filteredItems: T[] = [];
    
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      try {
        const text = textExtractor(item);
        if (typeof text === 'string') {
          // 文本直接匹配 Text direct match
          const lowerText = this.toLowercase(text);
          if (this.stringContains(lowerText, lowerKeyword)) {
            filteredItems.push(item);
            continue;
          }
          
          // 拼音首字母匹配 Pinyin first letter match
          if (this.containsPinyin(text, lowerKeyword)) {
            filteredItems.push(item);
          }
        }
      } catch (error) {
        // 处理单个项目处理错误的情况 Handles single item processing error
        Logger.warn(TAG, `Error processing item in filterByPinyin: ${error instanceof Error ? error.message : String(error)}`);
      }
    }
    
    Logger.debug(TAG, `Filtered array from ${items.length} to ${filteredItems.length} items`);
    return filteredItems;
  }
  
  /**
   * 删除字符串前后空格 Removes spaces around string
   * 兼容ArkTS语法的实现 ArkTS syntax compatible implementation
   */
  private trimString(str: string): string {
    if (!str || typeof str !== 'string') {
      return str || '';
    }
    
    let start = 0;
    let end = str.length;
    
    // 查找开始非空格位置 Finds start non-space position
    while (start < end && this.isWhitespace(str.charAt(start))) {
      start++;
    }
    
    // 查找结束非空格位置 Finds end non-space position
    while (end > start && this.isWhitespace(str.charAt(end - 1))) {
      end--;
    }
    
    return str.substring(start, end);
  }
  
  /**
   * 检查字符是否为空白字符 Checks if character is whitespace
   */
  private isWhitespace(char: string): boolean {
    const charCode = char.charCodeAt(0);
    // 空格、制表符、换行符、回车符等 Space, tab, newline, carriage return, etc.
    return charCode === 32 || charCode === 9 || charCode === 10 || charCode === 13;
  }
}

// 导出单例 Export singleton
export const pinyinUtil = PinyinUtil.getInstance();
export default pinyinUtil;


