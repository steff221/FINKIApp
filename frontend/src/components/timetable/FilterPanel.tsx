"use client";

import type { TimetableFilters, TimetableFiltersResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS } from "@/types";

interface Props {
  filters: TimetableFilters;
  options: TimetableFiltersResponse | undefined;
  onChange: (f: TimetableFilters) => void;
  onReset: () => void;
}

const selectCls =
  "mt-1 w-full bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all appearance-none cursor-pointer";

export default function FilterPanel({ filters, options, onChange, onReset }: Props) {
  function set<K extends keyof TimetableFilters>(key: K, val: TimetableFilters[K]) {
    onChange({ ...filters, [key]: val });
  }

  const num = (v: string) => (v === "" ? null : Number(v));
  const str = (v: string) => (v === "" ? null : v);

  const activeCount = Object.values(filters).filter(v => v !== null).length;

  return (
    <div className="bg-white rounded-xl shadow-panel overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
        <div className="flex items-center gap-2">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="2" className="text-finki-mid">
            <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
          </svg>
          <span className="font-semibold text-sm text-gray-800">Filters</span>
          {activeCount > 0 && (
            <span className="bg-finki-mid text-white text-xs font-bold rounded-full w-5 h-5 flex items-center justify-center leading-none">
              {activeCount}
            </span>
          )}
        </div>
        <button
          onClick={onReset}
          className="text-xs text-gray-400 hover:text-finki-mid transition-colors font-medium"
        >
          Reset
        </button>
      </div>

      {/* Filter fields */}
      <div className="p-4 space-y-4">
        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Year</span>
          <select
            value={filters.year ?? ""}
            onChange={e => set("year", num(e.target.value) as number | null)}
            className={selectCls}
          >
            <option value="">All years</option>
            {(options?.years ?? []).map(y => (
              <option key={y} value={y}>Year {y}</option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Programme</span>
          <select
            value={filters.programmeCode ?? ""}
            onChange={e => set("programmeCode", str(e.target.value))}
            className={selectCls}
          >
            <option value="">All programmes</option>
            {(options?.programmes ?? []).map(p => (
              <option key={p} value={p}>{p}</option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Day</span>
          <select
            value={filters.dayOfWeek ?? ""}
            onChange={e => set("dayOfWeek", num(e.target.value) as number | null)}
            className={selectCls}
          >
            <option value="">All days</option>
            {DAY_NAMES.map((d, i) => <option key={i} value={i}>{d}</option>)}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Type</span>
          <select
            value={filters.lessonType ?? ""}
            onChange={e => set("lessonType", str(e.target.value))}
            className={selectCls}
          >
            <option value="">All types</option>
            {Object.entries(LESSON_TYPE_LABELS).map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Teacher</span>
          <select
            value={filters.teacherId ?? ""}
            onChange={e => set("teacherId", num(e.target.value) as number | null)}
            className={selectCls}
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
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Room</span>
          <select
            value={filters.classroomId ?? ""}
            onChange={e => set("classroomId", num(e.target.value) as number | null)}
            className={selectCls}
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
    </div>
  );
}
