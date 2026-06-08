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

  if (isLoading) return <p className="text-xs text-gray-400">Loading consultations…</p>;

  if (!data || data.length === 0) {
    return (
      <p className="text-xs text-gray-400">
        No upcoming consultations for {teacherName} in the next 6 days.
      </p>
    );
  }

  return (
    <div>
      <p className="text-xs font-medium text-gray-600 mb-1">
        Upcoming consultations — {teacherName}:
      </p>
      <div className="space-y-1">
        {data.map(slot => (
          <div key={slot.id} className="text-xs text-gray-700 flex gap-2">
            <span className="font-medium">{slot.date}</span>
            <span>{formatTime(slot.startTime)}–{formatTime(slot.endTime)}</span>
            {slot.room && <span className="text-gray-500">· {slot.room}</span>}
            {slot.instructions && (
              <span className="text-gray-400 truncate max-w-xs" title={slot.instructions}>
                · {slot.instructions}
              </span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
