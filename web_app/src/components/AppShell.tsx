'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { useAuth } from '../lib/auth/AuthProvider';
import styles from './AppShell.module.css';

const NAV = [
  { href: '/', label: 'Обзор' },
  { href: '/students', label: 'Ученики' },
  { href: '/slots', label: 'Слоты' },
  { href: '/sessions', label: 'Занятия' },
  { href: '/finance', label: 'Финансы' },
  { href: '/tags', label: 'Теги' },
  { href: '/plans', label: 'Планы' },
  { href: '/invites', label: 'Приглашения' },
  { href: '/profile', label: 'Публичный профиль' },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const { user, loading, isTrainer, logout } = useAuth();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (loading) return;
    if (!user) {
      router.replace('/login');
      return;
    }
    if (!isTrainer) {
      /* stay — page shows denial */
    }
  }, [loading, user, isTrainer, router]);

  if (loading) {
    return <div className={styles.center}>Загрузка…</div>;
  }

  if (!user) {
    return <div className={styles.center}>Перенаправление…</div>;
  }

  if (!isTrainer) {
    return (
      <div className={styles.center}>
        <h1>Консоль только для тренеров</h1>
        <p>Войдите аккаунтом тренера. Сейчас: {user.email}</p>
        <button
          type="button"
          className={styles.button}
          onClick={async () => {
            await logout();
            router.replace('/login');
          }}
        >
          Выйти
        </button>
      </div>
    );
  }

  return (
    <div className={styles.layout}>
      <aside className={styles.sidebar}>
        <div className={styles.brand}>Fitness Yoda</div>
        <nav className={styles.nav}>
          {NAV.map((item) => (
            <Link
              key={item.href}
              href={item.href}
              className={
                pathname === item.href ? styles.navActive : styles.navLink
              }
            >
              {item.label}
            </Link>
          ))}
        </nav>
        <div className={styles.footer}>
          <div className={styles.email}>{user.email}</div>
          <button
            type="button"
            className={styles.buttonGhost}
            onClick={async () => {
              await logout();
              router.replace('/login');
            }}
          >
            Выйти
          </button>
        </div>
      </aside>
      <main className={styles.main}>{children}</main>
    </div>
  );
}
