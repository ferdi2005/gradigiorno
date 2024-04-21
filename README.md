# Comuni italiani e gradi giorno
Questo progetto ha lo scopo di rilevare la presenza dei gradi giorno dei comuni Italiani su Wikipedia e su Wikidata e la corrispondenza delle stesse ai dati ufficiali così come allegati alla normativa di settore (DPR 412/1993 allegato A) aggiornato al 24-8-2016.
## Tabella
Il DPR è pieno di errori. Per questo motivo, si sono rese necessarie alcune correzioni, che sono state operate sulla lista stessa. Il file originale si può recuperare da https://www.normattiva.it/eli/stato/DECRETO_DEL_PRESIDENTE_DELLA_REPUBBLICA/1993/08/26/412/CONSOLIDATED
## Esclusioni
Nelle esclusioni ci sono i titoli di voce su cui non si vuole intervenire in quanto si sa che i dati sono disallienati, ad esempio a casua di fusioni di comuni non riconosciute nel decreto.
## .config
Il file
```
username
password
salvataggio delle modifiche su Wikipedia
verifica dei dati su Wikidata
```
## Licenza
I dati presenti nel file _tabella.csv_ sono stati estratti con [Tabula](https://tabula.technology) dal file *dpr412-93_allA_tabellagradigiorno.pdf*, allegato ad un DPR e dunque in pubblico dominio.

Il codice presente in questa repository è distribuito sotto licenza MIT.