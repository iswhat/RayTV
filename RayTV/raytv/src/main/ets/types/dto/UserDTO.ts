interface UserDTO {
  id: string;
  username: string;
  email?: string;
  isLoggedIn: boolean;
  lastLogin?: string;
}

export { UserDTO };