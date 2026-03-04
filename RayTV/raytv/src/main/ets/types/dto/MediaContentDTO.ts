interface MediaContentDTO {
  id: string;
  title: string;
  description: string;
  coverUrl: string;
  duration: number;
  url: string;
  category: string;
  tags: string[];
  views: number;
  rating: number;
  releaseDate: string;
  isFavorite?: boolean;
}