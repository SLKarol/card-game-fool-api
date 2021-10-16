import { Controller, Get, Param } from '@nestjs/common';

import { ReportService } from './report.service';

@Controller('report')
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Get(':id')
  async tableInfo(@Param('id') idGame: string): Promise<string[]> {
    const table = await this.reportService.getGameScore(idGame);
    return table;
  }
}
