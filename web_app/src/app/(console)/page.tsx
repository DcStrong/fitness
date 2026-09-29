'use client';

import Link from 'next/link';
import { useAuth } from '../../lib/auth/AuthProvider';

export default function DashboardPage() {
  const { user } = useAuth();
  return (
    <div className="stack">
      <h1>Обзор</h1>
      <p className="muted">
        Здравствуйте, {user?.email}. Это web-консоль тренера — тот же API, что и
        в мобильном приложении.
      </p>
      <div className="row">
        <Link className="btn" href="/students">
          Ученики
        </Link>
        <Link className="btnSecondary" href="/slots">
          Слоты
        </Link>
        <Link className="btnSecondary" href="/sessions">
          Занятия
        </Link>
        <Link className="btnSecondary" href="/plans">
          Планы
        </Link>
      </div>
    </div>
  );
}
