# Lokalni razvoj

## Preduvjeti

- macOS
- Docker Desktop
- .NET SDK 10
- Flutter i Xcode za iOS simulator
- `dotnet-ef`

## Baza

Pokretanje PostgreSQL-a:

```bash
cp .env.example .env
docker compose up -d
```

Pri prvom pokretanju s praznim volumeom `db/bootstrap.sh` redom primjenjuje
`db/schema`, `db/migrations` i `db/seeds`. Init skripte PostgreSQL containera ne
izvode se ponovno nad postojecim volumeom.

Provjera containera:

```bash
docker ps --filter name=fitness_studio_postgres
```

Gasanje projekta bez brisanja podataka:

```bash
docker compose down
```

Podaci ostaju u Docker volumeu `postgres_data`. `docker compose down -v` brise volume i ne treba ga koristiti bez svjesne odluke o brisanju baze.

Aktualna lokalna veza:

```text
Host=localhost;Port=5432;Database=fitness_studio;Username=fitness;Password=fitness_dev
```

Novi studio i prvi admin mogu se sigurno provisionirati bez javnog HTTP
endpointa. Lozinka se ne stavlja u argumente naredbe:

```bash
FITNESS_STUDIO_ADMIN_PASSWORD='sigurna-lozinka' \
dotnet run --project api/FitnessStudio.Api -- provision-studio \
  --name 'Novi studio' \
  --code NOVISTUDIO \
  --timezone Europe/Zagreb \
  --email admin@example.com
```

Nova SQL promjena dobiva novu datoteku u `db/migrations/`. Nakon primjene migracije EF model treba ponovno scaffoldati:

```bash
cd api/FitnessStudio.Api
dotnet ef dbcontext scaffold \
  "Host=localhost;Port=5432;Database=fitness_studio;Username=fitness;Password=fitness_dev" \
  Npgsql.EntityFrameworkCore.PostgreSQL \
  --context FitnessStudioDbContext \
  --context-dir Data \
  --output-dir Entities \
  --force \
  --no-onconfiguring
```

Scaffold moze prepisati `Data/FitnessStudioDbContext.cs` i EF entitete. Poslovna logika ne smije se stavljati u generirane klase.

## Izolirana provjera svjezeg sustava

Iz korijena repozitorija:

```bash
./scripts/verify-fresh-stack.sh
```

Skripta zahtijeva Docker, .NET SDK, `curl` i `jq`. Pokrece zaseban PostgreSQL
container na nasumicnom portu i API na `127.0.0.1:55146`, provjerava migracije,
seedove, demo prijave, multi-studio granicu, registraciju i join kodom, rasporede,
rezervacije i naplatu te
na kraju uklanja privremeni container. Razvojna baza `fitness_studio` ostaje
netaknuta. Ako je port zauzet, moze se zadati drugi:

```bash
FITNESS_STUDIO_VERIFY_API_PORT=55147 ./scripts/verify-fresh-stack.sh
```

Za provjeru stvarnog Flutter account toka (registracija, lookup, join i odabir
studija) protiv izolirane baze i API-ja koristi se:

```bash
./scripts/verify-fresh-stack.sh account-client
```

Test ponovnom prijavom potvrduje da je clanstvo studija zapisano u PostgreSQL.
Izvodi se rucno i ne ulazi u coverage baseline.

Za manju vertikalnu provjeru rezervacija kroz Flutter data/domain sloj, stvarni
API i privremenu PostgreSQL bazu koristi se:

```bash
./scripts/verify-fresh-stack.sh booking-client
```

Ovaj nacin prijavljuje demo clana, ucitava rezervacije i povezani termin,
otkazuje rezervaciju, stvara zamjensku rezervaciju te ponovnim citanjem
potvrduje obje promjene iz baze. Dodatni pokusaj rezervacije potvrduje konflikt
kada clan dosegne ogranicenje svojeg plana. Test je
namjerno izvan standardnog `test/` direktorija: ne pokrece se uz `flutter test`,
ne ulazi u coverage baseline i zasad se izvodi samo rucno. Za njega su dodatno
potrebni Flutter/Dart alati dostupni u `PATH` varijabli.

Vertikalna provjera naplate koristi isti izolirani stack:

```bash
./scripts/verify-fresh-stack.sh payment-client
```

Test ukljucuje naplatu za jedno clanstvo, zatim stvarnim Flutter klijentom
provjerava obvezu clana, HUB3 barkod, prijavu uplate, administratorsku potvrdu
i konacni status `paid`. Izvodi se rucno i ne ulazi u coverage baseline.

Vertikalna provjera antropometrijskih mjerenja pokrece se naredbom:

```bash
./scripts/verify-fresh-stack.sh progress-client
```

Test prijavljuje trenera, pronalazi demo clana i aktivne parametre visine i
tezine, sprema mjerenje te se zatim prijavljuje kao clan. Ponovnim citanjem
potvrduje latest vrijednosti, zapis u povijesti i BMI izracunat u API-ju. Test
je rucan i ne ulazi u coverage baseline.

Vertikalna provjera pregleda treninga pokrece se naredbom:

```bash
./scripts/verify-fresh-stack.sh workouts-client
```

Test kroz stvarni Flutter data/domain sloj provjerava filtriranje aktivnih
treninga po treneru, paginaciju i redoslijed rezultata. Na kraju potvrduje da
clan ne moze pristupiti staff endpointu. Izvodi se protiv svjeze baze, rucan je
i ne ulazi u coverage baseline.

Vertikalna provjera lifecyclea ponavljajuceg rasporeda pokrece se naredbom:

```bash
./scripts/verify-fresh-stack.sh schedule-client
```

Test potvrduje da clan ne moze mijenjati raspored, zatim administratorskim
racunom pauzira aktivni raspored, ponovno ga ucitava iz baze, nastavlja ga i
potvrduje povratak u aktivno stanje. Test je rucan i ne ulazi u coverage
baseline.

Vertikalna provjera fiksne dodjele clana pokrece se naredbom:

```bash
./scripts/verify-fresh-stack.sh fixed-schedule-client
```

Test pronalazi Aninu aktivnu dodjelu i slobodan termin istog dana, potvrduje da
clan ne smije izvesti premjestanje, a zatim ga izvodi administratorskim racunom.
Ponovnim citanjem iz baze provjerava novu dodjelu, otkazane buduce rezervacije
izvornog termina i automatski stvorene rezervacije ciljnog termina. Test je
rucan i ne ulazi u coverage baseline.

## API

```bash
cd api/FitnessStudio.Api
dotnet build
dotnet run
```

HTTP profil koristi `http://localhost:5146`. Swagger UI je na `http://localhost:5146/swagger`.

API se zaustavlja s `Ctrl+C` u terminalu u kojem je pokrenut.

Za FCM na Docker/VPS posluzitelju service-account JSON se montira kao read-only
secret, primjerice na `/run/secrets/firebase-service-account.json`, te se po
okruzenju postavljaju:

```text
FirebaseMessaging__Enabled=true
FirebaseMessaging__ProjectId=<firebase-project-id>
FirebaseMessaging__CredentialPath=/run/secrets/firebase-service-account.json
FirebaseMessaging__UseApplicationDefaultCredentials=false
FirebaseMessaging__PollSeconds=30
```

Vjerodajnica se ne sprema u repozitorij. Na Google Cloud infrastrukturi moze se
koristiti identitet servisa postavljanjem
`FirebaseMessaging__UseApplicationDefaultCredentials=true` bez
`CredentialPath` vrijednosti. API pri pokretanju odbija nepotpunu ili nepostojecu
FCM konfiguraciju kada je slanje ukljuceno.

## Mobilna aplikacija

```bash
cd mobile/fitness_studio_mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Na iOS simulatoru `localhost` pokazuje na Mac pa zadani API URL radi izravno.
Prije Firebase registracije treba zamijeniti razvojne `com.example...`
identifikatore konacnim Android application ID-em i iOS bundle ID-em. Zatim se
iz korijena Flutter projekta pokrece `flutterfire configure` za Android i iOS.
Time se aplikacije registriraju u Firebase projektu i generira se njihova
klijentska konfiguracija. Alternativno, Android `google-services.json` ide u
`android/app/`, a iOS `GoogleService-Info.plist` mora biti dodan u Runner target
kroz Xcode. Te klijentske datoteke nisu service-account vjerodajnice.

Za iOS se u Firebase Console ucitava APNs `.p8` authentication key s pripadnim
Key ID-em i Apple Team ID-em. Runner vec ima Push Notifications i Background
Modes (`fetch` i `remote-notification`) konfiguraciju. Zbog aktualnog Firebase
iOS SDK-a minimalno podrzana verzija aplikacije je iOS 15. Aplikacija bez
Firebase projektnih datoteka nastavlja raditi bez push registracije.

Dozvola za obavijesti trazi se nakon uspjesne prijave. Push u pozadini prikazuje
FCM, a poruka zaprimljena dok je aplikacija otvorena prikazuje se preko lokalne
visokoprioritetne obavijesti. Dodir na podsjetnik clanarine otvara odgovarajuci
ekran clanarine; ostale vrste otvaraju centar obavijesti.

Za fizicki Android uredjaj spojen USB kabelom najjednostavnije je prije
`flutter run` proslijediti API port:

```bash
adb reverse tcp:5146 tcp:5146
adb reverse --list
```

Tada zadani `http://localhost:5146` radi i na mobitelu. Prosljedjivanje se moze
izgubiti nakon odspajanja uredjaja, restarta ADB-a ili racunala pa ga tada treba
ponovno postaviti. Alternativa je pokrenuti aplikaciju s adresom Mac racunala
dostupnom na lokalnoj mrezi i odgovarajuce izloziti API na toj adresi.

## Provjere prije zavrsetka promjene

```bash
cd mobile/fitness_studio_mobile
flutter analyze
cd ../..
./scripts/check-coverage.sh
./scripts/verify-fresh-stack.sh
git diff --check
```

## Pokrivenost testovima

Iz korijena repozitorija pokrenuti:

```bash
./scripts/check-coverage.sh
```

Skripta izvodi sve backend i Flutter testove te sprema LCOV izvjestaje i sazeti
Markdown pregled u `artifacts/coverage/`. Backend mjerenje obuhvaca ulaznu tocku,
kontrolere, servise, domensku logiku, validaciju i razvojni auth seeder. Iz mjere
su iskljuceni generirani EF entiteti i kontekst, DTO-i, profili mapiranja i
konfiguracijske klase. Flutter mjerenje obuhvaca rucno pisani kod u `lib/`, a
iskljucuje generirane lokalizacijske datoteke.

Gate provjerava tri pravila:

- ukupna pokrivenost ne smije pasti ispod verzioniranog baselinea;
- poboljsanje od najmanje 0,1 postotnog boda mora se zapisati u baseline;
- promijenjene izvrsne linije moraju imati najmanje 80% pokrivenosti, zasebno za
  backend i Flutter.

Kad testovi legitimno povecaju pokrivenost, baseline se podize naredbom:

```bash
./scripts/check-coverage.sh --update-baseline
```

Baseline se tom naredbom moze samo povecati. Dugorocni cilj za oba dijela je 60%.
GitHub Actions pokrece isti gate na pull requestovima i na `main` grani, prikazuje
sazetak u jobu te cuva LCOV izvjestaje 14 dana.
