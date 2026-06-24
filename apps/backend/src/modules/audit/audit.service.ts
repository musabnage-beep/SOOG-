import { Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '@/prisma/prisma.service';

export interface AuditEntry {
  userId?: string | null;
  action: string;
  entity: string;
  entityId?: string | null;
  ip?: string | null;
  oldValue?: Prisma.InputJsonValue | null;
  newValue?: Prisma.InputJsonValue | null;
}

@Injectable()
export class AuditService {
  constructor(private readonly prisma: PrismaService) {}

  /** Records an audit/activity-log entry. Never throws (best-effort). */
  async record(entry: AuditEntry): Promise<void> {
    try {
      await this.prisma.activityLog.create({
        data: {
          userId: entry.userId ?? null,
          action: entry.action,
          entity: entry.entity,
          entityId: entry.entityId ?? null,
          ip: entry.ip ?? null,
          oldValue: entry.oldValue ?? Prisma.JsonNull,
          newValue: entry.newValue ?? Prisma.JsonNull,
        },
      });
    } catch {
      // swallow — auditing must not break the primary operation
    }
  }
}
