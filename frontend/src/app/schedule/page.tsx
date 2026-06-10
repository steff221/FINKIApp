"use client";

import { useState, useCallback, useMemo, useEffect, useRef } from "react";
import useSWR, { mutate as globalMutate } from "swr";
import Image from "next/image";
import WeeklyCalendar from "@/components/schedule/WeeklyCalendar";
import AddEntryModal from "@/components/schedule/AddEntryModal";
import AuthModal from "@/components/ui/AuthModal";
import ErrorBoundary from "@/components/ui/ErrorBoundary";
import type { CustomEntryResponse, CustomEntryRequest } from "@/types";
import { getCustomEntries, createCustomEntry, updateCustomEntry, deleteCustomEntry, getIcsUrl } from "@/lib/api";
import { getAuth } from "@/lib/auth";

const SWR_KEY = "/schedule/custom";

export default function SchedulePage() {
  const [auth, setAuth] = useState(() => typeof window !== "undefined" ? getAuth() : null);
  const [showReauth, setShowReauth] = useState(false);
  const [toast, setToast] = useState<string | null>(null);
  const toastTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => () => { if (toastTimerRef.current) clearTimeout(toastTimerRef.current); }, []);

  const showToast = useCallback((msg: string) => {
    if (toastTimerRef.current) clearTimeout(toastTimerRef.current);
    setToast(msg);
    toastTimerRef.current = setTimeout(() => setToast(null), 3000);
  }, []);

  useEffect(() => {
    const onExpired = () => { setAuth(null); setShowReauth(true); };
    window.addEventListener("finki:session-expired", onExpired);
    return () => window.removeEventListener("finki:session-expired", onExpired);
  }, []);

  const { data: entries = [], isLoading, error: scheduleError } = useSWR<CustomEntryResponse[]>(
    auth ? SWR_KEY : null,
    () => getCustomEntries(),
    { shouldRetryOnError: false }
  );

  // Entries on the same day whose time ranges overlap
  const conflictIds = useMemo(() => {
    const ids = new Set<number>();
    const byDay: Record<number, CustomEntryResponse[]> = {};
    entries.forEach(e => { (byDay[e.dayOfWeek] ??= []).push(e); });
    Object.values(byDay).forEach(list => {
      for (let i = 0; i < list.length; i++) {
        for (let j = i + 1; j < list.length; j++) {
          const a = list[i], b = list[j];
          if (a.startTime < b.endTime && b.startTime < a.endTime) { ids.add(a.id); ids.add(b.id); }
        }
      }
    });
    return ids;
  }, [entries]);

  const [modal, setModal] = useState<{
    open: boolean;
    entry: CustomEntryResponse | null;
    defaultDay: number;
    defaultStart: string;
    defaultLab: boolean;
    prefill?: Partial<CustomEntryRequest>;
  }>({ open: false, entry: null, defaultDay: 0, defaultStart: "08:00", defaultLab: false });

  function openAdd(day: number, startTime: string) {
    setModal({ open: true, entry: null, defaultDay: day, defaultStart: startTime, defaultLab: false, prefill: undefined });
  }

  function openAddLab() {
    setModal({ open: true, entry: null, defaultDay: 0, defaultStart: "08:00", defaultLab: true, prefill: undefined });
  }

  function openEdit(entry: CustomEntryResponse) {
    setModal({ open: true, entry, defaultDay: entry.dayOfWeek, defaultStart: entry.startTime, defaultLab: false, prefill: undefined });
  }

  function handleDuplicate(data: CustomEntryRequest) {
    closeModal();
    setModal({ open: true, entry: null, defaultDay: data.dayOfWeek, defaultStart: data.startTime, defaultLab: false, prefill: data });
  }

  function closeModal() {
    setModal(m => ({ ...m, open: false }));
  }

  const handleSave = useCallback(async (data: CustomEntryRequest) => {
    if (modal.entry) {
      await updateCustomEntry(modal.entry.id, data);
    } else {
      await createCustomEntry(data);
    }
    await globalMutate(SWR_KEY);
    showToast(modal.entry ? "Entry updated" : "Entry added");
  }, [modal.entry, showToast]);

  const handleDelete = useCallback(async () => {
    if (!modal.entry) return;
    await deleteCustomEntry(modal.entry.id);
    await globalMutate(SWR_KEY);
    showToast("Entry deleted");
  }, [modal.entry, showToast]);

  if (!auth && !showReauth) {
    return (
      <div className="flex items-center justify-center py-32">
        <div className="text-center space-y-4">
          <div className="w-16 h-16 bg-blue-100 rounded-2xl flex items-center justify-center mx-auto">
            <Image src="/Callendar.png" alt="" width={32} height={32} className="object-contain opacity-70" />
          </div>
          <h1 className="text-xl font-bold text-gray-900">My Schedule</h1>
          <p className="text-gray-500 text-sm">Please log in to manage your personal calendar.</p>
        </div>
      </div>
    );
  }

  return (
    <ErrorBoundary>
      <div className="py-2">
        {/* Header */}
        <div className="flex items-center justify-between mb-6">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-finki-navy rounded-xl flex items-center justify-center shadow-sm">
              <Image src="/Callendar.png" alt="" width={20} height={20} className="object-contain brightness-0 invert" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-gray-900">My Schedule</h1>
              <p className="text-sm text-gray-500">
                {entries.length === 0
                  ? "Click any time slot to add a subject"
                  : `${entries.length} entr${entries.length === 1 ? "y" : "ies"}`}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            {entries.length > 0 && (
              <a
                href={getIcsUrl()}
                title="Download your schedule as a calendar file (.ics)"
                className="flex items-center gap-2 bg-white text-gray-600 border border-gray-200 px-3.5 py-2.5 rounded-xl text-sm font-semibold hover:bg-gray-50 hover:text-finki-navy transition-colors shadow-sm"
              >
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                  <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                  <polyline points="7 10 12 15 17 10" />
                  <line x1="12" y1="15" x2="12" y2="3" />
                </svg>
                Export
              </a>
            )}
            <button
              onClick={openAddLab}
              className="group w-44 flex items-center gap-2.5 bg-white text-emerald-700 border border-emerald-200 pl-1.5 pr-4 py-1.5 rounded-xl text-sm font-semibold hover:bg-emerald-50 hover:border-emerald-300 transition-colors shadow-sm"
            >
              <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-emerald-50 group-hover:bg-white transition-colors">
                <Image src="/Lab.png" alt="" width={20} height={20} className="object-contain" />
              </span>
              <span className="flex items-center gap-1">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                  <path d="M12 5v14M5 12h14" />
                </svg>
                Add lab
              </span>
            </button>
            <button
              onClick={() => openAdd(0, "08:00")}
              className="group w-44 flex items-center gap-2.5 bg-finki-navy text-white pl-1.5 pr-4 py-1.5 rounded-xl text-sm font-semibold hover:bg-finki-mid transition-colors shadow-sm"
            >
              <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-white/10 group-hover:bg-white/20 transition-colors">
                <Image src="/Subject.png" alt="" width={20} height={20} className="object-contain brightness-0 invert" />
              </span>
              <span className="flex items-center gap-1">
                <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                  <path d="M12 5v14M5 12h14" />
                </svg>
                Add subject
              </span>
            </button>
          </div>
        </div>

        {/* Legend */}
        <div className="flex flex-wrap gap-2 mb-4">
          {[
            { label: "Lecture",           color: "bg-blue-500" },
            { label: "Auditory Exercise", color: "bg-violet-500" },
            { label: "Combined",          color: "bg-amber-500" },
          ].map(({ label, color }) => (
            <span key={label} className="flex items-center gap-1.5 text-xs text-gray-500 bg-white rounded-full px-3 py-1 border border-gray-100">
              <span className={`w-2 h-2 rounded-full ${color}`} />
              {label}
            </span>
          ))}
          <span className="text-xs text-gray-400 ml-auto self-center hidden sm:block">
            Click a slot to add · Click an entry to edit
          </span>
        </div>

        {/* Conflict warning */}
        {conflictIds.size > 0 && (
          <div className="flex items-center gap-3 bg-white rounded-xl px-4 py-3 mb-4 shadow-card border-l-4 border-l-red-500">
            <span className="shrink-0 w-9 h-9 rounded-full bg-red-100 flex items-center justify-center">
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" className="text-red-600">
                <path d="M12 9v4M12 17h.01M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
              </svg>
            </span>
            <div className="min-w-0">
              <p className="text-sm font-semibold text-gray-900">
                Scheduling conflict
                <span className="ml-2 text-xs font-bold text-red-600 bg-red-50 rounded-full px-2 py-0.5">
                  {conflictIds.size}
                </span>
              </p>
              <p className="text-xs text-gray-500 mt-0.5">
                Overlapping entries are outlined in red on the calendar below.
              </p>
            </div>
          </div>
        )}

        {/* Calendar */}
        {isLoading ? (
          <div className="bg-white rounded-2xl border border-gray-100 h-96 flex items-center justify-center">
            <div className="flex flex-col items-center gap-3">
              <div className="w-8 h-8 border-2 border-blue-200 border-t-blue-500 rounded-full animate-spin" />
              <p className="text-sm text-gray-400">Loading your schedule…</p>
            </div>
          </div>
        ) : scheduleError ? (
          <div className="bg-white rounded-2xl border border-gray-100 h-48 flex items-center justify-center">
            <div className="text-center space-y-2">
              <p className="text-sm font-semibold text-gray-700">Failed to load your schedule</p>
              <p className="text-xs text-gray-400">{scheduleError instanceof Error ? scheduleError.message : "Please refresh and try again."}</p>
              <button
                onClick={() => globalMutate(SWR_KEY)}
                className="mt-1 text-xs text-finki-mid font-semibold hover:underline"
              >
                Retry
              </button>
            </div>
          </div>
        ) : entries.length === 0 ? (
          <div className="bg-white rounded-2xl border border-gray-100 flex flex-col items-center justify-center py-16 gap-4">
            <div className="w-16 h-16 bg-gray-50 rounded-2xl flex items-center justify-center">
              <Image src="/Callendar.png" alt="" width={32} height={32} className="object-contain opacity-25" />
            </div>
            <div className="text-center">
              <p className="text-sm font-semibold text-gray-700">Your schedule is empty</p>
              <p className="text-xs text-gray-400 mt-1">Add your subjects to see them on the calendar</p>
            </div>
            <div className="flex gap-2">
              <button
                onClick={openAddLab}
                className="flex items-center gap-1.5 bg-white text-emerald-700 border border-emerald-200 px-3.5 py-2 rounded-xl text-sm font-semibold hover:bg-emerald-50 transition-colors"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M12 5v14M5 12h14" /></svg>
                Add lab
              </button>
              <button
                onClick={() => openAdd(0, "08:00")}
                className="flex items-center gap-1.5 bg-finki-navy text-white px-3.5 py-2 rounded-xl text-sm font-semibold hover:bg-finki-mid transition-colors"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="M12 5v14M5 12h14" /></svg>
                Add subject
              </button>
            </div>
          </div>
        ) : (
          <WeeklyCalendar entries={entries} conflictIds={conflictIds} onAdd={openAdd} onEdit={openEdit} />
        )}
      </div>

      {modal.open && (
        <AddEntryModal
          initial={modal.entry}
          prefill={modal.prefill}
          defaultDay={modal.defaultDay}
          defaultStart={modal.defaultStart}
          defaultLab={modal.defaultLab}
          onSave={handleSave}
          onDelete={modal.entry ? handleDelete : undefined}
          onDuplicate={modal.entry ? handleDuplicate : undefined}
          onClose={closeModal}
        />
      )}
      {showReauth && <AuthModal onClose={() => setShowReauth(false)} />}

      {toast && (
        <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[200] bg-gray-900 text-white text-sm font-medium px-4 py-2.5 rounded-xl shadow-xl flex items-center gap-2 pointer-events-none">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <path d="M20 6 9 17l-5-5" />
          </svg>
          {toast}
        </div>
      )}
    </ErrorBoundary>
  );
}
