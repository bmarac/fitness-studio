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

Ponavljajuci raspored ima stanja `active`, `paused` i `ended`. Pauza, nastavak i trajni
zavrsetak primaju datum od kojeg promjena vrijedi. Otkazani termini i rezervacije cuvaju
razlog otkazivanja kako nastavak ne bi vratio pojedinacno otkazane termine ili rezervacije.

Admin moze otkazati svaki termin svojeg studija. Trener moze otkazati samo vlastiti termin.

## Mobilni tijek

Clan u prvom tabu **Termini** vidi tjedni pregled konkretnih izvedbi. Treneru i adminu
prvi tab vodi na zasebnu rutu **Rasporedi**, koja ponavljajuce rasporede prikazuje u
tjednoj mrezi s popunjenoscu aktivnih fiksnih grupa. Filteri odvajaju aktivne, pauzirane
i zavrsene rasporede, a isti ekran omogucuje kreiranje i upravljanje njihovim zivotnim
ciklusom. Detalji konkretnog termina i dalje nude samo otkazivanje te izvedbe.

Admin pri kreiranju rasporeda moze odabrati bilo kojeg trenera svojeg studija. Trener
moze kreirati raspored samo za sebe, a API tu vezu provjerava prema `trainer_id` claimu.

Klik na karticu rasporeda otvara trenutno aktivne clanove fiksne grupe i akcije
zivotnog ciklusa rasporeda. Clana je moguce premjestiti od danas na drugi aktivni
raspored s dostupnim fiksnim mjestom; buduce rezervacije prenose se transakcijski,
a raniji dolasci ostaju na izvornom rasporedu.

## Planirano

Promjena buducih termina jos nije implementirana. Predlozeno ponasanje je zatvoriti stari raspored dan prije datuma promjene, kreirati novi raspored i otkazati stare generirane buduce termine koje zamjenjuje novi raspored. Povijesni termini ne bi se brisali.
