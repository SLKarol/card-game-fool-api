import { Controller, Get, UseGuards, Query } from '@nestjs/common';

import { TableInfo } from './types/tableInfo';
import { TableService } from './table.service';
import { JwtAuthGuard } from '@app/user/guards/jwt.guard';

@Controller('table')
export class TableController {
  constructor(private readonly tableService: TableService) {}

  @Get()
  @UseGuards(JwtAuthGuard)
  async tableInfo(@Query('id') idGame: string): Promise<TableInfo> {
    const table = await this.tableService.getTableContent(idGame);
    return table;
  }
}
