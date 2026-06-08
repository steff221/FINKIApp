"use client";

import { useState } from "react";
import useSWR from "swr";
import { getConsultations } from "@/lib/api";
import type { TeacherWithSlotsResponse } from "@/types";
import { formatTime } from "@/types";

export default function ConsultationsPage() {
  const [query, setQuery] = useState("");
  const [debouncedQuery, setDebouncedQuery] = useState("");

  const { data, isLoading } = useSWR<TeacherWithSlotsResponse[]>(
    ["/api/consultations", debouncedQuery],
    ([, q]) => getConsultations(q || undefined)
  );

  function handleSearch(e: React.ChangeEvent<HTMLInputElement>) {
    const val = e.target.value;
    setQuery(val);
    clearTimeout((window as Window & { _searchTimer?: number })._searchTimer);
    (window as Window & { _searchTimer?: number })._searchTimer = window.setTimeout(() => {
      setDebouncedQuery(val);
    }, 300);
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-finki-blue">Consultations</h1>
        <p className="text-sm text-gray-500">Next 6 days · refreshed daily</p>
      </div>

      <input
        type="text"
        placeholder="Search by professor name…"
        value={query}
        onChange={handleSearch}
        className="w-full max-w-md border rounded px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-finki-blue"
      />

      {isLoading && <p className="text-gray-500">Loading…</p>}

      {data && (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {data.map(({ teacher, slots }) => (
            <div key={teacher.id} className="bg-white border rounded-lg p-4">
              <p className="font-semibold text-gray-800 mb-1">
                {teacher.cyrillicName ?? teacher.consultationUsername}
              </p>

              {slots.length === 0 ? (
                <p className="text-xs text-gray-400">
                  No consultations scheduled in the next 6 days.
                </p>
              ) : (
                <div className="space-y-2 mt-2">
                  {slots.map(slot => (
                    <div key={slot.id} className="border-l-2 border-finki-light pl-2">
                      <p className="text-xs font-medium text-gray-700">
                        {slot.date}
                      </p>
                      <p className="text-xs text-gray-500">
                        {formatTime(slot.startTime)}–{formatTime(slot.endTime)}
                        {slot.room && ` · ${slot.room}`}
                      </p>
                      {slot.instructions && (
                        <p className="text-xs text-gray-400 mt-0.5">{slot.instructions}</p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {data && data.length === 0 && (
        <p className="text-gray-500">No professors found.</p>
      )}
    </div>
  );
}
