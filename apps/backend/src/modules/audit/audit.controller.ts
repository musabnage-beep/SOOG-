import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';
import { Roles } from '@/common/decorators/roles.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PaginationDto, paginate } from '@/common/dto/pagination.dto';

@ApiTags('Audit Logs')
@ApiBearerAuth()
@Controller('activity-logs')
@Roles(RoleName.ADMIN)
@UseGuards(RolesGuard)
export class AuditController {
  constructor(private readonly prisma: PrismaService) {}

  @Get()
  async list(@Query() query: PaginationDto) {
    const where = query.search
      ? {
          OR: [
            { action: { contains: query.search, mode: 'insensitive' as const } },
            { entity: { contains: query.search, mode: 'insensitive' as const } },
          ],
        }
      : {};
    const [items, total] = await Promise.all([
      this.prisma.activityLog.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: query.skip,
        take: query.limit,
        include: { user: { select: { id: true, fullName: true, email: true } } },
      }),
      this.prisma.activityLog.count({ where }),
    ]);
    return paginate(items, total, query.page, query.limit);
  }
}
