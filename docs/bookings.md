# Rezervacije

`Booking` povezuje clana s konkretnim `ClassSession` zapisom. Rezervacije se koriste u oba nacina rada studija kako bi se pratili kapacitet i dolasci.

## Kreiranje

Clan moze rezervirati samo aktivan buduci termin koji nije popunjen. Ne moze imati vise aktivnih rezervacija za isti termin. Backend ne vjeruje `memberId` vrijednosti koju clan posalje, nego koristi `member_id` iz JWT-a.

Datum termina mora biti unutar clanstva clana. Paket odreduje broj dopustenih
termina po kalendarskom tjednu (ponedjeljak-nedjelja), kalendarskom mjesecu ili
cijelom trajanju clanstva. Granice se racunaju u vremenskoj zoni studija, a
`ends_on` je iskljuciva granica. Paket bez limita je neogranicen.

Limit vrijedi jednako za samostalne i administratorske rezervacije. Provjera i
upis serijalizirani su po clanu kako paralelni zahtjevi ne bi mogli potrositi isto
posljednje mjesto u paketu.

Za clana s tjednim paketom i fiksnim rasporedom limit se racuna po mjesecnom
obracunskom ciklusu clanarine. Ukupan broj dopustenih termina dobiva se brojanjem
dana iz njegovih fiksnih dodjela unutar ciklusa, bez ovisnosti o tome jesu li
konkretni termini vec generirani. Aktivne, odradjene i `no_show` rezervacije trose
kvotu. Pravodobno otkazivanje rezervacije oslobadja jedno mjesto u kvoti unutar
istog ciklusa; mjesto se ne prenosi u sljedeci ciklus. Status uplate ne utjece
na ovu kvotu.

`booking_source` razlikuje izvor rezervacije:

- `self_service`
- `fixed_schedule`
- `admin`

## Statusi

- `booked`: aktivna rezervacija
- `cancelled`: otkazana rezervacija
- `late_cancelled`: kasni otkaz koji i dalje trosi kvotu
- `attended`: clan je prisustvovao
- `no_show`: clan nije dosao
- `waitlisted`: lista cekanja

`cancelled` i `late_cancelled` rezervacije ne zauzimaju kapacitet. Kod
otkazivanja termina sve njegove neotkazane rezervacije prelaze u `cancelled`, a
`cancelled_at` se postavlja na vrijeme otkazivanja.

U potrosnju paketa ulaze `booked`, `attended`, `no_show` i `late_cancelled`.
`cancelled` i `waitlisted` ne trose paket. Prijelaz u status koji trosi paket
ponovno provjerava clanstvo i raspolozivi limit.

Jedna rezervacija otkazuje se pozivom:

```http
DELETE /api/bookings/{id}
```

Brisanje je logicko. Ako do pocetka ima najmanje
`cancellation_cutoff_hours`, rezervacija prelazi u `cancelled` i vraca kvotu.
Kasniji otkaz prelazi u `late_cancelled`: oslobadja kapacitet, ali i dalje trosi
kvotu i blokira ponovnu prijavu na isti termin. Rezervacija na listi cekanja
uvijek prelazi u `cancelled`. Isto vremensko pravilo vrijedi za clana, admina i
trenera kod pojedinacnog uklanjanja. Otkazivanje jednog termina ne prekida
clanovu fiksnu dodjelu.

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

## Fiksni raspored i paket

Automatsko stvaranje ili obnavljanje rezervacije iz fiksnog rasporeda koristi
ista pravila clanstva. Ako clan nema paket za datum termina ili je limit vec
potrosen, rezervacija se preskace i ne stvara se ni zapis na listi cekanja.
Rezervacija otkazana zbog pauze rasporeda ostaje otkazana ako pri nastavku vise
ne zadovoljava pravila paketa.

## Planirano

- rucno dodavanje clana na termin
