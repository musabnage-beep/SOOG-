import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DeleteObjectCommand, PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { StorageProvider, StoredObject, UploadInput } from './storage.interface';

/** Production provider: uploads to AWS S3, serves via CloudFront/public base URL. */
@Injectable()
export class S3StorageProvider implements StorageProvider {
  private readonly logger = new Logger(S3StorageProvider.name);
  private readonly client: S3Client;
  private readonly bucket: string;
  private readonly publicBase: string;

  constructor(config: ConfigService) {
    const region = config.getOrThrow<string>('AWS_REGION');
    this.bucket = config.getOrThrow<string>('S3_BUCKET');
    this.publicBase =
      config.get<string>('S3_PUBLIC_BASE_URL') ||
      `https://${this.bucket}.s3.${region}.amazonaws.com`;
    this.client = new S3Client({
      region,
      credentials: {
        accessKeyId: config.getOrThrow<string>('AWS_ACCESS_KEY_ID'),
        secretAccessKey: config.getOrThrow<string>('AWS_SECRET_ACCESS_KEY'),
      },
    });
  }

  async upload(input: UploadInput): Promise<StoredObject> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: input.key,
        Body: input.buffer,
        ContentType: input.contentType,
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );
    this.logger.debug(`Uploaded ${input.key} to s3://${this.bucket}`);
    return { key: input.key, url: this.urlFor(input.key) };
  }

  async delete(key: string): Promise<void> {
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
  }

  urlFor(key: string): string {
    return `${this.publicBase}/${key}`;
  }
}
