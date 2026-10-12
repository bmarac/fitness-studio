# API

Lokalna adresa API-ja je `http://localhost:5146`. Swagger UI dostupan je u Development okruzenju na `/swagger`, a OpenAPI dokument na `/openapi/v1.json`.

Svi endpointi osim prijave zahtijevaju valjani JWT zbog globalne fallback authorization policy. Podaci se ogranicavaju na studio iz JWT-a.

## Endpointi

| Resurs | Endpointi |
| --- | --- |
| Auth | `POST /api/auth/login` |
| Profil | `GET /api/profile` |
| Parametri mjerenja | CRUD na `/api/measurement-parameters` |
| Mjerenja clanova | povijest, posljednje stanje i unos na `/api/members/{memberId}/measurements` |
| Studio | `GET/PUT /api/studios/current` |
| Postavke | `GET /api/studio-settings`, `GET/PUT/DELETE /api/studio-settings/{setting}` |
| Postavke placanja | `GET/PUT /api/payment-settings` |
| Clanarine | `GET /api/membership-payments/mine`; administratorski pregled s `view=pending|reported|overdue|paid|all`; prijava, potvrda i HUB3 barkod |
| Obavijesti | `GET /api/notifications`, oznacavanje procitanog i registracija tokena uredjaja |
| Clanovi | CRUD na `/api/members` |
| Treneri | CRUD na `/api/trainers` |
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

## Posebne operacije

### Clanovi

Pregled popisa i pojedinog clana dostupan je adminu i treneru unutar istog studija. Kreiranje, izmjena i brisanje clana dostupni su samo adminu. Obican clan nema pristup `/api/members`, nego vlastite podatke dobiva preko `/api/profile`.

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

Admin i trener mogu citati i unositi mjerenja clanova svojeg studija. Clan moze citati samo vlastita mjerenja i ne moze ih unositi.

Povijest vraca pojedinacne dogadjaje mjerenja. `latest` vraca posljednju poznatu vrijednost svakog parametra, neovisno o tome jesu li unesene u istom dogadjaju. BMI se izracunava iz posljednje dostupne visine i tezine i nikad se ne prima kao rucna vrijednost.

### Profil prijavljenog korisnika

```http
GET /api/profile
```

Objedinjuje korisnicki racun, uloge, studio te povezane podatke clana i/ili trenera. Za clana dodatno vraca aktivnu clanarinu s paketom, iskoristenost limita u aktualnom razdoblju i aktivne fiksne termine.

Razdoblje iskoristenosti prati `sessionLimitPeriod` paketa: `week`, `month` ili `membership`. U iskoristenost ulaze rezervacije statusa `booked`, `attended` i `no_show`; `cancelled` i `waitlisted` se ne racunaju. Sve datumske granice racunaju se u vremenskoj zoni studija.

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

### Polaznici termina

```http
GET /api/bookings?classSessionId={id}
```

Vraca aktivne rezervacije sortirane po prezimenu i imenu. Admin moze pregledati svaki termin, a trener samo svoj. Svaka rezervacija sadrzi `bookingSource`. Ako je nastala iz fiksne dodjele, API vraca i opcionalni `memberFixedScheduleId`, koji klijentu omogucuje prekid te dodjele.

### Uklanjanje clana s termina

```http
DELETE /api/bookings/{id}
```

Operacija logicki otkazuje jednu rezervaciju. Clan moze otkazati vlastitu rezervaciju, admin svaku rezervaciju u studiju, a trener samo rezervaciju na svojem terminu.

### Prekid fiksne dodjele

```http
PATCH /api/member-fixed-schedules/{id}/cancel
Content-Type: application/json

{
  "effectiveFrom": "2026-09-28"
}
```

Admin moze prekinuti svaku fiksnu dodjelu u studiju, a trener samo dodjelu koja pripada njegovom ponavljajucem rasporedu. Operacija otkazuje aktivne buduce rezervacije te dodjele od zadanog datuma. Promjena dodjele i rezervacija izvodi se u jednoj transakciji.

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
