# MyWallet - Ziraat Bank Automation 🏦📈

A robust, offline-first personal finance tracker built with Flutter. MyWallet automates the tedious process of manual expense tracking by securely parsing unread bank transaction emails via IMAP, categorizing them, and updating a reactive dashboard in real-time.

## 📱 UI Preview

<div align="center">
<div style="background:var(--surface-1);border-radius:16px;padding:24px;display:flex;justify-content:center;gap:32px;flex-wrap:wrap">
<div style="width:280px;background:#000000;border-radius:28px;padding:14px;font-family:var(--font-sans);position:relative;overflow:hidden;box-shadow:0 0 0 6px #1a1a1a">
<div style="display:flex;align-items:center;gap:10px;margin-bottom:16px">
<div style="width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,#9E829C,#5C4A5A);display:flex;align-items:center;justify-content:center"><i class="ti ti-menu-2" style="font-size:16px;color:#000"></i></div>
<span style="color:#F0EFF4;font-size:15px;font-weight:500">MyWallet</span>
</div>
<div style="background:linear-gradient(135deg,#432349,#34193A 55%,#1B0E1E);border-radius:18px;padding:16px;margin-bottom:10px">
<div style="color:#F0EFF480;font-size:10px;letter-spacing:1px;margin-bottom:6px">NET BALANCE</div>
<div style="color:#F0EFF4;font-size:24px;font-weight:500">₺ 4,230.50</div>
</div>
<div style="display:flex;gap:8px;margin-bottom:14px">
<div style="flex:1;background:linear-gradient(135deg,#3A4238,#34193A);border-radius:14px;padding:10px">
<div style="width:20px;height:20px;border-radius:50%;background:#7C8877;margin-bottom:6px"></div>
<div style="color:#F0EFF488;font-size:9px;letter-spacing:0.5px">INCOME</div>
<div style="color:#F0EFF4;font-size:13px;font-weight:500">₺ 8,100</div>
</div>
<div style="flex:1;background:linear-gradient(135deg,#4A3549,#34193A);border-radius:14px;padding:10px">
<div style="width:20px;height:20px;border-radius:50%;background:#9E829C;margin-bottom:6px"></div>
<div style="color:#F0EFF488;font-size:9px;letter-spacing:0.5px">EXPENSE</div>
<div style="color:#F0EFF4;font-size:13px;font-weight:500">₺ 3,870</div>
</div>
</div>
<div style="color:#F0EFF480;font-size:9px;letter-spacing:1px;margin:0 0 8px 2px">OVERVIEW</div>
<div style="display:flex;gap:8px">
<div style="flex:1;background:#2C1730;border-radius:14px;padding:10px;display:flex;flex-direction:column;align-items:center">
<svg width="70" height="70" viewBox="0 0 36 36" style="margin-bottom:8px">
<circle cx="18" cy="18" r="15.5" fill="none" stroke="#3A3E3B" stroke-width="5"></circle>
<circle cx="18" cy="18" r="15.5" fill="none" stroke="#9E829C" stroke-width="5" stroke-dasharray="58 100" stroke-dashoffset="0"></circle>
<circle cx="18" cy="18" r="15.5" fill="none" stroke="#7C8877" stroke-width="5" stroke-dasharray="24 100" stroke-dashoffset="-58"></circle>
<circle cx="18" cy="18" r="15.5" fill="none" stroke="#6E5A6C" stroke-width="5" stroke-dasharray="18 100" stroke-dashoffset="-82"></circle>
</svg>
<div style="width:100%;font-size:9px;color:#F0EFF4"><span style="display:inline-block;width:6px;height:6px;border-radius:50%;background:#9E829C;margin-right:4px"></span>Food</div>
<div style="width:100%;font-size:9px;color:#F0EFF4;margin-top:3px"><span style="display:inline-block;width:6px;height:6px;border-radius:50%;background:#7C8877;margin-right:4px"></span>Bills</div>
</div>
<div style="flex:1.2;background:#2C1730;border-radius:14px;padding:10px">
<div style="display:flex;justify-content:space-between;font-size:9px;color:#F0EFF480;margin-bottom:8px"><span>RECENT</span><span style="color:#9E829C">View all</span></div>
<div style="border-left:2px solid #9E829C;background:#34193A;border-radius:8px;padding:6px 8px;margin-bottom:5px">
<div style="color:#F0EFF4;font-size:9px">Groceries</div>
<div style="color:#9E829C;font-size:8px">Food</div>
</div>
<div style="border-left:2px solid #7C8877;background:#34193A;border-radius:8px;padding:6px 8px">
<div style="color:#F0EFF4;font-size:9px">Salary</div>
<div style="color:#7C8877;font-size:8px">Income</div>
</div>
</div>
</div>
<div style="position:absolute;bottom:16px;right:16px;background:#9E829C;border-radius:20px;padding:8px 14px;display:flex;align-items:center;gap:6px">
<i class="ti ti-plus" style="font-size:14px;color:#000"></i><span style="color:#000;font-size:11px;font-weight:500">Add</span>
</div>
</div>
<div style="width:280px;background:#000000;border-radius:28px;padding:14px;font-family:var(--font-sans);position:relative;overflow:hidden;box-shadow:0 0 0 6px #1a1a1a">
<div style="position:absolute;inset:0;background:rgba(0,0,0,0.55)"></div>
<div style="position:relative;width:210px;height:100%;background:#000;padding:18px 16px;display:flex;flex-direction:column">
<div style="display:flex;align-items:center;gap:10px;margin-bottom:20px">
<div style="width:38px;height:38px;border-radius:50%;background:linear-gradient(135deg,#9E829C,#5C4A5A);display:flex;align-items:center;justify-content:center"><i class="ti ti-wallet" style="font-size:17px;color:#000"></i></div>
<div><div style="color:#F0EFF4;font-size:14px;font-weight:500">MyWallet</div><div style="color:#F0EFF460;font-size:9px">Personal finance</div></div>
</div>
<div style="height:1px;background:#F0EFF414;margin-bottom:12px"></div>
<div style="display:flex;flex-direction:column;gap:6px">
<div style="display:flex;align-items:center;gap:10px;padding:8px;border-radius:10px"><div style="width:26px;height:26px;border-radius:50%;background:#34193A;display:flex;align-items:center;justify-content:center"><i class="ti ti-plus" style="font-size:13px;color:#F0EFF4d9"></i></div><span style="color:#F0EFF4;font-size:11px">Add transaction</span></div>
<div style="display:flex;align-items:center;gap:10px;padding:8px;border-radius:10px"><div style="width:26px;height:26px;border-radius:50%;background:#34193A;display:flex;align-items:center;justify-content:center"><i class="ti ti-category" style="font-size:13px;color:#F0EFF4d9"></i></div><span style="color:#F0EFF4;font-size:11px">Manage categories</span></div>
<div style="display:flex;align-items:center;gap:10px;padding:8px;border-radius:10px"><div style="width:26px;height:26px;border-radius:50%;background:#34193A;display:flex;align-items:center;justify-content:center"><i class="ti ti-refresh" style="font-size:13px;color:#F0EFF4d9"></i></div><span style="color:#F0EFF4;font-size:11px">Sync bank emails</span></div>
<div style="display:flex;align-items:center;gap:10px;padding:8px;border-radius:10px;background:#34193A"><div style="width:26px;height:26px;border-radius:50%;background:#291528;display:flex;align-items:center;justify-content:center"><i class="ti ti-adjustments" style="font-size:13px;color:#F0EFF4d9"></i></div><span style="color:#F0EFF4;font-size:11px">Daily limit</span></div>
</div>
</div>
</div>
</div>
</div>

## ✨ Key Features

* **Automated Data Pipeline:** Integrates an IMAP client to fetch and securely read automated bank emails (Ziraat Bankası) entirely on the device.
* **Smart Regex Parsing:** Sanitizes raw, unstructured HTML emails and extracts precise transaction data (Dates, Minor/Major Units, Senders/Receivers, FAST transfers) using strict Regular Expressions.
* **Local Persistence Sandbox:** Utilizes an isolated SQLite database to store transactions and custom user categories offline, ensuring complete data privacy.
* **Reactive Architecture:** Built on a Riverpod state management foundation. The UI, data repository layer, and background parsers remain perfectly synchronized without requiring manual state refreshes.
* **Dynamic Categorization Engine:** Automatically intercepts, maps, and sorts incoming/outgoing automated transactions. It intelligently falls back to recognized internal database IDs to prevent UI state rendering errors.

## 🛠 Tech Stack

* **Framework:** Flutter / Dart
* **State Management:** Riverpod
* **Database:** SQLite
* **Email Client:** enough_mail (IMAP)

## 🚀 Architectural Challenges Overcome

Building this application required navigating complex mobile development hurdles:
1. **R8 Compiler Stripping:** Resolved silent runtime failures in Android Release builds by overriding `build.gradle` rules to protect core data models.
2. **State-Sync Fallbacks:** Engineered a bulletproof fallback mechanism for the UI to prevent unhandled ID exceptions when dynamically generating SQL database categories during background tasks.

## ⚙️ Getting Started

### Prerequisites
* Flutter SDK (latest stable)
* An App Password generated from your email provider (e.g., Gmail) to allow secure IMAP access.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/muhammedham/automated-finance-tracker.git
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Set up your environment variables (ensure your personal IMAP credentials are not hardcoded!).

4. Run the app:
   ```bash
   flutter run
   ```

## 👤 Author

**Muhammed Hamadin**
* Software Engineer
* GitHub: https://github.com/muhammedham
