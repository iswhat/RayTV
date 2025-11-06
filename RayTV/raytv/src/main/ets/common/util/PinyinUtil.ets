// PinyinUtil.ets - 拼音工具类
// 负责中文到拼音的转换，支持全拼和首字母提取

import Logger from './Logger';

const TAG = 'PinyinUtil';

/**
 * 汉字首字母映射表（常用汉字）
 * 这里只包含部分常用汉字的首字母映射，实际应用中可以扩展
 */
const PINYIN_MAP: Record<string, string> = {
  // 声母部分
  'a': 'a', 'o': 'o', 'e': 'e', 'i': 'i', 'u': 'u', 'v': 'v',
  // 部分常用汉字
  '一': 'y', '丁': 'd', '七': 'q', '万': 'w', '三': 's', '上': 's', '下': 'x', '不': 'b', '与': 'y', '丑': 'c',
  '专': 'z', '且': 'q', '世': 's', '丙': 'b', '业': 'y', '丛': 'c', '东': 'd', '丝': 's', '丞': 'c', '丢': 'd',
  '两': 'l', '严': 'y', '丧': 's', '个': 'g', '中': 'z', '丰': 'f', '临': 'l', '丸': 'w', '丹': 'd', '为': 'w',
  '主': 'z', '丽': 'l', '举': 'j', '乃': 'n', '久': 'j', '么': 'm', '义': 'y', '之': 'z', '乌': 'w', '乍': 'z',
  '乎': 'h', '乏': 'f', '乐': 'l', '乒': 'p', '乓': 'p', '乔': 'q', '乖': 'g', '乘': 'c', '乙': 'y', '九': 'j',
  '乞': 'q', '也': 'y', '习': 'x', '乡': 'x', '书': 's', '予': 'y', '云': 'y', '互': 'h', '五': 'w', '井': 'j',
  '亘': 'g', '亚': 'y', '亡': 'w', '亥': 'h', '交': 'j', '亦': 'y', '产': 'c', '亨': 'h', '亩': 'm', '享': 'x',
  '京': 'j', '亭': 't', '亮': 'l', '亲': 'q', '人': 'r', '仁': 'r', '仅': 'j', '从': 'c', '仑': 'l', '仓': 'c',
  '仕': 's', '他': 't', '仗': 'z', '付': 'f', '仙': 'x', '们': 'm', '代': 'd', '令': 'l', '以': 'y', '仪': 'y',
  '仲': 'z', '任': 'r', '伊': 'y', '伍': 'w', '伏': 'f', '伐': 'f', '休': 'x', '会': 'h', '伟': 'w', '传': 'c',
  '伞': 's', '伤': 's', '何': 'h', '估': 'g', '佑': 'y', '余': 'y', '佩': 'p', '侯': 'h', '侵': 'q', '便': 'b',
  '促': 'c', '俄': 'e', '俅': 'q', '俊': 'j', '俏': 'q', '俐': 'l', '侯': 'h', '侵': 'q', '便': 'b', '促': 'c',
  // 数字
  '0': '0', '1': '1', '2': '2', '3': '3', '4': '4', '5': '5', '6': '6', '7': '7', '8': '8', '9': '9',
  // 字母
  'A': 'a', 'B': 'b', 'C': 'c', 'D': 'd', 'E': 'e', 'F': 'f', 'G': 'g', 'H': 'h', 'I': 'i', 'J': 'j',
  'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'O': 'o', 'P': 'p', 'Q': 'q', 'R': 'r', 'S': 's', 'T': 't',
  'U': 'u', 'V': 'v', 'W': 'w', 'X': 'x', 'Y': 'y', 'Z': 'z'
};

/**
 * 拼音工具类
 * 提供中文到拼音的转换功能，支持全拼和首字母提取
 */
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
   * 提取字符串的拼音首字母
   * @param text 输入文本
   * @returns 拼音首字母字符串
   */
  public getFirstLetter(text: string): string {
    if (!text || typeof text !== 'string') {
      return '';
    }

    let result = '';
    for (let i = 0; i < text.length; i++) {
      const char = text.charAt(i);
      // 如果是英文字母，直接转为小写
      if (/^[a-zA-Z]$/.test(char)) {
        result += char.toLowerCase();
      }
      // 如果是数字，直接添加
      else if (/^[0-9]$/.test(char)) {
        result += char;
      }
      // 如果是汉字，查找首字母
      else if (char in PINYIN_MAP) {
        result += PINYIN_MAP[char];
      }
      // 其他字符，跳过
    }

    return result;
  }

  /**
   * 检查文本是否包含指定的拼音首字母序列
   * @param text 输入文本
   * @param pinyin 拼音首字母序列
   * @returns 是否匹配
   */
  public containsPinyin(text: string, pinyin: string): boolean {
    if (!text || !pinyin) {
      return false;
    }

    const firstLetters = this.getFirstLetter(text);
    return firstLetters.includes(pinyin.toLowerCase());
  }

  /**
   * 检查文本是否以指定的拼音首字母序列开头
   * @param text 输入文本
   * @param pinyin 拼音首字母序列
   * @returns 是否匹配
   */
  public startsWithPinyin(text: string, pinyin: string): boolean {
    if (!text || !pinyin) {
      return false;
    }

    const firstLetters = this.getFirstLetter(text);
    return firstLetters.startsWith(pinyin.toLowerCase());
  }

  /**
   * 扩展拼音映射表
   * @param map 要添加的映射
   */
  public extendPinyinMap(map: Record<string, string>): void {
    // 手动合并映射表，避免使用Object.assign（ArkTS限制）
    for (const key in map) {
      if (map.hasOwnProperty(key)) {
        PINYIN_MAP[key] = map[key];
      }
    }
    Logger.debug(TAG, `Pinyin map extended with ${Object.keys(map).length} entries`);
  }

  /**
   * 搜索过滤函数 - 根据拼音首字母过滤数组
   * @param items 要过滤的数组
   * @param keyword 搜索关键词
   * @param textExtractor 从数组项中提取文本的函数
   * @returns 过滤后的数组
   */
  public filterByPinyin<T>(items: T[], keyword: string, textExtractor: (item: T) => string): T[] {
    if (!keyword || keyword.trim() === '') {
      return items;
    }

    const lowerKeyword = keyword.toLowerCase();
    
    return items.filter(item => {
      const text = textExtractor(item);
      // 文本直接匹配
      if (text.toLowerCase().includes(lowerKeyword)) {
        return true;
      }
      // 拼音首字母匹配
      return this.containsPinyin(text, lowerKeyword);
    });
  }
}

// 导出单例
export const pinyinUtil = PinyinUtil.getInstance();
export default pinyinUtil;