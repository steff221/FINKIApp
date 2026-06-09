"use client";

import { useState } from "react";
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
          <p className="text-sm text-gray-500 mt-1">
            Browse and filter every class — log in to build your own schedule
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          {slots && (
            <span className="text-sm text-gray-400">
              {slots.length} class{slots.length === 1 ? "" : "es"}
            </span>
          )}
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
