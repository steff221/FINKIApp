"use client";

import { useState, useEffect, useCallback } from "react";
import useSWR from "swr";
import { getFilters, getSlots } from "@/lib/api";
import type { TimetableFilters, TimetableFiltersResponse } from "@/types";
import FilterPanel from "@/components/timetable/FilterPanel";
import TimetableGrid from "@/components/timetable/TimetableGrid";
import SchedulePanel from "@/components/schedule/SchedulePanel";
import { useSchedule } from "@/hooks/useSchedule";

const EMPTY_FILTERS: TimetableFilters = {
  year: null,
  programmeCode: null,
  teacherId: null,
  subjectId: null,
  classroomId: null,
  lessonType: null,
  dayOfWeek: null,
  editionNumber: null,   // null → backend defaults to the current edition
};

function GridSkeleton() {
  return (
    <div className="space-y-8">
      {[3, 2].map((rows, s) => (
        <section key={s}>
          <div className="flex items-center gap-3 mb-3">
            <div className="h-3 w-20 bg-gray-200 rounded animate-pulse" />
            <div className="flex-1 h-px bg-gray-200" />
          </div>
          <div className="space-y-2.5">
            {Array.from({ length: rows }).map((_, i) => (
              <div key={i} className="bg-white rounded-xl shadow-card h-[88px] animate-pulse" />
            ))}
          </div>
        </section>
      ))}
    </div>
  );
}

export default function TimetablePage() {
  const [filters, setFilters] = useState<TimetableFilters>(EMPTY_FILTERS);
  const [showSchedule, setShowSchedule] = useState(false);
  const [copied, setCopied] = useState(false);

  const copyLink = useCallback(() => {
    navigator.clipboard.writeText(window.location.href).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }, []);

  // ── Shareable URL: hydrate filters from the query string on mount … ──────────
  useEffect(() => {
    const sp = new URLSearchParams(window.location.search);
    if ([...sp.keys()].length === 0) return;
    const numOr = (k: string) => (sp.get(k) != null ? Number(sp.get(k)) : null);
    setFilters({
      year:          numOr("year"),
      programmeCode: sp.get("programme"),
      teacherId:     numOr("teacher"),
      subjectId:     numOr("subject"),
      classroomId:   numOr("room"),
      lessonType:    sp.get("type"),
      dayOfWeek:     numOr("day"),
      editionNumber: sp.get("semester"),
    });
  }, []);

  // … and reflect filter changes back into the URL (bookmarkable / shareable)
  useEffect(() => {
    const sp = new URLSearchParams();
    if (filters.year != null)        sp.set("year", String(filters.year));
    if (filters.programmeCode)       sp.set("programme", filters.programmeCode);
    if (filters.teacherId != null)   sp.set("teacher", String(filters.teacherId));
    if (filters.subjectId != null)   sp.set("subject", String(filters.subjectId));
    if (filters.classroomId != null) sp.set("room", String(filters.classroomId));
    if (filters.lessonType)          sp.set("type", filters.lessonType);
    if (filters.dayOfWeek != null)   sp.set("day", String(filters.dayOfWeek));
    if (filters.editionNumber)       sp.set("semester", filters.editionNumber);
    const qs = sp.toString();
    window.history.replaceState(null, "", qs ? `?${qs}` : window.location.pathname);
  }, [filters]);

  const { data: filterOptions } = useSWR<TimetableFiltersResponse>(
    "/api/timetable/filters",
    getFilters
  );

  const { data: slots, isLoading } = useSWR(
    ["/api/timetable/slots", filters],
    ([, f]) => getSlots(f),
    { keepPreviousData: true }
  );

  const schedule = useSchedule();

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end gap-4">
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-finki-navy tracking-tight">Class Timetable</h1>
    
        </div>

        <div className="flex items-center gap-3 shrink-0">
          {slots && (
            <span className="text-sm text-gray-400">
              {slots.length} class{slots.length === 1 ? "" : "es"}
            </span>
          )}
          <button
            onClick={copyLink}
            title="Copy shareable link"
            className="flex items-center gap-1.5 px-3 py-2 rounded-xl text-sm font-medium border border-gray-200 text-gray-600 hover:border-finki-navy hover:text-finki-navy transition-colors"
          >
            {copied ? (
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M20 6 9 17l-5-5"/></svg>
            ) : (
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"/><path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"/></svg>
            )}
            {copied ? "Copied!" : "Share"}
          </button>
          {schedule.loggedIn && (
            <button
              onClick={() => setShowSchedule(!showSchedule)}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-sm font-semibold transition-colors shadow-sm ${
                showSchedule
                  ? "bg-blue-50 text-finki-navy border border-blue-200"
                  : "bg-finki-navy text-white hover:bg-finki-mid"
              }`}
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <rect x="3" y="4" width="18" height="18" rx="2" />
                <path d="M16 2v4M8 2v4M3 10h18" />
              </svg>
              {showSchedule ? "Hide schedule" : "My schedule"}
              {schedule.slotIds.size > 0 && (
                <span className={`text-xs font-bold rounded-full min-w-[18px] h-[18px] px-1 flex items-center justify-center ${
                  showSchedule ? "bg-finki-navy text-white" : "bg-white/20 text-white"
                }`}>
                  {schedule.slotIds.size}
                </span>
              )}
            </button>
          )}
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-5">
        <div className="w-full lg:w-72 shrink-0">
          <div className="lg:sticky lg:top-20">
            <FilterPanel
              filters={filters}
              options={filterOptions}
              onChange={setFilters}
              onReset={() => setFilters(EMPTY_FILTERS)}
            />
          </div>
        </div>

        <div className="flex-1 min-w-0">
          {isLoading && !slots ? (
            <GridSkeleton />
          ) : slots ? (
            <TimetableGrid slots={slots} schedule={schedule} />
          ) : null}
        </div>

        {showSchedule && (
          <div className="w-full xl:w-80 shrink-0">
            <div className="xl:sticky xl:top-20">
              <SchedulePanel schedule={schedule} />
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
