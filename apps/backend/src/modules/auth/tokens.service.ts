import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import * as argon2 from 'argon2';
import { PrismaService } from '@/prisma/prisma.service';
import { JwtPayload } from './strategies/jwt.strategy';

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

@Injectable()
export class TokensService {
  constructor(
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  /** Issues an access + refresh pair and persists a hashed refresh token (session). */
  async issue(
    userId: string,
    role: string,
    meta?: { ip?: string; userAgent?: string },
  ): Promise<TokenPair> {
    const accessTtl = this.config.get<number>('JWT_ACCESS_TTL', 900);
    const refreshTtl = this.config.get<number>('JWT_REFRESH_TTL', 2592000);

    const payload: JwtPayload = { sub: userId, role, type: 'access' };
    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.getOrThrow('JWT_ACCESS_SECRET'),
      expiresIn: accessTtl,
    });
    const refreshToken = await this.jwt.signAsync(
      { sub: userId, type: 'refresh' },
      { secret: this.config.getOrThrow('JWT_REFRESH_SECRET'), expiresIn: refreshTtl },
    );

    await this.prisma.session.create({
      data: {
        userId,
        refreshTokenHash: await argon2.hash(refreshToken),
        ip: meta?.ip,
        userAgent: meta?.userAgent,
        expiresAt: new Date(Date.now() + refreshTtl * 1000),
      },
    });

    return { accessToken, refreshToken, expiresIn: accessTtl };
  }

  /** Validates a refresh token against stored sessions, rotates it, returns a new pair. */
  async rotate(refreshToken: string, meta?: { ip?: string; userAgent?: string }): Promise<TokenPair> {
    let decoded: { sub: string };
    try {
      decoded = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
      });
    } catch {
      throw new Error('Invalid refresh token');
    }

    const sessions = await this.prisma.session.findMany({
      where: { userId: decoded.sub, revokedAt: null, expiresAt: { gt: new Date() } },
    });
    let matched = null;
    for (const s of sessions) {
      if (await argon2.verify(s.refreshTokenHash, refreshToken)) {
        matched = s;
        break;
      }
    }
    if (!matched) throw new Error('Refresh token not recognized');

    await this.prisma.session.update({
      where: { id: matched.id },
      data: { revokedAt: new Date() },
    });

    const user = await this.prisma.user.findUniqueOrThrow({
      where: { id: decoded.sub },
      include: { role: true },
    });
    return this.issue(user.id, user.role.name, meta);
  }

  /** Revokes a specific refresh token's session (logout). */
  async revoke(refreshToken: string): Promise<void> {
    let decoded: { sub: string };
    try {
      decoded = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.getOrThrow('JWT_REFRESH_SECRET'),
      });
    } catch {
      return;
    }
    const sessions = await this.prisma.session.findMany({
      where: { userId: decoded.sub, revokedAt: null },
    });
    for (const s of sessions) {
      if (await argon2.verify(s.refreshTokenHash, refreshToken)) {
        await this.prisma.session.update({ where: { id: s.id }, data: { revokedAt: new Date() } });
        return;
      }
    }
  }
}
