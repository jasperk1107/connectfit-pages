# ConnectFit sitestructuur — previews

Previews van de ConnectFit-pagina's, met dezelfde paden als de echte site.
De preview-URL is de basis plus het pad uit de spreadsheet:

```
https://jasperk1107.github.io/connectfit-pages  +  /hoogeveen/egym/
```

Overzicht van alle 25 pagina's in spreadsheetvolgorde:
https://jasperk1107.github.io/connectfit-pages/overzicht/

## Pagina's toevoegen of de volgorde wijzigen

Pas `pages.tsv` aan. Vier kolommen, gescheiden door een tab:

```
pad<TAB>naam<TAB>hoofdzoekwoord<TAB>bronbestand
```

Het bronbestand is de naam van een html-bestand in
`clients/connectfit/created/landing-pages/`. Laat de kolom leeg en de pagina
krijgt een placeholder met de vastgelegde URL.

De volgorde van de regels is de volgorde van het overzicht.

## Bijwerken

Gaat automatisch. Twee hooks in `clients/connectfit/.claude/settings.local.json`
draaien `sync.sh`: één zodra Claude een bestand in `created/landing-pages/`
schrijft of bewerkt, en één aan het eind van elke beurt, zodat ook wijzigingen
via de shell meegaan. Handmatig kan ook:

```bash
"/Users/jasperkoekoek/PPC OS/connectfit-pages/sync.sh"
```

Bouwt alles opnieuw uit `pages.tsv`, verwijdert wat er niet meer in staat en
pusht. Live na ongeveer een minuut.

Root-absolute links in de bronbestanden worden bij het bouwen omgezet naar
`/connectfit-pages/...`, zodat je tussen de previews kunt doorklikken.

De repo staat op noindex via `robots.txt`. Publieke repo: alleen pagina-html
erin, geen accountdata.
