"use client";

import { useEffect } from "react";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

export interface MapPin {
  name: string;
  lat: number;
  lng: number;
  kind: "lab" | "amphitheatre" | "classroom" | "office" | "other" | "baraka";
}

const KIND_COLOR: Record<MapPin["kind"], string> = {
  lab:          "#10b981",
  amphitheatre: "#3b82f6",
  classroom:    "#8b5cf6",
  office:       "#f59e0b",
  baraka:       "#6b7280",
  other:        "#0d1b40",
};

function makeIcon(kind: MapPin["kind"]) {
  const color = KIND_COLOR[kind];
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16">
      <circle cx="8" cy="8" r="7" fill="${color}" stroke="white" stroke-width="2"/>
    </svg>`;
  return L.divIcon({
    html: `<div style="
      display:flex;align-items:center;gap:5px;white-space:nowrap;
      background:white;border:1.5px solid ${color};border-radius:6px;
      padding:3px 7px 3px 5px;box-shadow:0 1px 4px rgba(0,0,0,.18);
      font-family:system-ui,sans-serif;font-size:11px;font-weight:600;color:#111;
      line-height:1.2;cursor:pointer;
    ">${svg}&nbsp;<span style="max-width:130px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">{NAME}</span></div>`,
    className: "",
    iconAnchor: [8, 8],
  });
}

// Precompute icons
const ICONS: Record<MapPin["kind"], L.DivIcon> = {} as Record<MapPin["kind"], L.DivIcon>;
const KINDS: MapPin["kind"][] = ["lab","amphitheatre","classroom","office","baraka","other"];

function getIcon(pin: MapPin) {
  if (!ICONS[pin.kind]) {
    const color = KIND_COLOR[pin.kind];
    const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16"><circle cx="8" cy="8" r="7" fill="${color}" stroke="white" stroke-width="2"/></svg>`;
    ICONS[pin.kind] = L.divIcon({
      html: `<div style="display:flex;align-items:center;gap:4px;white-space:nowrap;background:white;border:1.5px solid ${color};border-radius:6px;padding:3px 7px 3px 5px;box-shadow:0 1px 4px rgba(0,0,0,.18);font-family:system-ui,sans-serif;font-size:11px;font-weight:600;color:#111;line-height:1.2;">${svg}<span>${pin.name}</span></div>`,
      className: "",
      iconAnchor: [10, 10],
    });
  }
  // Return a fresh icon per pin so name varies
  const color = KIND_COLOR[pin.kind];
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 16 16"><circle cx="8" cy="8" r="7" fill="${color}" stroke="white" stroke-width="2"/></svg>`;
  return L.divIcon({
    html: `<div style="display:flex;align-items:center;gap:4px;white-space:nowrap;background:white;border:1.5px solid ${color};border-radius:6px;padding:3px 7px 3px 5px;box-shadow:0 1px 4px rgba(0,0,0,.18);font-family:system-ui,sans-serif;font-size:11px;font-weight:600;color:#111;line-height:1.2;">${svg}<span>${pin.name}</span></div>`,
    className: "",
    iconAnchor: [10, 10],
  });
}

function SetView({ center, zoom }: { center: [number, number]; zoom: number }) {
  const map = useMap();
  useEffect(() => { map.setView(center, zoom); }, []);
  return null;
}

interface Props {
  pins: MapPin[];
  center?: [number, number];
  zoom?: number;
  height?: string;
  selectedPin?: string | null;
}

export default function FinkiMap({
  pins,
  center = [42.00460, 21.40945],
  zoom = 18,
  height = "100%",
  selectedPin,
}: Props) {
  return (
    <MapContainer
      center={center}
      zoom={zoom}
      style={{ height, width: "100%", borderRadius: 0 }}
      scrollWheelZoom
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      {pins.map((pin, i) => (
        <Marker key={i} position={[pin.lat, pin.lng]} icon={getIcon(pin)}>
          <Popup>
            <strong>{pin.name}</strong>
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}
