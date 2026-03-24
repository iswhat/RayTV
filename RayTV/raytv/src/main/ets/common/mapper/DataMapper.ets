import { MediaContentDTO } from '../../types/dto/MediaContentDTO';
import { UserDTO } from '../../types/dto/UserDTO';
import { SettingsDTO } from '../../types/dto/SettingsDTO';
import { ConfigSourceDTO } from '../../types/dto/ConfigSourceDTO';

export class DataMapper {
  mapToMediaContentDTO(media: Record<string, Object>): MediaContentDTO {
    return {
      id: media.id as string,
      title: media.title as string,
      description: media.description as string,
      url: media.url as string,
      thumbnail: media.thumbnail as string,
      duration: media.duration as number,
      source: media.source as string,
      category: media.category as string,
      createdAt: media.createdAt instanceof Date ? media.createdAt.toISOString() : media.createdAt as string
    };
  }

  mapFromMediaContentDTO(dto: MediaContentDTO): Record<string, Object> {
    return {
      id: dto.id,
      title: dto.title,
      description: dto.description,
      url: dto.url,
      thumbnail: dto.thumbnail,
      duration: dto.duration,
      source: dto.source,
      category: dto.category,
      createdAt: new Date(dto.createdAt)
    };
  }

  mapToUserDTO(user: Record<string, Object>): UserDTO {
    return {
      id: user.id as string,
      username: user.username as string,
      email: user.email as string,
      isLoggedIn: user.isLoggedIn as boolean,
      lastLogin: user.lastLogin instanceof Date ? user.lastLogin.toISOString() : user.lastLogin as string
    };
  }

  mapFromUserDTO(dto: UserDTO): Record<string, Object> {
    return {
      id: dto.id,
      username: dto.username,
      email: dto.email,
      isLoggedIn: dto.isLoggedIn,
      lastLogin: dto.lastLogin ? new Date(dto.lastLogin) : undefined
    };
  }

  mapToSettingsDTO(settings: Record<string, Object>): SettingsDTO {
    return {
      theme: settings.theme as string,
      language: settings.language as string,
      autoPlay: settings.autoPlay as boolean,
      notifications: settings.notifications as boolean,
      quality: settings.quality as string
    };
  }

  mapFromSettingsDTO(dto: SettingsDTO): Record<string, Object> {
    return {
      theme: dto.theme,
      language: dto.language,
      autoPlay: dto.autoPlay,
      notifications: dto.notifications,
      quality: dto.quality
    };
  }

  mapToConfigSourceDTO(source: Record<string, Object>): ConfigSourceDTO {
    return {
      id: source.id as string,
      name: source.name as string,
      url: source.url as string,
      enabled: source.enabled as boolean,
      lastUpdated: source.lastUpdated instanceof Date ? source.lastUpdated.toISOString() : source.lastUpdated as string
    };
  }

  mapFromConfigSourceDTO(dto: ConfigSourceDTO): Record<string, Object> {
    return {
      id: dto.id,
      name: dto.name,
      url: dto.url,
      enabled: dto.enabled,
      lastUpdated: dto.lastUpdated ? new Date(dto.lastUpdated) : undefined
    };
  }
}

export const dataMapper = new DataMapper();