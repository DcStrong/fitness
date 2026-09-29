'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import Link from 'next/link';
import { useState } from 'react';
import { api } from '../../../lib/api/api';
import type { PaymentMethod, SessionFinance } from '../../../lib/api/types';
import { formatMoney } from '../../../lib/finance/money';

const STATUS_RU: Record<string, string> = {
  booked: 'Запланирована',
  completed: 'Проведена',
  cancelled: 'Отменена',
  no_show: 'Неявка',
};

const PAYMENT_METHODS: Record<PaymentMethod, string> = {
  cash: 'Наличные',
  transfer: 'Перевод',
  card: 'Карта',
  other: 'Другое',
};

function financeDescription(finance: SessionFinance): string {
  if (finance.status === 'not_tracked') {
    return 'Финансы: legacy-занятие, стоимость не отслеживается';
  }
  const amount = formatMoney(finance.amountMinor, finance.currency);
  if (finance.status === 'paid') {
    return `${amount} · оплачено${
      finance.paymentMethod ? ` (${PAYMENT_METHODS[finance.paymentMethod]})` : ''
    }`;
  }
  if (finance.status === 'cancelled') return `${amount} · не начисляется`;
  return finance.earnedAt
    ? `${amount} · ожидается оплата`
    : `${amount} · будет начислено после занятия`;
}

export default function SessionsPage() {
  const qc = useQueryClient();
  const [noShowId, setNoShowId] = useState<string | null>(null);
  const [paymentMethods, setPaymentMethods] = useState<
    Record<string, PaymentMethod>
  >({});
  const { data, isLoading, error } = useQuery({
    queryKey: ['sessions'],
    queryFn: () => api.listSessions(),
  });

  const complete = useMutation({
    mutationFn: (id: string) => api.completeSession(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['sessions'] }),
  });
  const cancel = useMutation({
    mutationFn: (id: string) => api.cancelSession(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['sessions'] }),
  });
  const noShow = useMutation({
    mutationFn: ({ id, charge }: { id: string; charge: boolean }) =>
      api.noShowSession(id, charge),
    onSuccess: () => {
      setNoShowId(null);
      void qc.invalidateQueries({ queryKey: ['sessions'] });
      void qc.invalidateQueries({ queryKey: ['finance'] });
    },
  });
  const markPaid = useMutation({
    mutationFn: ({
      chargeId,
      paymentMethod,
    }: {
      chargeId: string;
      paymentMethod: PaymentMethod;
    }) => api.markChargePaid(chargeId, { paymentMethod }),
    onSuccess: () => {
      void qc.invalidateQueries({ queryKey: ['sessions'] });
      void qc.invalidateQueries({ queryKey: ['finance'] });
    },
  });

  const busy =
    complete.isPending ||
    cancel.isPending ||
    noShow.isPending ||
    markPaid.isPending;
  const mutationError =
    complete.error || cancel.error || noShow.error || markPaid.error;

  return (
    <div className="stack">
      <h1>Занятия</h1>
      {isLoading ? <p>Загрузка…</p> : null}
      {error ? <p className="error">{(error as Error).message}</p> : null}
      {mutationError ? (
        <p className="error">{(mutationError as Error).message}</p>
      ) : null}
      {(data ?? []).map((s) => {
        const payableFinance =
          s.finance.status === 'pending' && s.finance.earnedAt
            ? s.finance
            : null;
        return (
        <div key={s.id} className="card stack">
          <strong>
            {new Date(s.startsAt).toLocaleString()} —{' '}
            {new Date(s.endsAt).toLocaleTimeString()}
          </strong>
          <div className="muted">
            {STATUS_RU[s.status] ?? s.status} ·{' '}
            {s.studentEmail ?? s.coachEmail ?? ''}
          </div>
          <div className="chip">{financeDescription(s.finance)}</div>
          <div className="row">
            {s.status === 'booked' ? (
              <>
                <button
                  type="button"
                  className="btn"
                  disabled={busy}
                  onClick={() => complete.mutate(s.id)}
                >
                  Провести
                </button>
                <button
                  type="button"
                  className="btnSecondary"
                  disabled={busy}
                  onClick={() => setNoShowId(s.id)}
                >
                  Неявка
                </button>
                <button
                  type="button"
                  className="btnSecondary"
                  disabled={busy}
                  onClick={() => cancel.mutate(s.id)}
                >
                  Отменить
                </button>
              </>
            ) : null}
            {payableFinance ? (
              <>
                <select
                  className="select"
                  style={{ width: 'auto' }}
                  value={paymentMethods[payableFinance.chargeId] ?? 'transfer'}
                  onChange={(event) =>
                    setPaymentMethods((current) => ({
                      ...current,
                      [payableFinance.chargeId]:
                        event.target.value as PaymentMethod,
                    }))
                  }
                  aria-label="Способ оплаты"
                >
                  {Object.entries(PAYMENT_METHODS).map(([value, label]) => (
                    <option key={value} value={value}>
                      {label}
                    </option>
                  ))}
                </select>
                <button
                  type="button"
                  className="btn"
                  disabled={busy}
                  onClick={() =>
                    markPaid.mutate({
                      chargeId: payableFinance.chargeId,
                      paymentMethod:
                        paymentMethods[payableFinance.chargeId] ?? 'transfer',
                    })
                  }
                >
                  Отметить оплаченным
                </button>
              </>
            ) : null}
            <Link className="btnSecondary" href={`/sessions/${s.id}/history`}>
              История
            </Link>
          </div>
          {noShowId === s.id ? (
            <div className="card stack" role="group" aria-label="Решение по неявке">
              <strong>Списать стоимость за неявку?</strong>
              <p className="muted">
                Выберите, станет ли занятие долгом ученика.
              </p>
              <div className="row">
                <button
                  type="button"
                  className="btn"
                  disabled={busy}
                  onClick={() => noShow.mutate({ id: s.id, charge: true })}
                >
                  Да, начислить
                </button>
                <button
                  type="button"
                  className="btnSecondary"
                  disabled={busy}
                  onClick={() => noShow.mutate({ id: s.id, charge: false })}
                >
                  Нет, не начислять
                </button>
                <button
                  type="button"
                  className="btnSecondary"
                  disabled={busy}
                  onClick={() => setNoShowId(null)}
                >
                  Отмена
                </button>
              </div>
            </div>
          ) : null}
        </div>
        );
      })}
    </div>
  );
}
