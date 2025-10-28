import { ParserService, parserService } from './ParserService';

// 导出解析器服务
export { ParserService, parserService };

// 从解析器服务中重新导出关键方法，以便于外部直接使用
export { parserService as default };