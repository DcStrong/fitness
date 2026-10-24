/**
 * Схлопывает пробелы и обрезает края.
 */
export function collapseGymText(value: string): string {
  return value.trim().replace(/\s+/gu, ' ');
}

/**
 * Нормализованная пара «название + адрес + город»: регистр, ё/е и пробелы
 * не создают дублей одного и того же зала.
 */
export function buildGymDedupeKey(input: {
  name: string;
  address: string;
  city: string;
}): string {
  /**
   *
   */
  function normalize(value: string): string {
    return collapseGymText(value).toLowerCase().replace(/ё/gu, 'е');
  }

  return [input.name, input.address, input.city].map(normalize).join('|');
}
