# Mobilna aplikacija

Flutter projekt nalazi se u `mobile/fitness_studio_mobile`.

## Tehnologije

- Riverpod za upravljanje stanjem
- GetIt za dependency injection
- Dio za HTTP pozive
- GoRouter za navigaciju
- Flutter Secure Storage za JWT sesiju

## Navigacija

Glavni tabovi su:

- **Termini**: tjedni pregled grupnih treninga
- **Moji treninzi**: korisnikove rezervacije i fiksni termini
- **Profil**: osobni podaci i podatak o paketu

Dodatne rute:

- `/login`
- `/termini/termin/{id}`
- `/termini/novi-termin`
- `/profil/napredak`
- `/profil/clanovi`
- `/profil/clanovi/{memberId}/napredak`
- `/profil/clanovi/{memberId}/novo-mjerenje`

## Trenutno implementirano

- login i automatska obnova spremljene sesije
- tjedni pregled termina
- detalji termina i popunjenost
- rezerviranje termina za korisnika povezanog s clanom
- forma za kreiranje ponavljajuceg rasporeda vidljiva adminu/treneru; API spremanje trenutno zahtijeva i ulogu `admin`
- otkazivanje konkretnog termina uz provjeru uloge
- pregled polaznika za admina ili dodijeljenog trenera
- upravljanje polaznicima s detalja termina preko izbornika uz svakog clana
- **Ukloni s ovog termina** otkazuje samo odabranu rezervaciju
- **Ukloni iz fiksne grupe** otkazuje odabrani i buduce termine iste fiksne dodjele
- trenerski pregled **Moji treninzi** s današnjim, nadolazećim i završenim terminima
- evidencija prisutnosti i nedolaska na zapocetim terminima
- profil prijavljenog korisnika s osobnim podacima, ulogama i studijem
- clanski prikaz aktivnog paketa, iskoristenosti i fiksnih termina
- trenerski profil bez praznih clanskih sekcija
- povlacenje za osvjezavanje profila i odjava uz potvrdu
- sazetak posljednjih mjerenja i promjene na profilu clana
- detaljni ekran napretka s odabirom parametra, linijskim grafom i povijesti
- trenerski popis clanova s pretragom i pregledom napretka odabranog clana
- trenerski unos novog mjerenja s aktivnim rucnim parametrima studija
- debug login forma s unaprijed popunjenim Filipovim racunom

Ekran **Profil** koristi `GET /api/profile` i prilagodjava sadrzaj povezanim ulogama. Korisnik koji je istodobno clan i trener dobiva obje vrste podataka, dok se neprimjenjive sekcije ne prikazuju.

Sekcija **Napredak** na profilu prikazuje tezinu, BMI i opseg struka kada su dostupni. Promjena se racuna prema prethodnoj zabiljezenoj vrijednosti istog parametra. Detaljni ekran koristi `fl_chart`, omogucuje izbor svih dostupnih parametara te prikazuje graf i zapise od najnovijeg prema najstarijem.

Admin i trener na profilu vide akciju **Napredak clanova**. Nakon odabira clana mogu pregledati istu povijest koju clan vidi za sebe te dodati novo mjerenje. Obrazac prikazuje samo aktivne parametre sa `source = manual`, prihvaca decimalni zarez i zahtijeva barem jednu vrijednost. Izracunati parametri poput BMI-ja ne unose se rucno.

## Konfiguracija

Zadane vrijednosti su:

```text
API_BASE_URL=http://localhost:5146
CURRENT_STUDIO_ID=1
```

Mogu se promijeniti pri pokretanju:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:5146 \
  --dart-define=CURRENT_STUDIO_ID=1
```

Uloga odredjuje vidljive akcije, ali backend ponavlja sve sigurnosne provjere. Mobilna aplikacija ne smije biti jedino mjesto provedbe poslovnih pravila.

## Upravljanje polaznicima

Sekcija **Polaznici** prikazuje se na detaljima termina samo adminu ili treneru kojem je termin dodijeljen. Izbornik s tri tocke uz polaznika uvijek nudi uklanjanje s konkretnog termina. Uklanjanje iz fiksne grupe prikazuje se samo kada API za rezervaciju vrati `memberFixedScheduleId`.

Kod prekida fiksne dodjele aplikacija koristi datum trenutno otvorenog termina kao `effectiveFrom`. Prije obje akcije prikazuje se potvrda. Nakon uspjeha osvjezavaju se popis polaznika, popunjenost detalja i popis termina.
