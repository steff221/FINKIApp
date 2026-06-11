import type { MapPin } from "@/components/maps/FinkiMap";

export const FINKI_PINS: MapPin[] = [
  // ── Main FINKI building ──────────────────────────────────────────────────────
  { name: "ФИНКИ - деканат",            lat: 42.00439, lng: 21.40985, kind: "office" },
  { name: "Амфитеатар ФИНКИ Голем",     lat: 42.00449, lng: 21.40955, kind: "amphitheatre" },
  { name: "Амфитеатар ФИНКИ Кабинет 10",lat: 42.00432, lng: 21.41015, kind: "amphitheatre" },
  { name: "Конференциска сала на ФИНКИ", lat: 42.00415, lng: 21.40955, kind: "other" },
  { name: "Инфо Стоп ФИНКИ",            lat: 42.00455, lng: 21.40995, kind: "other" },

  // ── Главна зграда (ФИНКИ/ФЕИТ) ───────────────────────────────────────────────
  { name: "Амфитеатар МФ",              lat: 42.00570, lng: 21.40820, kind: "amphitheatre" },
  { name: "Електротехника",             lat: 42.00448, lng: 21.40750, kind: "other" },
  { name: "ЛАБ SOCD",                   lat: 42.00428, lng: 21.40745, kind: "lab" },

  // ── ТМФ / ФФ building ────────────────────────────────────────────────────────
  { name: "Книжара",                    lat: 42.00530, lng: 21.41060, kind: "other" },
  { name: "Кабинети 115",               lat: 42.00518, lng: 21.41090, kind: "office" },
  { name: "Студентска служба",          lat: 42.00506, lng: 21.41075, kind: "office" },
  { name: "Амфитеатар ФФ",              lat: 42.00498, lng: 21.41100, kind: "amphitheatre" },
  { name: "Конференциска сала на ТМФ",  lat: 42.00488, lng: 21.41120, kind: "other" },
  { name: "Амфитеатар ФФ 138",          lat: 42.00477, lng: 21.41115, kind: "amphitheatre" },
  { name: "Кабинет 122",                lat: 42.00510, lng: 21.41160, kind: "office" },

  // ── Бараки ───────────────────────────────────────────────────────────────────
  { name: "Барака 3.2",                 lat: 42.00490, lng: 21.40620, kind: "baraka" },
  { name: "Барака 3.1",                 lat: 42.00478, lng: 21.40648, kind: "baraka" },
  { name: "Барака 2.2",                 lat: 42.00462, lng: 21.40618, kind: "baraka" },
  { name: "Барака 2.1",                 lat: 42.00450, lng: 21.40645, kind: "baraka" },
  { name: "Барака 1",                   lat: 42.00432, lng: 21.40622, kind: "baraka" },
];
