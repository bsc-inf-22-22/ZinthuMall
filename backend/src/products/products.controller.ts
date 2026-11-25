import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileFieldsInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ProductImageFiles, ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { AdminGuard } from '../auth/guards';
import {
  imageFileFilter,
  MAX_IMAGE_BYTES,
  MAX_PRODUCT_IMAGES,
} from '../cloudinary/image-file.filter';

/**
 * "images": one or more photos (the admin app sends this).
 * "image": a single photo, as older app versions send it.
 */
const imageUpload = FileFieldsInterceptor(
  [
    { name: 'images', maxCount: MAX_PRODUCT_IMAGES },
    { name: 'image', maxCount: 1 },
  ],
  {
    storage: memoryStorage(),
    limits: { fileSize: MAX_IMAGE_BYTES },
    fileFilter: imageFileFilter,
  },
);

@Controller('products')
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  findAll() {
    return this.productsService.findAll();
  }

  @Get('search')
  search(@Query('q') q = '') {
    return this.productsService.search(q);
  }

  @Get('category/:category')
  findByCategory(@Param('category') category: string) {
    return this.productsService.findByCategory(category);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.productsService.findOne(id);
  }

  @UseGuards(AdminGuard)
  @Post()
  @UseInterceptors(imageUpload)
  create(
    @Body() dto: CreateProductDto,
    @UploadedFiles() files?: ProductImageFiles,
  ) {
    return this.productsService.create(dto, files);
  }

  @UseGuards(AdminGuard)
  @Patch(':id')
  @UseInterceptors(imageUpload)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateProductDto,
    @UploadedFiles() files?: ProductImageFiles,
  ) {
    return this.productsService.update(id, dto, files);
  }

  @UseGuards(AdminGuard)
  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.productsService.remove(id);
  }
}
