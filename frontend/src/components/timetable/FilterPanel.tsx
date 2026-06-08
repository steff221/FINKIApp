"use client";

import type { TimetableFilters, TimetableFiltersResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS } from "@/types";

interface Props {
  filters: TimetableFilters;
  options: TimetableFiltersResponse | undefined;
  onChange: (f: TimetableFilters) => void;
  onReset: () => void;
}

export default function FilterPanel({ filters, options, onChange, onReset }: Props) {
  function set<K extends keyof TimetableFilters>(key: K, val: TimetableFilters[K]) {
    onChange({ ...filters, [key]: val });
  }

  const num = (v: string) => (v === "" ? null : Number(v));
  const str = (v: string) => (v === "" ? null : v);

  return (
    <div className="bg-white rounded-lg border p-4 space-y-4 text-sm">
      <div className="flex items-center justify-between">
        <span className="font-semibold text-gray-700">Filters</span>
        <button onClick={onReset} className="text-xs text-finki-light hover:underline">Reset</button>
      </div>

      <label className="block">
        <span className="text-gray-600">Year</span>
        <select
          value={filters.year ?? ""}
          onChange={e => set("year", num(e.target.value) as number | null)}
          className="mt-1 w-full border rounded px-2 py-1"
        >
          <option value="">All years</option>
          {(options?.years ?? []).map(y => (
            <option key={y} value={y}>Year {y}</option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="text-gray-600">Programme</span>
        <select
          value={filters.programmeCode ?? ""}
          onChange={e => set("programmeCode", str(e.target.value))}
          className="mt-1 w-full border rounded px-2 py-1"
        >
          <option value="">All programmes</option>
          {(options?.programmes ?? []).map(p => (
            <option key={p} value={p}>{p}</option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="text-gray-600">Day</span>
        <select
          value={filters.dayOfWeek ?? ""}
          onChange={e => set("dayOfWeek", num(e.target.value) as number | null)}
          className="mt-1 w-full border rounded px-2 py-1"
        >
          <option value="">All days</option>
          {DAY_NAMES.map((d, i) => <option key={i} value={i}>{d}</option>)}
        </select>
      </label>

      <label className="block">
        <span className="text-gray-600">Type</span>
        <select
          value={filters.lessonType ?? ""}
          onChange={e => set("lessonType", str(e.target.value))}
          className="mt-1 w-full border rounded px-2 py-1"
        >
          <option value="">All types</option>
          {Object.entries(LESSON_TYPE_LABELS).map(([k, v]) => (
            <option key={k} value={k}>{v}</option>
          ))}
        </select>
      </label>

      <label className="block">
        <span className="text-gray-600">Teacher</span>
        <select
          value={filters.teacherId ?? ""}
          onChange={e => set("teacherId", num(e.target.value) as number | null)}
          className="mt-1 w-full border rounded px-2 py-1"
        >
          <option value="">All teachers</option>
          {(options?.teachers ?? [])
            .filter(t => t.cyrillicName)
            .sort((a, b) => (a.cyrillicName ?? "").localeCompare(b.cyrillicName ?? ""))
            .map(t => (
              <option key={t.id} value={t.id}>{t.cyrillicName}</option>
            ))}
        </select>
      </label>

      <label className="block">
        <span className="text-gray-600">Room</span>
        <select
          value={filters.classroomId ?? ""}
          onChange={e => set("classroomId", num(e.target.value) as number | null)}
          className="mt-1 w-full border rounded px-2 py-1"
        >
          <option value="">All rooms</option>
          {(options?.classrooms ?? [])
            .sort((a, b) => a.name.localeCompare(b.name))
            .map(c => (
              <option key={c.id} value={c.id}>{c.name}</option>
            ))}
        </select>
      </label>
    </div>
  );
}
