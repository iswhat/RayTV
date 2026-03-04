interface MediaContent {
  id: string;
  title: string;
  description: string;
  url: string;
  thumbnail?: string;
  duration?: number;
  source: string;
  category: string;
  createdAt: Date;
}

interface AggregationOptions {
  page?: number;
  limit?: number;
  category?: string;
  sortBy?: 'relevance' | 'date' | 'popularity';
}

interface IContentAggregatorService {
  aggregate(options?: AggregationOptions): Promise<MediaContent[]>;
  getContentById(id: string): Promise<MediaContent | null>;
  getCategories(): Promise<string[]>;
  refreshContent(): Promise<void>;
}

export { IContentAggregatorService, MediaContent, AggregationOptions };