import { UserDto } from './user.dto';

export class PatchUserDto extends PartialType(
  PickType(UserDto, ['password', 'image'] as const),
) {}

export class PutUserDto extends PartialType(UserDto) {}

export class MainPutUserDto {
  @ApiProperty()
  readonly user: PutUserDto;
}
