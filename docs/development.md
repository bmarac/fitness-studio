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
docker compose up -d
```

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

Na iOS simulatoru `localhost` pokazuje na Mac pa zadani API URL radi izravno. Za fizicki uredjaj treba koristiti adresu Mac racunala dostupnu na lokalnoj mrezi.

## Provjere prije zavrsetka promjene

```bash
cd api/FitnessStudio.Api
dotnet build

cd ../../mobile/fitness_studio_mobile
dart format lib test
flutter analyze
flutter test
```
