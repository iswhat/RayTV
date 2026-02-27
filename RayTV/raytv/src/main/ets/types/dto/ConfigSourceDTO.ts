interface ConfigSourceDTO {
  id: string;
  name: string;
  url: string;
  enabled: boolean;
  lastUpdated?: string;
}

export { ConfigSourceDTO };