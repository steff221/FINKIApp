import Link from "next/link";
import Image from "next/image";

const CARDS = [
  {
    href: "/timetable",
    title: "Распоред",
    desc: "Прегледајте и филтрирајте ги сите часови за двата семестри.",
    img: "/schedule.png",
    chip: "bg-blue-50",
  },
  {
    href: "/consultations",
    title: "Консултации",
    desc: "Термините за консултации на профeсорите за тековната недела.",
    img: "/clock.png",
    chip: "bg-violet-50",
  },
  {
    href: "/schedule",
    title: "Мој Распоред",
    desc: "Изградете ваш личен неделен календар и извезете го.",
    img: "/calendar.png",
    chip: "bg-emerald-50",
  },
  {
    href: "/maps",
    title: "Мапа",
    desc: "Пронајдете простории, лаборатории и амфитеатри на кампусот.",
    img: "/campus%20map.png",
    chip: "bg-amber-50",
  },
];

export default function Home() {
  return (
    <div className="space-y-8">
      {/* Hero */}
      <section className="text-center py-8">
        <h1 className="text-3xl sm:text-4xl font-bold text-finki-navy tracking-tight">
          ФИНКИ Распоред
        </h1>
        <p className="text-gray-500 mt-3 max-w-xl mx-auto">
          Едно место за вашиот распоред, консултации, личен неделен календар и карта на кампусот.
        </p>
      </section>

      {/* Quick links */}
      <section className="grid gap-4 sm:grid-cols-2 max-w-3xl mx-auto">
        {CARDS.map(card => (
          <Link
            key={card.href}
            href={card.href}
            className="group bg-white rounded-2xl shadow-card hover:shadow-card-hover border border-gray-100 p-5 flex items-center gap-4 transition-all duration-200 hover:-translate-y-0.5"
          >
            <span className={`shrink-0 w-12 h-12 rounded-xl ${card.chip} flex items-center justify-center`}>
              <Image src={card.img} alt="" width={24} height={24} className="object-contain" />
            </span>
            <div className="min-w-0 flex-1">
              <p className="font-bold text-gray-900">{card.title}</p>
              <p className="text-sm text-gray-500 mt-0.5">{card.desc}</p>
            </div>
            <svg
              width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"
              className="text-gray-300 group-hover:text-finki-mid group-hover:translate-x-0.5 transition-all shrink-0"
            >
              <path d="m9 18 6-6-6-6" />
            </svg>
          </Link>
        ))}
      </section>
    </div>
  );
}
