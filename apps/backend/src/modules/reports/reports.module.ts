import { Module } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { ReportExporter } from './report-exporter';
import { ReportsController } from './reports.controller';

@Module({
  controllers: [ReportsController],
  providers: [ReportsService, ReportExporter],
})
export class ReportsModule {}
