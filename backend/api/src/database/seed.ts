import 'reflect-metadata';
import { config } from 'dotenv';
import { join } from 'path';
import * as bcrypt from 'bcrypt';
import dataSource from './data-source';
import { PermissionEntity } from './entity/permission.entity';
import { RoleEntity } from './entity/role.entity';
import { UserEntity } from './entity/user.entity';
import { seedCatalogWorkouts } from './catalog-workout-seed';

config({ path: join(__dirname, '..', '..', '.env') });
config({ path: join(__dirname, '..', '..', '..', '.env') });

const PERMISSIONS = [
  { code: 'users:read_self', description: 'Read own profile' },
  { code: 'admin:access', description: 'Access admin-only areas' },
  { code: 'invitations:create', description: 'Create coach invitations' },
  { code: 'invitations:read_own', description: 'List own invitations' },
  { code: 'invitations:revoke', description: 'Revoke own invitations' },
  { code: 'invitations:accept', description: 'Accept coach invitations' },
  {
    code: 'relationships:read_own',
    description: 'Read own coach-student relationships',
  },
  { code: 'schedules:create', description: 'Create own availability slots' },
  { code: 'schedules:read_own', description: 'List own availability slots' },
  { code: 'schedules:delete_own', description: 'Delete own open slots' },
  {
    code: 'schedules:read_linked',
    description: 'List open slots of a linked coach',
  },
  { code: 'sessions:book_self', description: 'Legacy student booking permission' },
  {
    code: 'sessions:book_for_student',
    description: 'Book own slot for a linked student',
  },
  { code: 'sessions:read_own', description: 'List own sessions' },
  { code: 'sessions:complete', description: 'Mark own coached session completed' },
  { code: 'sessions:cancel', description: 'Cancel own booked session' },
  {
    code: 'sessions:mark_no_show',
    description: 'Mark own coached session as no_show',
  },
  {
    code: 'sessions:read_history',
    description: 'Read history of own sessions',
  },
  { code: 'booking_requests:create', description: 'Create booking requests' },
  { code: 'booking_requests:read_own', description: 'Read and withdraw own booking requests' },
  { code: 'booking_requests:read_inbox', description: 'Read trainer booking request inbox' },
  { code: 'booking_requests:respond', description: 'Respond to owned booking requests' },
  { code: 'tags:create', description: 'Create own tags' },
  { code: 'tags:read_own', description: 'Read own or assigned tags' },
  { code: 'tags:delete_own', description: 'Delete own tags' },
  { code: 'tags:assign', description: 'Assign own tags to linked students' },
  { code: 'plans:create', description: 'Create own training plans' },
  { code: 'plans:read_own', description: 'List own training plans' },
  {
    code: 'plans:read_visible',
    description: 'List training plans visible via shared tags',
  },
  { code: 'plans:update_own', description: 'Update own training plans' },
  { code: 'plans:delete_own', description: 'Delete own training plans' },
  { code: 'exercises:manage_own', description: 'Create, update, and delete own exercises' },
  { code: 'exercises:read_own', description: 'Read own and catalog exercises' },
  {
    code: 'exercises:read_visible',
    description: 'Read exercises visible via shared tags or explicit assignment',
  },
  {
    code: 'finance:manage_settings',
    description: 'Manage own finance settings',
  },
  { code: 'finance:read_own', description: 'Read own finance ledger and stats' },
  { code: 'finance:mark_paid', description: 'Mark own session charges paid' },
  {
    code: 'finance:record_expense',
    description: 'Record own finance expenses',
  },
  { code: 'finance:adjust_own', description: 'Reverse own ledger entries' },
  {
    code: 'finance:read_own_charge',
    description: 'Read finance state of own sessions',
  },
  {
    code: 'packages:manage',
    description: 'Create, extend, and archive session packages for linked students',
  },
  {
    code: 'packages:read_own',
    description: 'Read own session packages as coach or student',
  },
  { code: 'profiles:read_public', description: 'Read public trainer profiles' },
  { code: 'profiles:update_own', description: 'Update own social profile' },
  {
    code: 'profiles:manage_privacy',
    description: 'Manage own social privacy',
  },
  {
    code: 'profiles:read_linked_contacts',
    description: 'Read contacts of an actively linked user',
  },
  { code: 'portfolio:manage_own', description: 'Manage own trainer portfolio' },
  { code: 'reviews:read', description: 'Read social reviews' },
  { code: 'reviews:create_own', description: 'Create own session review' },
  { code: 'reviews:update_own', description: 'Update own session review' },
] as const;

const ROLE_PERMISSIONS: Record<string, string[]> = {
  trainer: [
    'users:read_self',
    'invitations:create',
    'invitations:read_own',
    'invitations:revoke',
    'relationships:read_own',
    'schedules:create',
    'schedules:read_own',
    'schedules:delete_own',
    'sessions:book_for_student',
    'sessions:read_own',
    'sessions:complete',
    'sessions:cancel',
    'sessions:mark_no_show',
    'sessions:read_history',
    'booking_requests:read_inbox',
    'booking_requests:respond',
    'tags:create',
    'tags:read_own',
    'tags:delete_own',
    'tags:assign',
    'plans:create',
    'plans:read_own',
    'plans:update_own',
    'plans:delete_own',
    'exercises:manage_own',
    'exercises:read_own',
    'finance:manage_settings',
    'finance:read_own',
    'finance:mark_paid',
    'finance:record_expense',
    'finance:adjust_own',
    'finance:read_own_charge',
    'packages:manage',
    'packages:read_own',
    'profiles:read_public',
    'profiles:update_own',
    'profiles:manage_privacy',
    'profiles:read_linked_contacts',
    'portfolio:manage_own',
    'reviews:read',
  ],
  student: [
    'users:read_self',
    'invitations:accept',
    'relationships:read_own',
    'schedules:read_linked',
    'booking_requests:create',
    'booking_requests:read_own',
    'sessions:read_own',
    'sessions:cancel',
    'sessions:read_history',
    'tags:read_own',
    'plans:read_visible',
    'exercises:read_own',
    'exercises:read_visible',
    'finance:read_own_charge',
    'packages:read_own',
    'profiles:read_public',
    'profiles:update_own',
    'profiles:manage_privacy',
    'profiles:read_linked_contacts',
    'reviews:read',
    'reviews:create_own',
    'reviews:update_own',
  ],
  admin: [
    'users:read_self',
    'admin:access',
    'invitations:create',
    'invitations:read_own',
    'invitations:revoke',
    'invitations:accept',
    'relationships:read_own',
    'schedules:create',
    'schedules:read_own',
    'schedules:delete_own',
    'schedules:read_linked',
    'sessions:book_self',
    'sessions:book_for_student',
    'sessions:read_own',
    'sessions:complete',
    'sessions:cancel',
    'sessions:mark_no_show',
    'sessions:read_history',
    'booking_requests:create',
    'booking_requests:read_own',
    'booking_requests:read_inbox',
    'booking_requests:respond',
    'tags:create',
    'tags:read_own',
    'tags:delete_own',
    'tags:assign',
    'plans:create',
    'plans:read_own',
    'plans:read_visible',
    'plans:update_own',
    'plans:delete_own',
    'exercises:manage_own',
    'exercises:read_own',
    'finance:manage_settings',
    'finance:read_own',
    'finance:mark_paid',
    'finance:record_expense',
    'finance:adjust_own',
    'finance:read_own_charge',
    'packages:manage',
    'packages:read_own',
    'profiles:read_public',
    'profiles:update_own',
    'profiles:manage_privacy',
    'profiles:read_linked_contacts',
    'portfolio:manage_own',
    'reviews:read',
    'reviews:create_own',
    'reviews:update_own',
  ],
};

/**
 *
 */
async function main() {
  await dataSource.initialize();

  const permissionRepo = dataSource.getRepository(PermissionEntity);
  const roleRepo = dataSource.getRepository(RoleEntity);
  const userRepo = dataSource.getRepository(UserEntity);

  for (const permission of PERMISSIONS) {
    const existing = await permissionRepo.findOne({
      where: { code: permission.code },
    });
    if (existing) {
      existing.description = permission.description;
      await permissionRepo.save(existing);
    } else {
      await permissionRepo.save(permissionRepo.create(permission));
    }
  }

  const roleDefs = [
    { slug: 'trainer', name: 'Trainer' },
    { slug: 'student', name: 'Student' },
    { slug: 'admin', name: 'Admin' },
  ];

  for (const roleDef of roleDefs) {
    let role = await roleRepo.findOne({
      where: { slug: roleDef.slug },
      relations: { permissions: true },
    });
    if (!role) {
      role = roleRepo.create(roleDef);
    } else {
      role.name = roleDef.name;
    }

    const codes = ROLE_PERMISSIONS[roleDef.slug] ?? [];
    const permissions = [];
    for (const code of codes) {
      const permission = await permissionRepo.findOneOrFail({
        where: { code },
      });
      permissions.push(permission);
    }
    role.permissions = permissions;
    await roleRepo.save(role);
  }

  const adminEmail = process.env['ADMIN_EMAIL']?.toLowerCase().trim();
  const adminPassword = process.env['ADMIN_PASSWORD'];
  if (adminEmail && adminPassword) {
    const adminRole = await roleRepo.findOneOrFail({
      where: { slug: 'admin' },
    });
    const passwordHash = await bcrypt.hash(adminPassword, 10);
    let user = await userRepo.findOne({
      where: { email: adminEmail },
      relations: { roles: true },
    });
    if (!user) {
      user = userRepo.create({
        email: adminEmail,
        passwordHash,
        roles: [adminRole],
      });
    } else {
      user.passwordHash = passwordHash;
      const hasAdmin = (user.roles ?? []).some(r => r.slug === 'admin');
      if (!hasAdmin) {
        user.roles = [...user.roles ?? [], adminRole];
      }
    }
    await userRepo.save(user);
    console.log(`Admin user ready: ${adminEmail}`);
  }

  await seedCatalogWorkouts(dataSource);
  console.log('Catalog workout templates ready');

  console.log('Seed completed');
  await dataSource.destroy();
}

main().catch(async error => {
  console.error(error);
  if (dataSource.isInitialized) {
    await dataSource.destroy();
  }
  process.exit(1);
});
