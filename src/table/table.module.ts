import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';

import { CardsInTableView } from './entities/cardsInTableView.entity';
import { TableController } from './table.controller';
import { TableService } from './table.service';

@Module({
  imports: [TypeOrmModule.forFeature([CardsInTableView])],
  controllers: [TableController],
  providers: [TableService],
  exports: [TableService],
})
export class TableModule {}
