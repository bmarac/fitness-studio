# Mobilna aplikacija

Flutter projekt nalazi se u `mobile/fitness_studio_mobile`.

## Tehnologije

- Riverpod za upravljanje stanjem
- GetIt za dependency injection
- Dio za HTTP pozive
- GoRouter za navigaciju
- Flutter Secure Storage za JWT sesiju
- Firebase Messaging za push tokene i obavijesti

## Navigacija

Glavni tabovi su:

- **Termini**: članski tjedni pregled grupnih treninga
- **Rasporedi**: trenerski i administratorski tjedni pregled ponavljajućih rasporeda
- **Moji treninzi**: korisnikove rezervacije i fiksni termini
- **Profil**: osobni podaci i podatak o paketu

Dodatne rute:

- `/login`
- `/registracija`
- `/odabir-studija`
- `/termini/termin/{id}`
- `/rasporedi`
- `/profil/antropometrija`
- `/profil/clanovi`
- `/profil/clanovi/{memberId}/antropometrija`
- `/profil/clanovi/{memberId}/novo-mjerenje`
- `/profil/clanarine`
- `/profil/clanovi-i-paketi`
- `/profil/treneri`
- `/profil/treneri/novi-trener`
- `/profil/postavke-placanja`
- `/profil/obavijesti`
- `/profil/postavke-studija`

## Trenutno implementirano

- login i registracija samo emailom i lozinkom
- povezivanje kodom nakon prijave, izbor izmedju vise studija i pamcenje zadnjeg
- promjena ili dodavanje studija iz profila
- administratorska postavka za promjenu ili iskljucivanje `join_code`
- adminski popis trenera i unaprijed dodavanje trenera po emailu
- clanovi nastaju samostalnim pridruzivanjem studiju kodom
- tjedni pregled termina
- detalji termina i popunjenost
- rezerviranje termina za korisnika povezanog s clanom
- forma za kreiranje ponavljajuceg rasporeda nalazi se na ekranu **Rasporedi**; admin bira
  trenera, a trener moze kreirati raspored samo za sebe
- clan u prvom tabu vidi **Termine**, dok trener i admin na istom mjestu vide
  zasebnu rutu **Rasporedi** s tjednom mrezom, popunjenoscu fiksnih grupa i filtrima
  za aktivne, pauzirane i zavrsene rasporede
- upravljanje rasporedima nudi pauzu, nastavak i trajni zavrsetak od odabranog datuma
- otkazivanje konkretnog termina uz provjeru uloge
- administratorska postavka roka za povrat kvote pri otkazivanju
- pregled polaznika za admina ili dodijeljenog trenera
- upravljanje polaznicima s detalja termina preko izbornika uz svakog clana
- **Ukloni s ovog termina** otkazuje samo odabranu rezervaciju
- **Ukloni iz fiksne grupe** otkazuje odabrani i buduce termine iste fiksne dodjele
- trenerski pregled **Moji treninzi** s današnjim, nadolazećim i završenim terminima
  koristi server-side filtre i ucitava povijest u stranicama od 20 termina;
  isto vrijedi za administratorski pregled svih ili odabranog trenera
- admin na popisu clanova fiksnog rasporeda moze pretragom dodati aktivnog clana
  od odabranog datuma; buduci termini popunjavaju se odmah
- **Rasporedi** je početni i srednji tab za trenera/admina, dok član nakon prijave
  i dalje prvo vidi **Moje treninge**; član ondje vidi sve svoje rezervacije
  kronološki, razlikuje **Otkazano** od **Kasni otkaz** i može otkazati pojedini
  budući termin, dok admin može filtrirati
  pregled termina po aktivnom treneru ili odabrati **Svi treneri**
- evidencija prisutnosti i nedolaska na zapocetim terminima
- profil prijavljenog korisnika s osobnim podacima, ulogama i studijem
- clanski prikaz aktivnog paketa, iskoristenosti u mjesecnom obracunskom
  periodu te fiksnih termina
- trenerski profil bez praznih clanskih sekcija
- povlacenje za osvjezavanje profila i odjava uz potvrdu
- sazetak posljednjih mjerenja i promjene na profilu clana
- detaljni ekran napretka s odabirom parametra, linijskim grafom i povijesti
- trenerski popis clanova s pretragom i pregledom napretka odabranog clana
- administratorski popis clanova s pretragom, prikazom aktivnog paketa te
  dodjelom ili trenutnom promjenom paketa
- unos vlastitog mjerenja za clana te unos mjerenja clanova za trenera i admina, s aktivnim rucnim parametrima studija
- debug login forma s unaprijed popunjenim Filipovim racunom
- clanski pregled obracuna, HUB3 koda, prijava uplate i zavrsetak clanstva
- administratorski pregled i potvrda uplata te postavke primatelja i podsjetnika
- ukljucivanje naplate s obveznim datumom **Naplata vrijedi od** te odvojenim
  listama **Naplata nije ukljucena** i **Aktivna naplata**
- filtri **Za naplatu**, **Ceka potvrdu**, **Kasni**, **Placeno** i **Sve** te
  izravna akcija **Oznaci placeno** na svakom neplacenom mjesecnom obracunu
- studio-scoped in-app centar obavijesti i FCM registracija tokena

Push transport zahtijeva Firebase projektne datoteke, iOS APNs kljuc i serverske
vjerodajnice. Aplikacija registrira token nakon prijave, prikazuje foreground
banner te otvara clanarinu ili centar obavijesti nakon dodira.
Serverske vjerodajnice ne spremaju se u repozitorij. Bez Firebase konfiguracije
in-app obavijesti i dalje rade.

Ekran **Profil** koristi `GET /api/profile` i prilagodjava sadrzaj povezanim ulogama. Korisnik koji je istodobno clan i trener dobiva obje vrste podataka, dok se neprimjenjive sekcije ne prikazuju.

Admin preko kartice **Clanovi i paketi** otvara `/profil/clanovi-i-paketi`.
Ekran objedinjuje clanove, clanstva i cjenik, dopusta dodjelu samo aktivnih
paketa aktivnim clanovima te omogucuje promjenu paketa na postojecem aktivnom
clanstvu. Aktivni clanovi bez paketa prikazuju se prvi, a filter **Bez paketa**
izdvaja samo clanove kojima admin moze odmah dodijeliti paket. Dodjela
automatski pokrece obracun od datuma pocetka clanstva.

Kartica **Antropometrija** na profilu vodi na detaljni ekran tjelesnih mjerenja. Profil ne ucitava ni prikazuje sazetak mjerenja. Detaljni ekran koristi `fl_chart`, omogucuje izbor svih dostupnih parametara, prikazuje graf i zapise od najnovijeg prema najstarijem te clanu nudi unos vlastitog mjerenja. Stara ruta `/profil/napredak` preusmjerava na `/profil/antropometrija`.

Admin i trener na profilu vide akciju **Antropometrija clanova**. Nakon odabira clana mogu pregledati istu povijest koju clan vidi za sebe te dodati novo mjerenje. Stara ruta `/profil/clanovi/{memberId}/napredak` preusmjerava na `/profil/clanovi/{memberId}/antropometrija`. Obrazac prikazuje samo aktivne parametre sa `source = manual`, prihvaca decimalni zarez i zahtijeva barem jednu vrijednost. Izracunati parametri poput BMI-ja ne unose se rucno.

Admin na profilu vidi akciju **Treneri**. Ekran prikazuje trenere studija i omogucuje
unaprijed stvaranje trenerskog profila. Stara ruta `/profil/onboarding` preusmjerava
na `/profil/treneri`; rucno stvaranje clana u mobilnoj aplikaciji nije dostupno.

## Konfiguracija

Zadane vrijednosti su:

```text
API_BASE_URL=http://localhost:5146
```

Mogu se promijeniti pri pokretanju:

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:5146
```

Uloga odredjuje vidljive akcije, ali backend ponavlja sve sigurnosne provjere. Mobilna aplikacija ne smije biti jedino mjesto provedbe poslovnih pravila.

## Upravljanje polaznicima

Sekcija **Polaznici** prikazuje se na detaljima termina samo adminu ili treneru kojem je termin dodijeljen. Izbornik s tri tocke uz polaznika uvijek nudi uklanjanje s konkretnog termina. Uklanjanje iz fiksne grupe prikazuje se samo kada API za rezervaciju vrati `memberFixedScheduleId`.

Kod prekida fiksne dodjele aplikacija koristi datum trenutno otvorenog termina kao `effectiveFrom`. Prije obje akcije prikazuje se potvrda. Nakon uspjeha osvjezavaju se popis polaznika, popunjenost detalja i popis termina.

Na ekranu **Rasporedi** klik na karticu otvara modal s aktivnim clanovima fiksne
grupe. Akcije pauziranja, nastavka i zavrsavanja nalaze se na dnu modala. Akcija
**Premjesti** uz clana zatvara modal i prebacuje mrezu u odabir aktivnog odredista;
izvorni i puni rasporedi su onemoguceni, a promjena se izvrsava tek nakon potvrde.
Admin u istom modalu moze urediti trenera, dan, vrijeme i kapacitet od odabranog
datuma. Buduca verzija i prethodna verzija prikazuju se istodobno s oznakama
**od** i **do**, a postojeci clanovi i rezervacije automatski se prenose.
