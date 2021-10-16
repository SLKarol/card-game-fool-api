import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { ScoreEntity } from './entities/score.entity';
import { ReportController } from './report.controller';
import { ReportService } from './report.service';

@Module({
  imports: [TypeOrmModule.forFeature([ScoreEntity])],
  providers: [ReportService],
  controllers: [ReportController],
  exports: [ReportService],
})
export class ReportModule {}
