import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}

/**
 * Неавторизованные пользователи могут воспользоваться службой.
 * При этом user будет равен null
 */
@Injectable()
export class AllowNullUserGuard extends AuthGuard('jwt') {
  handleRequest(err, user) {
    // Если пользователь на авторизован, то user = null
    return user || null;
  }
}
