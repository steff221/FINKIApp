/** Formats a minute count as a Macedonian duration, e.g. 150 → "2ч 30мин". */
export function formatDuration(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (h === 0) return `${m}мин`;
  if (m === 0) return `${h}ч`;
  return `${h}ч ${m}мин`;
}
