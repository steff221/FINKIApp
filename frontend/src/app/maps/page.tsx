"use client";

import { useMemo, useState } from "react";
import { LOCATIONS, type FinkiLocation } from "@/lib/locations";

// FINKI indoor/campus map (OpenLevelUp) — shows every room label
const MAP_URL = "https://map.finki.ukim.mk/?l=0#18/42.00465/21.40903";

const KIND_STYLE: Record<NonNullable<FinkiLocation["kind"]> | "default", { dot: string; label: string }> = {
  lab:         { dot: "bg-emerald-500", label: "Lab" },
  amphitheatre:{ dot: "bg-blue-500",    label: "Amphitheatre" },
  classroom:   { dot: "bg-violet-500",  label: "Classroom" },
  office:      { dot: "bg-amber-500",   label: "Office" },
  other:       { dot: "bg-gray-400",    label: "Other" },
  default:     { dot: "bg-gray-400",    label: "" },
};

export default function MapsPage() {
  const [query, setQuery] = useState("");
  const [open, setOpen] = useState<Set<string>>(new Set());

  function toggle(building: string) {
    setOpen(prev => {
      const next = new Set(prev);
      next.has(building) ? next.delete(building) : next.add(building);
      return next;
    });
  }

  const results = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return LOCATIONS;
    return LOCATIONS.filter(l =>
      [l.name, l.building, l.floor, l.note].filter(Boolean).join(" ").toLowerCase().includes(q)
    );
  }, [query]);

  // Group filtered results by building, preserving first-seen order
  const grouped = useMemo(() => {
    const map = new Map<string, typeof results>();
    results.forEach(l => {
      if (!map.has(l.building)) map.set(l.building, []);
      map.get(l.building)!.push(l);
    });
    return Array.from(map.entries());
  }, [results]);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-end gap-4">
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-finki-navy tracking-tight">Maps</h1>
          <p className="text-sm text-gray-500 mt-1">
            Find a room or hall, then locate it on the campus map
          </p>
        </div>
        <a
          href={MAP_URL}
          target="_blank"
          rel="noopener noreferrer"
          className="flex items-center gap-2 bg-finki-navy text-white px-4 py-2 rounded-xl text-sm font-semibold hover:bg-finki-mid transition-colors shadow-sm shrink-0"
        >
          <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M15 3h6v6M10 14 21 3M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6" />
          </svg>
          Open full map
        </a>
      </div>

      {/* Room directory */}
      <section className="bg-white rounded-2xl shadow-card border border-gray-100 overflow-hidden">
        <div className="px-5 py-4 border-b border-gray-100">
          <div className="relative max-w-sm">
            <svg
              className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 pointer-events-none"
              width="14" height="14" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"
            >
              <circle cx="11" cy="11" r="8" />
              <path d="m21 21-4.35-4.35" />
            </svg>
            <input
              type="text"
              placeholder="Find a room… e.g. ЛАБ 117, Амфитеатар, ТМФ 315"
              value={query}
              onChange={e => setQuery(e.target.value)}
              className="w-full bg-gray-50 rounded-xl pl-9 pr-4 py-2.5 text-sm placeholder-gray-400 border border-gray-200 focus:outline-none focus:ring-2 focus:ring-blue-400/40 focus:border-blue-400 transition-all"
            />
          </div>
        </div>

        {LOCATIONS.length === 0 ? (
          <div className="px-5 py-10 text-center">
            <p className="text-sm text-gray-500 font-medium">No locations added yet</p>
            <p className="text-xs text-gray-400 mt-1">
              Send the campus / floor screenshots and they’ll be listed here.
            </p>
          </div>
        ) : results.length === 0 ? (
          <div className="px-5 py-10 text-center text-sm text-gray-400">
            No rooms match “{query}”.
          </div>
        ) : (
          <div className="max-h-[60vh] overflow-auto divide-y divide-gray-100">
            {grouped.map(([building, rooms]) => {
              const isOpen = query.trim() !== "" || open.has(building);
              return (
                <div key={building}>
                  <button
                    type="button"
                    onClick={() => toggle(building)}
                    className="w-full sticky top-0 z-10 bg-white hover:bg-gray-50 px-5 py-3 flex items-center gap-3 transition-colors text-left"
                  >
                    <svg
                      width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
                      className={`text-gray-400 shrink-0 transition-transform duration-200 ${isOpen ? "rotate-90" : ""}`}
                    >
                      <path d="m9 18 6-6-6-6" />
                    </svg>
                    <span className="text-sm font-bold text-gray-800 flex-1">{building}</span>
                    <span className="text-xs font-medium text-gray-400 bg-gray-100 rounded-full px-2 py-0.5">{rooms.length}</span>
                  </button>

                  {isOpen && (
                    <ul className="divide-y divide-gray-50 bg-gray-50/30">
                      {rooms.map((loc, i) => {
                        const style = KIND_STYLE[loc.kind ?? "default"];
                        return (
                          <li key={i} className="flex items-center gap-3 pl-12 pr-5 py-2.5 hover:bg-blue-50/50 transition-colors">
                            <span className={`w-2.5 h-2.5 rounded-full shrink-0 ${style.dot}`} title={style.label} />
                            <div className="min-w-0 flex-1">
                              <p className="font-semibold text-sm text-gray-900 truncate">{loc.name}</p>
                              {loc.note && <p className="text-xs text-gray-400 mt-0.5">{loc.note}</p>}
                            </div>
                            {loc.floor && (
                              <span className="text-xs text-gray-500 bg-white border border-gray-200 rounded-full px-2.5 py-0.5 shrink-0">
                                {loc.floor}
                              </span>
                            )}
                          </li>
                        );
                      })}
                    </ul>
                  )}
                </div>
              );
            })}
          </div>
        )}
      </section>

      {/* Embedded FINKI campus / indoor map */}
      <div className="rounded-2xl overflow-hidden shadow-card border border-gray-100 bg-white">
        <iframe
          src={MAP_URL}
          title="FINKI campus map"
          className="w-full h-[70vh] min-h-[480px] border-0 block"
        />
      </div>
      <p className="text-xs text-gray-400 text-center">
        Map not loading? In Safari, disable “Prevent Cross-Site Tracking”, or use the{" "}
        <a href={MAP_URL} target="_blank" rel="noopener noreferrer" className="text-finki-mid font-medium hover:underline">
          Open full map
        </a>{" "}
        button above.
      </p>
    </div>
  );
}
