// MovieMapper.ts - 电影数据映射器
// 负责电影领域模型和DTO之间的转换

import { Mapper } from './BaseMapper';
import { Movie } from '../../data/model/Movie';
import { MovieDetailDto, VideoDto } from '../../data/dto/MovieDetailDto';

/**
 * 电影映射器 | Movie mapper
 * 负责电影领域模型和DTO之间的转换
 */
export class MovieMapper extends Mapper<Movie, MovieDetailDto> {
  /**
   * 将电影领域模型转换为DTO | Convert movie domain model to DTO
   */
  toDTO(domain: Movie): MovieDetailDto {
    return {
      id: domain.id,
      name: domain.title,
      originalName: domain.originalTitle || '',
      year: domain.year || 0,
      rating: domain.rating || 0,
      genres: domain.genres || [],
      directors: domain.directors || [],
      actors: domain.actors || [],
      summary: domain.description || '',
      poster: domain.posterUrl || '',
      backdrop: domain.backdropUrl || '',
      videos: domain.videos?.map(video => ({
        id: video.id,
        name: video.title,
        url: video.url,
        quality: video.quality,
        size: video.size || 0,
        format: video.format || ''
      })) || []
    };
  }
  
  /**
   * 将电影DTO转换为领域模型 | Convert movie DTO to domain model
   */
  toDomain(dto: MovieDetailDto): Movie {
    return {
      id: dto.id,
      title: dto.name,
      originalTitle: dto.originalName,
      year: dto.year,
      rating: dto.rating,
      genres: dto.genres,
      directors: dto.directors,
      actors: dto.actors,
      description: dto.summary,
      posterUrl: dto.poster,
      backdropUrl: dto.backdrop,
      videos: dto.videos?.map(video => ({
        id: video.id,
        title: video.name,
        url: video.url,
        quality: video.quality,
        size: video.size,
        format: video.format
      })) || [],
      isFavorite: false,
      watchHistory: {
        lastWatched: 0,
        watchedDuration: 0,
        totalDuration: 0
      }
    };
  }
}

export default new MovieMapper();