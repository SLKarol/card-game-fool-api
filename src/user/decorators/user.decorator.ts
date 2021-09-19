import { createParamDecorator, ExecutionContext } from '@nestjs/common';

import { ExpressRequest } from '@app/types/expressRequest.interface';

export const User = createParamDecorator((data: any, ctx: ExecutionContext) => {
  const request = ctx.switchToHttp().getRequest<ExpressRequest>();
  if (!request.user) return null;

  if (data) {
    return request.user[data];
  }
  return request.user;
});
