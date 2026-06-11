"use client";

import { useState, useMemo } from "react";
import Link from "next/link";
import useSWR from "swr";
import { getConsultations, getMyConsultationBookings } from "@/lib/api";
import { getAuth } from "@/lib/auth";
import type { TeacherWithSlotsResponse, ConsultationSlotResponse } from "@/types";
import { formatTime } from "@/types";

const MK_DAYS_SHORT = ["Нед", "Пон", "Вто", "Сре", "Чет", "Пет", "Саб"];
const MK_DAYS_LONG  = ["Недела", "Понеделник", "Вторник", "Среда", "Четврток", "Петок", "Сабота"];

function getWeekDates(offset: number): Date[] {
  const today = new Date();
  const dow   = today.getDay();
  const mon   = new Date(today);
  mon.setDate(today.getDate() - (dow === 0 ? 6 : dow - 1) + offset * 7);
  return Array.from({ length: 5 }, (_, i) => {
    const d = new Date(mon);
    d.setDate(mon.getDate() + i);
    return d;
  });
}

function sameDay(a: Date, b: Date) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}

function formatWeekRange(dates: Date[]) {
  const f = dates[0], l = dates[4];
  return `${f.getDate()}.${f.getMonth() + 1} – ${l.getDate()}.${l.getMonth() + 1}.${l.getFullYear()}`;
}

export default function ConsultationsPage() {
  const auth = typeof window !== "undefined" ? getAuth() : null;
  const [search, setSearch]         = useState("");
  const [weekOffset, setWeekOffset] = useState(0);
  const weekDates = getWeekDates(weekOffset);
  const today     = new Date();

  const { data, isLoading } = useSWR<TeacherWithSlotsResponse[]>(
    "/api/consultations",
    () => getConsultations()
  );

  const { data: myBookedIds } = useSWR<number[]>(
    auth ? "/api/consultations/bookings/mine" : null,
    () => getMyConsultationBookings()
  );

  // All slots flat
  const allSlots = useMemo<ConsultationSlotResponse[]>(() =>
    data ? data.flatMap(d => d.slots) : [], [data]
  );

  // Booked slots with teacher info, grouped by date
  const bookedSlots = useMemo(() => {
    if (!myBookedIds || myBookedIds.length === 0) return [];
    return allSlots.filter(s => myBookedIds.includes(s.id));
  }, [allSlots, myBookedIds]);

  const bookedForDay = (date: Date) =>
    bookedSlots.filter(s => {
      const [y, m, d] = s.date.split("-").map(Number);
      return sameDay(new Date(y, m - 1, d), date);
    });

  // Professor list filtered + grouped
  const grouped = useMemo(() => {
    if (!data) return [] as [string, TeacherWithSlotsResponse[]][];
    const q = search.trim().toLowerCase();
    const filtered = q
      ? data.filter(({ teacher }) => {
          const name = (teacher.cyrillicName ?? teacher.consultationUsername ?? "").toLowerCase();
          return name.includes(q) || (teacher.consultationUsername ?? "").toLowerCase().includes(q);
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
            {totalCount} {totalCount === 1 ? "професор" : "професори"}
          </span>
        )}
      </div>

      {/* ── My booked consultations ── */}
      {auth && (
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <h2 className="text-sm font-bold text-gray-700 uppercase tracking-wide">Мои пријавени консултации</h2>
            <div className="flex items-center gap-2">
              <button
                onClick={() => setWeekOffset(w => w - 1)}
                className="w-7 h-7 flex items-center justify-center rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors text-gray-500"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M15 18l-6-6 6-6" /></svg>
              </button>
              <span className="text-xs font-medium text-gray-600 min-w-[130px] text-center">{formatWeekRange(weekDates)}</span>
              <button
                onClick={() => setWeekOffset(w => w + 1)}
                className="w-7 h-7 flex items-center justify-center rounded-lg border border-gray-200 hover:bg-gray-50 transition-colors text-gray-500"
              >
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M9 18l6-6-6-6" /></svg>
              </button>
            </div>
          </div>

          <div className="grid grid-cols-5 gap-2">
            {weekDates.map((date, i) => {
              const isToday   = sameDay(date, today);
              const daySlots  = bookedForDay(date);
              return (
                <div
                  key={i}
                  className={`rounded-xl border p-3 min-h-[90px] transition-all ${
                    isToday
                      ? "bg-finki-navy border-finki-navy text-white"
                      : "bg-white border-gray-200"
                  }`}
                >
                  <div className={`text-[10px] font-bold uppercase tracking-wider mb-0.5 ${isToday ? "text-blue-200" : "text-gray-400"}`}>
                    {MK_DAYS_SHORT[date.getDay()]}
                  </div>
                  <div className={`text-sm font-bold mb-2 ${isToday ? "text-white" : "text-gray-800"}`}>
                    {date.getDate()}.{date.getMonth() + 1}
                  </div>
                  {daySlots.length === 0 ? (
                    <p className={`text-[10px] ${isToday ? "text-blue-300" : "text-gray-300"}`}>—</p>
                  ) : (
                    <div className="space-y-1.5">
                      {daySlots.map(slot => (
                        <Link
                          key={slot.id}
                          href={`/consultations/professor/${slot.teacher.id}?name=${encodeURIComponent(slot.teacher.cyrillicName ?? "")}`}
                          className={`block rounded-lg px-2 py-1.5 text-[10px] leading-tight transition-colors ${
                            isToday
                              ? "bg-white/20 hover:bg-white/30 text-white"
                              : "bg-finki-navy/5 hover:bg-finki-navy/10 text-finki-navy"
                          }`}
                        >
                          <div className="font-bold">{formatTime(slot.startTime)}</div>
                          <div className="truncate opacity-80">{slot.teacher.cyrillicName?.split(" ")[0]}</div>
                        </Link>
                      ))}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          {bookedSlots.length === 0 && !isLoading && (
            <p className="text-center text-gray-400 text-xs py-1">Немате пријавени консултации оваа недела.</p>
          )}
        </div>
      )}

      {auth && <hr className="border-gray-100" />}

      {/* ── Search ── */}
      <div className="relative">
        <svg className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round">
          <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
        </svg>
        <input
          type="text"
          placeholder="Пребарај по имe на професор…"
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

      {/* ── No results ── */}
      {!isLoading && search && grouped.length === 0 && (
        <div className="text-center py-16">
          <svg className="mx-auto text-gray-300 mb-3" width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <circle cx="11" cy="11" r="8" /><path d="m21 21-4.35-4.35" />
          </svg>
          <p className="text-gray-500 text-sm">Нема резултати за &ldquo;{search}&rdquo;</p>
          <button onClick={() => setSearch("")} className="text-sm text-blue-600 hover:underline mt-2">Прикажи ги сите</button>
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
                  const isBooked = bookedSlots.some(s => s.teacher.id === teacher.id);
                  return (
                    <Link
                      key={teacher.id}
                      href={`/consultations/professor/${teacher.id}?name=${encodeURIComponent(name)}`}
                      className="group flex items-center gap-3 bg-white border border-gray-200 rounded-xl px-4 py-3.5 hover:border-finki-navy hover:shadow-md transition-all"
                    >
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-gray-900 leading-snug truncate">{name}</p>
                        <div className="flex items-center gap-2 mt-0.5">
                          {slots.length > 0 && (
                            <p className="text-xs text-gray-400">
                              {slots.length} {slots.length === 1 ? "термин" : "термини"}
                            </p>
                          )}
                          {isBooked && (
                            <span className="inline-flex items-center gap-1 text-[10px] font-semibold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                              <svg width="8" height="8" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M20 6 9 17l-5-5" /></svg>
                              Пријавени
                            </span>
                          )}
                        </div>
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
