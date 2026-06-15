"use client";

import { useState, useMemo } from "react";
import useSWR from "swr";
import { getExams, getExamSessions, getExamsIcsUrl } from "@/lib/api";
import type { ExamResponse } from "@/types";
import { formatTime } from "@/types";

const MK_MONTHS = [
  "јануари", "февруари", "март", "април", "мај", "јуни",
  "јули", "август", "септември", "октомври", "ноември", "декември",
];
const MK_DAYS_LONG = ["Недела", "Понеделник", "Вторник", "Среда", "Четврток", "Петок", "Сабота"];

/** Parses a "YYYY-MM-DD" string as a local date (no timezone shift). */
function parseDate(s: string): Date {
  const [y, m, d] = s.split("-").map(Number);
  return new Date(y, m - 1, d);
}

function formatDateHeading(s: string): string {
  const d = parseDate(s);
  return `${MK_DAYS_LONG[d.getDay()]}, ${d.getDate()} ${MK_MONTHS[d.getMonth()]} ${d.getFullYear()}`;
}

export default function ExamsPage() {
  const [search, setSearch]   = useState("");
  const [session, setSession] = useState<string | null>(null);

  const { data: sessions } = useSWR<string[]>("/api/exams/sessions", () => getExamSessions());

  // Default to the most recent session once the list loads.
  const activeSession = session ?? (sessions && sessions.length > 0 ? sessions[0] : null);

  const { data: exams, isLoading } = useSWR<ExamResponse[]>(
    activeSession ? ["/api/exams", activeSession] : "/api/exams",
    () => getExams(activeSession)
  );

  // Client-side subject filter + group by date.
  const grouped = useMemo(() => {
    if (!exams) return [] as [string, ExamResponse[]][];
    const q = search.trim().toLowerCase();
    const filtered = q
      ? exams.filter(e =>
          e.subjectName.toLowerCase().includes(q) ||
          (e.rooms ?? "").toLowerCase().includes(q))
      : exams;
    const map = new Map<string, ExamResponse[]>();
    filtered.forEach(e => {
      if (!map.has(e.date)) map.set(e.date, []);
      map.get(e.date)!.push(e);
    });
    return Array.from(map.entries()).sort(([a], [b]) => a.localeCompare(b));
  }, [exams, search]);

  const totalCount = grouped.reduce((n, [, arr]) => n + arr.length, 0);

  return (
    <div className="space-y-8">

      {/* ── Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Испити</h1>
          <p className="text-sm text-gray-500 mt-1">Распоред на испити по сесија</p>
        </div>
        <div className="flex items-center gap-2 self-start sm:self-end">
          {activeSession && totalCount > 0 && (
            <a
              href={getExamsIcsUrl(activeSession, search.trim() || undefined)}
              className="inline-flex items-center gap-1.5 text-sm font-medium text-finki-navy border border-gray-200 rounded-lg px-3 py-2 hover:bg-gray-50 transition-colors"
              title="Преземи .ics за календар"
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" />
              </svg>
              Календар
            </a>
          )}
        </div>
      </div>

      {/* ── Session tabs ── */}
      {sessions && sessions.length > 1 && (
        <div className="flex flex-wrap gap-2">
          {sessions.map(s => {
            const active = s === activeSession;
            return (
              <button
                key={s}
                onClick={() => setSession(s)}
                className={`px-3.5 py-1.5 rounded-lg text-sm font-medium transition-all ${
                  active
                    ? "bg-finki-navy text-white"
                    : "bg-white border border-gray-200 text-gray-600 hover:border-finki-navy"
                }`}
              >
                {s}
              </button>
            );
          })}
        </div>
      )}

      {/* ── Search ── */}
      <div className="relative">
        <svg className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
          <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
        </svg>
        <input
          type="text"
          placeholder="Пребарај по предмет или просторија…"
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="w-full border border-gray-300 rounded-xl pl-10 pr-10 py-3 text-sm focus:outline-none focus:ring-2 focus:ring-finki-navy/30 focus:border-finki-navy transition-all bg-white"
        />
        {search && (
          <button onClick={() => setSearch("")} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M18 6 6 18M6 6l12 12" /></svg>
          </button>
        )}
      </div>

      {/* ── Loading ── */}
      {isLoading && (
        <div className="flex justify-center py-16">
          <div className="w-8 h-8 border-2 border-gray-200 border-t-finki-navy rounded-full animate-spin" />
        </div>
      )}

      {/* ── Empty (no exams loaded at all) ── */}
      {!isLoading && (!sessions || sessions.length === 0) && (
        <div className="text-center py-16">
          <svg className="mx-auto text-gray-300 mb-3" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <rect x="3" y="4" width="18" height="18" rx="2" /><path d="M16 2v4M8 2v4M3 10h18" />
          </svg>
          <p className="text-gray-500 text-sm">Сè уште нема внесен распоред за испити.</p>
        </div>
      )}

      {/* ── No search results ── */}
      {!isLoading && sessions && sessions.length > 0 && search && grouped.length === 0 && (
        <div className="text-center py-16">
          <p className="text-gray-500 text-sm">Нема резултати за &ldquo;{search}&rdquo;</p>
          <button onClick={() => setSearch("")} className="text-sm text-blue-600 hover:underline mt-2">Прикажи ги сите</button>
        </div>
      )}

      {/* ── Exams grouped by date ── */}
      {!isLoading && grouped.length > 0 && (
        <div className="space-y-8">
          {grouped.map(([date, dayExams]) => (
            <div key={date}>
              <div className="flex items-center gap-3 mb-3">
                <h2 className="text-sm font-bold text-finki-navy capitalize shrink-0">{formatDateHeading(date)}</h2>
                <div className="flex-1 h-px bg-gray-100" />
                <span className="text-xs text-gray-400 shrink-0">
                  {dayExams.length} {dayExams.length === 1 ? "испит" : "испити"}
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                {dayExams.map(exam => (
                  <div
                    key={exam.id}
                    className="bg-white border border-gray-200 rounded-xl px-4 py-3.5 hover:border-finki-navy hover:shadow-md transition-all"
                  >
                    <p className="text-sm font-semibold text-gray-900 leading-snug">{exam.subjectName}</p>
                    <div className="flex flex-wrap items-center gap-x-3 gap-y-1 mt-2 text-xs text-gray-500">
                      {exam.startTime && (
                        <span className="inline-flex items-center gap-1 font-medium text-gray-700">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></svg>
                          {formatTime(exam.startTime)}{exam.endTime ? `–${formatTime(exam.endTime)}` : ""}
                        </span>
                      )}
                      {exam.rooms && (
                        <span className="inline-flex items-center gap-1">
                          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 10c0 7-9 12-9 12s-9-5-9-12a9 9 0 0 1 18 0z" /><circle cx="12" cy="10" r="3" /></svg>
                          {exam.rooms}
                        </span>
                      )}
                    </div>
                    {exam.note && <p className="text-xs text-gray-400 mt-1.5">{exam.note}</p>}
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
