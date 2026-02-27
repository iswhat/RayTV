import { MediaContentDTO } from '../../types/dto/MediaContentDTO';
import { UserDTO } from '../../types/dto/UserDTO';
import { SettingsDTO } from '../../types/dto/SettingsDTO';
import { ConfigSourceDTO } from '../../types/dto/ConfigSourceDTO';

class DataMapper {
  mapToMediaContentDTO(media: any): MediaContentDTO {
    return {
      id: media.id,
      title: media.title,
      description: media.description,
      url: media.url,
      thumbnail: media.thumbnail,
      duration: media.duration,
      source: media.source,
      category: media.category,
      createdAt: media.createdAt instanceof Date ? media.createdAt.toISOString() : media.createdAt
    };
  }

  mapFromMediaContentDTO(dto: MediaContentDTO): any {
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

  mapToUserDTO(user: any): UserDTO {
    return {
      id: user.id,
      username: user.username,
      email: user.email,
      isLoggedIn: user.isLoggedIn,
      lastLogin: user.lastLogin instanceof Date ? user.lastLogin.toISOString() : user.lastLogin
    };
  }

  mapFromUserDTO(dto: UserDTO): any {
    return {
      id: dto.id,
      username: dto.username,
      email: dto.email,
      isLoggedIn: dto.isLoggedIn,
      lastLogin: dto.lastLogin ? new Date(dto.lastLogin) : undefined
    };
  }

  mapToSettingsDTO(settings: any): SettingsDTO {
    return {
      theme: settings.theme,
      language: settings.language,
      autoPlay: settings.autoPlay,
      notifications: settings.notifications,
      quality: settings.quality
    };
  }

  mapFromSettingsDTO(dto: SettingsDTO): any {
    return {
      theme: dto.theme,
      language: dto.language,
      autoPlay: dto.autoPlay,
      notifications: dto.notifications,
      quality: dto.quality
    };
  }

  mapToConfigSourceDTO(source: any): ConfigSourceDTO {
    return {
      id: source.id,
      name: source.name,
      url: source.url,
      enabled: source.enabled,
      lastUpdated: source.lastUpdated instanceof Date ? source.lastUpdated.toISOString() : source.lastUpdated
    };
  }

  mapFromConfigSourceDTO(dto: ConfigSourceDTO): any {
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
export { DataMapper };