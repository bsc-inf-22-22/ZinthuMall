export type Role = 'admin' | 'customer';

/** What we put inside every access token. */
export interface JwtPayload {
  sub: number;
  email: string;
  role: Role;
}
