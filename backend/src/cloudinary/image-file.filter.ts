import { BadRequestException } from '@nestjs/common';

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024; // 5 MB

const ALLOWED = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

export function imageFileFilter(
  _req: unknown,
  file: Express.Multer.File,
  cb: (error: Error | null, accept: boolean) => void,
) {
  if (ALLOWED.includes(file.mimetype)) cb(null, true);
  else
    cb(new BadRequestException('Image must be JPEG, PNG, WebP or GIF'), false);
}
