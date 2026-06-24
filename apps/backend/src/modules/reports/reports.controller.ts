import { BadRequestException, Controller, Get, Query, Res, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiQuery, ApiTags } from '@nestjs/swagger';
import { Response } from 'express';
import { ReportFormat, ReportType, RoleName } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { ReportsService } from './reports.service';
import { ReportExporter } from './report-exporter';

@ApiTags('Reports')
@ApiBearerAuth()
@Controller('reports')
@Roles(RoleName.ADMIN)
@RequirePermissions('report.view')
@UseGuards(RolesGuard, PermissionsGuard)
export class ReportsController {
  constructor(
    private readonly service: ReportsService,
    private readonly exporter: ReportExporter,
  ) {}

  /** Returns report data as JSON (for on-screen tables). */
  @Get()
  @ApiQuery({ name: 'type', enum: ReportType })
  data(
    @Query('type') type: ReportType,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.service.build(type, { from: this.parse(from), to: this.parse(to) });
  }

  /** Exports a report as PDF / Excel / CSV. */
  @Get('export')
  @ApiQuery({ name: 'type', enum: ReportType })
  @ApiQuery({ name: 'format', enum: ReportFormat })
  async export(
    @Query('type') type: ReportType,
    @Query('format') format: ReportFormat,
    @Res() res: Response,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    const dataset = await this.service.build(type, { from: this.parse(from), to: this.parse(to) });
    const file =
      format === ReportFormat.PDF
        ? await this.exporter.toPdf(dataset)
        : format === ReportFormat.EXCEL
          ? await this.exporter.toExcel(dataset)
          : format === ReportFormat.CSV
            ? await this.exporter.toCsv(dataset)
            : null;
    if (!file) throw new BadRequestException('Invalid format');

    res.setHeader('Content-Type', file.contentType);
    res.setHeader('Content-Disposition', `attachment; filename="${file.filename}"`);
    res.send(file.buffer);
  }

  private parse(value?: string): Date | undefined {
    if (!value) return undefined;
    const d = new Date(value);
    return Number.isNaN(d.getTime()) ? undefined : d;
  }
}
