"use client";

import { useState } from "react";
import useSWR from "swr";
import { getConsultations } from "@/lib/api";
import type { ConsultationSlotResponse, TeacherWithSlotsResponse } from "@/types";
import { formatTime } from "@/types";

// Deterministic avatar color from name
const AVATAR_COLORS = [
  "bg-blue-600", "bg-violet-600", "bg-emerald-600",
  "bg-rose-600",  "bg-amber-600",  "bg-cyan-600",
  "bg-indigo-600","bg-teal-600",   "bg-pink-600",
];
function avatarColor(name: string) {
  let h = 0;
  for (let i = 0; i < name.length; i++) h = (h * 31 + name.charCodeAt(i)) >>> 0;
  return AVATAR_COLORS[h % AVATAR_COLORS.length];
}
function initials(name: string) {
  const parts = name.trim().split(/\s+/);
  return (parts[0][0] + (parts[1]?.[0] ?? "")).toUpperCase();
}

// ── Professor card ────────────────────────────────────────────────────────────
function ProfessorCard({
  teacher,
  slots,
}: {
  teacher: TeacherWithSlotsResponse["teacher"];
  slots: ConsultationSlotResponse[];
}) {
  const name = teacher.cyrillicName ?? teacher.consultationUsername ?? "Unknown";
  const hasSlots = slots.length > 0;
  const color = avatarColor(name);

  return (
    <div
      className={`group relative bg-white rounded-xl shadow-card hover:shadow-card-hover transition-all duration-200 overflow-hidden flex flex-col ${
        hasSlots ? "border-l-4 border-l-blue-500" : "border-l-4 border-l-gray-200"
      }`}
    >
      {/* Card header */}
      <div className="flex items-center gap-3 px-4 pt-4 pb-3">
        <div className={`${color} w-9 h-9 rounded-full flex items-center justify-center shrink-0`}>
          <span className="text-white text-xs font-bold tracking-wide">{initials(name)}</span>
        </div>
        <div className="min-w-0">
          <p className="font-semibold text-gray-900 text-sm leading-tight truncate">{name}</p>
          {hasSlots && (
            <p className="text-xs text-emerald-600 font-medium mt-0.5">
              {slots.length} slot{slots.length > 1 ? "s" : ""} available
            </p>
          )}
        </div>
      </div>

      {/* Divider */}
      <div className="h-px bg-gray-100 mx-4" />

      {/* Slots */}
      <div className="px-4 py-3 flex-1 space-y-2">
        {hasSlots ? (
          slots.map(slot => (
            <div key={slot.id} className="flex items-start gap-2.5">
              <div className="shrink-0 mt-0.5 bg-blue-50 text-blue-700 rounded-md px-2 py-0.5 text-xs font-semibold tabular-nums whitespace-nowrap">
                {slot.date}
              </div>
              <div className="min-w-0">
                <p className="text-xs font-medium text-gray-800">
                  {formatTime(slot.startTime)}–{formatTime(slot.endTime)}
                  {slot.room && <span className="text-gray-500 font-normal"> · {slot.room}</span>}
                </p>
                {slot.instructions && (
                  <p className="text-xs text-gray-400 mt-0.5 leading-relaxed">{slot.instructions}</p>
                )}
              </div>
            </div>
          ))
        ) : (
          <p className="text-xs text-gray-400 italic">No consultations in the next 6 days.</p>
        )}
      </div>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────
export default function ConsultationsPage() {
  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");

  const { data, isLoading } = useSWR<TeacherWithSlotsResponse[]>(
    ["/api/consultations", debouncedQuery],
    ([, q]: [string, string]) => getConsultations(q || undefined)
  );

  function handleSearch(e: React.ChangeEvent<HTMLInputElement>) {
    const val = e.target.value;
    setQuery(val);
    clearTimeout((window as Window & { _searchTimer?: number })._searchTimer);
    (window as Window & { _searchTimer?: number })._searchTimer = window.setTimeout(
      () => setDebouncedQuery(val),
      300
    );
  }

  const withSlots    = data?.filter(d => d.slots.length > 0) ?? [];
  const withoutSlots = data?.filter(d => d.slots.length === 0) ?? [];

  return (
    <div className="space-y-7">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end gap-4">
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-finki-navy tracking-tight">Consultations</h1>
          <p className="text-sm text-gray-500 mt-1">
            Office hours for the next 6 days — refreshed nightly
          </p>
        </div>

        {data && (
          <div className="flex items-center gap-3 text-sm shrink-0">
            <span className="flex items-center gap-1.5 bg-emerald-50 text-emerald-700 border border-emerald-200 rounded-full px-3 py-1 font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
              {withSlots.length} available
            </span>
            <span className="text-gray-400">{data.length} professors total</span>
          </div>
        )}
      </div>

      {/* Search */}
      <div className="relative max-w-xs">
        <svg
          className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
          width="14" height="14" viewBox="0 0 24 24" fill="none"
          stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"
        >
          <circle cx="11" cy="11" r="8" />
          <path d="m21 21-4.35-4.35" />
        </svg>
        <input
          type="text"
          placeholder="Search professor…"
          value={query}
          onChange={handleSearch}
          className="w-full bg-white shadow-card rounded-xl pl-9 pr-4 py-2.5 text-sm placeholder-gray-400 border-0 focus:outline-none focus:ring-2 focus:ring-blue-400/40 transition-all"
        />
      </div>

      {/* Loading skeleton */}
      {isLoading && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {Array.from({ length: 9 }).map((_, i) => (
            <div key={i} className="bg-white rounded-xl shadow-card h-32 animate-pulse" />
          ))}
        </div>
      )}

      {/* Results */}
      {data && data.length > 0 && (
        <div className="space-y-8">
          {withSlots.length > 0 && (
            <section className="space-y-3">
              <h2 className="text-xs font-semibold text-gray-400 uppercase tracking-widest">
                Available this week
              </h2>
              <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
                {withSlots.map(({ teacher, slots }) => (
                  <ProfessorCard key={teacher.id} teacher={teacher} slots={slots} />
                ))}
              </div>
            </section>
          )}

          {withoutSlots.length > 0 && (
            <section className="space-y-3">
              <h2 className="text-xs font-semibold text-gray-400 uppercase tracking-widest">
                No upcoming slots
              </h2>
              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
                {withoutSlots.map(({ teacher, slots }) => (
                  <ProfessorCard key={teacher.id} teacher={teacher} slots={slots} />
                ))}
              </div>
            </section>
          )}
        </div>
      )}

      {data && data.length === 0 && (
        <div className="flex flex-col items-center justify-center py-24 text-center">
          <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center mb-3">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor"
              strokeWidth="1.5" className="text-gray-400">
              <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
            </svg>
          </div>
          <p className="font-medium text-gray-700">No professors found</p>
          <p className="text-sm text-gray-400 mt-1">Try a different search term</p>
        </div>
      )}
    </div>
  );
}
