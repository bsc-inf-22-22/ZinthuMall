import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { JwtPayload, Role } from './jwt-payload';

function requireRole(role: Role) {
  @Injectable()
  class RoleGuard extends AuthGuard('jwt') {
    handleRequest<T = JwtPayload>(err: unknown, user: JwtPayload | false): T {
      if (err || !user) throw new UnauthorizedException('Please log in');
      if (user.role !== role)
        throw new ForbiddenException('You do not have access to this resource');
      return user as T;
    }
  }
  return RoleGuard;
}

/** Only logged-in store admins. */
export const AdminGuard = requireRole('admin');

/** Only logged-in customers. */
export const CustomerGuard = requireRole('customer');

/** Attaches the user if a valid token is sent, but also allows guests. */
@Injectable()
export class OptionalAuthGuard extends AuthGuard('jwt') {
  handleRequest<T = JwtPayload>(_err: unknown, user: JwtPayload | false): T {
    return (user || undefined) as T;
  }
}
