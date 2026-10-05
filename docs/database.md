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

Servis je odgovoran za provjeru dopustenog kljuca, tipa i vrijednosti.

## Statusi

- `class_sessions`: `scheduled`, `cancelled`, `completed`
- `bookings`: `booked`, `cancelled`, `attended`, `no_show`, `waitlisted`
- `recurring_class_schedules`: `active`, `inactive`
- `member_fixed_schedules`: `active`, `paused`, `cancelled`
- `app_users`: `active`, `inactive`, `blocked`

## Migracije

Pocetna struktura je u `db/schema/001_initial_schema.sql`, a naknadne promjene u `db/migrations/`. Migracije se izvode redoslijedom broja. Postojece migracije ne treba prepisivati nakon sto su primijenjene; nova promjena dobiva novu migraciju.

Demo podaci za Stay Fit & Joyful nalaze se u `db/seeds/001_stay_fit_joyful_demo.sql`.
Testni clanovi, clanarine, fiksne dodjele i rezervacije nalaze se u
`db/seeds/002_stay_fit_joyful_members.sql` i primjenjuju se nakon osnovnog demo seeda.
Parametri napretka za demo studio nalaze se u
`db/seeds/003_stay_fit_joyful_measurement_parameters.sql`.
Cetiri povijesna mjerenja za Anu nalaze se u
`db/seeds/004_ana_progress.sql`.
