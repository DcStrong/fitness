import {
  buildLogsFromPayload,
  buildLogsFromPrescription,
} from './session-set-log.builder';

describe('Сборка логов подходов', () => {
  it('пишет явные логи с порядком внутри упражнения', () => {
    const rows = buildLogsFromPayload('session-1', [
      {
        exerciseId: 'ex-1',
        sets: [
          { reps: 10, weightKg: 40 },
          { reps: 8, weightKg: 42.5 },
        ],
      },
    ]);

    expect(rows).toEqual([
      {
        sessionId: 'session-1',
        exerciseId: 'ex-1',
        sortOrder: 0,
        reps: 10,
        weightKg: '40.00',
        durationSeconds: null,
      },
      {
        sessionId: 'session-1',
        exerciseId: 'ex-1',
        sortOrder: 1,
        reps: 8,
        weightKg: '42.50',
        durationSeconds: null,
      },
    ]);
  });

  it('копирует prescription плана', () => {
    const rows = buildLogsFromPrescription('session-1', [
      {
        exerciseId: 'ex-1',
        sets: [{ reps: 12, weightKg: '30.00', durationSeconds: null }],
      },
    ]);

    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      exerciseId: 'ex-1',
      reps: 12,
      weightKg: '30.00',
    });
  });

  it('без упражнений даёт пустой список', () => {
    expect(buildLogsFromPrescription('session-1', [])).toEqual([]);
  });
});
