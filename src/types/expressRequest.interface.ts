import { Request } from 'express';

import { UserEntity } from '@app/user/user.entity';

export interface ExpressRequest extends Request {
	user?: UserEntity;
}
