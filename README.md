# Fitness Studio

Aplikacija za upravljanje fitness studijima i grupnim treninzima. Sustav cine ASP.NET Core API, PostgreSQL baza i Flutter mobilna aplikacija.

## Brzi pocetak

```bash
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
