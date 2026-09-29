'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { FormEvent, useEffect, useMemo, useState } from 'react';
import { api } from '../../../lib/api/api';
import type {
  OwnerPortfolioItem,
  OwnerPrivacySettings,
  SaveOwnerPortfolioItem,
  TrainingMode,
  UpdateOwnerProfile,
} from '../../../lib/api/types';
import styles from './profile.module.css';

const HTTPS_URL = /^https:\/\/\S+$/i;
const MODES: { value: TrainingMode; label: string }[] = [
  { value: 'online', label: 'Онлайн' },
  { value: 'offline', label: 'Очно' },
];

type ProfileForm = {
  displayName: string;
  avatarUrl: string;
  bio: string;
  city: string;
  specialties: string;
  trainingModes: TrainingMode[];
};

type PortfolioForm = {
  id: string | null;
  title: string;
  description: string;
  imageUrl: string;
};

const EMPTY_PROFILE: ProfileForm = {
  displayName: '',
  avatarUrl: '',
  bio: '',
  city: '',
  specialties: '',
  trainingModes: [],
};

const EMPTY_PORTFOLIO: PortfolioForm = {
  id: null,
  title: '',
  description: '',
  imageUrl: '',
};

function nullable(value: string): string | null {
  return value.trim() || null;
}

function validateHttps(value: string, label: string): void {
  if (value && (value.length > 2048 || !HTTPS_URL.test(value))) {
    throw new Error(`${label}: укажите корректный HTTPS-адрес`);
  }
}

function profilePayload(form: ProfileForm): UpdateOwnerProfile {
  const displayName = form.displayName.trim();
  if (displayName.length < 2 || displayName.length > 80) {
    throw new Error('Имя должно содержать от 2 до 80 символов');
  }
  if (form.bio.length > 1000) throw new Error('Описание длиннее 1000 символов');
  if (form.city.length > 120) throw new Error('Город длиннее 120 символов');
  validateHttps(form.avatarUrl.trim(), 'Фото профиля');

  const specialties = [
    ...new Set(
      form.specialties
        .split(',')
        .map((item) => item.trim())
        .filter(Boolean),
    ),
  ];
  if (specialties.length > 10 || specialties.some((item) => item.length > 40)) {
    throw new Error('Укажите до 10 специализаций, не длиннее 40 символов');
  }
  return {
    displayName,
    avatarUrl: nullable(form.avatarUrl),
    bio: nullable(form.bio),
    city: nullable(form.city),
    specialties,
    trainingModes: form.trainingModes,
  };
}

function portfolioPayload(form: PortfolioForm): SaveOwnerPortfolioItem {
  const title = form.title.trim();
  if (!title || title.length > 120) {
    throw new Error('Название должно содержать от 1 до 120 символов');
  }
  if (form.description.length > 1000) {
    throw new Error('Описание работы длиннее 1000 символов');
  }
  validateHttps(form.imageUrl.trim(), 'Изображение');
  return {
    title,
    description: nullable(form.description),
    imageUrl: nullable(form.imageUrl),
  };
}

function SafeImage({
  src,
  alt,
  className,
}: {
  src: string | null;
  alt: string;
  className: string;
}) {
  const safeSrc = src && HTTPS_URL.test(src) ? src : null;
  const [failed, setFailed] = useState(false);

  useEffect(() => setFailed(false), [safeSrc]);

  if (!safeSrc || failed) {
    return (
      <div className={`${className} ${styles.imageFallback}`} aria-label={alt}>
        Фото недоступно
      </div>
    );
  }
  // A plain image supports arbitrary validated HTTPS portfolio URLs without
  // maintaining a remote-host allowlist or adding an upload dependency.
  // eslint-disable-next-line @next/next/no-img-element
  return <img className={className} src={safeSrc} alt={alt} onError={() => setFailed(true)} />;
}

function stars(rating: number): string {
  return `${'★'.repeat(rating)}${'☆'.repeat(5 - rating)}`;
}

export default function ProfilePage() {
  const queryClient = useQueryClient();
  const [profileForm, setProfileForm] = useState(EMPTY_PROFILE);
  const [privacy, setPrivacy] = useState<OwnerPrivacySettings | null>(null);
  const [portfolioForm, setPortfolioForm] = useState(EMPTY_PORTFOLIO);
  const [reviewPage, setReviewPage] = useState(1);
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const profile = useQuery({
    queryKey: ['owner-profile'],
    queryFn: () => api.ownerProfile(),
  });
  const reviews = useQuery({
    queryKey: ['owner-reviews', reviewPage],
    queryFn: () => api.ownerReceivedReviews(reviewPage, 10),
  });

  useEffect(() => {
    if (!profile.data) return;
    setProfileForm({
      displayName: profile.data.displayName ?? '',
      avatarUrl: profile.data.avatarUrl ?? '',
      bio: profile.data.bio ?? '',
      city: profile.data.city ?? '',
      specialties: profile.data.specialties.join(', '),
      trainingModes: profile.data.trainingModes,
    });
    setPrivacy(profile.data.privacy);
  }, [profile.data]);

  const orderedPortfolio = useMemo(
    () =>
      [...(profile.data?.portfolio ?? [])].sort(
        (left, right) => left.sortOrder - right.sortOrder,
      ),
    [profile.data?.portfolio],
  );

  function refreshProfile() {
    return queryClient.invalidateQueries({ queryKey: ['owner-profile'] });
  }

  const saveProfile = useMutation({
    mutationFn: () => api.updateOwnerProfile(profilePayload(profileForm)),
    onSuccess: () => {
      setError(null);
      setMessage('Профиль сохранён');
      void refreshProfile();
    },
    onError: (cause: Error) => {
      setMessage(null);
      setError(cause.message);
    },
  });

  const savePrivacy = useMutation({
    mutationFn: () => {
      if (!privacy) throw new Error('Настройки ещё загружаются');
      if (privacy.isDiscoverable && profileForm.displayName.trim().length < 2) {
        throw new Error('Перед публикацией укажите и сохраните имя');
      }
      return api.updateOwnerPrivacy(privacy);
    },
    onSuccess: (data) => {
      setPrivacy(data.privacy);
      setError(null);
      setMessage(data.privacy.isDiscoverable ? 'Профиль опубликован' : 'Профиль скрыт');
      void refreshProfile();
    },
    onError: (cause: Error) => {
      setMessage(null);
      setError(cause.message);
    },
  });

  const savePortfolio = useMutation({
    mutationFn: () => {
      const payload = portfolioPayload(portfolioForm);
      return portfolioForm.id
        ? api.updateOwnerPortfolioItem(portfolioForm.id, payload)
        : api.createOwnerPortfolioItem(payload);
    },
    onSuccess: () => {
      setPortfolioForm(EMPTY_PORTFOLIO);
      setError(null);
      setMessage('Работа в портфолио сохранена');
      void refreshProfile();
    },
    onError: (cause: Error) => {
      setMessage(null);
      setError(cause.message);
    },
  });

  const reorderPortfolio = useMutation({
    mutationFn: (itemIds: string[]) => api.reorderOwnerPortfolio(itemIds),
    onSuccess: () => {
      setError(null);
      setMessage('Порядок портфолио сохранён');
      void refreshProfile();
    },
    onError: (cause: Error) => {
      setMessage(null);
      setError(cause.message);
    },
  });

  const deletePortfolio = useMutation({
    mutationFn: (id: string) => api.deleteOwnerPortfolioItem(id),
    onSuccess: () => {
      setPortfolioForm(EMPTY_PORTFOLIO);
      setError(null);
      setMessage('Работа удалена');
      void refreshProfile();
    },
    onError: (cause: Error) => {
      setMessage(null);
      setError(cause.message);
    },
  });

  function movePortfolio(index: number, offset: -1 | 1) {
    const nextIndex = index + offset;
    if (nextIndex < 0 || nextIndex >= orderedPortfolio.length) return;
    const itemIds = orderedPortfolio.map((item) => item.id);
    [itemIds[index], itemIds[nextIndex]] = [itemIds[nextIndex], itemIds[index]];
    reorderPortfolio.mutate(itemIds);
  }

  function startPortfolioEdit(item: OwnerPortfolioItem) {
    setPortfolioForm({
      id: item.id,
      title: item.title,
      description: item.description ?? '',
      imageUrl: item.imageUrl ?? '',
    });
    setError(null);
  }

  const visibleRating = reviews.data?.averageRating ?? profile.data?.averageRating;
  const visibleReviewCount = reviews.data?.reviewCount ?? profile.data?.reviewCount ?? 0;
  const queryError = profile.error || reviews.error;

  if (profile.isLoading) return <p>Загрузка профиля…</p>;

  return (
    <div className="stack">
      <header>
        <h1>Публичный профиль</h1>
        <p className="muted">
          Подготовьте карточку тренера и опубликуйте её, когда она будет готова.
        </p>
      </header>

      {queryError ? <p className="error">{(queryError as Error).message}</p> : null}
      {error ? <p className="error" role="alert">{error}</p> : null}
      {message ? <p className={styles.success} role="status">{message}</p> : null}

      <div className={styles.columns}>
        <form
          className="card stack"
          onSubmit={(event: FormEvent) => {
            event.preventDefault();
            saveProfile.mutate();
          }}
        >
          <h2>Основная информация</h2>
          <label className={styles.field}>
            Имя в публичном профиле
            <input
              className="input"
              value={profileForm.displayName}
              maxLength={80}
              required
              onChange={(event) =>
                setProfileForm((current) => ({
                  ...current,
                  displayName: event.target.value,
                }))
              }
            />
          </label>
          <label className={styles.field}>
            Фото (HTTPS-ссылка)
            <input
              className="input"
              type="url"
              pattern="https://.*"
              value={profileForm.avatarUrl}
              maxLength={2048}
              placeholder="https://…"
              onChange={(event) =>
                setProfileForm((current) => ({
                  ...current,
                  avatarUrl: event.target.value,
                }))
              }
            />
          </label>
          <label className={styles.field}>
            О себе
            <textarea
              className="textarea"
              value={profileForm.bio}
              maxLength={1000}
              onChange={(event) =>
                setProfileForm((current) => ({ ...current, bio: event.target.value }))
              }
            />
          </label>
          <label className={styles.field}>
            Город
            <input
              className="input"
              value={profileForm.city}
              maxLength={120}
              onChange={(event) =>
                setProfileForm((current) => ({ ...current, city: event.target.value }))
              }
            />
          </label>
          <label className={styles.field}>
            Специализации через запятую
            <input
              className="input"
              value={profileForm.specialties}
              placeholder="Силовые тренировки, мобильность"
              onChange={(event) =>
                setProfileForm((current) => ({
                  ...current,
                  specialties: event.target.value,
                }))
              }
            />
          </label>
          <fieldset className={styles.fieldset}>
            <legend>Формат тренировок</legend>
            {MODES.map((mode) => (
              <label className={styles.check} key={mode.value}>
                <input
                  type="checkbox"
                  checked={profileForm.trainingModes.includes(mode.value)}
                  onChange={() =>
                    setProfileForm((current) => ({
                      ...current,
                      trainingModes: current.trainingModes.includes(mode.value)
                        ? current.trainingModes.filter((item) => item !== mode.value)
                        : [...current.trainingModes, mode.value],
                    }))
                  }
                />
                {mode.label}
              </label>
            ))}
          </fieldset>
          <button className="btn" disabled={saveProfile.isPending} type="submit">
            {saveProfile.isPending ? 'Сохраняем…' : 'Сохранить профиль'}
          </button>
        </form>

        <section className="card stack">
          <div className={styles.sectionHeader}>
            <div>
              <h2>Публикация и видимость</h2>
              <span className={privacy?.isDiscoverable ? styles.published : styles.hidden}>
                {privacy?.isDiscoverable ? 'Опубликован' : 'Скрыт'}
              </span>
            </div>
          </div>
          {!privacy?.isDiscoverable ? (
            <p className={styles.notice}>
              Профиль виден вам как черновик. Другие пользователи не найдут его.
            </p>
          ) : (
            <p className={styles.noticePublished}>
              Профиль доступен в поиске тренеров внутри Fitness Yoda.
            </p>
          )}
          {privacy ? (
            <>
              <label className={styles.switchRow}>
                <span>
                  <strong>Показывать в поиске</strong>
                  <small>Главный переключатель публикации</small>
                </span>
                <input
                  type="checkbox"
                  checked={privacy.isDiscoverable}
                  onChange={(event) =>
                    setPrivacy((current) =>
                      current ? { ...current, isDiscoverable: event.target.checked } : current,
                    )
                  }
                />
              </label>
              <label className={styles.switchRow}>
                <span>
                  <strong>Показывать рейтинг</strong>
                  <small>Средняя оценка и число отзывов</small>
                </span>
                <input
                  type="checkbox"
                  checked={privacy.showRating}
                  onChange={(event) =>
                    setPrivacy((current) =>
                      current ? { ...current, showRating: event.target.checked } : current,
                    )
                  }
                />
              </label>
              <label className={styles.switchRow}>
                <span>
                  <strong>Показывать отзывы</strong>
                  <small>Текст отзывов в публичной карточке</small>
                </span>
                <input
                  type="checkbox"
                  checked={privacy.showReviews}
                  onChange={(event) =>
                    setPrivacy((current) =>
                      current ? { ...current, showReviews: event.target.checked } : current,
                    )
                  }
                />
              </label>
              <label className={styles.switchRow}>
                <span>
                  <strong>Показывать моё имя в отзывах</strong>
                  <small>Для отзывов, которые вы оставляете как ученик</small>
                </span>
                <input
                  type="checkbox"
                  checked={privacy.showReviewerName}
                  onChange={(event) =>
                    setPrivacy((current) =>
                      current
                        ? { ...current, showReviewerName: event.target.checked }
                        : current,
                    )
                  }
                />
              </label>
              <button
                className="btn"
                type="button"
                disabled={savePrivacy.isPending}
                onClick={() => savePrivacy.mutate()}
              >
                {savePrivacy.isPending ? 'Сохраняем…' : 'Сохранить видимость'}
              </button>
            </>
          ) : null}
        </section>
      </div>

      <section className="card stack">
        <div className={styles.sectionHeader}>
          <div>
            <h2>Предпросмотр</h2>
            <p className="muted">Только поля безопасной публичной проекции.</p>
          </div>
          <span className={privacy?.isDiscoverable ? styles.published : styles.hidden}>
            {privacy?.isDiscoverable ? 'Виден другим' : 'Черновик — скрыт'}
          </span>
        </div>
        <article className={styles.preview}>
          <SafeImage
            src={profileForm.avatarUrl.trim() || null}
            alt="Фото тренера"
            className={styles.avatar}
          />
          <div className="stack">
            <div>
              <h2>{profileForm.displayName.trim() || 'Имя тренера'}</h2>
              <span className="muted">{profileForm.city.trim() || 'Город не указан'}</span>
            </div>
            <p className={styles.plainText}>
              {profileForm.bio.trim() || 'Добавьте короткое описание о себе.'}
            </p>
            <div className="row">
              {profileForm.specialties
                .split(',')
                .map((item) => item.trim())
                .filter(Boolean)
                .map((item) => <span className="chip" key={item}>{item}</span>)}
              {profileForm.trainingModes.map((mode) => (
                <span className="chip" key={mode}>
                  {MODES.find((item) => item.value === mode)?.label}
                </span>
              ))}
            </div>
            {privacy?.showRating ? (
              <strong>
                {visibleRating === null || visibleRating === undefined
                  ? 'Пока нет оценок'
                  : `★ ${visibleRating.toFixed(1)} · ${visibleReviewCount} отзывов`}
              </strong>
            ) : (
              <span className="muted">Рейтинг скрыт настройками приватности</span>
            )}
          </div>
        </article>
      </section>

      <section className="card stack">
        <div className={styles.sectionHeader}>
          <div>
            <h2>Портфолио</h2>
            <p className="muted">{orderedPortfolio.length} из 20 работ</p>
          </div>
          {!portfolioForm.id ? (
            <button
              className="btnSecondary"
              type="button"
              disabled={orderedPortfolio.length >= 20}
              onClick={() => setPortfolioForm({ ...EMPTY_PORTFOLIO })}
            >
              Добавить работу
            </button>
          ) : null}
        </div>

        <form
          className={styles.portfolioForm}
          onSubmit={(event) => {
            event.preventDefault();
            savePortfolio.mutate();
          }}
        >
          <label className={styles.field}>
            Название
            <input
              className="input"
              value={portfolioForm.title}
              maxLength={120}
              required
              onChange={(event) =>
                setPortfolioForm((current) => ({ ...current, title: event.target.value }))
              }
            />
          </label>
          <label className={styles.field}>
            Изображение (HTTPS-ссылка)
            <input
              className="input"
              type="url"
              pattern="https://.*"
              value={portfolioForm.imageUrl}
              maxLength={2048}
              placeholder="https://…"
              onChange={(event) =>
                setPortfolioForm((current) => ({ ...current, imageUrl: event.target.value }))
              }
            />
          </label>
          <label className={`${styles.field} ${styles.fullWidth}`}>
            Описание
            <textarea
              className="textarea"
              value={portfolioForm.description}
              maxLength={1000}
              onChange={(event) =>
                setPortfolioForm((current) => ({
                  ...current,
                  description: event.target.value,
                }))
              }
            />
          </label>
          <div className={`row ${styles.fullWidth}`}>
            <button
              className="btn"
              type="submit"
              disabled={savePortfolio.isPending || (!portfolioForm.id && orderedPortfolio.length >= 20)}
            >
              {portfolioForm.id ? 'Сохранить изменения' : 'Добавить в портфолио'}
            </button>
            {portfolioForm.id ? (
              <button
                className="btnSecondary"
                type="button"
                onClick={() => setPortfolioForm(EMPTY_PORTFOLIO)}
              >
                Отмена
              </button>
            ) : null}
          </div>
        </form>

        {!orderedPortfolio.length ? (
          <p className="muted">Портфолио пока пусто.</p>
        ) : (
          <div className={styles.portfolioGrid}>
            {orderedPortfolio.map((item, index) => (
              <article className={styles.portfolioCard} key={item.id}>
                <SafeImage
                  src={item.imageUrl}
                  alt={item.title}
                  className={styles.portfolioImage}
                />
                <div className="stack">
                  <strong>{item.title}</strong>
                  {item.description ? <p className={styles.plainText}>{item.description}</p> : null}
                  <div className="row">
                    <button
                      className="btnSecondary"
                      type="button"
                      disabled={index === 0 || reorderPortfolio.isPending}
                      aria-label={`Поднять «${item.title}»`}
                      onClick={() => movePortfolio(index, -1)}
                    >
                      ↑
                    </button>
                    <button
                      className="btnSecondary"
                      type="button"
                      disabled={index === orderedPortfolio.length - 1 || reorderPortfolio.isPending}
                      aria-label={`Опустить «${item.title}»`}
                      onClick={() => movePortfolio(index, 1)}
                    >
                      ↓
                    </button>
                    <button className="btnSecondary" type="button" onClick={() => startPortfolioEdit(item)}>
                      Изменить
                    </button>
                    <button
                      className={styles.dangerButton}
                      type="button"
                      disabled={deletePortfolio.isPending}
                      onClick={() => {
                        if (window.confirm(`Удалить «${item.title}» из портфолио?`)) {
                          deletePortfolio.mutate(item.id);
                        }
                      }}
                    >
                      Удалить
                    </button>
                  </div>
                </div>
              </article>
            ))}
          </div>
        )}
      </section>

      <section className="card stack">
        <div className={styles.sectionHeader}>
          <div>
            <h2>Полученные отзывы</h2>
            <p className="muted">Только чтение — изменить отзыв может только его автор.</p>
          </div>
          <strong className={styles.rating}>
            {visibleRating === null || visibleRating === undefined
              ? 'Нет оценок'
              : `★ ${visibleRating.toFixed(1)}`}
            {' · '}
            {visibleReviewCount}
          </strong>
        </div>
        {reviews.isLoading ? <p>Загрузка отзывов…</p> : null}
        {!reviews.isLoading && !reviews.data?.items.length ? (
          <p className="muted">Отзывов пока нет.</p>
        ) : null}
        {(reviews.data?.items ?? []).map((review) => (
          <article className={styles.review} key={review.id}>
            <SafeImage
              src={review.reviewer.avatarUrl}
              alt={`Аватар: ${review.reviewer.displayName}`}
              className={styles.reviewerAvatar}
            />
            <div className="stack">
              <div className={styles.reviewHeader}>
                <strong>{review.reviewer.displayName || 'Ученик'}</strong>
                <span className={styles.stars} aria-label={`Оценка ${review.rating} из 5`}>
                  {stars(review.rating)}
                </span>
              </div>
              <span className="muted">
                Занятие {new Date(review.sessionStartsAt).toLocaleDateString('ru-RU')}
              </span>
              <p className={styles.plainText}>{review.text || 'Без текста'}</p>
            </div>
          </article>
        ))}
        {reviews.data && reviews.data.meta.totalPages > 1 ? (
          <div className="row">
            <button
              className="btnSecondary"
              type="button"
              disabled={reviewPage <= 1}
              onClick={() => setReviewPage((current) => current - 1)}
            >
              Назад
            </button>
            <span className="muted">
              Страница {reviews.data.meta.page} из {reviews.data.meta.totalPages}
            </span>
            <button
              className="btnSecondary"
              type="button"
              disabled={reviewPage >= reviews.data.meta.totalPages}
              onClick={() => setReviewPage((current) => current + 1)}
            >
              Далее
            </button>
          </div>
        ) : null}
      </section>
    </div>
  );
}
