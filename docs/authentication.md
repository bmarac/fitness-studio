# Autentifikacija i ovlasti

## Prijava

Korisnik se prijavljuje email adresom i lozinkom:

```http
POST /api/auth/login
```

Request sadrzi samo `email` i `password`. Registracija koristi isti oblik na
`POST /api/auth/register`. Response sadrzi account JWT i sve studije kojima
racun pripada. Account JWT sluzi za povezivanje i izbor studija; poslovni
endpointi prihvacaju studio-scoped JWT dobiven izborom studija.

## Povezivanje sa studijem

Prijavljeni racun koristi `/api/account/studios/lookup` i `/join`. Kod se cita iz
`studio_settings.join_code`; brisanje postavke iskljucuje nova povezivanja.
Postojeci profil istog emaila povezuje se s racunom, a inace se kreira clan iz
unesenog imena i prezimena. Izbor preko `/{studioId}/select` izdaje studio JWT.
Trenerski profil admin unaprijed stvara na `/api/trainers`; racun s odgovarajucim
emailom zato pri pridruzivanju dobiva ulogu trenera umjesto novog clanskog profila.

## JWT

Account token sadrzi samo identitet i email. Studio token dodatno sadrzi
`studio_id`, uloge te opcionalni `member_id` i `trainer_id`. API validira issuer,
audience, potpis i vrijeme isteka.

## Uloge

- `member`: rezervira i otkazuje vlastite rezervacije
- `trainer`: upravlja svojim terminima i vidi njihove polaznike
- `admin`: upravlja studijem i svim terminima

Jedan racun moze pripadati vise studija, a uloge su izolirane po vezi u
`app_user_studio_roles`. Filip i Kristina u demo studiju imaju uloge `trainer` i `admin`.

Backend uvijek provjerava ovlasti. Skrivanje gumba u mobilnoj aplikaciji sluzi korisnickom iskustvu, ali nije sigurnosna zastita.

## Razvojni racuni

Development seeder odrzava sljedece racune:

| Korisnik | Email | Lozinka | Uloge |
| --- | --- | --- | --- |
| Filip Saric | `filip.saric@stayfitjoyful.demo` | `Fitness123!` | trainer, admin |
| Kristina Lisec | `kristina.lisec@stayfitjoyful.demo` | `Fitness123!` | trainer, admin |
| Ana Horvat | `ana.horvat@stayfitjoyful.demo` | `Fitness123!` | member |

Flutter login forma u debug buildu unaprijed popunjava Filipove podatke. Release build ostavlja polja prazna.

Google i Apple prijava mogu se kasnije dodati kao vanjski identiteti bez
uklanjanja globalnog racuna i studijskih pripadnosti.
