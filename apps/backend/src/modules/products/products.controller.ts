import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { RoleName } from '@prisma/client';
import { Public } from '@/common/decorators/public.decorator';
import { Roles } from '@/common/decorators/roles.decorator';
import { RequirePermissions } from '@/common/decorators/permissions.decorator';
import { CurrentUser } from '@/common/decorators/current-user.decorator';
import { RolesGuard } from '@/common/guards/roles.guard';
import { PermissionsGuard } from '@/common/guards/permissions.guard';
import { ProductsService } from './products.service';
import { CreateProductDto, QueryProductsDto, UpdateProductDto } from './dto/product.dto';

@ApiTags('Products')
@Controller('products')
export class ProductsController {
  constructor(private readonly service: ProductsService) {}

  @Public()
  @Get()
  findAll(@Query() query: QueryProductsDto) {
    return this.service.findAll(query);
  }

  @Public()
  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.service.findOne(id);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('product.create')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Post()
  create(@Body() dto: CreateProductDto, @CurrentUser('id') actorId: string) {
    return this.service.create(dto, actorId);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('product.update')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.service.update(id, dto);
  }

  @ApiBearerAuth()
  @Roles(RoleName.ADMIN, RoleName.EMPLOYEE)
  @RequirePermissions('product.delete')
  @UseGuards(RolesGuard, PermissionsGuard)
  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.service.remove(id);
  }
}
