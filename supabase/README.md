# toıdym — Supabase Backend & SQL Орнату Нұсқаулығы

Бұл папкада **toıdym** платформасының толық PostgreSQL дерекқоры, Row Level Security (RLS), атомарлы RPC транзакциялары, 1 минуттық Auto-Resale CRON жүйесі және Edge Functions бэкенді орналасқан.

## 1. Қандай файл не істейді?

- `supabase/migrations/001_schema_and_indexes.sql` — 9 кесте (`profiles`, `venues`, `venue_staff`, `box_templates`, `boxes`, `orders`, `reviews`, `notifications`, `audit_logs`), CHECK шектеулері, FK және өнімділік индекстері.
- `supabase/migrations/002_rls_and_rpcs.sql` — RLS саясаттары, `auth.users <-> profiles` триггерлері, `publish_sprint_box` (15 мин Спринт), `create_trust_reservation`, `complete_order_pickup`, `cancel_order_atomic`, `private.run_resale_cron_worker()`.
- `supabase/migrations/003_cron_and_seed.sql` — әр 1 минут сайын (`* * * * *`) қосылатын `pg_cron` жоспарлаушысы, Realtime баптауы және Астана қаласының бастапқы мекемелері/бокстары.
- `supabase/functions/resale-worker/index.ts` — 1 минуттық Resale CRON + Firebase (FCM) Strike Push хабарламасын жіберуші.
- `supabase/functions/approve-partner-lead/index.ts` — Админ өтінімді растағанда `PARTNER` аккаунты мен уақытша құпиясөз (`is_first_login = true`) жасаушы.
- `supabase/functions/create-partner/index.ts` — Жаңа `PARTNER` немесе `CASHIER` аккаунтын құрушы.

---

## 2. Қандай API кілттерді қайда қою керек?

Supabase Dashboard (`https://supabase.com/dashboard`) -> жобаңызды ашыңыз:

| Кілт / Айнымалы | Қайдан алады? | Қайда қояды? |
|---|---|---|
| `SUPABASE_URL` | **Project Settings -> API -> Project URL** | Flutter іске қосуда `--dart-define=SUPABASE_URL=...` немесе `lib/core/config/app_config.dart` |
| `SUPABASE_ANON_KEY` | **Project Settings -> API -> Project API keys -> `anon` / `publishable`** | Flutter іске қосуда `--dart-define=SUPABASE_ANON_KEY=...` немесе `lib/core/config/app_config.dart` |
| `USE_BACKEND` | Қолмен `true` деп бересіз | `--dart-define=USE_BACKEND=true` немесе `AppConfig.useBackend = true` |
| `SUPABASE_SERVICE_ROLE_KEY` | **Project Settings -> API -> `service_role` (secret)** | **ТЕК серверде!** Supabase Edge Functions авто-өзі алады; локалды/CLI үшін `supabase/.env` ішіне (`supabase secrets set`) |
| `CRON_SECRET` | Өзіңіз ойлап тапқан 32+ таңбалы кездейсоқ жол | `supabase secrets set CRON_SECRET=...` және сыртқы CRON шақырушы (`x-cron-secret` header) |
| `FCM_LEGACY_SERVER_KEY` *(міндетті емес)* | **Firebase Console -> Project Settings -> Cloud Messaging** | `supabase secrets set FCM_LEGACY_SERVER_KEY=...` (`resale-worker` push жіберу үшін) |

> **ҚАУІПСІЗДІК ЕРЕЖЕСІ:** `SUPABASE_SERVICE_ROLE_KEY` кілтін ЕШҚАШАН Flutter кодына (`lib/`) салмаңыз!

---

## 3. Іске қосу қадамдары

### 1-қадам: SQL кодты Supabase-ке жіберу
Supabase Dashboard -> **Database -> Extensions** бөлімінен **`pg_cron`** кеңейтімін қосыңыз.
Содан кейін **SQL Editor** арқылы ретімен іске қосыңыз (немесе CLI `supabase db push` арқылы):
1. `supabase/migrations/001_schema_and_indexes.sql`
2. `supabase/migrations/002_rls_and_rpcs.sql`
3. `supabase/migrations/003_cron_and_seed.sql`

*(Админ рөлін беру үшін алдымен қосымшада тіркеліңіз, сосын SQL Editor-да:)*
```sql
update public.profiles
set role = 'ADMIN', is_verified = true
where email = 'admin@toidym.kz';
```

### 2-қадам: Edge Functions деплой жасау
```bash
npm i -g supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set CRON_SECRET=your_random_32_char_secret
supabase functions deploy resale-worker --no-verify-jwt
supabase functions deploy approve-partner-lead
supabase functions deploy create-partner
```

### 3-қадам: Flutter қосымшасын нақты базамен іске қосу
```bash
flutter run -d chrome --web-port=8080 ^
  --dart-define=USE_BACKEND=true ^
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```
