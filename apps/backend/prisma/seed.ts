import { PrismaClient, RoleName } from '@prisma/client';
import * as argon2 from 'argon2';

const prisma = new PrismaClient();

// All permission keys grouped by domain.
const PERMISSIONS: { key: string; description: string }[] = [
  { key: 'product.create', description: 'Create products' },
  { key: 'product.update', description: 'Edit products' },
  { key: 'product.delete', description: 'Delete products' },
  { key: 'product.image.manage', description: 'Manage product images' },
  { key: 'category.manage', description: 'Manage categories' },
  { key: 'inventory.manage', description: 'Manage inventory' },
  { key: 'order.review', description: 'Review orders' },
  { key: 'order.approve', description: 'Approve orders' },
  { key: 'order.reject', description: 'Reject orders' },
  { key: 'order.request_confirmation', description: 'Request partial confirmation' },
  { key: 'employee.manage', description: 'Manage employees' },
  { key: 'customer.manage', description: 'Manage customers' },
  { key: 'report.view', description: 'View / export reports' },
  { key: 'settings.manage', description: 'Manage system & delivery settings' },
  { key: 'delivery.manage', description: 'Manage delivery zones' },
  { key: 'activity_log.view', description: 'View audit logs' },
  { key: 'notification.send', description: 'Send notifications' },
];

const EMPLOYEE_PERMISSIONS = [
  'product.create',
  'product.update',
  'product.delete',
  'product.image.manage',
  'category.manage',
  'inventory.manage',
  'order.review',
  'order.approve',
  'order.reject',
  'order.request_confirmation',
];

// 18 store categories (slug, ar, en, icon emoji).
const CATEGORIES: { nameAr: string; nameEn: string; slug: string; icon: string }[] = [
  { nameAr: 'معلبات', nameEn: 'Canned Goods', slug: 'canned-goods', icon: '🥫' },
  { nameAr: 'حلويات', nameEn: 'Sweets', slug: 'sweets', icon: '🍬' },
  { nameAr: 'شيبس', nameEn: 'Chips', slug: 'chips', icon: '🍟' },
  { nameAr: 'شوكولاتة', nameEn: 'Chocolate', slug: 'chocolate', icon: '🍫' },
  { nameAr: 'أسر منتجة', nameEn: 'Home Producers', slug: 'home-producers', icon: '🧺' },
  { nameAr: 'عطارة وتوابل', nameEn: 'Spices & Herbs', slug: 'spices-herbs', icon: '🌿' },
  { nameAr: 'شاهي', nameEn: 'Tea', slug: 'tea', icon: '🍵' },
  { nameAr: 'مشروبات غازية', nameEn: 'Soft Drinks', slug: 'soft-drinks', icon: '🥤' },
  { nameAr: 'تمر', nameEn: 'Dates', slug: 'dates', icon: '🌰' },
  { nameAr: 'ألبان وبيض', nameEn: 'Dairy & Eggs', slug: 'dairy-eggs', icon: '🥛' },
  { nameAr: 'نودلز', nameEn: 'Noodles', slug: 'noodles', icon: '🍜' },
  { nameAr: 'منتجات عضوية', nameEn: 'Organic', slug: 'organic', icon: '🥬' },
  { nameAr: 'الخبز والمخبوزات', nameEn: 'Bakery', slug: 'bakery', icon: '🍞' },
  { nameAr: 'المجمدات', nameEn: 'Frozen', slug: 'frozen', icon: '🧊' },
  { nameAr: 'الآيس كريم', nameEn: 'Ice Cream', slug: 'ice-cream', icon: '🍦' },
  { nameAr: 'البلاستيك والمنظفات', nameEn: 'Plastics & Cleaning', slug: 'plastics-cleaning', icon: '🧴' },
  { nameAr: 'الرز والحبوب', nameEn: 'Rice & Grains', slug: 'rice-grains', icon: '🌾' },
  { nameAr: 'الدجاج المبرد', nameEn: 'Chilled Chicken', slug: 'chilled-chicken', icon: '🍗' },
];

async function main() {
  console.log('🌱 Seeding ALDIAFAH database...');

  // 1) Permissions
  for (const p of PERMISSIONS) {
    await prisma.permission.upsert({
      where: { key: p.key },
      update: { description: p.description },
      create: p,
    });
  }
  const allPermissions = await prisma.permission.findMany();

  // 2) Roles
  const adminRole = await prisma.role.upsert({
    where: { name: RoleName.ADMIN },
    update: {},
    create: { name: RoleName.ADMIN, description: 'Full system access' },
  });
  const employeeRole = await prisma.role.upsert({
    where: { name: RoleName.EMPLOYEE },
    update: {},
    create: { name: RoleName.EMPLOYEE, description: 'Operations staff' },
  });
  const customerRole = await prisma.role.upsert({
    where: { name: RoleName.CUSTOMER },
    update: {},
    create: { name: RoleName.CUSTOMER, description: 'End customer' },
  });

  // 3) Role -> Permission assignments
  // Admin: every permission.
  for (const perm of allPermissions) {
    await prisma.rolePermission.upsert({
      where: { roleId_permissionId: { roleId: adminRole.id, permissionId: perm.id } },
      update: {},
      create: { roleId: adminRole.id, permissionId: perm.id },
    });
  }
  // Employee: scoped permissions.
  for (const perm of allPermissions.filter((p) => EMPLOYEE_PERMISSIONS.includes(p.key))) {
    await prisma.rolePermission.upsert({
      where: { roleId_permissionId: { roleId: employeeRole.id, permissionId: perm.id } },
      update: {},
      create: { roleId: employeeRole.id, permissionId: perm.id },
    });
  }
  // Customer: no admin permissions.

  // 4) Default admin user
  const adminEmail = process.env.SEED_ADMIN_EMAIL ?? 'admin@aldiafah.com';
  const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? 'ChangeMe!2026';
  const adminPhone = process.env.SEED_ADMIN_PHONE ?? '+966500000000';
  const passwordHash = await argon2.hash(adminPassword);

  await prisma.user.upsert({
    where: { email: adminEmail },
    update: {},
    create: {
      email: adminEmail,
      phone: adminPhone,
      passwordHash,
      fullName: 'ALDIAFAH Admin',
      roleId: adminRole.id,
      isEmailVerified: true,
      isPhoneVerified: true,
    },
  });

  // 5) Categories
  for (let i = 0; i < CATEGORIES.length; i++) {
    const c = CATEGORIES[i];
    await prisma.category.upsert({
      where: { slug: c.slug },
      update: { nameAr: c.nameAr, nameEn: c.nameEn, icon: c.icon, sortOrder: i },
      create: { ...c, sortOrder: i },
    });
  }

  // 6) Store settings (singleton)
  await prisma.settings.upsert({
    where: { id: 'singleton' },
    update: {},
    create: { id: 'singleton' },
  });

  // 7) Default delivery zones (radius-based)
  const zones = [
    { name: 'Free zone', minRadiusM: 0, maxRadiusM: 3000, fee: 0 },
    { name: 'Near zone', minRadiusM: 3000, maxRadiusM: 8000, fee: 15 },
    { name: 'Far zone', minRadiusM: 8000, maxRadiusM: 15000, fee: 25 },
  ];
  for (const z of zones) {
    const exists = await prisma.deliveryZone.findFirst({ where: { name: z.name } });
    if (!exists) await prisma.deliveryZone.create({ data: z });
  }

  console.log('✅ Seed complete.');
  console.log(`   Admin login: ${adminEmail} / (password from SEED_ADMIN_PASSWORD)`);
  console.log(`   Categories: ${CATEGORIES.length}, Permissions: ${PERMISSIONS.length}`);
}

main()
  .catch((e) => {
    console.error('❌ Seed failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
