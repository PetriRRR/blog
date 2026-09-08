# Fama–French data

Tämä hakemisto on tarkoitettu Fama–French-faktoriaineiston säilyttämiseen ja käsittelyyn analyysien yhteydessä.

## Tavoite

Hakemisto toimii työtilana, jossa Fama–French-faktoriaineisto voidaan ladata, tarkistaa ja jäsentää ennen sitä, kun dataa käytetään sijoitusanalyysissä. Tämän repositoryn tarkoitus ei ole tallentaa raakadataa pysyvästi, vaan pitää loki ja käsittelypolku selkeänä.

## Mistä data haetaan

Fama–French-aineisto haetaan Kenneth French Data Library -palvelusta. Aineisto käsitellään usein kuukausittaisen kolmen faktorin tai laajemman faktori- ja portfoliomallin muodossa, riippuen analyysin tarpeista.

## Prosessed-kansio

Käsitelty aineisto tallennetaan artikkelin omaan processed-kansioon seuraavassa polussa:

`posts/fama-french-data/data/processed/`

Tämä kansio muodostetaan vasta silloin, kun analyysikoodi on suoritettu. Lopullinen käsitellyn datan tiedostopolku on:

`posts/fama-french-data/data/processed/fama_french_3_monthly.csv`

## Huomioitavaa

- Raakadataa ei ole vielä tallennettu repositoryyn.
- `processed`-hakemisto syntyy vasta, kun analyysikoodi on suoritettu.
- Datan hakupäivä kannattaa dokumentoida analyysin yhteydessä, jotta aineiston ajankohtaisuus on jäljitettävissä.
- Repositoryyn ei saa tallentaa lisensoitua, luottamuksellista tai muuta käyttöoikeuksiltaan rajoitettua dataa.
