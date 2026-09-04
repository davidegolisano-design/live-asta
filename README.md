# LIVEASTA

Base grafica/funzionale: ROSARUSH V81, rinominata e collegata al nuovo progetto Supabase.

## Avvio
1. Eseguire `setup_supabase_liveasta.sql` nel SQL Editor del nuovo progetto Supabase.
2. Pubblicare tutti i file di questa cartella sul branch `main` del repository GitHub.
3. In GitHub: Settings > Pages > Deploy from a branch > main / root.
4. Il listone incluso può essere sostituito dalla gestione dell'app.

## Asset giocatori
Le miniature locali sono in `assets/players/<ID>.webp`.
Se una miniatura non è disponibile, l'app usa gli asset generici locali.

## Sicurezza
Le policy SQL incluse sono permissive per il test client-only. Prima di una pubblicazione commerciale
vanno introdotti autenticazione, RLS restrittiva e protezioni server-side/RPC.
