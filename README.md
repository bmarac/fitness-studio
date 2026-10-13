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

Manji vertikalni test rezervacije, od Flutter data sloja preko stvarnog API-ja
do privremene PostgreSQL baze, pokrece se rucno:

```bash
./scripts/verify-fresh-stack.sh booking-client
```

Vertikalni test naplate kroz Flutter klijent, API i privremenu bazu pokrece se:

```bash
./scripts/verify-fresh-stack.sh payment-client
```

Vertikalni test mjerenja i napretka kroz Flutter klijent, API i privremenu bazu:

```bash
./scripts/verify-fresh-stack.sh progress-client
```

Backend i Flutter testovi, LCOV izvjestaji te coverage pragovi pokrecu se jednom
naredbom:

```bash
./scripts/check-coverage.sh
```
