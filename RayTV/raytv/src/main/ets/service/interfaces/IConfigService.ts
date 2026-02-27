interface ConfigSource {
  id: string;
  name: string;
  url: string;
  enabled: boolean;
}

interface IConfigService {
  getConfigSources(): Promise<ConfigSource[]>;
  addConfigSource(source: Omit<ConfigSource, 'id'>): Promise<ConfigSource>;
  updateConfigSource(id: string, updates: Partial<ConfigSource>): Promise<ConfigSource>;
  deleteConfigSource(id: string): Promise<boolean>;
  enableConfigSource(id: string, enabled: boolean): Promise<ConfigSource>;
}

export { IConfigService, ConfigSource };