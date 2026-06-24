import {
  Body,
  Controller,
  Delete,
  Param,
  Patch,
  Post,
  UploadedFiles,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { IsArray, IsString } from 'class-validator';
import { RoleName } from '@prisma/client';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { ProductImagesService } from './product-images.service';

class ReorderDto {
  @IsArray()
  @IsString({ each: true })
  orderedIds!: string[];
}

@ApiTags('Product Images')
@ApiBearerAuth()
@Controller('products/:productId/images')
@Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
@RequirePermissions('product.image.manage')
@UseGuards(RolesGuard, PermissionsGuard)
export class ProductImagesController {
  constructor(private readonly service: ProductImagesService) {}

  @Post()
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: { files: { type: 'array', items: { type: 'string', format: 'binary' } } },
    },
  })
  @UseInterceptors(FilesInterceptor('files', 10))
  upload(@Param('productId') productId: string, @UploadedFiles() files: Express.Multer.File[]) {
    return this.service.upload(productId, files);
  }

  @Patch(':imageId/main')
  setMain(@Param('productId') productId: string, @Param('imageId') imageId: string) {
    return this.service.setMain(productId, imageId);
  }

  @Patch('reorder')
  reorder(@Param('productId') productId: string, @Body() dto: ReorderDto) {
    return this.service.reorder(productId, dto.orderedIds);
  }

  @Delete(':imageId')
  remove(@Param('productId') productId: string, @Param('imageId') imageId: string) {
    return this.service.remove(productId, imageId);
  }
}
