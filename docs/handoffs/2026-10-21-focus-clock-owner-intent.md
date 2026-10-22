# Focus Clock: Owner Intent & Product History Handoff

**Document Date:** 2026-10-21  
**Target Repository:** `/home/aizatfir/Project/Focus Clock - Claude`  
**Related Repositories:** `/home/aizatfir/Project/Sadar`, `/home/aizatfir/Project/Fitrah-Launcher`  
**Author:** Antigravity Assistant (Autonomous Context Extraction)  

---

## 1. Confirmed Owner Intent and Meaningful Quotes

### 1.1 Core Intent
The foundational purpose of **Focus Clock** is expressed in one word: **“Visualize”**.

Focus Clock exists to stabilize human daily life against sensory overload, forgetfulness, and cognitive drift. Humans are easily shaped and distracted by the sensory inputs surrounding them (notifications, social media feeds, decision fatigue). The app's purpose is not high-pressure productivity or maximizing streaks, but to keep a person's **real ultimate goal visible, memorable, and actionable** in everyday life.

Time management, at its best, is strategic energy spending management: knowing what is lacking today, deciding where mental energy should go, and having a direct, low-friction path to act.

### 1.2 Direct Quotes from Owner
* *"intinya semua app ku tuh beri visual cue biar user tiap buka hp tau, kegiatan ini kurang apa, hari ini blm belajar lks nih, harus ngapain, oh buka laptop, sekalian tinggal play timer. gitu. dapet selalu visual untuk tujuan akhir, time management at its best is energy spending strategical management"*
* *"fitrah launcehr tuh harusnya langsung muncul view buat ngapain, integrasi sadarnya woy"*
* *"damn son, focus clock ui nya fallback yg dah bagus sebelumnya, tambahan timer dll itu add on feature dengan basis yg kemarin, bikin lebih simple pangkas logic yg kepanjangan"*
* *"ngbug msh web saddar trs mlh jd 1 , pisahin"*
* *"release all web vercel jg woy focus clocknya. trus bikinin sadar web khusus vercel deploy biar bisa kucoba"*
* *"pake /apple-design /ponytail /ponytail-audit /ponytail-review /goal sampe semuanya enak dipake typography low cortisol, simple cue visual. mewwah. /caveman"*

---

## 2. Product Evolution: Original Purpose, Changes Over Time, Current Direction

```
Phase 1: Samsung Solve for Tomorrow (SFT) 2026 Competition Proposal
  │  - Context: SMKN 2 Surakarta team ("AC - NYA MATIIN WOY").
  │  - Framing: High-concept AI Agent, IoT edge devices, microservices, Kafka, Keycloak.
  │  - Status: REJECTED by competition. Education & heavy tech requirements superseded.
  ▼
Phase 2: All-in-One Multiplatform Monolith (Flutter)
  │  - Focus Clock, Sadar, and Fitrah Launcher developed in one Flutter repo.
  │  - Bloat accumulated: complex state machines, over-coupled UI, navigation confusion.
  ▼
Phase 3: Separation into Three Focused Repositories (Commit afab5cf)
  │  1. Focus Clock (`Focus Clock - Claude`): Analog time visualizer & timer.
  │  2. Sadar (`Sadar`): Conscious habit tracking & daily fulfillment companion.
  │  3. Fitrah Launcher (`Fitrah-Launcher`): Niagara-style Android home stream.
  ▼
Phase 4: Current Direction (Confirmed Intent)
     - Core Function: "Visualize" — make the ultimate goal tangible and visible at all times.
     - Low-Cortisol Aesthetics: Apple HIG clean design, calm obsidian tones, generous typography.
     - Direct Integration: Opening phone/launcher immediately reveals what is missing and provides
       a 1-tap trigger ("Buka Laptop & Play Timer").
     - Independence: Lightweight web apps deployed on Vercel for fast, cross-platform accessibility.
```

---

## 3. Intended Experience: Goal Visibility, Clock Face, Today/Now/Next, and UI Hierarchy

### 3.1 Experience Hierarchy (Order of Perception)
1. **First Glance (Phone Screen / Launcher / Web Entry):**
   - Immediate answer to: *"What is lacking today? What is my main goal?"*
   - Clear visual status: ratio of fulfilled intentions (e.g., `3/5 selesai (60%)`), without guilt.
   - Single highest-leverage next action highlighted (e.g., `Belajar LKS / Coding` • `⏱️ 45 Menit • 📍 Buka Laptop`).
   - Single-tap action trigger: `▶ Buka Laptop & Play Timer`.
2. **Clock Face (Visualizing Time & Energy):**
   - An analog dial that represents spatial allocation of the day.
   - Clarifies what the user is doing **now**, how much time remains, and what comes **next**.
   - Replaces stressful digital countdowns with calm, spatial perception of time.
3. **Timer / Execution (Add-on Feature):**
   - Simple, tactile trigger to start focus.
   - Low cognitive load: no unnecessary forms, settings, or complex dropdowns.
4. **Reflection (End of Day):**
   - Honest self-check: *"Did I live today in a way I can be proud of?"*
   - Descriptive awareness of repeated habits, not streak gamification.

### 3.2 What Obscured the Purpose and Must Be Removed/Simplified
- **Heavy, multi-screen navigation** that forces the user to browse before knowing what to do.
- **Complex AI chat interfaces or voice setups** that delay the start of action.
- **Microservice / IoT setup dependencies** that were created solely for the competition proposal.
- **Over-engineered timer state machines** that conflict with simple start/stop functionality.

---

## 4. Product Principles and Tone, Including Stated Spiritual Grounding

### 4.1 Spiritual Grounding (Tauhid, Ar-Rahman, Ar-Rahim)
- The owner's spiritual foundation is **Tauhid** (monotheism) and recognizing God as **Ar-Rahman** (The Most Gracious) and **Ar-Rahim** (The Most Merciful).
- Guidance is understood as protective mercy: helping human beings prevent harm, self-destruction, and decline.
- **Tone Requirement:** Preserve this grounding respectfully and authentically.
  - **NEVER** turn it into generic, hollow corporate productivity slogans (e.g., *"Crush your goals"*, *"Hustle harder"*).
  - **NEVER** use manipulative guilt, fear of failure, or punishing streak penalties.
  - Express it through calm reminders of purpose, balanced rest, and dignified intentionality (*Sadar*).

### 4.2 Low-Cortisol Visual Philosophy
- **Colors:** Deep obsidian backgrounds (`#0F0F12`, `#18171E`), warm gold accents (`#F0C987`), serene emerald (`#10B981`), muted slate borders (`#26252E`). Avoid alarm red.
- **Typography:** Apple-grade clean sans (`Inter` / Apple system), relaxed letter-spacing, clear hierarchy.
- **Zero Decision Fatigue:** The screen tells you what matters now so your brain does not have to compute it upon waking or unlocking your phone.

---

## 5. Confirmed Decisions vs. Agent Proposals or Assumptions

| Topic | Confirmed Owner Decision | Agent Proposal / Historical Artifact (Unconfirmed or Superseded) |
| :--- | :--- | :--- |
| **Primary Function** | **“Visualize”** the goal and day's energy allocation. | AI Agent conversational time-blocking via local LLMs. |
| **Architecture** | Separate repositories for Focus Clock, Sadar, and Fitrah Launcher. | Unified mono-repo with internal multi-app flavor switching. |
| **Web Deployments** | Standalone Vercel deployments for live cross-device access (`sadar-web.vercel.app`, `focus-clock-web.vercel.app`). | Complex self-hosted Docker/Kafka/Keycloak infrastructure. |
| **Focus Clock UI** | Fallback to clean, human tactile base; keep timer as streamlined add-on. | Full 3D Three.js luxury chronograph canvas with dense particle FX. |
| **Launcher UX** | Opening phone must immediately show the visual cue card of what's missing + 1-tap timer play. | Generic app list drawer requiring search before action. |
| **Gamification** | Meaningful action repetition, zero-guilt rest, no streak worship. | Experience points, competency badges, clan maps, and reward tiers. |

---

## 6. Work Already Executed: Status Classification and Evidence

### 6.1 Status Summary Table

| Component / Task | Classification | Evidence & File References |
| :--- | :--- | :--- |
| **Repository Sterilization & Split** | **Verified** | Commit `afab5cf` separated Sadar and Fitrah Launcher into dedicated repositories. Git history in `Focus Clock - Claude`. |
| **Focus Clock Web Deployment** | **Verified** | `vercel.json`, `web-app/` codebase, live production at `https://focus-clock-web.vercel.app`. |
| **Focus Clock UI Simplification** | **Verified** | Commit `0936524` (*"fallback UI to clean human base, streamline timer add-on and prune bloated logic"*). Files: [`web-app/components/clock-view.js`](file:///home/aizatfir/Project/Focus%20Clock%20-%20Claude/web-app/components/clock-view.js), [`web-app/components/timer-view.js`](file:///home/aizatfir/Project/Focus%20Clock%20-%20Claude/web-app/components/timer-view.js). |
| **Sadar Web Deployment** | **Verified** | Deployed via Vercel to `https://sadar-web.vercel.app`. Live screenshot verified in artifact [`sadar_web_verified.png`](file:///home/aizatfir/.gemini/antigravity-ide/brain/c51310d5-8236-4779-a7be-5ce843f1a8a4/sadar_web_verified.png). |
| **Sadar Strategic Cue Card** | **Verified** | [`lib/features/sadar/widgets/today_view.dart:427`](file:///home/aizatfir/Project/Sadar/lib/features/sadar/widgets/today_view.dart). Passing tests in `test/sadar_today_view_test.dart` and `test/sadar_appbar_layout_test.dart`. |
| **Sadar Low-Cortisol Typography** | **Verified** | [`lib/core/theme.dart`](file:///home/aizatfir/Project/Sadar/lib/core/theme.dart) uses `GoogleFonts.interTextTheme`. Verified visual rendering. |
| **Fitrah Launcher Home Cue Card** | **Verified** | [`lib/features/launcher/widgets/niagara_unified_stream_view.dart:783`](file:///home/aizatfir/Project/Fitrah-Launcher/lib/features/launcher/widgets/niagara_unified_stream_view.dart). Passing tests in `test/fitrah_launcher_test.dart` and `test/sadar_ui_test.dart`. |
| **Fitrah Wave Scrubber Overflow Fix** | **Verified** | [`lib/features/launcher/widgets/niagara_wave_scrubber.dart:120`](file:///home/aizatfir/Project/Fitrah-Launcher/lib/features/launcher/widgets/niagara_wave_scrubber.dart). `FittedBox` scale-down applied; test passing. |
| **Focus Clock Web Audio Engine** | **Implemented, unverified** | [`web-app/sound.js`](file:///home/aizatfir/Project/Focus%20Clock%20-%20Claude/web-app/sound.js) contains Web Audio API synthesizer chimes. Code exists; automated audio playback test not run. |
| **Cross-App Deep Linking Contract** | **Partial or unclear** | Contract defined in `FocusSessionContract v1` ([`ARCHITECTURE.md`](file:///home/aizatfir/Project/Focus%20Clock%20-%20Claude/ARCHITECTURE.md)), but live deep linking between web apps and Android native launcher remains partial across platforms. |
| **SFT 2026 AI Agent & IoT Engine** | **Superseded / Rejected** | Found in [`SFT 2026 - AC - NYA MATIIN WOY - SMK Negeri 2 Surakarta.md`](file:///home/aizatfir/Project/Focus%20Clock%20-%20Claude/SFT%202026%20-%20AC%20-%20NYA%20MATIIN%20WOY%20-%20SMK%20Negeri%202%20Surakarta.md). Marked out of scope by owner. |

---

## 7. Partial, Unfinished, Superseded, Rejected, or Not-Found Work

### 7.1 Superseded & Rejected
- **Samsung SFT 2026 Competition Specifications:** IoT hardware units, local SLM (Phi-3/Gemma), Apache Kafka message queues, Keycloak server, and classroom LMS features are **explicitly rejected / superseded**.
- **Heavy 3D Chronograph Visualizer:** Three.js 3D atmospheric canvas in Focus Clock Web was rejected in favor of the cleaner, tactile 2D analog face.

### 7.2 Partial & Unfinished
- **Cross-Device Goal Synchronization:** Currently, Sadar Web and Focus Clock Web store state in browser `localStorage`. A lightweight sync mechanism (without heavy cloud bloat) is not yet implemented.
- **Lock Screen Goal Display:** Displaying the goal text directly on Android lock screens (via native notification or Always-On Display widget) is partially prototyped in Flutter services, but not yet verified as a finished user experience.

---

## 8. Material Unknowns

*(Note: Stated as unknowns requiring future confirmation, per instructions. No questions asked.)*

1. **Target Sync Mechanism:** Unknown / needs owner confirmation whether habit/goal synchronization across phone launcher and laptop web app should use a simple peer sync, a minimalist Supabase/Firebase backend, or remain manual/local.
2. **Focus Clock Dial Interactivity:** Unknown / needs owner confirmation whether dragging directly on the analog clock dial to block time is desired in the web app, or if direct preset buttons are preferred.
3. **Lock Screen Presentation Method:** Unknown / needs owner confirmation whether the lock screen visual cue should be delivered via ongoing system notification, an Android widget, or an accessibility overlay.

---

## 9. Acceptance Criteria for the Next Design and Development Pass

Any future agent or developer continuing this work must verify the following criteria:

1. **Immediate Goal Visibility:**
   - Unlocking the phone or opening the web application must show the current high-leverage goal and remaining daily items within 1 second.
   - The user must never need to navigate through more than 1 screen to see what they should do next.
2. **Low-Cortisol Aesthetics:**
   - Inter typography with generous line-height and calm hierarchy.
   - Obsidian dark palette with warm gold/emerald accents; no alarming reds or flashing stimuli.
   - No guilt messaging, streak punishment, or aggressive warnings.
3. **One-Tap Action Trigger:**
   - A single prominent button (`▶ Buka Laptop & Play Timer`) must directly start the focus timer or launch the session without interstitial dialogs.
4. **Clean Decoupling:**
   - Changes to Focus Clock must not break Sadar or Fitrah Launcher, and vice-versa.
   - All web apps must remain functional offline via `localStorage` or PWA caching.
5. **Regression Verification:**
   - Flutter tests (`flutter test`) and analysis (`flutter analyze`) must pass with 0 errors across all three repositories before committing.

---

## 10. One Smallest Useful Next Step Grounded in Confirmed Intent

**Smallest Useful Action:**
Ensure that when a user clicks `▶ Buka Laptop & Play Timer` on either Fitrah Launcher or Sadar Web, it opens Focus Clock Web (`https://focus-clock-web.vercel.app`) with the specific task and duration pre-populated via URL query parameters (e.g., `?task=Belajar%20LKS&duration=45&autoStart=true`), enabling an immediate, zero-friction transition from phone cue to laptop focus.

---

*Handoff document saved to `docs/handoffs/2026-10-21-focus-clock-owner-intent.md`.*
