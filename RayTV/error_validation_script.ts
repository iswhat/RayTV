// 错误验证脚本 - 检查当前项目中的ArkTS编译错误
import { readFileSync, existsSync } from 'fs';
import { join } from 'path';

interface ErrorInfo {
    file: string;
    line: number;
    column: number;
    errorCode: string;
    message: string;
    type: string;
}

class ErrorValidator {
    private errors: ErrorInfo[] = [];
    private errorPatterns = [
        {
            pattern: /Error Message: ([^(]+) \(?([^)]*)\)? At File: ([^:]+):(\d+):(\d+)/,
            type: 'compiler-error'
        },
        {
            pattern: /WARN: ArkTS:WARN File: ([^:]+):(\d+):(\d+)\n(.+)/,
            type: 'warning'
        }
    ];

    validateBuildOutput(filePath: string): ErrorInfo[] {
        if (!existsSync(filePath)) {
            console.log('构建输出文件不存在:', filePath);
            return [];
        }

        const content = readFileSync(filePath, 'utf-8');
        const lines = content.split('\n');
        
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim();
            
            // 检查错误模式
            for (const patternInfo of this.errorPatterns) {
                const match = line.match(patternInfo.pattern);
                if (match) {
                    const errorInfo: ErrorInfo = {
                        file: '',
                        line: 0,
                        column: 0,
                        errorCode: '',
                        message: '',
                        type: patternInfo.type
                    };

                    if (patternInfo.type === 'compiler-error') {
                        errorInfo.message = match[1].trim();
                        errorInfo.errorCode = match[2] || '';
                        errorInfo.file = match[3];
                        errorInfo.line = parseInt(match[4]);
                        errorInfo.column = parseInt(match[5]);
                    } else {
                        errorInfo.file = match[1];
                        errorInfo.line = parseInt(match[2]);
                        errorInfo.column = parseInt(match[3]);
                        errorInfo.message = match[4];
                    }

                    this.errors.push(errorInfo);
                    break;
                }
            }
        }

        return this.errors;
    }

    categorizeErrors(errors: ErrorInfo[]): Record<string, ErrorInfo[]> {
        const categorized: Record<string, ErrorInfo[]> = {};
        
        for (const error of errors) {
            const category = this.categorizeError(error);
            if (!categorized[category]) {
                categorized[category] = [];
            }
            categorized[category].push(error);
        }
        
        return categorized;
    }

    private categorizeError(error: ErrorInfo): string {
        const message = error.message.toLowerCase();
        
        if (message.includes('any') || message.includes('unknown')) {
            return 'type-safety';
        } else if (message.includes('object literal')) {
            return 'object-literals';
        } else if (message.includes('catch') && message.includes('type')) {
            return 'catch-clauses';
        } else if (message.includes('throw')) {
            return 'throw-statements';
        } else if (message.includes('destructure')) {
            return 'destructuring';
        } else if (message.includes('import')) {
            return 'import-errors';
        } else {
            return 'other';
        }
    }

    generateReport(errors: ErrorInfo[], categorized: Record<string, ErrorInfo[]>): string {
        let report = '\n=== ArkTS 错误验证报告 ===\n\n';
        report += `总错误数: ${errors.length}\n\n`;
        
        report += '按类别统计:\n';
        for (const [category, categoryErrors] of Object.entries(categorized)) {
            report += `${category}: ${categoryErrors.length} 个错误\n`;
        }
        
        report += '\n详细错误列表:\n';
        for (const error of errors) {
            report += `\n文件: ${error.file}:${error.line}:${error.column}\n`;
            report += `类型: ${error.type}\n`;
            report += `消息: ${error.message}\n`;
            if (error.errorCode) {
                report += `错误码: ${error.errorCode}\n`;
            }
            report += '---\n';
        }
        
        return report;
    }
}

// 执行验证
const validator = new ErrorValidator();
const buildOutputPath = join(__dirname, '构建输出结果.md');

console.log('正在分析构建输出...');
const errors = validator.validateBuildOutput(buildOutputPath);

if (errors.length === 0) {
    console.log('✅ 没有检测到编译错误！');
} else {
    const categorized = validator.categorizeErrors(errors);
    const report = validator.generateReport(errors, categorized);
    console.log(report);
    
    // 保存详细报告
    const fs = require('fs');
    fs.writeFileSync(join(__dirname, 'error_validation_report.txt'), report);
    console.log('\n详细报告已保存到: error_validation_report.txt');
}