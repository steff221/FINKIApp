"use client";

import useSWR from "swr";
import { getConsultationsForTeacher } from "@/lib/api";
import type { ConsultationSlotResponse } from "@/types";
import { formatTime } from "@/types";

interface Props { teacherId: number; teacherName: string; }

export default function ConsultationInline({ teacherId, teacherName }: Props) {
  const { data, isLoading } = useSWR<ConsultationSlotResponse[]>(
    `/api/consultations/teacher/${teacherId}`,
    () => getConsultationsForTeacher(teacherId)
  );

  if (isLoading) {
    return (
      <div className="flex items-center gap-2 text-xs text-gray-400">
        <div className="w-3 h-3 rounded-full border-2 border-gray-200 border-t-finki-mid animate-spin" />
        Loading consultations…
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <p className="text-xs text-gray-400 italic">
        No upcoming consultations for {teacherName} in the next 6 days.
      </p>
    );
  }

  return (
    <div>
      <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">
        Upcoming — {teacherName}
      </p>
      <div className="space-y-1.5">
        {data.map(slot => (
          <div key={slot.id} className="flex items-start gap-2.5">
            <span className="shrink-0 bg-blue-50 text-blue-700 text-xs font-semibold rounded-md px-2 py-0.5 tabular-nums">
              {slot.date}
            </span>
            <div className="text-xs text-gray-700">
              <span className="font-medium tabular-nums">
                {formatTime(slot.startTime)}–{formatTime(slot.endTime)}
              </span>
              {slot.room && <span className="text-gray-400"> · {slot.room}</span>}
              {slot.instructions && (
                <p className="text-gray-400 mt-0.5">{slot.instructions}</p>
              )}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
