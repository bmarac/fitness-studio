# Fitness Studio

Aplikacija za upravljanje fitness studijima i grupnim treninzima. Sustav cine ASP.NET Core API, PostgreSQL baza i Flutter mobilna aplikacija.

## Brzi pocetak

```bash
cp .env.example .env
docker compose up -d
cd api/FitnessStudio.Api
dotnet run
```

U drugom terminalu:

```bash
cd mobile/fitness_studio_mobile
flutter pub get
flutter run
```

API se lokalno pokrece na `http://localhost:5146`. Detaljne upute, poslovna pravila i opis arhitekture nalaze se u [projektnoj dokumentaciji](docs/README.md).

Kod prvog pokretanja PostgreSQL automatski primjenjuje pocetnu shemu, sve SQL
migracije i demo seedove. Potpuno izolirana provjera svjeze baze i kljucnih API
tokova pokrece se iz korijena repozitorija:

```bash
./scripts/verify-fresh-stack.sh
```

Backend i Flutter testovi, LCOV izvjestaji te coverage pragovi pokrecu se jednom
naredbom:

```bash
./scripts/check-coverage.sh
```
