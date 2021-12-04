import { Controller, Get, Param, UseGuards } from '@nestjs/common';

import type { MyGames } from './types/myGames';

import { JwtAuthGuard } from '@app/user/guards/jwt.guard';
import { ReportService } from './report.service';
import { User } from '@app/user/decorators/user.decorator';

@Controller('report')
export class ReportController {
  constructor(private readonly reportService: ReportService) {}

  @Get('game/:id')
  async tableInfo(@Param('id') idGame: string): Promise<string[]> {
    const table = await this.reportService.getGameScore(idGame);
    return table;
  }

  @Get('mygames')
  @UseGuards(JwtAuthGuard)
  async myGames(@User('id_user') currentUserId: string): Promise<MyGames> {
    const report = await this.reportService.getMyGames(currentUserId);
    return report;
  }
}
