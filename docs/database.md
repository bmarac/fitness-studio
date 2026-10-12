# Baza podataka

Projekt koristi database-first pristup. SQL datoteke predstavljaju izvor strukture baze, a EF Core entiteti scaffoldaju se iz aktivne PostgreSQL baze.

## Tablice

| Tablica | Svrha |
| --- | --- |
| `studios` | Fitness studiji i njihova vremenska zona |
| `studio_settings` | Prosirive postavke studija zapisane kao kljuc, vrijednost i tip |
| `members` | Clanovi studija |
| `trainers` | Treneri studija |
| `class_types` | Vrste treninga, zadano trajanje i kapacitet |
| `recurring_class_schedules` | Tjedna pravila ponavljanja termina |
| `class_sessions` | Konkretni termini s datumom i vremenom |
| `member_fixed_schedules` | Dodjela clana fiksnom ponavljajucem rasporedu |
| `bookings` | Rezervacije za konkretne termine |
| `membership_plans` | Paketi i njihova ogranicenja |
| `member_memberships` | Paket dodijeljen clanu |
| `membership_payment_obligations` | Mjesecni obracuni clanarine sa snimljenim iznosom i podacima za uplatu |
| `app_notifications` | In-app podsjetnici clanovima i adminima |
| `app_user_device_tokens` | Registrirani mobilni uredjaji za buduci FCM transport |
| `app_users` | Korisnicki racuni za prijavu |
| `app_user_roles` | Vise uloga po korisnickom racunu |
| `measurement_parameters` | Parametri napretka koje definira pojedini studio |
| `member_measurements` | Jedan dogadjaj mjerenja clana |
| `member_measurement_values` | Vrijednosti parametara unutar jednog mjerenja |

## Vazni odnosi

```text
studios
  -> members, trainers, class_types
  -> recurring_class_schedules -> class_sessions -> bookings
  -> membership_plans -> member_memberships

app_users -> app_user_roles
app_users -> member ili trainer profil

measurement_parameters -> member_measurement_values
members -> member_measurements -> member_measurement_values
app_users -> member_measurements (korisnik koji je unio mjerenje)
```

`room_name` je uklonjen iz ponavljajucih rasporeda i termina migracijom `007_remove_rooms.sql`.

## Postavke studija

`studio_settings` omogucuje dodavanje pravila bez nove kolone za svaku postavku:

- `setting`: stabilan kljuc postavke
- `value`: tekstualno zapisana vrijednost
- `value_type`: `boolean`, `integer`, `decimal`, `string` ili `enum`

Trenutno vazne postavke:

- `booking_mode`: `open_booking` ili `fixed_schedule`
- `allow_makeups`: dopusta li studio nadoknade
- `class_session_generation_weeks_ahead`: broj tjedana unaprijed za generiranje termina
- `payment_recipient_name`, `payment_iban`, `payment_model`, `payment_reference`, `payment_description`: podaci za HUB3 uplatu
- `payment_member_reminder_days`, `payment_admin_reminder_days`, `payment_notification_time`: raspored podsjetnika

Servis je odgovoran za provjeru dopustenog kljuca, tipa i vrijednosti.

## Statusi

- `class_sessions`: `scheduled`, `cancelled`, `completed`
- `bookings`: `booked`, `cancelled`, `attended`, `no_show`, `waitlisted`
- `recurring_class_schedules`: `active`, `paused`, `ended`; `status_effective_from`
  biljezi datum pocetka pauze ili zavrsetka
- `class_sessions.cancellation_reason` i `bookings.cancellation_reason` razlikuju
  pojedinacno otkazivanje od promjene cijelog rasporeda
- `member_fixed_schedules`: `active`, `paused`, `cancelled`
- `app_users`: `active`, `inactive`, `blocked`
- `membership_payment_obligations`: `pending`, `reported`, `paid`; kasnjenje se racuna iz datuma dospijeca

Clanstvo nema status pauze. Aktivnost se racuna iz `starts_on` i opcionalnog,
iskljucivog `ends_on`. `billing_starts_on` cuva datum od kojeg je admin ukljucio
naplatu i izvorni dan mjesecnog ritma. `next_billing_on` je operativni pokazivac sljedeceg
mjesecnog obracuna. Postojeca clanstva nakon migracije nemaju automatsku
naplatu dok admin ne postavi prvi datum.

## Migracije

Pocetna struktura je u `db/schema/001_initial_schema.sql`, a naknadne promjene u
`db/migrations/`. `db/bootstrap.sh` primjenjuje pocetnu shemu, migracije i seedove
abecednim redoslijedom datoteka. Docker ga automatski izvodi samo pri inicijalizaciji
praznog PostgreSQL volumea. Postojece migracije ne treba prepisivati nakon sto su
primijenjene; nova promjena dobiva novu numeriranu migraciju.

Demo podaci za Stay Fit & Joyful nalaze se u `db/seeds/001_stay_fit_joyful_demo.sql`.
Testni clanovi, clanarine, fiksne dodjele i rezervacije nalaze se u
`db/seeds/002_stay_fit_joyful_members.sql` i primjenjuju se nakon osnovnog demo seeda.
Parametri napretka za demo studio nalaze se u
`db/seeds/003_stay_fit_joyful_measurement_parameters.sql`.
Cetiri povijesna mjerenja za Anu nalaze se u
`db/seeds/004_ana_progress.sql`.

Svjezi bootstrap i ocekivanu konacnu strukturu moguce je provjeriti bez promjene
razvojne baze naredbom `./scripts/verify-fresh-stack.sh`. Skripta koristi vlastiti
privremeni container i uklanja ga po zavrsetku.
