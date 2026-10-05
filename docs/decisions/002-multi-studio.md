# 002 - Multi-studio sustav

**Status:** prihvaceno

## Odluka

Jedan API i jedna baza posluzuju vise fitness studija. Studijski podaci nose `studio_id`, a studio prijavljenog korisnika dolazi iz JWT-a.

## Posljedice

- svaki podatkovni upit mora postovati granicu studija
- jedinstvena pravila koja ovise o studiju ukljucuju `studio_id`
- mobilna aplikacija ne odredjuje studij za pojedinacne operacije
- onboarding mora korisnika povezati s ispravnim studijem
