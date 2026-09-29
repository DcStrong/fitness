'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { api } from '../../../lib/api/api';
import type {
  LedgerType,
  PaymentMethod,
} from '../../../lib/api/types';
import {
  formatMoney,
  minorToRubles,
  rublesToMinor,
} from '../../../lib/finance/money';
import styles from './finance.module.css';

const LEDGER_TYPES: Record<LedgerType, string> = {
  income: 'Доход',
  expense: 'Расход',
  adjustment: 'Корректировка',
};

const PAYMENT_METHODS: Record<PaymentMethod, string> = {
  cash: 'Наличные',
  transfer: 'Перевод',
  card: 'Карта',
  other: 'Другое',
};

type Period = {
  from: string;
  to: string;
  label: string;
};

function monthPeriod(offset = 0): Period {
  const now = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() + offset, 1);
  const to = new Date(now.getFullYear(), now.getMonth() + offset + 1, 1);
  return {
    from: from.toISOString(),
    to: to.toISOString(),
    label: offset === 0 ? 'Текущий месяц' : 'Прошлый месяц',
  };
}

function dateInputValue(iso: string): string {
  const date = new Date(iso);
  const local = new Date(date.getTime() - date.getTimezoneOffset() * 60_000);
  return local.toISOString().slice(0, 10);
}

function customPeriod(fromValue: string, toValue: string): Period | null {
  const from = new Date(`${fromValue}T00:00:00`);
  const to = new Date(`${toValue}T00:00:00`);
  to.setDate(to.getDate() + 1);
  if (
    !fromValue ||
    !toValue ||
    Number.isNaN(from.getTime()) ||
    Number.isNaN(to.getTime()) ||
    to <= from
  ) {
    return null;
  }
  return { from: from.toISOString(), to: to.toISOString(), label: 'Свой период' };
}

function refreshFinance(qc: ReturnType<typeof useQueryClient>) {
  return Promise.all([
    qc.invalidateQueries({ queryKey: ['finance'] }),
    qc.invalidateQueries({ queryKey: ['sessions'] }),
  ]);
}

export default function FinancePage() {
  const qc = useQueryClient();
  const defaultPeriod = useMemo(() => monthPeriod(), []);
  const [period, setPeriod] = useState<Period>(defaultPeriod);
  const [customFrom, setCustomFrom] = useState(
    dateInputValue(defaultPeriod.from),
  );
  const [customTo, setCustomTo] = useState(
    dateInputValue(new Date(Date.now()).toISOString()),
  );
  const [ledgerType, setLedgerType] = useState<LedgerType | ''>('');
  const [studentId, setStudentId] = useState('');
  const [settingsPrice, setSettingsPrice] = useState('');
  const [expenseAmount, setExpenseAmount] = useState('');
  const [expenseCategory, setExpenseCategory] = useState('');
  const [expenseNote, setExpenseNote] = useState('');
  const [paymentMethods, setPaymentMethods] = useState<
    Record<string, PaymentMethod>
  >({});
  const [formError, setFormError] = useState<string | null>(null);

  const summary = useQuery({
    queryKey: ['finance', 'summary', period.from, period.to],
    queryFn: () => api.financeSummary(period.from, period.to),
  });
  const ledger = useQuery({
    queryKey: [
      'finance',
      'ledger',
      period.from,
      period.to,
      ledgerType,
      studentId,
    ],
    queryFn: () =>
      api.financeLedger(
        period.from,
        period.to,
        ledgerType || undefined,
        studentId || undefined,
      ),
  });
  const debts = useQuery({
    queryKey: ['finance', 'debts', studentId],
    queryFn: () => api.financeDebts(studentId || undefined),
  });
  const settings = useQuery({
    queryKey: ['finance', 'settings'],
    queryFn: () => api.financeSettings(),
    retry: false,
  });
  const relationships = useQuery({
    queryKey: ['relationships'],
    queryFn: () => api.relationships(),
  });

  useEffect(() => {
    if (settings.data) {
      setSettingsPrice(minorToRubles(settings.data.defaultSessionPriceMinor));
    }
  }, [settings.data]);

  const saveSettings = useMutation({
    mutationFn: () => {
      const amountMinor = rublesToMinor(settingsPrice);
      if (!amountMinor || amountMinor === '0') {
        throw new Error('Укажите положительную цену с точностью до копеек');
      }
      return api.updateFinanceSettings({
        defaultSessionPriceMinor: amountMinor,
        currency: 'RUB',
      });
    },
    onSuccess: () => {
      setFormError(null);
      void refreshFinance(qc);
    },
    onError: (error: Error) => setFormError(error.message),
  });

  const addExpense = useMutation({
    mutationFn: () => {
      const amountMinor = rublesToMinor(expenseAmount);
      if (!amountMinor || amountMinor === '0') {
        throw new Error('Укажите положительную сумму расхода');
      }
      return api.createExpense({
        amountMinor,
        category: expenseCategory.trim() || undefined,
        note: expenseNote.trim() || undefined,
      });
    },
    onSuccess: () => {
      setExpenseAmount('');
      setExpenseCategory('');
      setExpenseNote('');
      setFormError(null);
      void refreshFinance(qc);
    },
    onError: (error: Error) => setFormError(error.message),
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
      setFormError(null);
      void refreshFinance(qc);
    },
    onError: (error: Error) => setFormError(error.message),
  });

  const reverse = useMutation({
    mutationFn: (id: string) => api.reverseLedgerEntry(id),
    onSuccess: () => {
      setFormError(null);
      void refreshFinance(qc);
    },
    onError: (error: Error) => setFormError(error.message),
  });

  function applyCustomPeriod(event: FormEvent) {
    event.preventDefault();
    const nextPeriod = customPeriod(customFrom, customTo);
    if (!nextPeriod) {
      setFormError('Дата окончания должна быть не раньше даты начала');
      return;
    }
    setFormError(null);
    setPeriod(nextPeriod);
  }

  const queryError =
    summary.error || ledger.error || debts.error || relationships.error;
  const summaryCards = summary.data
    ? [
        ['Начислено', summary.data.accruedMinor],
        ['Получено', summary.data.receivedMinor],
        ['Ожидается', summary.data.outstandingMinor],
        ['Расходы', summary.data.expensesMinor],
        ['Корректировки', summary.data.adjustmentsMinor],
        ['Чистый доход', summary.data.netMinor],
      ]
    : [];

  return (
    <div className="stack">
      <div>
        <h1>Финансы</h1>
        <p className="muted">
          Учёт внешних оплат и расходов. Fitness Yoda не принимает платежи.
        </p>
      </div>

      <section className="card stack">
        <h2>Период</h2>
        <div className={styles.periods}>
          {[monthPeriod(), monthPeriod(-1)].map((item) => (
            <button
              key={item.label}
              type="button"
              className={period.label === item.label ? 'btn' : 'btnSecondary'}
              onClick={() => setPeriod(item)}
            >
              {item.label}
            </button>
          ))}
          <form className={styles.customPeriod} onSubmit={applyCustomPeriod}>
            <label>
              С
              <input
                className="input"
                type="date"
                value={customFrom}
                onChange={(event) => setCustomFrom(event.target.value)}
                required
              />
            </label>
            <label>
              По
              <input
                className="input"
                type="date"
                value={customTo}
                onChange={(event) => setCustomTo(event.target.value)}
                required
              />
            </label>
            <button className="btnSecondary" type="submit">
              Применить
            </button>
          </form>
        </div>
        <span className="muted">Выбран: {period.label}</span>
      </section>

      {queryError ? (
        <p className="error">{(queryError as Error).message}</p>
      ) : null}
      {formError ? <p className="error">{formError}</p> : null}

      <section className={styles.summaryGrid} aria-label="Финансовая сводка">
        {summary.isLoading ? <p>Загрузка сводки…</p> : null}
        {summaryCards.map(([label, value]) => (
          <article className="card stack" key={label}>
            <span className="muted">{label}</span>
            <strong className={styles.money}>
              {formatMoney(value, summary.data?.currency)}
            </strong>
          </article>
        ))}
      </section>

      {summary.data ? (
        <div className="card row">
          <span className="chip">
            Проведено: {summary.data.counts.completed}
          </span>
          <span className="chip">
            Платных неявок: {summary.data.counts.noShowChargeable}
          </span>
          <span className="chip">Оплачено: {summary.data.counts.paid}</span>
          <span className="chip">
            Долгов: {summary.data.counts.outstanding}
          </span>
        </div>
      ) : null}

      <div className={styles.formsGrid}>
        <form
          className="card stack"
          onSubmit={(event) => {
            event.preventDefault();
            saveSettings.mutate();
          }}
        >
          <h2>Базовая цена занятия</h2>
          <label>
            Сумма, ₽
            <input
              className="input"
              inputMode="decimal"
              value={settingsPrice}
              onChange={(event) => setSettingsPrice(event.target.value)}
              placeholder="1500.00"
              required
            />
          </label>
          {settings.error ? (
            <p className="muted">
              Цена ещё не настроена или недоступна. Сохраните новое значение.
            </p>
          ) : null}
          <button className="btn" disabled={saveSettings.isPending} type="submit">
            Сохранить цену
          </button>
        </form>

        <form
          className="card stack"
          onSubmit={(event) => {
            event.preventDefault();
            addExpense.mutate();
          }}
        >
          <h2>Добавить расход</h2>
          <label>
            Сумма, ₽
            <input
              className="input"
              inputMode="decimal"
              value={expenseAmount}
              onChange={(event) => setExpenseAmount(event.target.value)}
              placeholder="500.00"
              required
            />
          </label>
          <input
            className="input"
            value={expenseCategory}
            onChange={(event) => setExpenseCategory(event.target.value)}
            placeholder="Категория (необязательно)"
          />
          <input
            className="input"
            value={expenseNote}
            onChange={(event) => setExpenseNote(event.target.value)}
            placeholder="Комментарий (необязательно)"
          />
          <button className="btn" disabled={addExpense.isPending} type="submit">
            Записать расход
          </button>
        </form>
      </div>

      <section className="card stack">
        <div className={styles.sectionHeader}>
          <h2>Долги</h2>
          <select
            className="select"
            value={studentId}
            onChange={(event) => setStudentId(event.target.value)}
            aria-label="Фильтр финансов по ученику"
          >
            <option value="">Все ученики (долги и журнал)</option>
            {(relationships.data ?? [])
              .filter((item) => item.roleForViewer === 'coach')
              .map((item) => (
                <option key={item.studentId} value={item.studentId}>
                  {item.studentEmail ?? item.studentId}
                </option>
              ))}
          </select>
        </div>
        {debts.isLoading ? <p>Загрузка долгов…</p> : null}
        {!debts.isLoading && !debts.data?.length ? (
          <p className="muted">Нет неоплаченных начислений.</p>
        ) : null}
        {(debts.data ?? []).map((debt) => {
          const method = paymentMethods[debt.chargeId] ?? 'transfer';
          return (
            <div className={styles.listItem} key={debt.chargeId}>
              <div>
                <strong>{formatMoney(debt.amountMinor, debt.currency)}</strong>
                <div className="muted">
                  {debt.studentEmail ?? debt.studentId} · начислено{' '}
                  {new Date(debt.earnedAt).toLocaleString('ru-RU')}
                </div>
              </div>
              <div className="row">
                <select
                  className="select"
                  value={method}
                  onChange={(event) =>
                    setPaymentMethods((current) => ({
                      ...current,
                      [debt.chargeId]: event.target.value as PaymentMethod,
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
                  className="btn"
                  type="button"
                  disabled={markPaid.isPending}
                  onClick={() =>
                    markPaid.mutate({
                      chargeId: debt.chargeId,
                      paymentMethod: method,
                    })
                  }
                >
                  Отметить оплаченным
                </button>
              </div>
            </div>
          );
        })}
      </section>

      <section className="card stack">
        <div className={styles.sectionHeader}>
          <h2>Журнал операций</h2>
          <select
            className="select"
            value={ledgerType}
            onChange={(event) =>
              setLedgerType(event.target.value as LedgerType | '')
            }
            aria-label="Тип операции"
          >
            <option value="">Все типы</option>
            {Object.entries(LEDGER_TYPES).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>
        </div>
        {ledger.isLoading ? <p>Загрузка журнала…</p> : null}
        {!ledger.isLoading && !ledger.data?.length ? (
          <p className="muted">За выбранный период операций нет.</p>
        ) : null}
        <div className={styles.ledger}>
          {(ledger.data ?? []).map((entry) => (
            <div className={styles.listItem} key={entry.id}>
              <div>
                <strong>
                  {LEDGER_TYPES[entry.type]} ·{' '}
                  {formatMoney(entry.amountMinor, entry.currency)}
                </strong>
                <div className="muted">
                  {new Date(entry.occurredAt).toLocaleString('ru-RU')}
                  {entry.category ? ` · ${entry.category}` : ''}
                  {entry.note ? ` · ${entry.note}` : ''}
                </div>
                {entry.reversesEntryId ? (
                  <span className="chip">Корректирует другую операцию</span>
                ) : null}
              </div>
              {!entry.reversesEntryId ? (
                <button
                  className="btnSecondary"
                  type="button"
                  disabled={reverse.isPending}
                  onClick={() => {
                    if (
                      window.confirm(
                        'Добавить компенсирующую корректировку? Исходная операция останется в журнале.',
                      )
                    ) {
                      reverse.mutate(entry.id);
                    }
                  }}
                >
                  Сторнировать
                </button>
              ) : null}
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
