# 004 - Raspored i konkretni termin

**Status:** prihvaceno

## Odluka

Ponavljajuci raspored i konkretni termin odvojeni su entiteti. `recurring_class_schedules` opisuje pravilo, a `class_sessions` pojedinacne izvedbe tog pravila.

## Posljedice

- rezervacija uvijek pripada konkretnom terminu
- moguce je otkazati samo jedan termin bez promjene rasporeda
- povijest odrzanih i otkazanih termina ostaje sacuvana
- promjena svih buducih termina zahtijeva posebno definiranu poslovnu operaciju
