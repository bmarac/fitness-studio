# API

Lokalna adresa API-ja je `http://localhost:5146`. Swagger UI dostupan je u Development okruzenju na `/swagger`, a OpenAPI dokument na `/openapi/v1.json`.

Registracija i prijava su anonimne. Account endpointi traze account JWT, a svi
poslovni endpointi studio-scoped JWT. Podaci se ogranicavaju na studio iz JWT-a.

## Endpointi

| Resurs | Endpointi |
| --- | --- |
| Auth | `POST /api/auth/register`, `POST /api/auth/login` |
| Studiji racuna | `GET`, `lookup`, `join` i `{studioId}/select` na `/api/account/studios` |
| Profil | `GET /api/profile` |
| Parametri mjerenja | CRUD na `/api/measurement-parameters` |
| Mjerenja clanova | povijest, posljednje stanje i unos na `/api/members/{memberId}/measurements` |
| Studio | `GET/PUT /api/studios/current` |
| Postavke studija | objedinjeni `GET/PUT /api/studio-settings/configuration`; genericki `GET /api/studio-settings` i `GET/PUT/DELETE /api/studio-settings/{setting}` |
| Naslijedene postavke placanja | `GET/PUT /api/payment-settings` ostaje radi kompatibilnosti; mobilna aplikacija koristi objedinjenu konfiguraciju |
| Clanarine | `GET /api/membership-payments/mine`; administratorski pregled s `view=pending|reported|overdue|paid|all`; prijava, potvrda i HUB3 barkod |
| Obavijesti | `GET /api/notifications`, oznacavanje procitanog i registracija tokena uredjaja |
| Clanovi | `GET`, `PUT` i `DELETE` na `/api/members`; novi clan nastaje pridruzivanjem studiju |
| Treneri | CRUD na `/api/trainers`; samo admin mijenja podatke |
| Vrste treninga | CRUD na `/api/class-types` |
| Paketi | CRUD na `/api/membership-plans` |
| Clanarine | CRUD na `/api/member-memberships` |
| Rasporedi | CRUD na `/api/recurring-class-schedules` |
| Fiksne dodjele | CRUD i prekid dodjele na `/api/member-fixed-schedules` |
| Termini | CRUD na `/api/class-sessions` |
| Rezervacije | CRUD i statusi na `/api/bookings` |

`PUT /api/member-memberships/{id}/billing` prima `firstBillingOn`. Odabrani datum
sprema se kao pocetak ritma naplate, odmah se stvaraju svi dospjeli mjesecni
obracuni, a odgovor vraca clanstvo, `createdObligations` i `nextBillingOn`.

Razdoblja clanstva tretiraju se kao poluotvorena (`startsOn` je ukljucen,
`endsOn` nije). API odbija drugo clanstvo istog clana koje se vremenski
preklapa. `isActive` se racuna prema danasnjem datumu u vremenskoj zoni studija
i zahtijeva da je clanstvo vec pocelo. Promjena paketa na postojecem clanstvu
ne mijenja pocetak ni sljedeci datum naplate; vec nastale obveze zadrzavaju
snimljeni naziv i iznos starog paketa.

## Posebne operacije

### Clanovi

Pregled popisa i pojedinog clana dostupan je adminu i treneru unutar istog studija. Novi clan nastaje iskljucivo kada se registrirani racun pridruzi studiju kodom. Izmjena i brisanje clana dostupni su samo adminu. Obican clan nema pristup `/api/members`, nego vlastite podatke dobiva preko `/api/profile`.

### Treneri

Prijavljeni korisnici studija mogu citati trenere. Samo admin moze unaprijed
kreirati, mijenjati ili brisati trenerski profil. Email se normalizira i ne smije
vec pripadati clanu ili treneru istog studija. Kada se racun s tim emailom
pridruzi studiju kodom, povezuje se s pripremljenim profilom i dobiva ulogu trenera.

### Parametri mjerenja

```http
GET    /api/measurement-parameters
GET    /api/measurement-parameters/{id}
POST   /api/measurement-parameters
PUT    /api/measurement-parameters/{id}
DELETE /api/measurement-parameters/{id}
```

Svi prijavljeni korisnici mogu citati aktivne parametre svog studija. Admin vidi i neaktivne parametre te jedini moze stvarati, mijenjati i deaktivirati parametre. `DELETE` ne brise povijesni zapis, nego postavlja status `inactive`.

`code` se zadaje pri kreiranju i ne mijenja se. Nakon sto parametar ima spremljene vrijednosti vise se ne mogu promijeniti `valueType`, `source` ni `calculationType`, kako bi povijesni podaci zadrzali isto znacenje.

### Mjerenja clanova

```http
GET  /api/members/{memberId}/measurements
GET  /api/members/{memberId}/measurements/latest
POST /api/members/{memberId}/measurements
```

Admin i trener mogu citati i unositi mjerenja clanova svojeg studija. Clan moze citati i unositi samo vlastita mjerenja.

Povijest vraca pojedinacne dogadjaje mjerenja. `latest` vraca posljednju poznatu vrijednost svakog parametra, neovisno o tome jesu li unesene u istom dogadjaju. BMI se izracunava iz posljednje dostupne visine i tezine i nikad se ne prima kao rucna vrijednost.

### Profil prijavljenog korisnika

```http
GET /api/profile
```

Objedinjuje korisnicki racun, uloge, studio te povezane podatke clana i/ili trenera. Za clana dodatno vraca aktivnu clanarinu s paketom, iskoristenost limita u aktualnom razdoblju i aktivne fiksne termine.

Razdoblje iskoristenosti prati `sessionLimitPeriod` paketa: `week`, `month` ili `membership`. U iskoristenost ulaze rezervacije statusa `booked`, `attended`, `no_show` i `late_cancelled`; `cancelled` i `waitlisted` se ne racunaju. Sve datumske granice racunaju se u vremenskoj zoni studija.

### Ogranicenje rezervacija paketom

`POST /api/bookings` zahtijeva clanstvo koje pokriva lokalni datum termina.

Isto pravilo vrijedi kada admin rezervira za clana i kada se rezervacija iz
`waitlisted` ili `cancelled` statusa prebacuje u status koji trosi paket.
Dosegnuti limit ili nepostojece clanstvo vracaju `409 Problem Details` s posebnim
razlogom. Paket bez `sessionLimit` je neogranicen. Automatske fiksne rezervacije
koje ne zadovoljavaju ova pravila preskacu se.

### Otkazivanje jednog termina

```http
PATCH /api/class-sessions/{id}/cancel
```

Admin moze otkazati svaki termin svojeg studija. Trener moze otkazati samo termin kojem je dodijeljen. Termin i njegove aktivne rezervacije prelaze u `cancelled`; ponavljajuci raspored ostaje nepromijenjen.

Ponavljajucim rasporedom upravlja se kroz `PATCH /api/recurring-class-schedules/{id}/pause`,
`/resume` i `/end`, uz tijelo `{ "effectiveFrom": "YYYY-MM-DD" }`. Admin upravlja
svim rasporedima studija, a trener samo vlastitima. Pauza otkazuje buduce generirane
termine i rezervacije uz cuvanje razloga otkazivanja; nastavak vraca samo termine i
fiksne rezervacije otkazane pauzom. Zavrseni raspored nije moguce ponovno aktivirati.

`POST /api/recurring-class-schedules` dostupan je adminu i treneru. Admin moze odabrati
bilo kojeg trenera svojeg studija, dok trener moze kreirati raspored samo za
`trainer_id` iz vlastitog JWT-a.

`PUT /api/recurring-class-schedules/{id}` dostupan je samo adminu i prima
`trainerId`, `dayOfWeek`, `startsAtTime`, `capacity` i `effectiveFrom`. Promjena
stvara novu vremensku verziju rasporeda, prenosi buduce termine, rezervacije i
fiksne dodjele te cuva povijesne termine. Kapacitet se ne moze smanjiti ispod
najveceg broja postojecih rezervacija ili aktivnih clanova fiksne grupe.

`GET /api/recurring-class-schedules/{id}/members` vraca trenutno aktivne clanove
fiksne grupe, sortirane po prezimenu i imenu. Admin moze otvoriti svaki raspored
studija, a trener samo vlastiti.

`GET /api/recurring-class-schedules/{id}/available-members?startsOn=YYYY-MM-DD`
dostupan je samo adminu i vraca aktivne clanove koje je moguce dodati od odabranog
datuma. Clan mora imati clanarinu za taj datum; tjedni paket smije imati najvise
`sessionLimit` aktivnih preklapajucih fiksnih dodjela, neograniceni paket nema taj
limit, a ograniceni mjesecni i ukupni paketi nisu dostupni za fiksne grupe.

`POST /api/member-fixed-schedules` dostupan je samo adminu. Aktivna dodjela stvara
se transakcijski zajedno s rezervacijama vec generiranih buducih termina od
`startsOn`. Neaktivni clanovi, neaktivni ili puni rasporedi i ponovljene aktivne ili
pauzirane dodjele odbijaju se. Termin bez slobodnog mjesta dobiva rezervaciju na
listi cekanja, a termini koje clanarina ne pokriva ostaju bez rezervacije. Paketni
limit ponovno se provjerava u istoj transakciji nakon zakljucavanja clana.

### Polaznici termina

```http
GET /api/bookings?classSessionId={id}
```

Vraca aktivne rezervacije sortirane po prezimenu i imenu. Admin moze pregledati svaki termin, a trener samo svoj. Svaka rezervacija sadrzi `bookingSource`. Ako je nastala iz fiksne dodjele, API vraca i opcionalni `memberFixedScheduleId`, koji klijentu omogucuje prekid te dodjele.

### Uklanjanje clana s termina

```http
DELETE /api/bookings/{id}
```

Operacija logicki otkazuje jednu buducu aktivnu rezervaciju. Clan moze otkazati
vlastitu rezervaciju, admin svaku rezervaciju u studiju, a trener samo rezervaciju
na svojem terminu. Otkaz na granici postavke `cancellationCutoffHours` ili ranije
dobiva status `cancelled` i vraca kvotu. Kasniji otkaz dobiva status
`late_cancelled`, oslobadja kapacitet i zadrzava potrosnju kvote. Waitlist
rezervacija uvijek dobiva `cancelled`.

### Prekid fiksne dodjele

```http
PATCH /api/member-fixed-schedules/{id}/cancel
Content-Type: application/json

{
  "effectiveFrom": "2026-09-28"
}
```

Admin moze prekinuti svaku fiksnu dodjelu u studiju, a trener samo dodjelu koja pripada njegovom ponavljajucem rasporedu. Operacija otkazuje aktivne buduce rezervacije te dodjele od zadanog datuma. Promjena dodjele i rezervacija izvodi se u jednoj transakciji.

### Premjestanje fiksne dodjele

```http
PATCH /api/member-fixed-schedules/{id}/move
Content-Type: application/json

{
  "targetRecurringScheduleId": 42
}
```

Premjestanje vrijedi od danas u vremenskoj zoni studija. Izvorna dodjela i njene
buduce rezervacije se otkazuju, a na aktivnom odredisnom rasporedu stvara se nova
dodjela i rezervacije vec generiranih termina. Puni raspored nije dopusteno odabrati.
Admin moze premjestati izmedu svih rasporeda studija, a trener samo izmedu vlastitih.
Promjena je transakcijska i ne mijenja povijesne dolaske.

### Termini prijavljenog trenera

```http
GET /api/class-sessions/mine
```

Vraca samo termine kojima je prijavljeni trener dodijeljen. Identitet trenera cita se iz JWT-a.

## Greske

- `400` neispravan request DTO
- `401` korisnik nije prijavljen ili je token istekao
- `403` korisnik nema ovlast za trazeni podatak ili akciju
- `404` resurs ne postoji unutar trenutnog studija
- `409` poslovno pravilo onemogucuje operaciju
- `500` neocekivana serverska greska

Greske se vracaju u Problem Details formatu. Primjeri zahtjeva nalaze se u `api/FitnessStudio.Api/FitnessStudio.Api.http`.
