import { Controller, Get, UseGuards, Query } from '@nestjs/common';

import { TableService } from './table.service';
import { JwtAuthGuard } from '@app/user/guards/jwt.guard';
import { User } from '@app/user/decorators/user.decorator';

@Controller('table')
export class TableController {
  constructor(private readonly tableService: TableService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async tableInfo(
    @User('id_user') currentUserId: string,
    @Query('id') idGame: string,
  ): Promise<any> {
    const table = await this.tableService.getTableContent(
      currentUserId,
      idGame,
    );
    return { table };
  }
}
