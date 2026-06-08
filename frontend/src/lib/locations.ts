// FINKI room / location directory — read from the campus & floor-plan screenshots.
// Buildings/floors reflect the OpenLevelUp indoor maps; tweak freely if anything's off.

export interface FinkiLocation {
  name: string;        // room / hall label as shown on the map
  building: string;    // building / wing
  floor?: string;      // floor description
  note?: string;       // extra hint
  kind?: "lab" | "amphitheatre" | "classroom" | "office" | "other";
}

export const LOCATIONS: FinkiLocation[] = [
  // ── ФИНКИ ──────────────────────────────────────────────────────────────────
  { name: "Амфитеатар ФИНКИ",          building: "ФИНКИ", floor: "Приземје", kind: "amphitheatre" },
  { name: "Амфитеатар ФИНКИ - Голем",  building: "ФИНКИ", floor: "Приземје", kind: "amphitheatre" },
  { name: "Конференциска сала на ФИНКИ",building: "ФИНКИ", floor: "Приземје", kind: "other" },
  { name: "Инфо Стоп ФИНКИ",           building: "ФИНКИ", floor: "Приземје", kind: "other" },
  { name: "ФИНКИ - деканат",           building: "ФИНКИ", floor: "Приземје", kind: "office" },
  { name: "Кабинет 10",                building: "ФИНКИ", floor: "Приземје", kind: "office" },
  { name: "Кабинет Ф10",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет Ф11",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет Ф12",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет Ф13",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет Ф14",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М1",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М2",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М3",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М4",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М5",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М6",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М7",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М8",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М9",                building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М10",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М11",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М12",               building: "ФИНКИ", kind: "office" },
  { name: "Кабинет М13",               building: "ФИНКИ", kind: "office" },

  // ── Главна зграда (ФИНКИ/ФЕИТ) — нумерирани простории по катови ──────────────
  { name: "ЛАБ 2",        building: "Главна зграда", floor: "Подрум (-1)", kind: "lab" },
  { name: "ЛАБ 3",        building: "Главна зграда", floor: "Подрум (-1)", kind: "lab" },
  { name: "ЛАБ 12",       building: "Главна зграда", floor: "Подрум (-1)", kind: "lab" },
  { name: "ЛАБ 13",       building: "Главна зграда", floor: "Подрум (-1)", kind: "lab" },
  { name: "Гуштеров",     building: "Главна зграда", floor: "Подрум (-1)", kind: "amphitheatre" },
  { name: "Кабинет 26",   building: "Главна зграда", floor: "Подрум (-1)", kind: "office" },
  { name: "Кабинет 26А",  building: "Главна зграда", floor: "Подрум (-1)", kind: "office" },
  { name: "Кабинет 34",   building: "Главна зграда", floor: "Подрум (-1)", kind: "office" },
  { name: "Кабинет 35",   building: "Главна зграда", floor: "Подрум (-1)", kind: "office" },
  { name: "Кабинет 36",   building: "Главна зграда", floor: "Подрум (-1)", kind: "office" },
  { name: "Кабинет 37",   building: "Главна зграда", floor: "Подрум (-1)", kind: "office" },
  { name: "ЛАБ 200АБ",    building: "Главна зграда", floor: "Кат 1", kind: "lab" },
  { name: "ЛАБ 200В",     building: "Главна зграда", floor: "Кат 1", kind: "lab" },
  { name: "ЛАБ 215",      building: "Главна зграда", floor: "Кат 1", kind: "lab" },
  { name: "Предавална 203",building: "Главна зграда", floor: "Кат 1", kind: "classroom" },
  { name: "Предавална 216",building: "Главна зграда", floor: "Кат 1", kind: "classroom" },
  { name: "Кабинет 209",  building: "Главна зграда", floor: "Кат 1", kind: "office" },
  { name: "Кабинет 222",  building: "Главна зграда", floor: "Кат 1", kind: "office" },
  { name: "Кабинет 224",  building: "Главна зграда", floor: "Кат 1", kind: "office" },
  { name: "Предавална 302",building: "Главна зграда", floor: "Кат 2", kind: "classroom" },
  { name: "Предавална 315",building: "Главна зграда", floor: "Кат 2", kind: "classroom" },
  { name: "Кабинет 321а", building: "Главна зграда", floor: "Кат 2", kind: "office" },
  { name: "Кабинет 321б", building: "Главна зграда", floor: "Кат 2", kind: "office" },
  { name: "Кабинет 322",  building: "Главна зграда", floor: "Кат 2", kind: "office" },
  { name: "Кабинет 332",  building: "Главна зграда", floor: "Кат 2", kind: "office" },

  // ── ТМФ (Технолошко-металуршки факултет) ────────────────────────────────────
  { name: "Амфитеатар ТМФ",            building: "ТМФ", floor: "Приземје", kind: "amphitheatre" },
  { name: "Конференциска сала на ТМФ", building: "ТМФ", floor: "Приземје", kind: "other" },
  { name: "Студентска служба",         building: "ТМФ", floor: "Приземје", kind: "office" },
  { name: "Книжара 119",               building: "ТМФ", floor: "Приземје", kind: "other" },
  { name: "ЛАБ 138",                   building: "ТМФ", floor: "Приземје", kind: "lab" },
  { name: "Кабинет 122",               building: "ТМФ", floor: "Приземје", kind: "office" },
  { name: "114",                       building: "ТМФ", floor: "Приземје", kind: "classroom" },
  { name: "115",                       building: "ТМФ", floor: "Приземје", kind: "classroom" },
  { name: "116",                       building: "ТМФ", floor: "Приземје", kind: "classroom" },

  // ── МФ (Машински факултет) ──────────────────────────────────────────────────
  { name: "Амфитеатар МФ",  building: "МФ", floor: "Приземје", kind: "amphitheatre" },
  { name: "Студентски сервис", building: "МФ", floor: "Приземје", kind: "office" },
  { name: "123 МФ",         building: "МФ", floor: "Приземје", kind: "classroom" },
  { name: "124 МФ",         building: "МФ", floor: "Приземје", kind: "classroom" },
  { name: "224 МФ",         building: "МФ", floor: "Кат 2", kind: "classroom" },
  { name: "225 МФ",         building: "МФ", floor: "Кат 2", kind: "classroom" },

  // ── ФЕИТ (Електротехника) ───────────────────────────────────────────────────
  { name: "ЛАБ SOCD",   building: "ФЕИТ (Електротехника)", floor: "Приземје", kind: "lab" },
  { name: "110 ФЕИТ",   building: "ФЕИТ (Електротехника)", floor: "Приземје", kind: "classroom" },
  { name: "112 ФЕИТ",   building: "ФЕИТ (Електротехника)", floor: "Приземје", kind: "classroom" },
  { name: "223 ФЕИТ",   building: "ФЕИТ (Електротехника)", floor: "Кат 2", kind: "classroom" },
  { name: "310 ФЕИТ",   building: "ФЕИТ (Електротехника)", floor: "Кат 3", kind: "classroom" },
  { name: "311 ФЕИТ",   building: "ФЕИТ (Електротехника)", floor: "Кат 3", kind: "classroom" },

  // ── Барака ──────────────────────────────────────────────────────────────────
  { name: "Барака 1",   building: "Барака", floor: "Приземје", kind: "classroom" },
  { name: "Барака 2.1", building: "Барака", floor: "Приземје", kind: "classroom" },
  { name: "Барака 2.2", building: "Барака", floor: "Приземје", kind: "classroom" },
  { name: "Барака 3.1", building: "Барака", floor: "Приземје", kind: "classroom" },
  { name: "Барака 3.2", building: "Барака", floor: "Приземје", kind: "classroom" },
];
