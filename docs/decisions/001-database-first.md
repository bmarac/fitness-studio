# 001 - Database-first

**Status:** prihvaceno

## Odluka

PostgreSQL SQL schema i migracije izvor su strukture baze. EF Core `DbContext` i entiteti generiraju se naredbom `dotnet ef dbcontext scaffold`.

## Posljedice

- promjena baze prvo se zapisuje kao SQL migracija
- nakon primjene migracije ponovno se scaffoldaju EF modeli
- generirane klase ne sadrze poslovnu logiku
- rucne promjene generiranih klasa mogu nestati pri sljedecem scaffoldu
