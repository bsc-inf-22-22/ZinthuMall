import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { v2 as cloudinary } from 'cloudinary';
import { Readable } from 'stream';

/**
 * Uploads product images to Cloudinary.
 * If the CLOUDINARY_* variables are not set, the API still starts;
 * only image uploads are refused with a clear error.
 */
@Injectable()
export class CloudinaryService {
  private readonly logger = new Logger(CloudinaryService.name);
  private readonly configured: boolean;

  constructor(config: ConfigService) {
    const cloudName = config.get<string>('CLOUDINARY_CLOUD_NAME');
    const apiKey = config.get<string>('CLOUDINARY_API_KEY');
    const apiSecret = config.get<string>('CLOUDINARY_API_SECRET');
    this.configured = Boolean(cloudName && apiKey && apiSecret);
    if (this.configured) {
      cloudinary.config({
        cloud_name: cloudName,
        api_key: apiKey,
        api_secret: apiSecret,
        secure: true,
      });
    } else {
      this.logger.warn(
        'Cloudinary is not configured: product image uploads are disabled',
      );
    }
  }

  uploadImage(file: Express.Multer.File): Promise<string> {
    if (!this.configured) {
      throw new ServiceUnavailableException(
        'Image uploads are not configured on this server',
      );
    }
    return new Promise((resolve, reject) => {
      const upload = cloudinary.uploader.upload_stream(
        { folder: 'kachipapa/products' },
        (error, result) => {
          if (error || !result)
            reject(new Error(error?.message ?? 'Upload failed'));
          else resolve(result.secure_url);
        },
      );
      Readable.from(file.buffer).pipe(upload);
    });
  }

  async deleteImage(imageUrl: string): Promise<void> {
    if (!this.configured) return;
    // .../upload/v123/kachipapa/products/abc.jpg -> kachipapa/products/abc
    const match = imageUrl.match(/\/upload\/(?:v\d+\/)?(.+)\.[a-z0-9]+$/i);
    if (match) await cloudinary.uploader.destroy(match[1]);
  }
}
