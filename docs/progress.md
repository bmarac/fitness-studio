# Antropometrija

Svaki studio samostalno definira parametre koje prati kod svojih clanova. Dodavanje novog parametra ne zahtijeva novu kolonu ni migraciju baze.

## Model podataka

`measurement_parameters` sadrzi definiciju parametra unutar studija:

- automatski generirani stabilni `code` i prikazni `name`
- opcionalnu mjernu jedinicu
- redoslijed i status

`member_measurements` predstavlja jedan dogadjaj mjerenja. Sadrzi clana, vrijeme mjerenja, korisnika koji ga je unio i opcionalnu biljesku.

`member_measurement_values` sadrzi numericke vrijednosti parametara unutar tog dogadjaja. Kombinacija mjerenja i parametra jedinstvena je, pa jedan parametar ne moze biti dvaput unesen u istom mjerenju.

## Demo parametri

Stay Fit & Joyful trenutno ima:

- visinu
- tezinu
- BMI
- opseg struka
- opseg ruke
- opseg prsa
- postotak masnog tkiva

## Ovlasti

Implementirane ovlasti:

- admin upravlja parametrima i svim mjerenjima
- trener pregledava i unosi mjerenja clanova
- clan pregledava i unosi samo vlastita antropometrijska mjerenja

## API parametara

CRUD parametara dostupan je na `/api/measurement-parameters`. Svi prijavljeni korisnici mogu citati aktivne parametre svog studija, dok samo admin moze upravljati definicijama. Admin pri dohvatu vidi i neaktivne parametre.

Brisanje je logicko i postavlja status `inactive`. `code` se generira iz naziva, jedinstven je unutar studija i nakon stvaranja se ne mijenja.

## API mjerenja

```http
GET  /api/members/{memberId}/measurements
GET  /api/members/{memberId}/measurements/latest
POST /api/members/{memberId}/measurements
```

Povijest sadrzi stvarne dogadjaje i vrijednosti koje su tada unesene. Posljednje stanje za svaki parametar pronalazi njegovu najnoviju vrijednost i zato moze objediniti podatke iz vise mjerenja.

Kod unosa backend provjerava studio, ovlasti, aktivnost parametra i duplikate. Svaki aktivni parametar prihvaca cijelu ili decimalnu numericku vrijednost, a BMI se unosi rucno kao i ostali parametri.

## Mobilna aplikacija

Clan na profilu vidi kompaktnu karticu **Antropometrija** s opisom **Tjelesna mjerenja**. Kartica otvara `/profil/antropometrija`, gdje moze pregledati povijest i preko akcije **Mjerenje** unijeti vlastite vrijednosti. Clan ne moze unositi mjerenja drugom clanu. Stara ruta `/profil/napredak` automatski se preusmjerava na novu.

Admin i trener preko **Profil -> Antropometrija clanova** otvaraju pretrazivi popis clanova. Administrator preko ikone postavki na tom ekranu uredjuje naziv, jedinicu, status i redoslijed parametara. Odabrani clan ima vlastiti ekran povijesti na `/profil/clanovi/{memberId}/antropometrija` i akciju **Mjerenje**. Stara ruta s nastavkom `/napredak` preusmjerava na novu. Obrazac prikazuje aktivne parametre i nakon uspjesnog spremanja osvjezava povijest clana.

Demo seed `db/seeds/004_ana_progress.sql` sadrzi cetiri mjerenja za Anu kroz razdoblje od otprilike tri mjeseca.
Naplata clanarina opisana je zasebno u [payments.md](payments.md).
