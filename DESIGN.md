# DESIGN.md — UI/UX Design System

## 1. Design Direction

### Product
Aplikasi sistem informasi sekolah yang berfokus pada guru, terutama untuk:
- Melihat jadwal mengajar.
- Melakukan presensi siswa.
- Melihat ringkasan data kelas.
- Mengelola jurnal pembelajaran bila diperlukan.
- Melihat status presensi yang sudah dilakukan.

### Design Style
Gunakan gaya **Flat UI** yang modern, bersih, profesional, dan ringan.

Prinsip utama:
- Flat design, tanpa gradient.
- Gunakan warna solid.
- Minimal dekorasi.
- Prioritaskan informasi dan tindakan utama.
- Layout rapi dengan whitespace yang cukup.
- Komponen memiliki hierarchy visual yang jelas.
- Hindari efek glassmorphism, neumorphism, dan visual yang terlalu kompleks.
- Gunakan elevation/shadow secara minimal hanya bila membantu hierarchy.
- UI harus terasa seperti aplikasi sekolah profesional, bukan aplikasi gaming.

### Primary Accent
Warna aksen utama adalah **biru**.

Gunakan satu keluarga warna biru secara konsisten untuk:
- Primary button.
- Active navigation.
- Link/action penting.
- Highlight informasi.
- Selected state.
- Progress/status tertentu.

Jangan menggunakan banyak warna aksen yang berbeda tanpa alasan UX yang jelas.

---

# 2. Color System

Gunakan warna berikut sebagai baseline. Semua warna harus didefinisikan sebagai design tokens agar mudah diubah.

## Primary

| Token | Color | Usage |
|---|---|---|
| `primary` | `#2563EB` | Primary action, active state |
| `primaryDark` | `#1D4ED8` | Pressed/strong primary state |
| `primaryLight` | `#DBEAFE` | Soft background/highlight |
| `primarySurface` | `#EFF6FF` | Very subtle blue surface |

Primary color harus menjadi identitas visual utama aplikasi.

## Background

| Token | Color | Usage |
|---|---|---|
| `background` | `#F8FAFC` | Main application background |
| `surface` | `#FFFFFF` | Cards, sheets, dialogs |
| `surfaceMuted` | `#F1F5F9` | Secondary surface |

## Text

| Token | Color | Usage |
|---|---|---|
| `textPrimary` | `#0F172A` | Main text/headings |
| `textSecondary` | `#475569` | Supporting text |
| `textMuted` | `#64748B` | Metadata/less important text |
| `textDisabled` | `#94A3B8` | Disabled text |

## Border

| Token | Color | Usage |
|---|---|---|
| `border` | `#E2E8F0` | Card/input/divider border |
| `borderStrong` | `#CBD5E1` | Stronger separation |

## Semantic Colors

Semantic colors are not additional branding colors. They communicate system status.

| Token | Color | Usage |
|---|---|---|
| `success` | `#16A34A` | Present, successful action |
| `successSurface` | `#DCFCE7` | Success background |
| `warning` | `#D97706` | Warning/pending |
| `warningSurface` | `#FEF3C7` | Warning background |
| `error` | `#DC2626` | Error/failed action |
| `errorSurface` | `#FEE2E2` | Error background |
| `info` | `#0284C7` | Informational state |
| `infoSurface` | `#E0F2FE` | Information background |

### Important
Do not use semantic colors merely for decoration.

For example:
- Green = successful/present.
- Red = absent/error.
- Orange = pending/warning.
- Blue = primary interaction/information.

---

# 3. Typography

Use a modern sans-serif font.

### Recommended
**Inter** is preferred if available.

If Inter is unavailable, use the platform's default modern sans-serif font.

## Typography Scale

| Style | Size | Weight | Usage |
|---|---:|---:|---|
| Display | 28px | 700 | Large page title |
| H1 | 24px | 700 | Main heading |
| H2 | 20px | 700 | Section heading |
| H3 | 18px | 600 | Card/subsection title |
| Body Large | 16px | 400 | Important body text |
| Body | 14px | 400 | Normal body text |
| Body Medium | 14px | 500 | Labels/emphasis |
| Caption | 12px | 400 | Metadata |
| Button | 14px | 600 | Button text |

### Typography Rules
- Never use too many font sizes on one screen.
- Heading hierarchy must be obvious.
- Avoid all-caps text except very small labels when necessary.
- Use font weight rather than excessive color changes for emphasis.

---

# 4. Spacing System

Use an **8px spacing system**.

Allowed primary spacing values:

```text
4px
8px
12px
16px
20px
24px
32px
40px
48px
64px
```

### Common Usage

- Screen horizontal padding: `20px` or `24px`
- Card internal padding: `16px`
- Small component gap: `8px`
- Normal component gap: `12px`
- Section gap: `24px`
- Major section gap: `32px`

Avoid arbitrary spacing values unless there is a clear reason.

---

# 5. Border Radius

Use moderate rounded corners.

| Component | Radius |
|---|---:|
| Button | 10px |
| Input | 10px |
| Card | 14px |
| Dialog | 16px |
| Bottom sheet | 20px |
| Avatar | 999px |
| Small badge | 999px |

Avoid extremely rounded containers unless they are pills/badges.

---

# 6. Elevation and Shadows

Flat UI does not mean every component must have a shadow.

Default preference:

```text
Cards:
- Prefer border
- Optional very subtle shadow

Dialogs:
- Subtle elevation

Bottom sheets:
- Moderate elevation

Buttons:
- No shadow by default
```

Avoid:
- Heavy shadows.
- Multiple layered shadows.
- Glow effects.
- Neon effects.

The interface should remain clean and lightweight.

---

# 7. Layout Principles

## Mobile First

The application is primarily designed for mobile.

Design for:
- Android phones.
- iOS phones.
- Different screen sizes.
- Portrait orientation as the primary layout.

The UI should remain usable on smaller screens without horizontal scrolling.

## Safe Area

Always respect:
- Status bar.
- Navigation area.
- Device cutouts/notches.

## Content Priority

Every screen must answer:

1. What does the user need to know?
2. What does the user need to do?
3. What is the most important action?

The most important information/action should visually receive the highest hierarchy.

---

# 8. Navigation

Use a simple and predictable navigation structure.

### Recommended Bottom Navigation

For the main teacher application:

```text
Home
Schedule
Attendance
Profile
```

Use icons + labels.

The active item:
- Uses `primary`.
- Has a clear active indicator.
- Inactive items use muted text/icon color.

Do not create excessive navigation destinations.

If a feature is secondary, place it inside a page or menu rather than adding another bottom navigation item.

---

# 9. App Bar

Use a simple flat app bar.

### Standard App Bar

```text
[Back]    Page Title                         [Action]
```

Characteristics:
- White/surface background.
- No gradient.
- Minimal elevation.
- Title aligned consistently.
- Icons use 24px size.

For the dashboard/home page, the app bar may contain:

```text
Good morning, [Teacher Name]
[Profile Avatar]
```

Avoid overly decorative headers.

---

# 10. Buttons

## Primary Button

Use for the main action.

Example:

```text
[ Simpan Presensi ]
```

Properties:
- Solid `primary` background.
- White text.
- Radius: 10px.
- Height: approximately 48px.
- Font weight: 600.

## Secondary Button

Use for secondary actions.

```text
[ Batal ]
```

Use:
- White/surface background.
- `border`.
- `textPrimary` text.

## Text Button

Use for low-priority actions.

```text
Lihat Semua
```

Use primary blue text without a large container.

## Destructive Button

Use only for destructive actions.

```text
[ Hapus ]
```

Use `error`.

Do not make destructive actions visually dominant unless necessary.

---

# 11. Cards

Cards are the primary information container.

### Card Style

```text
Background: surface
Border: 1px border
Radius: 14px
Padding: 16px
```

Cards should have a clear purpose.

Good:
- Today's schedule.
- Student statistics.
- Attendance status.
- Upcoming lesson.

Avoid placing unrelated information into one giant card.

---

# 12. Dashboard / Home

The dashboard should prioritize the teacher's daily workflow.

Recommended hierarchy:

```text
Greeting
↓
Today's Schedule
↓
Attendance Action
↓
Class Statistics
↓
Recent Activity
```

## Greeting

Example:

```text
Selamat pagi,
Budi Santoso
```

Keep it simple.

## Today's Schedule

Display the next/current lesson prominently.

Example:

```text
Matematika
XII PPLG 1

08:00 — 09:30

[ Mulai Presensi ]
```

The current/next schedule should be visually prioritized.

## Statistics

Use compact statistic cards.

Example:

```text
Laki-laki     Perempuan      Total
    18            14            32
```

Do not overload the dashboard with charts if simple numbers are sufficient.

---

# 13. Schedule UI

Schedule is a core feature.

Each schedule item should show:

```text
Subject
Class
Time
Room
Status
```

Example:

```text
08:00 — 09:30
Pemrograman Dasar
XII PPLG 1
Ruang Lab 2

[ Belum Presensi ]
```

### Schedule Status

Possible states:

- Upcoming
- Ongoing
- Completed
- Locked/Unavailable

Use semantic colors carefully.

### Important UX Rule

A schedule should not suddenly disappear or become inaccessible because of a normal state transition.

If an action is unavailable, explain why.

---

# 14. Attendance UI

Attendance is the most important workflow.

The interface must be optimized for **fast classroom input**.

## Student List

Recommended structure:

```text
[ Search siswa ]

01  Ahmad Fauzan              [Hadir]
02  Budi Setiawan             [Izin]
03  Citra Ramadhani           [Sakit]
04  Dimas Pratama             [Alpa]
```

Use clear status controls.

## Attendance Status

Recommended statuses:

```text
Hadir
Izin
Sakit
Alpa
```

Each status must be visually distinguishable without relying only on color.

Use:
- Text.
- Icon.
- Color.

This improves accessibility.

## Attendance Summary

At the top or bottom:

```text
Hadir 28
Izin 2
Sakit 1
Alpa 1

Total 32 siswa
```

## Save Action

Use a prominent fixed bottom action when appropriate:

```text
[ Simpan Presensi ]
```

Before saving, show useful confirmation if the action is significant.

---

# 15. Attendance States

The UI must clearly distinguish:

### Not Started

```text
Presensi belum dimulai

[ Mulai Presensi ]
```

### In Progress

```text
Presensi sedang diisi

28 / 32 siswa telah diisi

[ Simpan Presensi ]
```

### Completed

```text
Presensi selesai

32 / 32 siswa

✓ Presensi sudah tersimpan
```

### Important Business Rule

A completed attendance record should not appear as an editable draft unless the application's business rules explicitly allow editing.

The UI must not imply that teachers can freely modify finalized records when they cannot.

---

# 16. Journal / Optional Input

Journal is optional.

The UI must clearly communicate that journal input is not required to complete attendance.

Example:

```text
Jurnal Pembelajaran
Opsional

[ Tambahkan jurnal ]
```

If the journal is empty:
- Attendance can still be completed.
- Do not block the primary attendance workflow.

Never make optional journal input visually look mandatory.

---

# 17. Forms and Inputs

## Text Field

Properties:

```text
Height: ~48–52px
Radius: 10px
Border: 1px
Padding: 12–16px
```

States:
- Default.
- Focused.
- Filled.
- Error.
- Disabled.

### Focus State

Use the primary blue to clearly communicate focus.

Example:

```text
border: primary
```

Do not use excessive glow.

### Error State

Show:
1. Error border.
2. Error icon if useful.
3. Short explanatory message.

Bad:

```text
Invalid input
```

Better:

```text
Email tidak valid. Periksa kembali format email.
```

---

# 18. Search

Search should be simple.

Example:

```text
🔍 Cari nama siswa
```

Use search when a list can become long.

Search results should update quickly and preserve the user's input.

---

# 19. Status Badges

Use pill-shaped badges for compact status.

Examples:

```text
[ Berlangsung ]
[ Selesai ]
[ Belum ]
[ Hadir ]
[ Izin ]
```

Style:

```text
Radius: 999px
Horizontal padding: 10–12px
Vertical padding: 4–6px
Font: 12px / Medium
```

Use a light semantic surface with readable text.

---

# 20. Dialogs

Use dialogs only when the user needs to make a decision.

Example:

```text
Simpan Presensi?

Pastikan data presensi sudah benar sebelum disimpan.

[ Batal ] [ Simpan ]
```

Do not use dialogs for every small interaction.

---

# 21. Bottom Sheets

Use bottom sheets for:
- Quick actions.
- Selecting attendance status.
- Additional filters.
- Compact forms.

Bottom sheets should:
- Have rounded top corners.
- Have sufficient padding.
- Avoid excessive content.

---

# 22. Empty States

Every list-based screen should have a meaningful empty state.

Example:

```text
Belum ada jadwal

Tidak ada jadwal mengajar untuk hari ini.
```

If an action can solve the empty state, provide it.

Example:

```text
[ Muat Ulang ]
```

Do not use empty states as purely decorative illustrations.

---

# 23. Loading States

Avoid blocking the entire application with unnecessary loading screens.

Prefer:
- Skeleton loading for large content.
- Progress indicator for actions.
- Inline loading for lists.

Example:

```text
Memuat jadwal...
```

Buttons should show loading state after submission to prevent duplicate actions.

---

# 24. Error States

Errors must be understandable to teachers who may not have technical knowledge.

Avoid:

```text
Exception: PostgrestException 23505
```

Instead:

```text
Gagal menyimpan presensi.

Periksa koneksi internet lalu coba lagi.
```

Technical error details should only appear in developer logs, not normal user UI.

---

# 25. Toast / Snackbar

Use snackbar for lightweight feedback.

Examples:

```text
✓ Presensi berhasil disimpan
```

or

```text
Gagal menyimpan data. Coba lagi.
```

Do not use snackbar for information that requires a decision.

---

# 26. Icons

Use a single consistent icon library.

Recommended:
- Material Icons.
- Font Awesome where specifically required.

Icon guidelines:
- Default size: 24px.
- Small icon: 20px.
- Large feature icon: 32px.
- Do not mix visually incompatible icon styles.

Icons must support the meaning of text, not replace important text unnecessarily.

---

# 27. Avatar

Teacher profile avatar:

```text
Circle
Radius: 999px
Size: 40–44px
```

Fallback:
- Initials.

Example:

```text
BS
```

Keep the avatar simple.

---

# 28. Accessibility

The application must remain usable for users with different visual abilities.

Requirements:
- Do not communicate status through color alone.
- Maintain readable text contrast.
- Touch targets should generally be at least 44px.
- Interactive elements need clear pressed/focused states.
- Avoid tiny text for important information.
- Icons that perform actions should have accessible labels.
- Error messages must be explicit.

---

# 29. Responsive Behavior

Although mobile-first, components should behave correctly on larger screens.

### Small Mobile
- Reduce horizontal padding if necessary.
- Stack content vertically.
- Avoid cramped cards.

### Standard Mobile
- Use default spacing system.
- Two-column statistic cards are acceptable.

### Tablet/Web
- Increase max content width.
- Use responsive grids.
- Avoid stretching cards across the entire screen unnecessarily.

Recommended content max width:

```text
~1200px
```

---

# 30. Component Consistency

The same component must look and behave consistently throughout the application.

For example:

If the primary button is:

```text
Blue
48px high
10px radius
White text
```

do not create another primary button that is:

```text
Green
56px high
20px radius
```

unless there is a specific semantic reason.

Consistency is more important than visual novelty.

---

# 31. Motion and Animation

Animations should be subtle and functional.

Recommended:
- Page transition.
- Button loading.
- List appearance.
- Expand/collapse.

Avoid:
- Excessive bouncing.
- Large zoom effects.
- Decorative animations.
- Long transitions.

Default animation duration:

```text
150–250ms
```

---

# 32. Dark Mode

Dark mode may be supported later.

Do not design the architecture in a way that hardcodes colors directly into individual widgets.

Use centralized design tokens/theme values so dark mode can be added without redesigning every component.

---

# 33. Flutter Implementation Guidelines

The Flutter implementation must use centralized theme/design tokens.

Recommended structure:

```dart
ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Color(0xFF2563EB),
  ),
)
```

However, do not blindly rely on generated Material colors if they conflict with this design specification.

Important values such as:
- Primary color.
- Background.
- Surface.
- Text colors.
- Border colors.
- Radius.
- Spacing.

should be centralized.

Avoid hardcoding colors repeatedly inside pages.

---

# 34. UI Architecture Principles

The UI should remain simple.

Do not introduce complex state-management or component architecture solely for visual styling.

Prioritize:

```text
Consistency
↓
Readability
↓
Usability
↓
Maintainability
↓
Visual polish
```

Do not overengineer the UI.

---

# 35. Design Do / Don't

## DO

- Use flat solid colors.
- Use blue as the primary accent.
- Use whitespace generously.
- Keep cards simple.
- Prioritize attendance workflow.
- Make current/next schedule easy to identify.
- Use clear status indicators.
- Keep actions obvious.
- Maintain consistent spacing.
- Maintain consistent typography.
- Design mobile-first.

## DON'T

- Do not use gradients.
- Do not use glassmorphism.
- Do not use excessive shadows.
- Do not use excessive rounded containers.
- Do not use too many accent colors.
- Do not overcrowd the dashboard.
- Do not hide important actions behind unnecessary menus.
- Do not make optional journal input mandatory.
- Do not display technical error messages to normal users.
- Do not create unnecessary animations.
- Do not introduce UI patterns that contradict this document.

---

# 36. Screen-Level Design Direction

## Splash

Purpose:
- Establish branding.
- Brief loading.

Design:

```text
        [App Logo]

        App Name
        Loading...
```

Keep it minimal.

---

## Login

Hierarchy:

```text
Logo
Welcome text
Email
Password
Forgot password
[ Masuk ]

──── atau ────

[ Masuk dengan Google ]

Register link
```

The primary action must be obvious.

---

## Register

Hierarchy:

```text
Logo
Buat Akun
Username
Email
Password
Confirm Password

[ Daftar ]

──── atau ────

[ Daftar dengan Google ]

Login link
```

Do not add unnecessary fields.

---

## Home / Dashboard

Hierarchy:

```text
Greeting + Profile
↓
Today's / Current Schedule
↓
Attendance CTA
↓
Student Statistics
↓
Recent Activity
```

Keep the dashboard focused.

---

## Schedule

Hierarchy:

```text
Tanggal
↓
Today's Schedule
↓
Schedule List
```

Current lesson should be visually highlighted.

---

## Attendance

Hierarchy:

```text
Class + Subject
Time
↓
Attendance Summary
↓
Student Search
↓
Student List
↓
Save Action
```

This screen should require minimal taps.

---

## Profile

Hierarchy:

```text
Avatar
Teacher Name
Email / Basic Information
↓
Account Settings
↓
Logout
```

Keep profile simple.

---

# 37. UX Priority

The most important user journey is:

```text
Login
  ↓
Dashboard
  ↓
View Current Schedule
  ↓
Start Attendance
  ↓
Mark Students
  ↓
Review Summary
  ↓
Save Attendance
  ↓
Attendance Completed
```

This flow must always be easier and more prominent than secondary features.

---

# 38. AI Agent Implementation Rules

When implementing UI from this `DESIGN.md`, the AI agent MUST:

1. Follow this design system consistently.
2. Use blue as the primary accent.
3. Never introduce gradients unless explicitly requested.
4. Avoid unnecessary UI complexity.
5. Preserve existing design decisions when modifying screens.
6. Reuse existing components whenever possible.
7. Centralize theme values and design tokens.
8. Ensure responsive behavior.
9. Prioritize teacher attendance workflow.
10. Never invent functionality that is not defined by product requirements.
11. Never make optional features appear mandatory.
12. Maintain accessibility standards.
13. Use meaningful loading, empty, success, and error states.
14. Keep UI copy in clear Indonesian unless the product requirements specify another language.
15. Before creating a new component, check whether an existing component can be reused.
16. Before changing the visual system, check this file first.
17. If a requirement conflicts with this design system, follow the latest explicit product requirement and update the implementation without unnecessarily changing unrelated UI.

---

# 39. Design Token Summary

```text
PRIMARY
#2563EB

PRIMARY DARK
#1D4ED8

PRIMARY LIGHT
#DBEAFE

BACKGROUND
#F8FAFC

SURFACE
#FFFFFF

SURFACE MUTED
#F1F5F9

TEXT PRIMARY
#0F172A

TEXT SECONDARY
#475569

TEXT MUTED
#64748B

BORDER
#E2E8F0

SUCCESS
#16A34A

WARNING
#D97706

ERROR
#DC2626

INFO
#0284C7

RADIUS
10px / 14px / 16px / 20px

SPACING
4 / 8 / 12 / 16 / 20 / 24 / 32 / 40 / 48 / 64px

TOUCH TARGET
≥44px

PRIMARY BUTTON HEIGHT
≈48px
```

---

# 40. Final Design Goal

The final application should feel:

**Clean · Professional · Modern · Calm · Fast · Easy to Understand**

The design should help teachers complete their daily work quickly, especially attendance input, without visual distractions.

**Function first, visual polish second — but never sacrifice consistency.**
