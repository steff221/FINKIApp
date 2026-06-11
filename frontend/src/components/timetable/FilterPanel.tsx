"use client";

import { useState, useRef, useEffect } from "react";
import type { TimetableFilters, TimetableFiltersResponse, TeacherResponse } from "@/types";
import { DAY_NAMES, LESSON_TYPE_LABELS, editionLabel } from "@/types";

interface Props {
  filters: TimetableFilters;
  options: TimetableFiltersResponse | undefined;
  onChange: (f: TimetableFilters) => void;
  onReset: () => void;
}

const selectCls =
  "mt-1 w-full bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all appearance-none cursor-pointer";

const inputCls =
  "mt-1 w-full bg-white border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-800 shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all";

/** Inline searchable combobox — no external deps */
function SearchableSelect({
  value,
  options,
  placeholder,
  onChange,
}: {
  value: number | null;
  options: TeacherResponse[];
  placeholder: string;
  onChange: (id: number | null) => void;
}) {
  const selected = options.find(t => t.id === value);
  const [query, setQuery]     = useState("");
  const [open, setOpen]       = useState(false);
  const containerRef          = useRef<HTMLDivElement>(null);

  const filtered = query.trim()
    ? options.filter(t =>
        (t.cyrillicName ?? "").toLowerCase().includes(query.toLowerCase())
      )
    : options;

  useEffect(() => {
    function handleClick(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
        setQuery("");
      }
    }
    document.addEventListener("mousedown", handleClick);
    return () => document.removeEventListener("mousedown", handleClick);
  }, []);

  return (
    <div ref={containerRef} className="relative mt-1">
      <div
        className={`flex items-center bg-white border rounded-lg shadow-sm cursor-pointer transition-all ${
          open ? "border-blue-400 ring-2 ring-blue-400/40" : "border-gray-200"
        }`}
        onClick={() => { setOpen(o => !o); setQuery(""); }}
      >
        {open ? (
          <input
            autoFocus
            value={query}
            onChange={e => { setQuery(e.target.value); setOpen(true); }}
            onClick={e => e.stopPropagation()}
            placeholder="Пребарај…"
            className="flex-1 px-3 py-2 text-sm bg-transparent focus:outline-none"
          />
        ) : (
          <span className="flex-1 px-3 py-2 text-sm text-gray-800 truncate">
            {selected?.cyrillicName ?? placeholder}
          </span>
        )}
        <svg className="shrink-0 mr-2 text-gray-400" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
          <path d="M6 9l6 6 6-6" />
        </svg>
      </div>

      {open && (
        <div className="absolute z-50 mt-1 w-full bg-white border border-gray-200 rounded-lg shadow-lg max-h-52 overflow-y-auto">
          <div
            className="px-3 py-2 text-sm text-gray-400 hover:bg-gray-50 cursor-pointer"
            onMouseDown={() => { onChange(null); setOpen(false); setQuery(""); }}
          >
            {placeholder}
          </div>
          {filtered.slice(0, 100).map(t => (
            <div
              key={t.id}
              onMouseDown={() => { onChange(t.id); setOpen(false); setQuery(""); }}
              className={`px-3 py-2 text-sm cursor-pointer truncate transition-colors ${
                t.id === value ? "bg-finki-navy/5 text-finki-navy font-semibold" : "text-gray-800 hover:bg-gray-50"
              }`}
            >
              {t.cyrillicName}
            </div>
          ))}
          {filtered.length === 0 && (
            <div className="px-3 py-3 text-sm text-gray-400 text-center">Нема резултати</div>
          )}
        </div>
      )}
    </div>
  );
}

export default function FilterPanel({ filters, options, onChange, onReset }: Props) {
  function set<K extends keyof TimetableFilters>(key: K, val: TimetableFilters[K]) {
    onChange({ ...filters, [key]: val });
  }

  const num = (v: string) => (v === "" ? null : Number(v));
  const str = (v: string) => (v === "" ? null : v);

  const activeCount = Object.values(filters).filter(v => v !== null).length;

  const sortedTeachers = (options?.teachers ?? [])
    .filter(t => t.cyrillicName)
    .sort((a, b) => (a.cyrillicName ?? "").localeCompare(b.cyrillicName ?? "", "mk"));

  return (
    <div className="bg-white rounded-xl shadow-panel overflow-hidden">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 border-b border-gray-100">
        <div className="flex items-center gap-2">
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor"
            strokeWidth="2" className="text-finki-mid">
            <polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" />
          </svg>
          <span className="font-semibold text-sm text-gray-800">Филтри</span>
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
          Ресетирај
        </button>
      </div>

      {/* Filter fields */}
      <div className="p-4 space-y-4">
        {(options?.editions?.length ?? 0) > 1 && (
          <label className="block">
            <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Семестар</span>
            <select
              value={filters.editionNumber ?? options?.currentEdition ?? ""}
              onChange={e => set("editionNumber", str(e.target.value))}
              className={selectCls}
            >
              {(options?.editions ?? []).map(ed => (
                <option key={ed} value={ed}>{editionLabel(ed)}</option>
              ))}
            </select>
          </label>
        )}

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Година</span>
          <select
            value={filters.year ?? ""}
            onChange={e => set("year", num(e.target.value) as number | null)}
            className={selectCls}
          >
            <option value="">Сите години</option>
            {(options?.years ?? []).map(y => (
              <option key={y} value={y}>Година {y}</option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Насока</span>
          <select
            value={filters.programmeCode ?? ""}
            onChange={e => set("programmeCode", str(e.target.value))}
            className={selectCls}
          >
            <option value="">Сите насоки</option>
            {(options?.programmes ?? []).map(p => (
              <option key={p} value={p}>{p}</option>
            ))}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Ден</span>
          <select
            value={filters.dayOfWeek ?? ""}
            onChange={e => set("dayOfWeek", num(e.target.value) as number | null)}
            className={selectCls}
          >
            <option value="">Сите денови</option>
            {DAY_NAMES.map((d, i) => <option key={i} value={i}>{d}</option>)}
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Тип</span>
          <select
            value={filters.lessonType ?? ""}
            onChange={e => set("lessonType", str(e.target.value))}
            className={selectCls}
          >
            <option value="">Сите типови</option>
            {Object.entries(LESSON_TYPE_LABELS).filter(([k]) => k !== "LAB").map(([k, v]) => (
              <option key={k} value={k}>{v}</option>
            ))}
          </select>
        </label>

        <div className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Предавач</span>
          <SearchableSelect
            value={filters.teacherId}
            options={sortedTeachers}
            placeholder="Сите предавачи"
            onChange={id => set("teacherId", id)}
          />
        </div>

        <label className="block">
          <span className="text-xs font-medium text-gray-500 uppercase tracking-wide">Просторија</span>
          <select
            value={filters.classroomId ?? ""}
            onChange={e => set("classroomId", num(e.target.value) as number | null)}
            className={selectCls}
          >
            <option value="">Сите простории</option>
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
