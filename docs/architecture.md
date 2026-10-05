# Arhitektura

## Komponente

- PostgreSQL 16 radi u Docker containeru `fitness_studio_postgres`.
- ASP.NET Core Web API koristi .NET 10 i Entity Framework Core s Npgsql providerom.
- Flutter mobilna aplikacija komunicira s API-jem preko HTTP/JSON protokola.
- Placanje trenutno nije dio sustava.

## Backend

Osnovni tok zahtjeva je:

```text
Controller -> Service -> FitnessStudioDbContext -> PostgreSQL
```

Controlleri obradjuju HTTP ugovor. Servisi sadrze poslovna pravila, autorizacijske provjere vezane uz podatke i transakcije. Jednostavni CRUD resursi također koriste servise radi konzistentnog multi-studio filtriranja. Repository sloj nije uveden.

API koristi:

- AutoMapper za mapiranje EF entiteta i DTO-a
- `ServiceResult` za ocekivane poslovne greske
- globalni exception handler i Problem Details za neocekivane greske
- Data Annotations za validaciju request DTO-a
- JWT autentifikaciju i globalnu fallback authorization policy

## Mobilna aplikacija

Mobilni featurei organizirani su po slojevima:

```text
feature/
  data/
    datasources/
    models/
    repositories/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    screens/
    state/
    widgets/
```

Koriste se Riverpod za stanje, GetIt za dependency injection, Dio za HTTP, GoRouter za navigaciju i Flutter Secure Storage za lokalno cuvanje autentifikacijske sesije.

## Multi-studio granica

Jedan API i jedna baza podrzavaju vise studija. JWT sadrzi `studio_id`, a svaki upit nad studijskim podacima mora biti filtriran prema studiju prijavljenog korisnika. Klijent ne smije proizvoljno birati `studio_id` nakon prijave.

## Vlasnistvo podataka

- `RecurringClassSchedule` opisuje pravilo ponavljanja.
- `ClassSession` opisuje jedan konkretan termin.
- `Booking` opisuje prijavu clana na konkretan termin.
- `MemberFixedSchedule` opisuje trajnu dodjelu clana ponavljajucem rasporedu.

Detalji su opisani u [scheduling.md](scheduling.md) i [bookings.md](bookings.md).
