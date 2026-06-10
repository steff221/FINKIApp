"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import useSWR from "swr";
import { getConsultations } from "@/lib/api";
import type { TeacherWithSlotsResponse } from "@/types";

export default function ConsultationsPage() {
  const [search, setSearch] = useState("");

  const { data, isLoading } = useSWR<TeacherWithSlotsResponse[]>(
    "/api/consultations",
    () => getConsultations()
  );

  const grouped = useMemo(() => {
    if (!data) return [] as [string, TeacherWithSlotsResponse[]][];
    const q = search.trim().toLowerCase();
    const filtered = q
      ? data.filter(({ teacher }) => {
          const name = (teacher.cyrillicName ?? teacher.consultationUsername ?? "").toLowerCase();
          const user = (teacher.consultationUsername ?? "").toLowerCase();
          return name.includes(q) || user.includes(q);
        })
      : data;
    const sorted = [...filtered].sort((a, b) =>
      (a.teacher.cyrillicName ?? "").localeCompare(b.teacher.cyrillicName ?? "", "mk")
    );
    const map = new Map<string, TeacherWithSlotsResponse[]>();
    sorted.forEach(item => {
      const name   = item.teacher.cyrillicName ?? item.teacher.consultationUsername ?? "?";
      const letter = name[0]?.toUpperCase() ?? "?";
      if (!map.has(letter)) map.set(letter, []);
      map.get(letter)!.push(item);
    });
    return Array.from(map.entries());
  }, [data, search]);

  const totalCount = grouped.reduce((n, [, arr]) => n + arr.length, 0);

  return (
    <div className="space-y-8">

      {/* ── Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Консултации</h1>
          <p className="text-sm text-gray-500 mt-1">Пронајдете го вашиот професор и пријавете се</p>
        </div>
        {!isLoading && totalCount > 0 && (
          <span className="text-sm text-gray-500 self-start sm:self-end">
            {totalCount} {totalCount === 1 ? "профeсор" : "профeсори"}
          </span>
        )}
      </div>

      {/* ── Search ── */}
      <div className="relative">
        <svg
          className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
          width="16" height="16" viewBox="0 0 24 24" fill="none"
          stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"
        >
          <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
        </svg>
        <input
          type="text"
          placeholder="Пребарај по ime на профeсор…"
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="w-full border border-gray-300 rounded-xl pl-10 pr-10 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-finki-navy/30 focus:border-finki-navy transition-all bg-white"
        />
        {search && (
          <button
            onClick={() => setSearch("")}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
            aria-label="Исчисти пребарување"
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M18 6 6 18M6 6l12 12" />
            </svg>
          </button>
        )}
      </div>

      {/* ── Loading ── */}
      {isLoading && (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 border-2 border-gray-200 border-t-finki-navy rounded-full animate-spin" />
        </div>
      )}

      {/* ── No results ── */}
      {!isLoading && search && grouped.length === 0 && (
        <div className="text-center py-16">
          <svg className="mx-auto text-gray-300 mb-3" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
          <p className="text-gray-500 text-sm">Нема резултати за &ldquo;{search}&rdquo;</p>
          <button onClick={() => setSearch("")} className="text-sm text-blue-600 hover:underline mt-2">
            Прикажи ги сите
          </button>
        </div>
      )}

      {/* ── Alphabetical list ── */}
      {!isLoading && grouped.length > 0 && (
        <div className="space-y-8">
          {grouped.map(([letter, professors]) => (
            <div key={letter}>
              <div className="flex items-center gap-3 mb-3">
                <span className="w-8 h-8 rounded-full bg-finki-navy text-white text-sm font-bold flex items-center justify-center shrink-0">
                  {letter}
                </span>
                <div className="flex-1 h-px bg-gray-100" />
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-2">
                {professors.map(({ teacher, slots }) => {
                  const name = teacher.cyrillicName ?? teacher.consultationUsername ?? "?";
                  return (
                    <Link
                      key={teacher.id}
                      href={`/consultations/professor/${teacher.id}?name=${encodeURIComponent(name)}`}
                      className="group flex items-center gap-3 bg-white border border-gray-200 rounded-xl px-4 py-3.5 hover:border-finki-navy hover:shadow-md transition-all"
                    >
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-900 leading-snug truncate">{name}</p>
                        {slots.length > 0 && (
                          <p className="text-xs text-gray-400 mt-0.5">
                            {slots.length} {slots.length === 1 ? "термин" : "термини"}
                          </p>
                        )}
                      </div>
                      <svg className="text-gray-300 group-hover:text-finki-navy shrink-0 transition-colors" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                        <path d="M9 18l6-6-6-6" />
                      </svg>
                    </Link>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
