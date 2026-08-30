# FairSplit Architecture — TRACK AI Hackathon

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        PRESENTATION LAYER                       │
├─────────────────────────────────────────────────────────────────┤
│  Flutter App (Dart)                                            │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────┐ │
│  │   Splash    │ │  Onboarding │ │   Tutorial  │ │ Settings │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └──────────┘ │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────┐ │
│  │   Dashboard │ │   Kasir     │ │  Riwayat    │ │ Insight  │ │
│  │   (UMKM)    │ │  Dialog     │ │  Transaksi  │ │   (AI)   │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └──────────┘ │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌──────────┐ │
│  │  Inventory  │ │  PDF Export │ │  Demo Mode  │ │ QR Code  │ │
│  └─────────────┘ └─────────────┘ └─────────────┘ └──────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        BUSINESS LOGIC LAYER                     │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  Services                                │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ • Sales Analytics Engine (SMA, EMA, Growth, Anomaly)    │   │
│  │ • AI Insight Service (9 Rekomendasi)                    │   │
│  │ • Cash Flow Projection (7-day forecast)                 │   │
│  │ • Category Guesser (Auto-categorization)                │   │
│  │ • Receipt Parser (OCR text → structured data)           │   │
│  │ • PDF Export Service (Daily + All transactions)         │   │
│  │ • Inventory Service (Stock tracking, alerts, waste)     │   │
│  │ • Currency Rates Service (Real-time exchange)           │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                  State Management                       │   │
│  ├─────────────────────────────────────────────────────────┤   │
│  │ • TransaksiUmkmStore (CRUD, filter, persist)            │   │
│  │ • SplitStore (Split bill state)                         │   │
│  │ • SettingsService (Theme, mode, locale)                 │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        DATA & AI LAYER                          │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐    ┌─────────────────────────────┐   │
│  │    Local Storage     │    │      External AI            │   │
│  ├─────────────────────┤    ├─────────────────────────────┤   │
│  │ • SharedPreferences │    │ • Google Gemini API         │   │
│  │ • JSON serialization│    │   (Menu analysis, forecast, │   │
│  │ • Offline-first     │    │    health score, efficiency) │   │
│  └─────────────────────┘    └─────────────────────────────┘   │
│  ┌─────────────────────┐    ┌─────────────────────────────┐   │
│  │    OCR Engine        │    │      Fallback Logic          │   │
│  ├─────────────────────┤    ├─────────────────────────────┤   │
│  │ • ML Kit (Offline)  │    │ • Auto: ML Kit → Gemini     │   │
│  │ • Text Recognition  │    │ • Graceful degradation      │   │
│  │ • No internet needed│    │ • Cost optimization         │   │
│  └─────────────────────┘    └─────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  Camera  │───▶│ ML Kit   │───▶│ Receipt  │───▶│ Category │
│  Input   │    │ OCR      │    │ Parser   │    │ Guesser  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                                      │               │
                                      ▼               ▼
                               ┌──────────┐    ┌──────────┐
                               │ Structured│    │ Auto-    │
                               │ Receipt  │    │ Category │
                               └──────────┘    └──────────┘
                                      │               │
                                      ▼               ▼
                               ┌─────────────────────────┐
                               │   Kasir Dialog          │
                               │   (Review & Confirm)    │
                               └─────────────────────────┘
                                      │
                                      ▼
                               ┌─────────────────────────┐
                               │   TransaksiUmkmStore    │
                               │   (Save to Local DB)    │
                               └─────────────────────────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
             ┌──────────┐     ┌──────────┐     ┌──────────┐
             │ Analytics│     │   PDF    │     │  Insight │
             │  Engine  │     │  Export  │     │  (AI)    │
             └──────────┘     └──────────┘     └──────────┘
```

## Key Features

### 1. OCR Scanner (3 Modes)
- **Offline Mode**: ML Kit Text Recognition (no internet)
- **AI Mode**: Gemini API (higher accuracy)
- **Auto Mode**: ML Kit first → Gemini fallback

### 2. Local Analytics Engine
- **Moving Average**: SMA (Simple), EMA (Exponential)
- **Growth Rate**: Daily, Weekly, Monthly
- **Anomaly Detection**: Z-score based
- **Trend Analysis**: Linear regression + R²
- **ABC Analysis**: Revenue contribution
- **Pattern Analysis**: Weekly + Hourly

### 3. AI Insights (9 Recommendations)
- Growth analysis
- Trend detection
- Revenue consistency
- Anomaly alerts
- Weekly patterns
- Top items
- Inventory alerts
- Waste detection
- Cash flow projection

### 4. Cash Flow Projection
- **Algorithm**: EMA-based forecasting
- **Horizon**: 7 days
- **Confidence**: High/Medium/Low
- **Visualization**: Progress bars + labels

### 5. Inventory Management
- **Stock Tracking**: Current/Min/Max
- **Alerts**: Low stock, Critical stock
- **Analytics**: Fast-moving, Slow-moving
- **Waste Estimation**: Below-cost items

## Scalability Path

### Current (Hackathon)
- ✅ 100% Offline-first
- ✅ Local SharedPreferences
- ✅ No backend dependency

### Production Ready
```
┌─────────────────────────────────────────┐
│           Migration Path                │
├─────────────────────────────────────────┤
│ 1. Backend: Firebase / Supabase         │
│    • Real-time sync                     │
│    • Multi-device support               │
│    • User authentication                │
│                                         │
│ 2. Database: Cloud Firestore / Postgres │
│    • ACID transactions                  │
│    • Query optimization                 │
│    • Backup & recovery                  │
│                                         │
│ 3. AI: Dedicated Gemini Backend         │
│    • Rate limiting                      │
│    • Cost optimization                  │
│    • Custom model fine-tuning           │
│                                         │
│ 4. Real-time: WebSocket / Server-Sent   │
│    • Collaborative split bill           │
│    • Live updates                       │
│    • Presence indicators                │
└─────────────────────────────────────────┘
```

## Tech Stack

| Layer | Technology |
|-------|------------|
| Framework | Flutter 3.x (Dart) |
| State | Provider (ChangeNotifier) |
| Storage | SharedPreferences (JSON) |
| OCR | Google ML Kit (Offline) |
| AI | Google Gemini API |
| Charts | fl_chart |
| PDF | pdf + printing |
| UI | Custom Neo-Brutalism |

## File Structure

```
lib/
├── core/
│   ├── data/           # Demo data
│   ├── models/         # Data models
│   ├── services/       # Business logic
│   ├── settings/       # App settings
│   ├── state/          # State management
│   ├── theme/          # Colors, typography
│   └── utils/          # Helpers, formatters
├── features/
│   ├── dashboard/      # Personal dashboard
│   ├── onboarding/     # First-time experience
│   ├── pengaturan/     # Settings screen
│   ├── ringkasan/      # Split bill summary
│   ├── split_bill/     # Bill creation
│   ├── splash/         # App splash
│   └── umkm/           # UMKM features
│       ├── screens/    # All UMKM screens
│       └── widgets/    # Reusable widgets
└── shared/
    └── widgets/        # Common widgets
```

## Performance Metrics

| Metric | Value |
|--------|-------|
| Cold start | < 2s |
| OCR scan | < 3s (offline) |
| AI analysis | < 5s (online) |
| PDF export | < 1s |
| Analytics | < 100ms |
| Tests | 71/71 passing |
