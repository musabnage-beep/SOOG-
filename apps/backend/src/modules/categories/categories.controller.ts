import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ApiBearerAuth, ApiBody, ApiConsumes, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { Public } from '@/common/decorators/public.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto, UpdateCategoryDto } from './dto/category.dto';

@ApiTags('Categories')
@Controller('categories')
export class CategoriesController {
  constructor(private readonly service: CategoriesService) {}

  @Public()
  @Get()
  findAll(@Query('includeInactive') includeInactive?: string) {
    return this.service.findAll(includeInactive === 'true');
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('category.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Post()
  create(@Body() dto: CreateCategoryDto) {
    return this.service.create(dto);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('category.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateCategoryDto) {
    return this.service.update(id, dto);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('category.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('category.manage')
  @UseGuards(RolesGuard, PermissionsGuard)
  @ApiConsumes('multipart/form-data')
  @ApiBody({ schema: { type: 'object', properties: { file: { type: 'string', format: 'binary' } } } })
  @Post(':id/image')
  @UseInterceptors(FileInterceptor('file'))
  uploadIcon(@Param('id') id: string, @UploadedFile() file: Express.Multer.File) {
    return this.service.uploadIcon(id, file);
  }
}
