# Termini i rasporedi

## Dva modela rada

Studio ima postavku `booking_mode`:

- `open_booking`: clan sam bira dostupne termine
- `fixed_schedule`: admin ili trener clanu dodjeljuje fiksni raspored, ali se dolasci i dalje prate kroz rezervacije

Stay Fit & Joyful koristi `fixed_schedule`.

## Ponavljajuci raspored

`recurring_class_schedules` opisuje tjedno pravilo, primjerice Pilates svakog ponedjeljka u 18:00. Sadrzi vrstu treninga, trenera, dan u tjednu, vrijeme, trajanje, kapacitet i razdoblje valjanosti.

Kod kreiranja aktivnog rasporeda `RecurringClassSchedulesService`:

1. provjerava pripadnost vrste treninga i trenera studiju
2. provjerava valjanost datuma i statusa
3. sprjecava vremensko preklapanje rasporeda istog trenera
4. sprema raspored unutar transakcije
5. generira konkretne `class_sessions`

Broj tjedana generiranja cita se iz `class_session_generation_weeks_ahead`. Zadana vrijednost je 4, a servis ogranicava vrijednost na najvise 52 tjedna.

## Konkretan termin

`class_sessions` je izvedba rasporeda na konkretnom datumu i vremenu. Termin moze postojati i bez ponavljajuceg rasporeda.

Otkazivanje kroz `PATCH /api/class-sessions/{id}/cancel` utjece samo na odabrani termin. Ponavljajuci raspored i ostali buduci termini ostaju aktivni. Aktivne rezervacije otkazanog termina također se otkazuju.

Admin moze otkazati svaki termin svojeg studija. Trener moze otkazati samo vlastiti termin.

## Mobilni tijek

Tab **Termini** prikazuje tjedni raspored. Trener i admin trenutno vide gumb za novi ponavljajuci termin, ali API write operacije nad ponavljajucim rasporedima trenutno zahtijevaju ulogu `admin`. Detalji konkretnog termina prikazuju datum, vrijeme, trajanje, status, popunjenost i, za ovlastene korisnike, polaznike i akciju otkazivanja.

## Planirano

Promjena buducih termina jos nije implementirana. Predlozeno ponasanje je zatvoriti stari raspored dan prije datuma promjene, kreirati novi raspored i otkazati stare generirane buduce termine koje zamjenjuje novi raspored. Povijesni termini ne bi se brisali.
