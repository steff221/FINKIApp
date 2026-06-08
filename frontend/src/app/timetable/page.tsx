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
};

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
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-finki-blue">Class Timetable</h1>
        {schedule.loggedIn && (
          <button
            onClick={() => setShowSchedule(!showSchedule)}
            className="bg-finki-blue text-white px-4 py-2 rounded text-sm font-medium hover:bg-finki-light"
          >
            {showSchedule ? "Hide" : "My Schedule"}{" "}
            {schedule.slotIds.size > 0 && `(${schedule.slotIds.size})`}
          </button>
        )}
      </div>

      <div className="flex gap-4">
        <div className="w-72 shrink-0">
          <FilterPanel
            filters={filters}
            options={filterOptions}
            onChange={setFilters}
            onReset={() => setFilters(EMPTY_FILTERS)}
          />
        </div>

        <div className="flex-1 min-w-0">
          {isLoading && <p className="text-gray-500">Loading…</p>}
          {slots && (
            <TimetableGrid
              slots={slots}
              schedule={schedule}
            />
          )}
        </div>

        {showSchedule && (
          <div className="w-80 shrink-0">
            <SchedulePanel schedule={schedule} />
          </div>
        )}
      </div>
    </div>
  );
}
