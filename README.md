# Filips Service – hjemmeside og fælles kalender

Hjemmesiden bliver på GitHub Pages. `kalender.html` er den separate side, som Filip kan åbne og logge ind på med en adgangskode.

**En HTML-fil gemmer ikke aftaler på tværs af enheder.** Derfor forbindes formularen og kalenderen til ét Supabase-projekt. Google og Cloudflare bruges ikke til denne løsning. E-mail sendes fortsat via FormSubmit til filipvsimonsen@gmail.com.

## Opsæt én gang – før upload

1. Opret et projekt på https://supabase.com/dashboard. Vælg en region i EU.
2. Opret en bruger under Authentication → Users → Add user → Create new user, med e-mail **filipvsimonsen@gmail.com** og en adgangskode på mindst 12 tegn. Markér e-mailen som bekræftet. Brug ikke en invitation. Slå nye brugerregistreringer fra i projektets indstillinger for Authentication. Filip skal ikke have en ChatGPT- eller Google-konto.
3. Åbn SQL Editor, indsæt hele `database.sql`, og kør den. Den opretter opgaverne og giver kun den oprettede Filip-bruger adgang til at læse og acceptere dem. `filips_private` må ikke tilføjes til API'ens exposed schemas; standarden med `public` er tilstrækkelig.
4. Find projektets URL og **publishable key**, som starter med `sb_publishable_`, under projektets Connect/API-indstillinger. Indsæt dem i `kalender-config.js`, eller brug den medfølgende separate opsætningsvejledning til at downloade filen. Brug aldrig en secret key, service_role-nøgle eller en adgangskode i filen.
5. Upload pakkens filer i roden af https://github.com/jacobsimonsen/FilipsService. Erstat `index.html` og eventuelle eksisterende filer med samme navn. Upload filerne fra den udpakkede mappe; upload ikke selve ZIP-filen eller mappen som en undermappe.

GitHub Pages skal fortsat udgive fra `main` og `/(root)`, som den nuværende side.

## Åbn og afprøv

Ved opdatering fra en tidligere kalenderpakke: kør den opdaterede database.sql i Supabase SQL Editor, og upload den nye index.html. Eksisterende opgaver og deres pris bevares. Behold din allerede udfyldte kalender-config.js med projektets URL og offentlige nøgle.

- Hjemmeside: https://jacobsimonsen.github.io/FilipsService/
- Kalender: https://jacobsimonsen.github.io/FilipsService/kalender.html
- Send én testforespørgsel fra hjemmesiden. Kontrollér den både i kalenderen og i Filips e-mail. FormSubmit kan sende en aktiveringsmail, som Filip skal godkende. Før aktivering er e-mailleveringen ikke klar.
- Log ind i kalenderen fra en anden enhed, og kontrollér at den samme opgave vises. Accepter den og vælg den aftalte dato.
- Log ud og kontrollér, at kundernes oplysninger er skjult. Den offentlige side indeholder ikke kundeoplysninger, og databasen afviser læsning uden Filips login.

## Brug

Græsslåning koster 50 kr. med opsamling af græs som tillæg til 10 kr. Ved snerydning skal der vælges lille indkørsel til 20 kr. eller stor indkørsel til 40 kr. oven i grundprisen på 40 kr. Hjørnegrund kan tilvælges til 30 kr.; saltning koster fortsat 15 kr. Løvrydning og bortkørsel af løv er uændret.

Nye forespørgsler får status **Ny**. De er først aftalt, når Filip har talt eller skrevet med kunden og markeret dem som **Accepteret**. Statusændringer sender ikke en e-mail til kunden. Den oprindeligt ønskede dato bevares, når Filip ændrer den aftalte dato. Listen **Alle opgaver** indeholder også tidligere måneder. Kalenderen opdateres hvert minut, når den er åben, og med knappen **Opdater**. Filip kan skifte adgangskode fra kalenderen. En glemt adgangskode kan ændres via Supabase-projektets brugeradministration.

De nye forespørgsler gemmes i den fælles database, før e-mailtjenesten åbnes. Hvis forbindelsen til databasen mangler, sendes formularen ikke; kunden får i stedet mulighed for at skrive direkte til Filip. Hvis e-mailtjenesten fejler efter gemning, findes opgaven stadig i kalenderen. Gamle e-mails og forespørgsler fra den tidligere hjemmeside bliver ikke automatisk importeret.

## Drift

Supabase har en gratisplan. Gratis projekter kan blive sat på pause efter en uge uden aktivitet; så virker login og formularens gemning ikke, før projektet genoptages i Supabase. Tjek de gældende vilkår på https://supabase.com/pricing. Projektet og databasen tilhører den konto, der opretter dem. Eksportér jævnligt opgaver fra Supabase, og slet kundedata, når de ikke længere skal bruges.

Der er enkel spambegrænsning på formularen. Telefon er obligatorisk. Priser og tillæg beregnes også i databasen, så en kunde ikke kan ændre dem ved at manipulere siden. Ingen adgangskoder eller private nøgler indgår i pakken.

Pakken er afprøvet lokalt med en PostgreSQL-database og tests af formular og kalender. Den er ikke forbundet til et rigtigt Supabase-projekt eller udgivet på GitHub endnu. Den afsluttende test ovenfor kræver den færdige opsætning.

Supabase JavaScript-klienten er version 2.117.3, leveret som lokal `supabase.js`; se `LICENSE_supabase.txt`.
