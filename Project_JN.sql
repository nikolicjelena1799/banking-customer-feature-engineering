# 1) ETA' CLIENTE
CREATE TEMPORARY TABLE tmp_eta AS
SELECT
    c.id_cliente,
    TIMESTAMPDIFF(YEAR, c.data_nascita, CURDATE()) AS eta_cliente
FROM banca.cliente c;

#2) TRANSAZIONI IN USCITA: conteggio e somma totale (tutti i conti)
CREATE TEMPORARY TABLE tmp_trans_uscite AS
SELECT
    c.id_cliente,
    COUNT(t.id_conto) AS num_transazioni_uscita,        # COUNT su id_conto: conta le righe transazione non-nulle
    COALESCE(SUM(t.importo), 0) AS importo_uscite       # COALESCE restituisce  un valore diverso da NUll 
FROM banca.cliente c
LEFT JOIN banca.conto co ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione
WHERE tt.segno = '-'
GROUP BY c.id_cliente;

# 3) TRANSAZIONI IN ENTRATA: conteggio e somma totale
CREATE TEMPORARY TABLE tmp_trans_entrate AS
SELECT
    c.id_cliente,
    COUNT(t.id_conto) AS num_transazioni_entrata,
    COALESCE(SUM(t.importo), 0) AS importo_entrate
FROM banca.cliente c
LEFT JOIN banca.conto co ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione
WHERE tt.segno = '+'
GROUP BY c.id_cliente;

# 4) NUMERO TOTALE DI CONTI PER CLIENTE
CREATE TEMPORARY TABLE tmp_conti_tot AS
SELECT
    c.id_cliente,
    COUNT(co.id_conto) AS num_conti
FROM banca.cliente c
LEFT JOIN banca.conto co ON c.id_cliente = co.id_cliente
GROUP BY c.id_cliente;

#  5) NUMERO DI CONTI PER TIPO (indicatori separati per ogni tipo)
CREATE TEMPORARY TABLE tmp_conti_tipo AS
SELECT
    c.id_cliente,
    SUM(CASE WHEN co.id_tipo_conto = 0 THEN 1 ELSE 0 END) AS conti_base,
    SUM(CASE WHEN co.id_tipo_conto = 1 THEN 1 ELSE 0 END) AS conti_business,
    SUM(CASE WHEN co.id_tipo_conto = 2 THEN 1 ELSE 0 END) AS conti_privati,
    SUM(CASE WHEN co.id_tipo_conto = 3 THEN 1 ELSE 0 END) AS conti_famiglie
FROM banca.cliente c
LEFT JOIN banca.conto co ON c.id_cliente = co.id_cliente
GROUP BY c.id_cliente;

# 6) TRANSAZIONI PER TIPOLOGIA DI CONTO: conteggi e importi (entrate/uscite per tipo conto)
CREATE TEMPORARY TABLE tmp_trans_tipo AS
SELECT
    c.id_cliente,
    #numero uscite per tipo conto
    SUM(CASE WHEN co.id_tipo_conto = 0 AND tt.segno = '-' THEN 1 ELSE 0 END) AS num_uscite_base,
    SUM(CASE WHEN co.id_tipo_conto = 1 AND tt.segno = '-' THEN 1 ELSE 0 END) AS num_uscite_business,
    SUM(CASE WHEN co.id_tipo_conto = 2 AND tt.segno = '-' THEN 1 ELSE 0 END) AS num_uscite_privati,
    SUM(CASE WHEN co.id_tipo_conto = 3 AND tt.segno = '-' THEN 1 ELSE 0 END) AS num_uscite_famiglie,
    #numero entrate per tipo conto
    SUM(CASE WHEN co.id_tipo_conto = 0 AND tt.segno = '+' THEN 1 ELSE 0 END) AS num_entrate_base,
    SUM(CASE WHEN co.id_tipo_conto = 1 AND tt.segno = '+' THEN 1 ELSE 0 END) AS num_entrate_business,
    SUM(CASE WHEN co.id_tipo_conto = 2 AND tt.segno = '+' THEN 1 ELSE 0 END) AS num_entrate_privati,
    SUM(CASE WHEN co.id_tipo_conto = 3 AND tt.segno = '+' THEN 1 ELSE 0 END) AS num_entrate_famiglie,
    # importi uscite per tipo conto
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 0 AND tt.segno = '-' THEN t.importo ELSE 0 END), 0) AS importo_uscite_base,
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 1 AND tt.segno = '-' THEN t.importo ELSE 0 END), 0) AS importo_uscite_business,
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 2 AND tt.segno = '-' THEN t.importo ELSE 0 END), 0) AS importo_uscite_privati,
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 3 AND tt.segno = '-' THEN t.importo ELSE 0 END), 0) AS importo_uscite_famiglie,
    # importi entrate per tipo conto
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 0 AND tt.segno = '+' THEN t.importo ELSE 0 END), 0) AS importo_entrate_base,
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 1 AND tt.segno = '+' THEN t.importo ELSE 0 END), 0) AS importo_entrate_business,
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 2 AND tt.segno = '+' THEN t.importo ELSE 0 END), 0) AS importo_entrate_privati,
    COALESCE(SUM(CASE WHEN co.id_tipo_conto = 3 AND tt.segno = '+' THEN t.importo ELSE 0 END), 0) AS importo_entrate_famiglie
FROM banca.cliente c
LEFT JOIN banca.conto co ON c.id_cliente = co.id_cliente
LEFT JOIN banca.transazioni t ON co.id_conto = t.id_conto
LEFT JOIN banca.tipo_transazione tt ON t.id_tipo_trans = tt.id_tipo_transazione
GROUP BY c.id_cliente;

# 7) CREO LA TABELLA FINALE DENORMALIZZATA (persistente)
DROP TABLE IF EXISTS banca.feature_cliente; # cosi sovrascrive la tabella esistente
CREATE TABLE banca.feature_cliente AS
SELECT
    c.id_cliente,
    c.nome,
    c.cognome,
    COALESCE(e.eta_cliente, NULL) AS eta_cliente,

    # conti
    COALESCE(ct.num_conti, 0) AS num_conti,
    COALESCE(cp.conti_base, 0) AS conti_base,
    COALESCE(cp.conti_business, 0) AS conti_business,
    COALESCE(cp.conti_privati, 0) AS conti_privati,
    COALESCE(cp.conti_famiglie, 0) AS conti_famiglie,

    #  transazioni totali
    COALESCE(tu.num_transazioni_uscita, 0) AS num_transazioni_uscita,
    COALESCE(te.num_transazioni_entrata, 0) AS num_transazioni_entrata,
    COALESCE(tu.importo_uscite, 0) AS importo_uscite,
    COALESCE(te.importo_entrate, 0) AS importo_entrate,

    # transazioni per tipo conto
    COALESCE(ttt.num_uscite_base, 0) AS num_uscite_base,
    COALESCE(ttt.num_uscite_business, 0) AS num_uscite_business,
    COALESCE(ttt.num_uscite_privati, 0) AS num_uscite_privati,
    COALESCE(ttt.num_uscite_famiglie, 0) AS num_uscite_famiglie,
    COALESCE(ttt.num_entrate_base, 0) AS num_entrate_base,
    COALESCE(ttt.num_entrate_business, 0) AS num_entrate_business,
    COALESCE(ttt.num_entrate_privati, 0) AS num_entrate_privati,
    COALESCE(ttt.num_entrate_famiglie, 0) AS num_entrate_famiglie,
    COALESCE(ttt.importo_uscite_base, 0) AS importo_uscite_base,
    COALESCE(ttt.importo_uscite_business, 0) AS importo_uscite_business,
    COALESCE(ttt.importo_uscite_privati, 0) AS importo_uscite_privati,
    COALESCE(ttt.importo_uscite_famiglie, 0) AS importo_uscite_famiglie,
    COALESCE(ttt.importo_entrate_base, 0) AS importo_entrate_base,
    COALESCE(ttt.importo_entrate_business, 0) AS importo_entrate_business,
    COALESCE(ttt.importo_entrate_privati, 0) AS importo_entrate_privati,
    COALESCE(ttt.importo_entrate_famiglie, 0) AS importo_entrate_famiglie

FROM banca.cliente c
LEFT JOIN tmp_eta e           ON c.id_cliente = e.id_cliente
LEFT JOIN tmp_conti_tot ct    ON c.id_cliente = ct.id_cliente
LEFT JOIN tmp_conti_tipo cp   ON c.id_cliente = cp.id_cliente
LEFT JOIN tmp_trans_uscite tu ON c.id_cliente = tu.id_cliente
LEFT JOIN tmp_trans_entrate te ON c.id_cliente = te.id_cliente
LEFT JOIN tmp_trans_tipo ttt  ON c.id_cliente = ttt.id_cliente
ORDER BY c.id_cliente;
SELECT * from  banca.feature_cliente