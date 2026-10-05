# Dokumentacija projekta

Ovaj direktorij sadrzi tehnicku i funkcionalnu dokumentaciju projekta Fitness Studio. Dokumentacija opisuje trenutno implementirano stanje; planirane funkcionalnosti izricito su oznacene kao plan.

## Sustav

- [Arhitektura](architecture.md)
- [Baza podataka](database.md)
- [API](api.md)
- [Autentifikacija i ovlasti](authentication.md)

## Funkcionalnosti

- [Termini i ponavljajuci rasporedi](scheduling.md)
- [Rezervacije](bookings.md)
- [Mobilna aplikacija](mobile.md)
- [Pracenje napretka](progress.md)

## Razvoj

- [Lokalni razvoj](development.md)
- [Arhitekturne odluke](decisions/README.md)

## Odrzavanje

Kod promjene poslovnog pravila potrebno je azurirati odgovarajuci funkcionalni dokument. Kod promjene strukture sustava, baze ili javnog API ugovora treba azurirati i arhitekturu, bazu ili API dokumentaciju. Vazne odluke koje utjecu na buduci razvoj zapisuju se kao novi ADR u `docs/decisions/`.
