# Dwillo

**A SwiftUI app for a home's maintenance history. Log a repair once and it works out when the
task is due again, reminds you, and scores how well the house is being kept up.**

![Four Dwillo screens from the iOS simulator: the welcome screen, the home dashboard with a home health score of 65 and its breakdown, the log form with category, cost, priority, and contractor fields, and the timeline calendar showing an upcoming HVAC filter change](docs/screens.png)

Most home maintenance goes wrong through forgetting, not through lack of skill. A filter change
or a gutter cleaning is easy to do and easy to lose track of, and the cost shows up years later as
an emergency repair. Dwillo treats the log as the schedule. Each entry carries a task title and a
category, which is enough to infer when the same job is due next, so the app can turn a record of
past work into a calendar of future work without asking the owner to plan anything.

Support, terms, and privacy: **https://keshavkrishnan08.github.io/Dwello/**

```
onboarding (12 steps: home type and age, habits, systems, goals, reminder time)
    ->  log an entry (category, title, date, cost, priority, contractor, notes)
    ->  scheduler: 31 keyword rules, then category defaults, pick the next check-in
    ->  reminder plus local notifications
    ->  home health score from hand-weighted features, A to F grade per category
    ->  stats: spend charts, linear-trend cost forecast, risk, savings tips, appliance age alerts
    ->  JSON in UserDefaults on the device, mirrored to the user's private iCloud database
```

Log it once. The app remembers when it is due again.

## The core idea

1. **The log drives the schedule.** "Changed HVAC filter" maps to 30 days, "clean gutters" to
   180, "inspect roof" to 365. If no keyword matches, the category default applies (90 days for
   HVAC and appliances, 180 for plumbing and exterior, 365 for electrical and structure). Logging
   a task creates the follow-up reminder unless one is already pending.
2. **Recurring work rolls forward.** Completing a recurring reminder creates the next occurrence
   (monthly, quarterly, semi-annual, or annual) and skips it if a matching one already exists.
3. **One number for "how is the house doing."** The health score starts at 75 and adds or
   subtracts for overdue reminders, days since the last log, recent activity, how many of the six
   areas were covered in the last six months, expired warranties, aging appliances, saved
   contractors, home age, recurring tasks, and recent completions. It is clamped to 0 to 100 and
   shows its own breakdown, so the user sees which items moved it.
4. **Everything stays with the user.** There is no app server. Data lives on the device and in the
   user's own private CloudKit database.

## What it does

| Area | In the code |
|---|---|
| Onboarding | 12 steps: home type, home age, maintenance habits, systems to track, goals, biggest challenge, existing systems, reminder time, a personalized summary, a plan-building animation, and a paywall |
| Home tab | Health score ring with its breakdown, spend this month and all time, projected yearly spend, estimated savings, quick-log shortcuts, upcoming reminders, recent entries |
| Log tab | Category, title with suggested tasks, date, cost, priority (routine, important, urgent), recurring toggle, contractor with rating, notes, and the recommended next check-in |
| Timeline tab | Month calendar of logged work and upcoming check-ins for the selected day |
| Stats tab | Swift Charts views: spend by month for the last six months, spend by category, a six-month cost forecast with a band, category risk, savings suggestions, appliance replacement alerts |
| Profile tab | Home profile, contractor address book with job history and total spend, appliance registry with purchase and warranty dates, reminders list, seasonal checklist for spring, summer, fall, and winter, and 10 achievements |
| Notifications | 9 AM on the due date, 6 PM the day before, a Sunday 10 AM weekly summary with the score and overdue count, and a monthly seasonal tip |
| Sync | Debounced push of logs, contractors, reminders, and appliances to the private iCloud database; restore from iCloud on a fresh install |
| Subscription | StoreKit 2 with monthly ($4.99) and yearly ($24.99) products, restore purchases, and a local StoreKit configuration with a one-week trial on the yearly plan |

## How it works

**Models.** Plain `Codable` structs: `Home`, `LogEntry`, `Reminder`, `Contractor`, `Appliance`,
`Achievement`, and `OnboardingResponses`, with `HomeCategory` (plumbing, electrical, HVAC,
exterior, appliances, structure, other), `Priority`, and `RecurringInterval` enums.

**State and persistence.** One `@Observable` `AppStore` owns the arrays. Every change encodes
them as JSON into `UserDefaults` and triggers a CloudKit sync debounced by 2 seconds. Onboarding
answers are stored the same way and set the home type and an approximate build year.

**Sync.** `CloudKitManager` maps each model to a `CKRecord` in the private database and saves in
batches with the changed-keys policy. On launch the app pulls everything from iCloud if the local
log is empty, and pushes local data otherwise.

**Scheduling.** `MaintenanceScheduler` matches the lowercased task title against 31 keyword rules
and falls back to a per-category default. It also labels the interval ("Every 3 months") and
annualizes a single cost.

**Scoring.** `HomeHealthScorer` computes the 0 to 100 score from 12 extracted features with fixed
weights and returns the component list the home screen displays. Each category gets a letter
grade from days since its last service and its overdue reminders.

**Forecast and insights.** `MaintenanceMLEngine` fits an ordinary least-squares line to monthly
spend and projects six months ahead with a band of 1.5 residual standard deviations. Category
risk grows with days since the last service (365 days reaches 100) and is raised 20% for
categories that average over $200 a job. Savings suggestions are rules: heavy spending in one
category, several tasks under $100, repeated HVAC filter changes, missing spring or fall
checkups, and repeated contractor visits. Appliance alerts compare age with typical lifespans for
10 appliance types.

**Design system.** `Theme/` holds colors, typography, spacing, animations, haptics, and the
gradient background. Views are built from atoms (button, chip, text field, progress bar),
molecules (category selector, reminder row, stat pill), and organisms (log form, timeline card,
charts).

## Run it

Open `HomeService.xcodeproj` in Xcode and run the `HomeService` scheme on a simulator or device
(iOS 17.0 or later). `HomeService/Configuration.storekit` lets you test the subscription locally.
iCloud sync needs a signing team with access to the app's CloudKit container; without iCloud the
app runs on local storage alone.

## Layout

```
HomeService/
  App/                     app entry: onboarding gate, iCloud restore, StoreKit, notifications
  Models/                  Codable models and category, priority, interval enums
  Stores/                  AppStore (state, persistence, scheduling hooks), OnboardingStore
  Services/                CloudKitManager, MaintenanceScheduler, HomeHealthScorer,
                           MaintenanceMLEngine, NotificationManager, SubscriptionManager
  Theme/                   colors, typography, spacing, animations, haptics
  Views/
    Onboarding/            12-step onboarding and paywall
    Tabs/                  Home, Log, Timeline, Stats, Profile
    Components/            atoms, molecules, organisms
  Legal/                   privacy, terms, and support pages
  Configuration.storekit   local StoreKit products
HomeServiceTests/          unit test target
HomeServiceUITests/        UI test target
docs/                      GitHub Pages site (support, terms, privacy)
SS/                        simulator and store-size screenshots
```

## Honesty

* Nothing here is trained. `MaintenanceMLEngine` and `HomeHealthScorer` are hand-set weights,
  rules, and a least-squares trend line.
* "Estimated savings" assumes deferred work costs three times as much and that each routine task
  done yourself avoids a $150 call. Those are assumptions in the code, not measurements.
* iCloud sync only pushes and upserts. Deletions are not sent to iCloud, and a restore happens only
  when the local log is empty.
* Some screens are still placeholders: data export, notification settings, help, and Delete
  Account. The app supports one home and has no accounts.
* The app's display name, bundle ID, StoreKit products, and legal pages say Dwillo; the repository
  is named Dwello.
