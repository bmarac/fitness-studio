# Antropometrija

Svaki studio samostalno definira parametre koje prati kod svojih clanova. Dodavanje novog parametra ne zahtijeva novu kolonu ni migraciju baze.

## Model podataka

`measurement_parameters` sadrzi definiciju parametra unutar studija:

- stabilni `code` i prikazni `name`
- opcionalnu mjernu jedinicu
- `value_type`: `decimal` ili `integer`
- `source`: `manual` ili `calculated`
- opcionalne minimalne i maksimalne vrijednosti
- broj decimalnih mjesta, redoslijed i status

`member_measurements` predstavlja jedan dogadjaj mjerenja. Sadrzi clana, vrijeme mjerenja, korisnika koji ga je unio i opcionalnu biljesku.

`member_measurement_values` sadrzi numericke vrijednosti parametara unutar tog dogadjaja. Kombinacija mjerenja i parametra jedinstvena je, pa jedan parametar ne moze biti dvaput unesen u istom mjerenju.

## Izracunati parametri

BMI je parametar sa `source = calculated` i `calculation_type = bmi`. Ne unosi se rucno, nego se racuna iz tezine i visine:

```text
BMI = tezina u kg / (visina u metrima * visina u metrima)
```

Genericki izrazi i formule nisu dio MVP-a. Backend servis ce eksplicitno poznavati podrzane vrste izracuna.

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

Brisanje je logicko i postavlja status `inactive`. `code` je nepromjenjiv, a tip vrijednosti, izvor i vrsta izracuna ne mogu se promijeniti nakon prvog spremljenog mjerenja.

## API mjerenja

```http
GET  /api/members/{memberId}/measurements
GET  /api/members/{memberId}/measurements/latest
POST /api/members/{memberId}/measurements
```

Povijest sadrzi stvarne dogadjaje i vrijednosti koje su tada unesene. Posljednje stanje za svaki parametar pronalazi njegovu najnoviju vrijednost i zato moze objediniti podatke iz vise mjerenja.

Kod unosa backend provjerava studio, ovlasti, aktivnost parametra, dopusteni raspon, broj decimalnih mjesta i duplikate. Izracunati parametri ne mogu se unositi rucno. BMI se vraca kada postoje visina i tezina.

## Mobilna aplikacija

Clan na profilu vidi kompaktnu karticu **Antropometrija** s opisom **Tjelesna mjerenja**. Kartica otvara `/profil/antropometrija`, gdje moze pregledati povijest i preko akcije **Mjerenje** unijeti vlastite vrijednosti. Clan ne moze unositi mjerenja drugom clanu. Stara ruta `/profil/napredak` automatski se preusmjerava na novu.

Admin i trener preko **Profil -> Antropometrija clanova** otvaraju pretrazivi popis clanova. Odabrani clan ima vlastiti ekran povijesti na `/profil/clanovi/{memberId}/antropometrija` i akciju **Mjerenje**. Stara ruta s nastavkom `/napredak` preusmjerava na novu. Obrazac ucitava konfiguraciju studija, prikazuje samo aktivne rucne parametre, lokalno provjerava granice i nakon uspjesnog spremanja osvjezava povijest clana.

Demo seed `db/seeds/004_ana_progress.sql` sadrzi cetiri mjerenja za Anu kroz razdoblje od otprilike tri mjeseca. BMI nije spremljen u seedu nego ga API racuna iz svake visine i tezine.
Naplata clanarina opisana je zasebno u [payments.md](payments.md).
