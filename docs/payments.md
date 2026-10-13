# Naplata clanarina

Sustav vodi mjesecne obveze i status uplate. Ne izvrsava bankovne transakcije i
ne potvrduje ih automatski preko banke; clan prijavljuje uplatu, a administrator
je potvrduje.

## Ukljucivanje naplate

Administrator najprije postavlja primatelja, IBAN, model i poziv na broj, opis
placanja te dane podsjetnika. Naplata se zatim ukljucuje zasebno za clanstvo uz
datum `firstBillingOn`. Datum mora biti unutar razdoblja clanstva.

Clanstvo cuva izvorni `billing_starts_on` i operativni `next_billing_on`. Generator
stvara sve obveze dospjele do danas i ne stvara duplikat za isto clanstvo i
pocetak mjesecnog razdoblja.

## Zivotni ciklus obveze

- `pending`: obveza ceka uplatu ili prijavu clana
- `reported`: clan je prijavio uplatu i ceka potvrdu
- `paid`: administrator je potvrdio uplatu

Administrator moze prijavljenu uplatu odbiti i vratiti u `pending`, oznaciti
neprijavljenu obvezu placenom ili ponovno otvoriti placenu obvezu. Administratorski
pregled razlikuje nedospjele obveze od kasnjenja prema `due_on` datumu studija.

## Iznos i zavrsetak clanstva

Svaka obveza sprema snimku naziva paketa, punog iznosa i podataka za placanje.
Zato kasnija promjena paketa ili postavki ne mijenja vec nastalu obvezu. Ako
clanstvo zavrsi usred zadnjeg neplacenog ciklusa, iznos se proracunava prema broju
dana. Vec potvrdene uplate ostaju nepromijenjene.

## HUB3 i obavijesti

API generira HUB3 PDF417 kao SVG iz spremljene snimke obveze. Podsjetnici se
spremaju idempotentno u in-app centar za clana i administratora. Registracija
tokena uredjaja postoji, ali stvarna push dostava nije aktivna bez Firebase
projektnih datoteka, iOS APNs kljuca i ukljucene serverske vjerodajnice. Nakon
konfiguracije podsjetnici se prikazuju kao sistemske obavijesti u pozadini i kao
lokalni banner dok je aplikacija otvorena.

## API

```http
GET  /api/studio-settings/configuration
PUT  /api/studio-settings/configuration
PUT  /api/member-memberships/{id}/billing
PUT  /api/member-memberships/{id}/end
GET  /api/membership-payments/mine
GET  /api/membership-payments?view=pending|reported|overdue|paid|all
GET  /api/membership-payments/{id}/barcode
POST /api/membership-payments/{id}/report
POST /api/membership-payments/{id}/confirm
POST /api/membership-payments/{id}/reject-report
POST /api/membership-payments/{id}/reopen
```

Mobilna aplikacija cita i sprema pristupni kod, podatke za placanje i podsjetnike
atomarno preko `studio-settings/configuration`. Stari endpoint
`GET/PUT /api/payment-settings` ostaje dostupan samo radi kompatibilnosti.
