import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'fs';
import { join, dirname } from 'path';
import { StorageProvider, StoredObject, UploadInput } from './storage.interface';

/** Dev/local provider: writes files under LOCAL_UPLOAD_DIR, served by the API statically. */
@Injectable()
export class LocalStorageProvider implements StorageProvider {
  private readonly logger = new Logger(LocalStorageProvider.name);
  private readonly baseDir: string;
  private readonly publicBase: string;

  constructor(config: ConfigService) {
    this.baseDir = config.get<string>('LOCAL_UPLOAD_DIR', './uploads');
    const port = config.get<number>('PORT', 3000);
    const prefix = config.get<string>('API_PREFIX', 'api');
    this.publicBase = config.get<string>('S3_PUBLIC_BASE_URL') || `http://localhost:${port}/${prefix}/static`;
  }

  async upload(input: UploadInput): Promise<StoredObject> {
    const full = join(this.baseDir, input.key);
    await fs.mkdir(dirname(full), { recursive: true });
    await fs.writeFile(full, input.buffer);
    this.logger.debug(`Stored ${input.key} locally`);
    return { key: input.key, url: this.urlFor(input.key) };
  }

  async delete(key: string): Promise<void> {
    await fs.rm(join(this.baseDir, key), { force: true });
  }

  urlFor(key: string): string {
    return `${this.publicBase}/${key}`;
  }
}
