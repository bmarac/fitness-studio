# Rezervacije

`Booking` povezuje clana s konkretnim `ClassSession` zapisom. Rezervacije se koriste u oba nacina rada studija kako bi se pratili kapacitet i dolasci.

## Kreiranje

Clan moze rezervirati samo aktivan buduci termin koji nije popunjen. Ne moze imati vise aktivnih rezervacija za isti termin. Backend ne vjeruje `memberId` vrijednosti koju clan posalje, nego koristi `member_id` iz JWT-a.

`booking_source` razlikuje izvor rezervacije:

- `self_service`
- `fixed_schedule`
- `makeup`
- `admin`

## Statusi

- `booked`: aktivna rezervacija
- `cancelled`: otkazana rezervacija
- `attended`: clan je prisustvovao
- `no_show`: clan nije dosao
- `waitlisted`: lista cekanja

Otkazane rezervacije ne zauzimaju kapacitet. Kod otkazivanja termina sve njegove neotkazane rezervacije prelaze u `cancelled`, a `cancelled_at` se postavlja na vrijeme otkazivanja.

Jedna rezervacija otkazuje se pozivom:

```http
DELETE /api/bookings/{id}
```

Brisanje je logicko: zapis ostaje u bazi sa statusom `cancelled`. Clan moze otkazati vlastitu rezervaciju, admin bilo koju rezervaciju u studiju, a trener samo rezervaciju termina kojem je dodijeljen.

## Uklanjanje iz fiksnog termina

```http
PATCH /api/member-fixed-schedules/{id}/cancel
Content-Type: application/json

{
  "effectiveFrom": "2026-09-28"
}
```

Admin moze prekinuti bilo koju fiksnu dodjelu, a trener samo dodjelu sa svog ponavljajuceg termina. Dodjela prelazi u `cancelled`, a buduce aktivne rezervacije izvora `fixed_schedule` za tog clana, ponavljajuci termin i datum od `effectiveFrom` nadalje prelaze u `cancelled`. Raniji dolasci, evidentirana prisutnost i rezervacije iz drugih izvora ostaju sacuvani. Promjena dodjele i rezervacija izvodi se u jednoj transakciji.

## Pregled polaznika

```http
GET /api/bookings?classSessionId={id}
```

Endpoint vraca neotkazane rezervacije. Admin vidi polaznike svakog termina u studiju, a trener samo termina kojem je dodijeljen. Mobilna aplikacija prikazuje sekciju **Polaznici** ispod popunjenosti na detaljima termina.

Odgovor rezervacije sadrzi `bookingSource`. Za rezervaciju izvora `fixed_schedule` sadrzi i `memberFixedScheduleId` kada postoji pripadajuca dodjela aktivna na datum termina. Mobilna aplikacija taj ID koristi za prikaz akcije prekida fiksne dodjele.

Admin moze mijenjati status svake rezervacije u studiju. Trener moze postaviti prisutnost ili drugi status samo za rezervacije termina kojem je osobno dodijeljen. Clan nema ovlast izravno postavljati `attended` ili `no_show`.

## Nadoknade

Baza podrzava vezu `makeup_for_booking_id`, kojom nova rezervacija moze predstavljati nadoknadu otkazane rezervacije. Potpuni poslovni tijek odobravanja i odabira nadoknade jos nije implementiran.

## Planirano

- rucno dodavanje clana na termin
- korisnicko otkazivanje vlastite rezervacije kroz mobilni UI
