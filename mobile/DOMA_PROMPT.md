# Task: build the "Дома" home screen

Work in `~/Desktop/FINKIApp/mobile` (Flutter + Riverpod + go_router).

Implement a new **Дома** (home) screen matching the Figma frame `0 Дома`:
https://www.figma.com/design/NeSsT6CobQt8vDMciWsOqg/?node-id=24-192

## Hard constraints — read first

**Do NOT touch these files. At all.**
- `lib/features/auth/splash_screen.dart` — the loading screen stays exactly as is
- `lib/core/widgets/finki_loader.dart`
- `lib/core/widgets/finki_ball.dart`
- `lib/features/map/map_screen.dart` — leave the map completely alone

**Keep the map reachable.** `/map` keeps its route and keeps its `Карта` tab in the
bottom nav. Do not remove it.

**Do not invent colors or text styles.** Everything you need already exists in
`lib/core/theme/app_colors.dart` and `lib/core/theme/lesson_type.dart`. Use those
constants by name — no new `Color(0x...)` literals anywhere in this task.

**Use the SVGs in `assets/`** for nav icons, via `flutter_svg` + `ColorFilter.mode(..., BlendMode.srcIn)`,
exactly like `home_shell.dart` already does. One new icon is needed — see step 1.

## Step 1 — the Дома nav icon

`assets/` has no home icon, so create `assets/home.svg` with exactly this content
(it is the house shape from the Figma design, traced at the nav's 1.8pt stroke weight):

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
     fill="none" stroke="#6B7280" stroke-width="1.8"
     stroke-linecap="round" stroke-linejoin="round">
  <path d="M2.7 10.9 L12 3.5 L21.3 10.9 L21.3 19 Q21.3 20.4 19.9 20.4 L4.1 20.4 Q2.7 20.4 2.7 19 Z"/>
</svg>
```

Register it under `flutter: assets:` in `pubspec.yaml`. The stroke color is
irrelevant at runtime — `BlendMode.srcIn` overrides it — but keep it so the file
previews sensibly.

## Step 2 — bottom nav: 5 tabs

Edit `lib/features/shell/home_shell.dart`. Final tab order:

| # | Label | Asset | Route |
|---|---|---|---|
| 0 | Дома | `assets/home.svg` | `/home` |
| 1 | Консултации | `assets/invite-alt.svg` | `/consultations` |
| 2 | Испити | `assets/test.svg` | `/exams` |
| 3 | Распоред | `assets/calendar-clock.svg` | `/timetable` |
| 4 | Карта | `assets/map-marker.svg` | `/map` |

`Мој Распоред` loses its tab — the Дома screen shows that saved-schedule list now,
so a separate tab is redundant. **Keep the `/schedule` route and `ScheduleScreen`
intact and registered**, just not as a nav branch; the Дома screen links to it.
Do not delete `schedule_screen.dart`.

Keep the existing `NavigationBar` (height 64), the `_Dest` / `_NavIcon` pattern, and
the `AppColors.muted` → `AppColors.navy` selected tint. Don't restyle the bar.

## Step 3 — routing

In `lib/core/router/app_router.dart`:
- add `/home` → `HomeScreen` as the **first** `StatefulShellBranch`
- reorder the remaining branches to match the table above
- change the post-login redirect from `return '/timetable'` to `return '/home'`
- keep `/schedule` routable (e.g. a plain `GoRoute` outside the shell, or a nested
  route under the Дома branch — your call, but it must still be navigable)
- do not change the `/splash` handling or the auth guard logic

## Step 4 — the screen: `lib/features/home/home_screen.dart`

A `ConsumerWidget` (or `ConsumerStatefulWidget` if you need a ticker for the
relative time). Background `AppColors.canvas`. Use a `CustomScrollView`.

### 4a. Large title header

An iOS-style large title — **not** the navy `AppBar` used on the other screens.

- `SliverAppBar.large`, `backgroundColor: AppColors.canvas`, `surfaceTintColor:
  Colors.transparent`, `elevation: 0`, `scrolledUnderElevation: 0`
- Title `Дома`, color `AppColors.navy`
- Expanded: 34px, `FontWeight.w700`, `height: 41/34`, `letterSpacing: 0.37`
- Collapsed: 17px, `FontWeight.w600`, `letterSpacing: -0.43`, centered
  (`centerTitle: true`), with a 1px bottom border in `AppColors.border`
- Use the **system font** for this title (leave `fontFamily` null so iOS renders
  SF Pro, which is what the design uses). Everything else on the screen stays Inter
  via the existing `google_fonts` theme. On Android it falls back to Roboto —
  that's expected.
- 16px leading inset, matching the list

### 4b. Hero card — "what now"

Full width minus 16px side margins. Two states in one widget.

Container:
- `AppColors.card`, `BorderRadius.circular(16)`
- `BoxShadow(color: AppColors.navy.withValues(alpha: 0.08), blurRadius: 10, offset: Offset(0, 3))`
- 4px accent bar flush to the left edge, stretched to the content height
- content padding: 14 top, 14 bottom, 14 right, 12 gap after the accent bar
  (so text starts 16px from the card's left edge, matching every other card)

**State: next class**
- accent bar = `lessonTypeStyle(type).accent`
- relative time, largest element: 28px `FontWeight.w800`, `AppColors.navy` — e.g. `за 20 минути`
- 10px gap
- course name: 14.5px `FontWeight.w700`, `AppColors.ink`
- 4px gap
- meta row, `crossAxisAlignment: center`, 6px gaps:
  7px circle in `lessonTypeStyle(type).accent` · `Предавање ·` in 12.5px
  `FontWeight.w400` `AppColors.muted` · then the room

**The room is a link, not a button.** Wrap only the room text in a
`GestureDetector`/`InkWell`: 12.5px, `FontWeight.w600`, `AppColors.navy`,
`decoration: TextDecoration.underline`. No fill, no border, no padding. Tapping it
navigates to `/map`. Do not modify `MapScreen` to support this — just navigate.

**State: nothing left today**
- accent bar = `AppColors.faint`
- title: `Нема повеќе часови денес`, 18px `FontWeight.w700`, `AppColors.navy`
- 4px gap
- subtitle: 12.5px `FontWeight.w400`, `AppColors.muted`, naming the next class day,
  e.g. `Следен час во вторник, 08:00`

### 4c. Day-grouped class list

This is the **same list already rendered in `ScheduleScreen`** (`_WeeklyAgenda`,
plus its day header and class card). Reuse it — do not write a second
implementation and do not copy-paste it.

Extract the day header and the class card out of
`lib/features/schedule/schedule_screen.dart` into
`lib/features/schedule/widgets/` as public widgets, then have **both**
`ScheduleScreen` and `HomeScreen` use them. `ScheduleScreen` must look and behave
identically after the refactor.

The day header keeps its current structure: uppercase day name in
`AppColors.navy` `FontWeight.w800` 12px, a flexible 1px `AppColors.border`
hairline, and the **class count right-aligned** in `AppColors.faint` 12px
(`2 класи` / `1 класа` — keep the existing Macedonian pluralization).

Class cards keep everything they already have: white, radius 14, the same shadow
as the hero, 4px lesson-type accent bar, start/end time column, title, and the
dot + `тип · просторија` meta line.

### 4d. Data

Reuse the existing providers — `schedule_providers.dart`, `timetable_providers.dart`,
`savedExamsProvider`. Do not add new API calls or new endpoints.

Derive the hero from the saved schedule: find the next upcoming slot relative to
`DateTime.now()`; if none remain today, render the empty state and look ahead for
the next day that has one.

Put the relative-time formatting in `lib/core/utils/mk_date.dart` alongside the
existing helpers. Macedonian, correct plural forms:
`за 1 минута` / `за 20 минути` / `за 1 час` / `за 3 часа` / `сега`.

Use the existing `FinkiLoader` for loading and `state_views.dart` for empty/error —
reference them, don't edit them.

## Copy rules

Macedonian, sentence case, plain register. No exclamation marks, no marketing
phrasing. Labels name what the user controls.

## When done

1. `flutter analyze` — must be clean
2. `flutter run` and confirm: Дома is the landing tab after login; the large title
   collapses correctly on scroll; the hero shows the right next class; the room link
   opens the map; the day list matches `Мој Распоред` exactly
3. Open `Мој Распоред` via its route and confirm the refactor changed nothing there
4. Confirm the splash/loading screen and the map are byte-identical to before
   (`git diff --stat` should not list `splash_screen.dart`, `finki_loader.dart`,
   `finki_ball.dart`, or `map_screen.dart`)
