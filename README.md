# Folio — Portfolio Tracker

> Track your Mutual Funds and Stocks in one place. Import from Groww, get live prices, and know exactly how your money is doing — every day.

---

## What is Folio?

Folio is a simple, private portfolio tracker for anyone who invests in **Mutual Funds** and **Stocks**. No login, no cloud, no subscriptions. Just your data on your phone.

You import your holdings once, add a free API key to fetch live prices, and Folio handles the rest — showing your total net worth, profit/loss, and daily change in a clean dark interface.

---

## How it helps you

### Know your net worth at a glance
Folio adds up all your Mutual Fund and Stock holdings and shows you your **total invested value**, **current value**, and **overall profit or loss** — all in one screen.

### Import straight from Groww
Already investing on Groww? Just export your **MF holdings report** or **stock holdings report** as an Excel file and import it into Folio. No manual entry needed.

### Live prices, always fresh
Add a free stock data API key and Folio will fetch the **latest NAV for Mutual Funds** and **live stock prices** for you. You can add multiple API keys as fallback.

### Daily portfolio summary
Folio sends you a **daily notification** with your portfolio summary — so you always know how your investments moved today, without opening the app.

### Day change tracking
See how much your portfolio **gained or lost today**, both in rupees and percentage — just like a brokerage app.

### 100% private
Everything is stored **locally on your phone**. No account, no server, no data sharing.

---

## Getting the app

Download the latest APK from the [Releases](../../releases) page and install it on your Android device.

> You may need to enable **"Install from unknown sources"** in your Android settings.

---

## How to use

### 1. Import your Mutual Fund holdings
- Open Groww → Portfolio → Mutual Funds → Export as Excel
- In Folio, go to the **Import** tab and pick the file

### 2. Import your Stock holdings
- Open Groww → Portfolio → Stocks → Export as Excel
- In Folio, go to the **Import** tab and pick the file

### 3. Add an API key for live prices
- Get a free key from [mboum.com](https://mboum.com) or similar stock data providers
- In Folio, go to **Import → API Keys** and add your key
- Folio supports multiple keys and rotates between them automatically

### 4. Set your daily notification time
- Go to **Import → Daily Summary** and set a time
- Folio will notify you every day with your portfolio snapshot

---

## Tech

Built with Flutter. Uses SQLite for local storage, WorkManager for background tasks, and flutter_local_notifications for daily alerts.

---

## License

MIT
