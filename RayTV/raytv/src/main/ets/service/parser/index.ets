// 解析器服务导出文件 | Parser service export file
// 导出解析器服务的所有相关内容 | Export all parser service related content

import { ParserService, getParserService } from './ParserService';

// 导出解析器服务 | Export parser service
export { ParserService, getParserService };

// 从解析器服务中重复导出关闭方法，以便于外部直接使用 | Export close method from parser service for external direct use
export { getParserService as default };



