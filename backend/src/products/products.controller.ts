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
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { ProductsService } from './products.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { AdminGuard } from '../auth/guards';
import {
  imageFileFilter,
  MAX_IMAGE_BYTES,
} from '../cloudinary/image-file.filter';

const imageUpload = FileInterceptor('image', {
  storage: memoryStorage(),
  limits: { fileSize: MAX_IMAGE_BYTES },
  fileFilter: imageFileFilter,
});

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
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.productsService.create(dto, file);
  }

  @UseGuards(AdminGuard)
  @Patch(':id')
  @UseInterceptors(imageUpload)
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body() dto: UpdateProductDto,
    @UploadedFile() file?: Express.Multer.File,
  ) {
    return this.productsService.update(id, dto, file);
  }

  @UseGuards(AdminGuard)
  @Delete(':id')
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.productsService.remove(id);
  }
}
