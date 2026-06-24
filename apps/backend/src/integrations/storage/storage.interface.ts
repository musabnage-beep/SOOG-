export interface UploadInput {
  buffer: Buffer;
  contentType: string;
  /** Logical key/path within the bucket, e.g. "products/<id>/main.webp" */
  key: string;
}

export interface StoredObject {
  key: string;
  url: string;
}

export const STORAGE_PROVIDER = Symbol('STORAGE_PROVIDER');

export interface StorageProvider {
  upload(input: UploadInput): Promise<StoredObject>;
  delete(key: string): Promise<void>;
  /** Public/CDN URL for a stored key. */
  urlFor(key: string): string;
}
