/**
 * 自动修复ArkTS违规问题 - P0级别
 * 修复: any类型、索引签名、索引访问
 */

import * as fs from 'fs';
import * as path from 'path';

// 忽略的目录
const IGNORE_DIRS = [
  'node_modules',
  'oh_modules',
  '.hvigor',
  'build',
  'dist',
  '.idea',
  '.vscode',
  '__tests__'
];

// 类型替换映射 - 为常见any类型提供更具体的类型
const TYPE_REPLACEMENTS: Record<string, string> = {
  'private.*: any\\[\\]': 'private $1: unknown[]',
  'public.*: any\\[\\]': 'public $1: unknown[]',
  ': any\\[\\]': ': unknown[]',
  'function.*any\\[\\]': 'function',
  '=> any\\[\\]': '=> unknown[]',
  'Promise<any>': 'Promise<unknown>',
  ': any =': ': unknown =',
  ': any;': ': unknown;',
  ': any,': ': unknown,',
  ': any)': ': unknown)',
  ': any ': ': unknown ',
  '\\(.*: any\\)': '($1: unknown)',
  '<any>': '<unknown>',
  '\\.any\\(': '.unknown(',
  'as any': 'as unknown',
  'Record<string, any>': 'Record<string, Object>',
  '\\{ \\[key: string\\]: any \\}': 'Map<string, Object>',
  '\\[key: string\\]: any': '// Removed: index signature not supported in ArkTS',
};

// 接口生成模板
const INTERFACE_TEMPLATES: Record<string, string> = {
  'ConfigItem': `interface ConfigItem {
  key: string;
  value: string;
}`,
  'CacheEntry': `interface CacheEntry {
  key: string;
  value: unknown;
  timestamp: number;
}`,
  'StorageData': `interface StorageData {
  data: unknown;
  version: number;
  timestamp: number;
}`,
};

interface FixResult {
  file: string;
  type: string;
  fixed: number;
  details: string[];
}

class ArkTSFixer {
  private results: FixResult[] = [];

  /**
   * 递归扫描目录
   */
  private scanDirectory(dir: string, extensions: string[] = ['.ets', '.ts']): string[] {
    const files: string[] = [];

    if (!fs.existsSync(dir)) {
      return files;
    }

    const entries = fs.readdirSync(dir);

    for (const entry of entries) {
      const fullPath = path.join(dir, entry);
      const stat = fs.statSync(fullPath);

      if (stat.isDirectory()) {
        // 检查是否应该忽略此目录
        if (!IGNORE_DIRS.some(ignored => fullPath.includes(ignored))) {
          files.push(...this.scanDirectory(fullPath, extensions));
        }
      } else if (stat.isFile() && extensions.some(ext => entry.endsWith(ext))) {
        files.push(fullPath);
      }
    }

    return files;
  }

  /**
   * 修复any类型
   */
  private fixAnyTypes(content: string): { content: string; fixes: string[] } {
    const fixes: string[] = [];
    let newContent = content;

    // 替换常见的any类型为unknown
    Object.entries(TYPE_REPLACEMENTS).forEach(([pattern, replacement]) => {
      const regex = new RegExp(pattern, 'g');
      const matches = content.match(regex);
      if (matches) {
        newContent = newContent.replace(regex, replacement);
        fixes.push(`替换 ${matches.length} 处 "${pattern}" 为 "${replacement}"`);
      }
    });

    return { content: newContent, fixes };
  }

  /**
   * 修复索引签名
   */
  private fixIndexSignatures(content: string): { content: string; fixes: string[] } {
    const fixes: string[] = [];
    let newContent = content;

    // 匹配索引签名模式
    const indexSignaturePattern = /(\[key:\s*(string|number)\]:\s*)(any|unknown|Object|string|number|boolean)/g;
    let match;

    while ((match = indexSignaturePattern.exec(content)) !== null) {
      fixes.push(`移除索引签名: ${match[0]}`);
    }

    // 替换索引签名为注释
    newContent = content.replace(indexSignaturePattern, '// $1$3 - index signature not supported in ArkTS');

    return { content: newContent, fixes };
  }

  /**
   * 修复索引访问
   */
  private fixIndexedAccess(content: string): { content: string; fixes: string[] } {
    const fixes: string[] = [];
    let newContent = content;

    // 匹配索引访问模式 obj['key']
    const indexedAccessPattern = /(\w+)\[['"]([^'"]+)['"]\]/g;
    let match;

    while ((match = indexedAccessPattern.exec(content)) !== null) {
      const fullMatch = match[0];
      const obj = match[1];
      const key = match[2];

      // 检查key是否是有效的标识符
      if (/^[a-zA-Z_$][a-zA-Z0-9_$]*$/.test(key)) {
        newContent = newContent.replace(fullMatch, `${obj}.${key}`);
        fixes.push(`替换索引访问: ${fullMatch} -> ${obj}.${key}`);
      }
    }

    return { content: newContent, fixes };
  }

  /**
   * 修复文件
   */
  private fixFile(filePath: string): FixResult {
    const result: FixResult = {
      file: filePath,
      type: 'P0',
      fixed: 0,
      details: []
    };

    try {
      let content = fs.readFileSync(filePath, 'utf-8');
      const originalContent = content;

      // 修复any类型
      const anyFixResult = this.fixAnyTypes(content);
      content = anyFixResult.content;
      result.details.push(...anyFixResult.fixes);

      // 修复索引签名
      const indexFixResult = this.fixIndexSignatures(content);
      content = indexFixResult.content;
      result.details.push(...indexFixResult.fixes);

      // 修复索引访问
      const accessFixResult = this.fixIndexedAccess(content);
      content = accessFixResult.content;
      result.details.push(...accessFixResult.fixes);

      result.fixed = result.details.length;

      // 如果内容有变化,写回文件
      if (content !== originalContent) {
        fs.writeFileSync(filePath, content, 'utf-8');
        console.log(`✅ 修复完成: ${filePath} (${result.fixed} 处修复)`);
      } else {
        console.log(`ℹ️  无需修复: ${filePath}`);
      }

    } catch (error) {
      console.error(`❌ 修复失败: ${filePath}`, error);
      result.details.push(`修复失败: ${error}`);
    }

    return result;
  }

  /**
   * 批量修复
   */
  public fixAll(baseDir: string): FixResult[] {
    console.log('🔧 开始修复ArkTS P0级别违规...\n');

    const files = this.scanDirectory(baseDir);
    console.log(`📁 找到 ${files.length} 个文件\n`);

    for (const file of files) {
      const result = this.fixFile(file);
      if (result.fixed > 0) {
        this.results.push(result);
      }
    }

    return this.results;
  }

  /**
   * 生成修复报告
   */
  public generateReport(): void {
    console.log('\n' + '='.repeat(80));
    console.log('📊 修复报告');
    console.log('='.repeat(80) + '\n');

    const totalFixed = this.results.reduce((sum, r) => sum + r.fixed, 0);
    console.log(`总计修复: ${totalFixed} 处`);
    console.log(`修复文件: ${this.results.length} 个\n`);

    // 按文件显示修复详情
    if (this.results.length > 0) {
      console.log('修复详情:\n');
      for (const result of this.results) {
        console.log(`📄 ${result.file}`);
        for (const detail of result.details) {
          console.log(`   • ${detail}`);
        }
        console.log('');
      }
    }

    console.log('='.repeat(80) + '\n');
  }
}

// 执行修复
const fixer = new ArkTSFixer();
const workspace = process.cwd();
const results = fixer.fixAll(workspace);
fixer.generateReport();
