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
seedove, demo prijave, multi-studio granicu, rasporede, rezervacije i naplatu te
na kraju uklanja privremeni container. Razvojna baza `fitness_studio` ostaje
netaknuta. Ako je port zauzet, moze se zadati drugi:

```bash
FITNESS_STUDIO_VERIFY_API_PORT=55147 ./scripts/verify-fresh-stack.sh
```

## API

```bash
cd api/FitnessStudio.Api
dotnet build
dotnet run
```

HTTP profil koristi `http://localhost:5146`. Swagger UI je na `http://localhost:5146/swagger`.

API se zaustavlja s `Ctrl+C` u terminalu u kojem je pokrenut.

## Mobilna aplikacija

```bash
cd mobile/fitness_studio_mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Na iOS simulatoru `localhost` pokazuje na Mac pa zadani API URL radi izravno.

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
