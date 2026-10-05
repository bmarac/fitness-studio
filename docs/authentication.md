# Autentifikacija i ovlasti

## Prijava

Korisnik se prijavljuje email adresom i lozinkom:

```http
POST /api/auth/login
```

Request sadrzi `studioId`, `email` i `password`. Response sadrzi JWT, vrijeme isteka i podatke korisnika. Mobilna aplikacija sprema sesiju u Flutter Secure Storage i pokusava je obnoviti pri sljedecem pokretanju.

## JWT

Token sadrzi identitet korisnika, `studio_id`, uloge te opcionalni `member_id` i `trainer_id`. API validira issuer, audience, potpis i vrijeme isteka. Razvojni token trenutno traje 60 minuta.

## Uloge

- `member`: rezervira i otkazuje vlastite rezervacije
- `trainer`: upravlja svojim terminima i vidi njihove polaznike
- `admin`: upravlja studijem i svim terminima

Jedan korisnik moze imati vise uloga kroz `app_user_roles`. Filip i Kristina u demo studiju imaju uloge `trainer` i `admin`.

Backend uvijek provjerava ovlasti. Skrivanje gumba u mobilnoj aplikaciji sluzi korisnickom iskustvu, ali nije sigurnosna zastita.

## Razvojni racuni

Development seeder odrzava sljedece racune:

| Korisnik | Email | Lozinka | Uloge |
| --- | --- | --- | --- |
| Filip Saric | `filip.saric@stayfitjoyful.demo` | `Fitness123!` | trainer, admin |
| Kristina Lisec | `kristina.lisec@stayfitjoyful.demo` | `Fitness123!` | trainer, admin |
| Ana Horvat | `ana.horvat@stayfitjoyful.demo` | `Fitness123!` | member |

Flutter login forma u debug buildu unaprijed popunjava Filipove podatke. Release build ostavlja polja prazna.

## Planirano

Invite kod ili QR povezivat ce novog korisnika s odgovarajucim studijem. Google i Apple prijava mogu se dodati kasnije kao vanjski identiteti, bez uklanjanja postojeceg korisnickog racuna i studijske pripadnosti.
