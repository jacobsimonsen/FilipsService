# Filips Service – enkel GitHub Pages-version

En almindelig HTML-hjemmeside med servicevalg, prisberegning og e-mailformular. Ingen installation, database, Cloudflare, Google-hosting eller privat kalender.

## Sådan udgiver du

1. Pak `filips_service_github_pages.zip` ud.
2. Opret et **offentligt repository** på GitHub med navnet `filips-service`. Det giver adgang til Pages med GitHub Free. Hvis du i stedet opretter `<dit-brugernavn>.github.io`, får du en adresse uden `/filips-service/` til sidst.
3. Upload indholdet af den udpakkede mappe til repositoryets øverste niveau. Her skal `index.html`, `logo.png`, `.nojekyll` og denne README ligge. Upload indholdet, ikke blot ZIP-filen eller den ydre mappe.
4. Vælg repositoryets **Settings → Pages**. Under **Build and deployment** vælger du **Source: Deploy from a branch**, **Branch: main**, **Folder: /(root)** og trykker **Save**. Vælg den faktiske hovedgren, hvis den hedder noget andet end `main`.
5. Vent på udgivelsen, og brug adressen, som GitHub viser under Pages. Den vil normalt være `https://DIT-BRUGERNAVN.github.io/filips-service/`. Det er et eksempel, ikke en allerede oprettet adresse.

Der er ingen build-kommando, API-nøgle eller betalt hostingtjeneste at sætte op. `.nojekyll` fortæller GitHub, at hjemmesidens filer er klar til at blive vist direkte.

[GitHub: Opret en Pages-side](https://docs.github.com/en/pages/getting-started-with-github-pages/creating-a-github-pages-site) · [GitHub: Indstil udgivelse fra en gren](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site)

## Aktivér e-mailformularen

Formularen sender forespørgsler via FormSubmit til **filipvsimonsen@gmail.com**. Den kræver ikke, at kunden selv åbner et mailprogram.

Efter udgivelsen: send en testforespørgsel med dine egne oplysninger. FormSubmit kan sende en aktiveringsmail til Filip ved første brug af den nye webadresse. Åbn den, bekræft formularen, og kontrollér også spam. Send derefter en ny testforespørgsel og kontrollér, at den bliver modtaget.

En afsendelse bliver først bekræftet på siden, når FormSubmit sender kunden tilbage. Siden gemmer ingen opgaver eller kontaktoplysninger i en kalender eller database. Filip behandler forespørgsler i sin indbakke og bekræfter aftalen over for kunden.

FormSubmit behandler formularens oplysninger. Google reCAPTCHA er slået fra. Der er en skjult spamfælde, men denne statiske version har ingen egen server til at begrænse afsendelser. [FormSubmit: Formular og aktivering](https://formsubmit.co/)

## Funktioner

- Det store logo har en fremtrædende plads i introduktionen.
- Gl. Kongsvang står i introduktion, formular og kontaktoplysninger.
- Snerydning 40 kr.; saltning +15 kr.; lille indkørsel +20 kr. eller stor indkørsel +40 kr.; ekstra fortov +10/20/30 meter til +10/20/30 kr. Hjørnegrund er fjernet.
- Græsslåning 50 kr.; løvrydning 40 kr.; bortkørsel af løv som tillæg +10 kr.
- Telefon, navn, adresse, e-mail og ønsket dato er obligatoriske.
- Knappen hedder **Send forespørgsel**. Filip bekræfter opgaven og prisen efterfølgende.
- Ingen privat kalender eller login. Kundedata og adgangskoder skal ikke lægges i repositoryet.

## Senere ændringer og eget domæne

Tekst, udseende og priser findes i `index.html`; logoet ligger i `logo.png`. Upload ændringer til den valgte gren, så opdateres siden igen. Logoets relative sti virker både på en GitHub-projektadresse og på et eget domæne.

Et registreret domæne kan tilsluttes under **Settings → Pages → Custom domain**. Følg GitHubs vejledning til domænets DNS-indstillinger; et domænekøb er ikke inkluderet. Send en ny testforespørgsel efter adresseskift, da FormSubmit kan kræve ny aktivering. [GitHub: Eget domæne](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)

## GitHubs begrænsninger

GitHub Pages begrænser brug som gratis hosting af onlinevirksomheder, webshops og sider, der primært faciliterer kommercielle transaktioner. Den tekniske pakke ændrer ikke disse vilkår. Brug et almindeligt webhotel til den kommercielle drift, hvis siden falder under begrænsningen; de samme statiske filer kan også uploades dér. [GitHubs gældende begrænsninger](https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits)

## Kontrol

Sidekode og formularlogik er kontrolleret lokalt, herunder priser, tillæg, telefonvalidering, relative filstier og returadresse under en GitHub-projektsti. Testene sender ingen rigtige e-mails. Der er ikke oprettet et repository eller gennemført en udgivelse på din konto. Den faktiske e-maillevering skal prøves efter udgivelsen.
