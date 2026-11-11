# =============================================================================
# Evolution of Purchasing Power in Italy (2016-2024)
# Author: Sofia Menegozzo
#
# Run from the repository folder. Input data are in data/ (exported from
# dati.xlsx); intermediate tables are written to output/.
# Regional maps need the ISTAT boundary shapefile (see README).
# =============================================================================
dir.create("output", showWarnings = FALSE)

# CARICAMENTO DEI DATI 
library(dplyr)
library(ggplot2)
library(tidyr)
reddito <- read.csv2("data/reddito.csv")
reddito
poverta <- read.csv2("data/poverta.csv")
poverta
popolazione <- read.csv2("data/popolazione.csv")
popolazione <- popolazione %>% filter(!is.na(Anno))
popolazione
nic <- read.csv2("data/nic.csv")
nic <- nic %>% filter(!is.na(Anno))
nic
gini<- read.csv2("data/gini.csv")
gini
disoccupazione <- read.csv2("data/disoccupazione.csv")
disoccupazione
reddito$Anno <- as.numeric(reddito$Anno)
popolazione$Anno <- as.numeric(popolazione$Anno)
nic$Anno <- as.numeric(nic$Anno)
disoccupazione$Anno <- as.numeric(disoccupazione$Anno)
gini$Anno <- as.numeric(gini$Anno)
poverta$Anno <- as.numeric(poverta$Anno)
reddito <- reddito %>%
  mutate(Reddito_netto = as.numeric(gsub("\\.", "", Reddito_netto)))
popolazione <- popolazione %>%
  mutate(Popolazione = as.numeric(gsub("\\.", "", Popolazione)))
nic <- nic %>%
  mutate(Indice_Prezzi = as.numeric(Indice_Prezzi))
disoccupazione <- disoccupazione %>%
  mutate(Tasso_Disoccupazione = as.numeric(Tasso_Disoccupazione))
gini <- gini %>%
  mutate(Indice_Gini = as.numeric(Indice_Gini))
poverta_long <- poverta %>%
  pivot_longer(cols = c(Nord_Ovest, Nord_Est, Centro, Mezzogiorno),
               names_to = "Area",
               values_to = "Valore")
write.csv2(poverta_long, "output/poverta_long.csv", row.names = FALSE)


# INDICATORI DERIVATI 
# reddito procapite 
reddito_procapite <- reddito %>%
  inner_join(popolazione, by = c("Anno", "Area")) %>%
  mutate(Reddito_Procapite = (Reddito_netto * 1000000) / Popolazione)
print(reddito_procapite)
# tasso di inflazione annuale
inflazione <- nic %>%
  group_by(Area) %>%
  arrange(Anno) %>%
  mutate(Inflazione = (Indice_Prezzi - lag(Indice_Prezzi)) / lag(Indice_Prezzi) * 100) %>%
  ungroup()
print(inflazione)
# potere d'acquisto (reddito reale procapite)
reddito_reale <- reddito_procapite %>%
  inner_join(nic, by = c("Anno", "Area")) %>%
  mutate( Reddito_Reale_Procapite = Reddito_Procapite / Indice_Prezzi * 100)
print(reddito_reale)
# tasso di crescita del reddito procapite
crescita_reddito <- reddito_procapite %>%
  group_by(Area) %>%
  arrange(Anno) %>%
  mutate(Crescita_Reddito = (Reddito_Procapite - lag(Reddito_Procapite)) / lag(Reddito_Procapite) * 100) %>%
  ungroup()
crescita_reddito
# creazione del dataset completo con tutti gli indicatori
dataset_completo <- reddito_reale %>%
  left_join(inflazione %>% select(Anno, Area, Inflazione), by = c("Anno", "Area")) %>%
  left_join(crescita_reddito %>% select(Anno, Area, Crescita_Reddito), by = c("Anno", "Area")) %>%
  left_join(gini, by = "Anno") %>%   # Gini dato nazionale ripetuto per tutte le aree
  left_join(disoccupazione, by = c("Anno", "Area")) %>%
  left_join(
    poverta_long %>% 
      filter(Indicatore == "Incidenza povertà assoluta familiare") %>%
      select(Anno, Area, Poverta_assoluta_familiare = Valore),
    by = c("Anno", "Area")
  ) %>%
  left_join(
    poverta_long %>% 
      filter(Indicatore == "Intensità povertà assoluta familiare") %>%
      select(Anno, Area, Intensita_poverta_assoluta = Valore),
    by = c("Anno", "Area")
  ) %>%
  left_join(
    poverta_long %>% 
      filter(Indicatore == "Incidenza povertà relativa familiare") %>%
      select(Anno, Area, Poverta_relativa_familiare = Valore),
    by = c("Anno", "Area")
  )
dataset_completo <- dataset_completo %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2(dataset_completo, "output/indicatori_economici_completi.csv", row.names = FALSE)
# indicatori nazionali
dati_nazionali <- dataset_completo %>%
  group_by(Anno) %>%
  summarise(
    Reddito_Procapite = mean(Reddito_Procapite, na.rm = TRUE),
    Reddito_Reale_Procapite = mean(Reddito_Reale_Procapite, na.rm = TRUE),
    Inflazione = mean(Inflazione, na.rm = TRUE),
    Indice_Gini = first(Indice_Gini),  # Gini è già nazionale
    Tasso_Disoccupazione = mean(Tasso_Disoccupazione, na.rm = TRUE),
    Poverta_assoluta_familiare = mean(Poverta_assoluta_familiare, na.rm = TRUE)
  ) %>%
  ungroup()
dati_nazionali <- dati_nazionali %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2(dati_nazionali, "output/indicatori_economici_nazionali.csv", row.names = FALSE)

# ANALISI DESCRITTIVA 
#REDDITO 
#L'evoluzione del reddito pro capite, nominale e reale in Italia (2016-2024)
dati_nazionali
ggplot(dati_nazionali, aes(x = Anno)) +
  geom_line(aes(y = Reddito_Procapite, color = "Reddito Nominale"), size = 1.2) +
  geom_line(aes(y = Reddito_Reale_Procapite, color = "Reddito Reale"), size = 1.2) +
  geom_point(aes(y = Reddito_Procapite), size = 2) +
  geom_point(aes(y = Reddito_Reale_Procapite), size = 2) +
  labs(title = "Evoluzione del Reddito Procapite in Italia (2016-2024)",
       subtitle = "Confronto tra valore nominale e reale (deflazionato)",
       x = "Anno",
       y = "Reddito Procapite (Euro)",
       color = "Tipo Reddito") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  theme(legend.position = "bottom")
# L’andamento del reddito reale nelle diverse aree del Paese
ggplot(dataset_completo, aes(x = Anno, y = Reddito_Reale_Procapite, color = Area)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  labs(title = "Evoluzione del Reddito Reale Procapite per Macroarea (2016-2024)",
       x = "Anno",
       y = "Reddito Reale Procapite (Euro)",
       color = "Area") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  theme(legend.position = "bottom")
# Variazione percentuale rispetto all'anno precedente
variazioni_reddito <- dataset_completo %>%
  group_by(Area) %>%
  arrange(Anno) %>%
  mutate(Variazione_Reddito = (Reddito_Reale_Procapite - lag(Reddito_Reale_Procapite)) / lag(Reddito_Reale_Procapite) * 100) %>%
  ungroup()
variazioni_reddito <- variazioni_reddito %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2 (variazioni_reddito, "output/indicatori_e_variazioni_reddito.csv", row.names = FALSE)
# Identificazione anni critici (post-pandemia 2020-2022)
anni_critici <- variazioni_reddito %>%
  filter(Anno %in% c(2020, 2021, 2022)) %>%
  group_by(Area) %>%
  summarise(
    Variazione_2020 = Variazione_Reddito[Anno == 2020],
    Variazione_2021 = Variazione_Reddito[Anno == 2021],
    Variazione_2022 = Variazione_Reddito[Anno == 2022]
  )
print("Variazioni reddito negli anni post-pandemia:")
print(anni_critici)
anni_critici <- anni_critici %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2 (anni_critici, "output/anni_critici.csv", row.names = FALSE)

# REDDITO PRO CAPITE E CONFRONTO TERRITORIALE 
# Livelli di reddito procapite per macroarea
dataset_territoriale <- dataset_completo %>%
  mutate(
    Macroarea = case_when(
      Area %in% c("Nord_Ovest", "Nord_Est") ~ "Nord",
      Area == "Centro" ~ "Centro",
      Area == "Mezzogiorno" ~ "Sud"
    )
  )
ggplot(dataset_territoriale, aes(x = as.factor(Anno), y = Reddito_Procapite, fill = Macroarea)) +
  geom_col(position = "dodge") +
  labs(title = "Confronto Reddito Procapite per Macroarea (2016-2024)",
       subtitle = "Valori nominali",
       x = "Anno",
       y = "Reddito Procapite (Euro)",
       fill = "Macroarea") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
# Aggreghiamo i dati per Macroarea 
dataset_macroarea <- dataset_territoriale %>%
  group_by(Anno, Macroarea) %>%
  summarise(
    Reddito_Procapite = mean(Reddito_Procapite, na.rm = TRUE),
    .groups = "drop"
  )
divario_reddito <- dataset_macroarea %>%
  select(Anno, Macroarea, Reddito_Procapite) %>%
  pivot_wider(names_from = Macroarea, values_from = Reddito_Procapite) %>%
  mutate(
    Divario_Sud_Nord = (Sud - Nord) / Nord * 100,
    Divario_Sud_Centro = (Sud - Centro) / Centro * 100,
    Divario_Sud_Media_CN = (Sud - ((Nord + Centro)/2)) / ((Nord + Centro)/2) * 100
  )
print("Divario percentuale del Sud rispetto al Nord e Centro:")
print(divario_reddito)
divario_reddito <- divario_reddito %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2(divario_reddito, "output/divario_reddito_percentuale.csv", row.names = FALSE)


ultimo_anno <- max(dataset_territoriale$Anno)
reddito_2024 <- dataset_territoriale %>%
  filter(Anno == ultimo_anno) %>%
  group_by(Macroarea) %>%
  summarise(Reddito_Procapite = mean(Reddito_Procapite))
primo_anno <- min(dataset_territoriale$Anno)
reddito_2016 <- dataset_territoriale %>%
  filter(Anno == primo_anno) %>%
  group_by(Macroarea) %>%
  summarise(Reddito_Procapite = mean(Reddito_Procapite))
# Differenza percentuale per l'ultimo anno
reddito_nord_2024 <- reddito_2024$Reddito_Procapite[reddito_2024$Macroarea == "Nord"]
reddito_centro_2024 <- reddito_2024$Reddito_Procapite[reddito_2024$Macroarea == "Centro"]
reddito_sud_2024 <- reddito_2024$Reddito_Procapite[reddito_2024$Macroarea == "Sud"]
differenza_sud_vs_nord2024 <- (reddito_sud_2024 - reddito_nord_2024) / reddito_nord_2024 * 100
differenza_sud_vs_centro2024 <- (reddito_sud_2024 - reddito_centro_2024) / reddito_centro_2024 * 100
print(paste("Nel", ultimo_anno, "il reddito procapite del Sud è inferiore del", 
            round(abs(differenza_sud_vs_nord2024), 1), "% rispetto al Nord"))
print(paste("e del", round(abs(differenza_sud_vs_centro2024), 1), "% rispetto al Centro"))
# Differenza percentuale per il primo anno
reddito_nord_2016 <- reddito_2016$Reddito_Procapite[reddito_2016$Macroarea == "Nord"]
reddito_centro_2016 <- reddito_2016$Reddito_Procapite[reddito_2016$Macroarea == "Centro"]
reddito_sud_2016 <- reddito_2016$Reddito_Procapite[reddito_2016$Macroarea == "Sud"]
differenza_sud_vs_nord2016 <- (reddito_sud_2016 - reddito_nord_2016) / reddito_nord_2016 * 100
differenza_sud_vs_centro2016 <- (reddito_sud_2016 - reddito_centro_2016) / reddito_centro_2016 * 100
print(paste("Nel", primo_anno, "il reddito procapite del Sud è inferiore del", 
            round(abs(differenza_sud_vs_nord2016), 1), "% rispetto al Nord"))
print(paste("e del", round(abs(differenza_sud_vs_centro2016), 1), "% rispetto al Centro"))
 # divario tra Nord Ovest e Mezzogiorno
gap_annuale <- dataset_completo %>%
     filter(Area %in% c("Nord_Ovest", "Mezzogiorno")) %>%
     group_by(Anno) %>%
    summarise(
         reddito_nord = mean(Reddito_Reale_Procapite[Area %in% c("Nord_Ovest")], na.rm = TRUE),
         reddito_sud = mean(Reddito_Reale_Procapite[Area == "Mezzogiorno"], na.rm = TRUE),
         gap_assoluto = reddito_nord - reddito_sud,
         gap_relativo = (reddito_nord / reddito_sud - 1) * 100  # percentuale in più del Nord
    )
gap_annuale
write.csv2 (gap_annuale, "output/gap_annuale.csv", row.names = FALSE)

# tasso medio annuo di crescita per macroarea CAGR = (Valore_finale / Valore_iniziale)^(1/n) - 1
cagr_macroaree <- dataset_completo %>%
  filter(Anno %in% c(2016, 2024)) %>%
  group_by(Area) %>%
  summarise(
    reddito_2016 = Reddito_Reale_Procapite[Anno == 2016],
    reddito_2024 = Reddito_Reale_Procapite[Anno == 2024],
    cagr = (reddito_2024 / reddito_2016)^(1/8) - 1,
    cagr_perc = cagr * 100
  )
cagr_macroaree
write.csv2 (cagr_macroaree, "output/Tasso_medio_annuo_crescita_macroareaCAGR.csv", row.names = FALSE)

# deviazione standard
sigma_convergence <- dataset_completo %>%
  group_by(Anno) %>%
  summarise(
    sd_reddito = sd(Reddito_Reale_Procapite, na.rm = TRUE),
    cv_reddito = sd_reddito / mean(Reddito_Reale_Procapite, na.rm = TRUE) * 100  # coefficiente di variazione
  )
sigma_convergence
write.csv2 (sigma_convergence, "output/sigma_convergence.csv", row.names = FALSE)

# grafico dispersione reddito macroaree
ggplot(sigma_convergence, aes(x = Anno, y = sd_reddito)) +
  geom_line(color = "darkred", size = 1.2) +
  geom_point(color = "darkred", size = 3) +
  geom_smooth(method = "lm", se = TRUE, linetype = "dashed", color = "blue", fill = "lightblue") +
  labs(title = "σ-convergence: la dispersione del reddito tra macroaree",
       x = "Anno",
       y = "Deviazione standard del reddito reale pro capite") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024)
# converge Crescita_%_2016_2024 = α + β * ln(Reddito_iniziale) + ε
dati_beta <- dataset_completo %>%
  filter(Anno == 2016) %>%
  select(Area, reddito_iniziale = Reddito_Reale_Procapite) %>%
  left_join(
    dataset_completo %>%
      filter(Anno == 2024) %>%
      select(Area, reddito_finale = Reddito_Reale_Procapite),
    by = "Area"
  ) %>%
  mutate(
    crescita_totale = (reddito_finale / reddito_iniziale - 1) * 100,
    ln_reddito_iniziale = log(reddito_iniziale)
  )
modello_beta <- lm(crescita_totale ~ ln_reddito_iniziale, data = dati_beta)
summary(modello_beta)
# t test sulle differenze 
differenze <- dataset_completo %>%
  filter(Area %in% c("Nord_Ovest", "Mezzogiorno"), Anno %in% c(2016, 2024)) %>%
  select(Anno, Area, Reddito_Reale_Procapite) %>%
  pivot_wider(names_from = Area, values_from = Reddito_Reale_Procapite) %>%
  mutate(diff = Nord_Ovest - Mezzogiorno)
print(differenze)
# differenze per tutti gli anni
differenze_annuali <- dataset_completo %>%
  filter(Area %in% c("Nord_Ovest", "Mezzogiorno")) %>%
  select(Anno, Area, Reddito_Reale_Procapite) %>%
  pivot_wider(names_from = Area, values_from = Reddito_Reale_Procapite) %>%
  mutate(diff = Nord_Ovest - Mezzogiorno) %>%
  filter(!is.na(diff))
# Test t tra i due periodi
differenze_annuali <- differenze_annuali %>%
  mutate(periodo = ifelse(Anno <= 2020, "2016-2020", "2021-2024"))
t.test(diff ~ periodo, data = differenze_annuali)
# correlazione differenza e anno
cor.test(differenze_annuali$Anno, differenze_annuali$diff)
# Regressione della differenza sull'anno
modello_diff <- lm(diff ~ Anno, data = differenze_annuali)
summary(modello_diff)
# Installare se necessario install.packages("Kendall")
library(Kendall)
MannKendall(differenze_annuali$diff)
# Dataset del gap annuale
gap_annuale <- dataset_completo %>%
  filter(Area %in% c("Nord_Ovest", "Mezzogiorno")) %>%
  group_by(Anno) %>%
  summarise(
    reddito_nord = mean(Reddito_Reale_Procapite[Area %in% c("Nord_Ovest")], na.rm = TRUE),
    reddito_sud = mean(Reddito_Reale_Procapite[Area == "Mezzogiorno"], na.rm = TRUE),
    gap_assoluto = reddito_nord - reddito_sud,
    gap_relativo = (reddito_nord / reddito_sud - 1) * 100
  )
# test: il gap è aumentato nel tempo
cor.test(gap_annuale$Anno, gap_annuale$gap_assoluto)
# Regressione
summary(lm(gap_assoluto ~ Anno, data = gap_annuale))


#INFLAZIONE E POTERE D'ACQUISTO REALE
# inflazione per macroarea
ggplot(inflazione %>% filter(Anno >= 2016), aes(x = Anno, y = Inflazione, color = Area)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  labs(title = "Tasso di Inflazione Annuale per Macroarea (2016-2024)",
       subtitle = "Base 2015=100",
       x = "Anno",
       y = "Tasso di Inflazione (%)",
       color = "Area") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  theme(legend.position = "bottom")
# Confronto crescita nominale vs inflazione (nazionale)
confronto_crescita <- dati_nazionali %>%
  mutate(
    Crescita_Nominale = (Reddito_Procapite - lag(Reddito_Procapite)) / lag(Reddito_Procapite) * 100,
    Anno_analisi = Anno
  ) %>%
  filter(!is.na(Crescita_Nominale)) %>%
  select(Anno_analisi, Crescita_Nominale, Inflazione)
# Grafico confronto
ggplot(confronto_crescita, aes(x = Anno_analisi)) +
  geom_line(aes(y = Crescita_Nominale, color = "Crescita Reddito Nominale"), size = 1.2) +
  geom_line(aes(y = Inflazione, color = "Inflazione"), size = 1.2) +
  geom_point(aes(y = Crescita_Nominale), size = 2) +
  geom_point(aes(y = Inflazione), size = 2) +
  labs(title = "Confronto: Crescita Reddito Nominale vs Inflazione",
       subtitle = "Anni in cui l'inflazione supera la crescita = perdita di potere d'acquisto",
       x = "Anno",
       y = "Variazione Percentuale (%)",
       color = "Indicatore") +
  theme_minimal() +
  scale_x_continuous(breaks = 2017:2024) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  scale_color_manual(values = c("Crescita Reddito Nominale" = "blue", "Inflazione" = "red"))
# Anni di perdita di potere d'acquisto
perdita_potere <- confronto_crescita %>%
  mutate(
    Differenza = Crescita_Nominale - Inflazione,
    Effetto = case_when(
      Differenza > 0 ~ "Guadagno potere d'acquisto",
      Differenza < 0 ~ "Perdita potere d'acquisto",
      TRUE ~ "Stabile"
    )
  )
print("Analisi potere d'acquisto:")
print(perdita_potere %>% select(Anno_analisi, Crescita_Nominale, Inflazione, Differenza, Effetto))
perdita_potere  <- perdita_potere %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2(perdita_potere, "output/perdita_potere.csv", row.names = FALSE)

# Inflazione e potere d'acquisto reale per macroarea
ggplot(inflazione %>% filter(Anno >= 2016) %>%
         mutate(Macroarea = case_when(
           Area %in% c("Nord_Ovest", "Nord_Est") ~ "Nord",
           Area == "Centro" ~ "Centro",
           Area == "Mezzogiorno" ~ "Sud"
         )), 
       aes(x = Anno, y = Inflazione, color = Macroarea)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  labs(title = "Confronto Tassi di Inflazione per Macroarea (2016-2024)",
       subtitle = "Differenze territoriali nei rincari",
       x = "Anno",
       y = "Tasso di Inflazione (%)",
       color = "Macroarea") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  scale_color_manual(values = c("Nord" = "steelblue", "Centro" = "darkgreen", "Sud" = "red"))
# Perdita di potere d'acquisto per macroarea (impatto inflazione)
perdita_territoriale <- dataset_territoriale %>%
  group_by(Macroarea, Anno) %>%
  summarise(
    Reddito_Nominale = mean(Reddito_Procapite),
    Reddito_Reale = mean(Reddito_Reale_Procapite),
    .groups = "drop"
  ) %>%
  group_by(Macroarea) %>%
  arrange(Anno) %>%
  mutate(
    Perdita_Annuale = (Reddito_Reale - lag(Reddito_Reale)) / lag(Reddito_Reale) * 100,
    Perdita_Cumulata_2020_2024 = (Reddito_Reale[Anno == 2024] - Reddito_Reale[Anno == 2020]) / Reddito_Reale[Anno == 2020] * 100
  )
print("Perdita cumulata di potere d'acquisto 2020-2024 per macroarea:")
perdita_territoriale %>%
  group_by(Macroarea) %>%
  summarise(Perdita_Cumulata = first(Perdita_Cumulata_2020_2024)) %>%
  print()

#TASSO DI DISOCCUPAZIONE
# Trend nazionale
disoccupazione_nazionale <- disoccupazione %>%
  group_by(Anno) %>%
  summarise(Tasso_Disoccupazione = mean(Tasso_Disoccupazione, na.rm = TRUE)) %>%
  filter(Anno >= 2016)

ggplot(disoccupazione_nazionale, aes(x = Anno, y = Tasso_Disoccupazione)) +
  geom_line(color = "darkred", size = 1.5) +
  geom_point(color = "darkred", size = 3) +
  labs(title = "Evoluzione del Tasso di Disoccupazione in Italia (2016-2024)",
       x = "Anno",
       y = "Tasso di Disoccupazione (%)") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024)
# Trend per macroaree
ggplot(disoccupazione %>% filter(Anno >= 2016), 
       aes(x = Anno, y = Tasso_Disoccupazione, color = Area)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  labs(title = "Tasso di Disoccupazione per Macroarea (2016-2024)",
       subtitle = "Confronto territoriale",
       x = "Anno",
       y = "Tasso di Disoccupazione (%)",
       color = "Area") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  theme(legend.position = "bottom")
# Tabella riassuntiva
tabella_disoccupazione <- disoccupazione %>%
  filter(Anno >= 2016) %>%
  group_by(Area) %>%
  summarise(
    Media_2016_2024 = mean(Tasso_Disoccupazione, na.rm = TRUE),
    Min = min(Tasso_Disoccupazione, na.rm = TRUE),
    Max = max(Tasso_Disoccupazione, na.rm = TRUE),
    Variazione_2024_2016 = last(Tasso_Disoccupazione) - first(Tasso_Disoccupazione)
  )
print("Statistiche descrittive disoccupazione per area:")
print(tabella_disoccupazione)
tabella_disoccupazione <- tabella_disoccupazione %>%
  mutate(across(where(is.numeric), ~ round(.x, 3)))
write.csv2(tabella_disoccupazione, "output/tabella_disoccupazione.csv", row.names = FALSE)
# Confronto tassi di disoccupazione per macroarea
disoccupazione_territoriale <- disoccupazione %>%
  filter(Anno >= 2016) %>%
  mutate(
    Macroarea = case_when(
      Area %in% c("Nord_Ovest", "Nord_Est") ~ "Nord",
      Area == "Centro" ~ "Centro",
      Area == "Mezzogiorno" ~ "Sud"
    )
  )

# Divario di disoccupazione (Sud vs Nord)
divario_disoccupazione <- disoccupazione_territoriale %>%
  group_by(Anno, Macroarea) %>%
  summarise(Tasso_medio = mean(Tasso_Disoccupazione), .groups = "drop") %>%
  pivot_wider(names_from = Macroarea, values_from = Tasso_medio) %>%
  mutate(
    Divario_Sud_Nord = Sud - Nord,
    Rapporto_Sud_Nord = Sud / Nord
  )
write.csv2(divario_disoccupazione , "output/divario_disoccupazione.csv", row.names = FALSE)

 # Divario territoriale in sintesi
# Creo un indice di svantaggio territoriale (normalizzato)
dati_sintesi <- dataset_territoriale %>%  # era "implicazioni", ora è "dataset_territoriale"
  group_by(Anno) %>%
  mutate(
    # Normalizzo le variabili (0-1 dove 1 = situazione migliore)
    Reddito_norm = (Reddito_Reale_Procapite - min(Reddito_Reale_Procapite)) / 
      (max(Reddito_Reale_Procapite) - min(Reddito_Reale_Procapite)),
    Disoccupazione_norm = 1 - (Tasso_Disoccupazione - min(Tasso_Disoccupazione)) / 
      (max(Tasso_Disoccupazione) - min(Tasso_Disoccupazione)),
    # Indice composito (media semplice)
    Indice_svantaggio = (Reddito_norm + Disoccupazione_norm) / 2 * 100
  ) %>%
  ungroup()

# Identifica i duplicati
duplicati <- dati_sintesi %>%
  group_by(Anno, Macroarea) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1)
print("Combinazioni Anno-Macroarea con duplicati:")
print(duplicati)
# Aggrega i duplicati prendendo la media
dati_sintesi_aggregati <- dati_sintesi %>%
  group_by(Anno, Macroarea) %>%
  summarise(
    Indice_svantaggio = mean(Indice_svantaggio, na.rm = TRUE),
    .groups = "drop"
  )
# Ora fai il pivot
divario_temporale <- dati_sintesi_aggregati %>%
  pivot_wider(
    names_from = Macroarea, 
    values_from = Indice_svantaggio
  ) %>%
  mutate(
    Divario_Nord_Sud = Nord - Sud,
    Divario_Centro_Sud = Centro - Sud
  )
print(divario_temporale)
# Report finale con tabelle riassuntive
# Tabella 1: Reddito procapite per macroarea (valori e divari)
tabella_reddito <- dataset_territoriale %>%
  group_by(Anno, Macroarea) %>%
  summarise(Reddito_medio = round(mean(Reddito_Procapite), 0), .groups = "drop") %>%
  pivot_wider(names_from = Macroarea, values_from = Reddito_medio) %>%
  mutate(
    Divario_Sud_Nord_perc = round((Sud - Nord) / Nord * 100, 1),
    Divario_Sud_Centro_perc = round((Sud - Centro) / Centro * 100, 1)
  )
print("=== TABELLA 1: REDDITO PROCAPITE PER MACROAREA ===")
print(tabella_reddito)
# Tabella 2: Tasso disoccupazione per macroarea
tabella_disoccupazione <- disoccupazione_territoriale %>%
  group_by(Anno, Macroarea) %>%
  summarise(Disoccupazione = round(mean(Tasso_Disoccupazione), 1), .groups = "drop") %>%
  pivot_wider(names_from = Macroarea, values_from = Disoccupazione) %>%
  mutate(
    Rapporto_Sud_Nord = round(Sud / Nord, 1),
    Differenza_Sud_Nord = round(Sud - Nord, 1)
  )
print("=== TABELLA 2: TASSO DISOCCUPAZIONE PER MACROAREA ===")
print(tabella_disoccupazione)
# Tabella 3: Potere d'acquisto reale (ultimo anno vs 2016)
potere_acquisto <- dataset_territoriale %>%
  group_by(Macroarea) %>%
  summarise(
    Reddito_Reale_2016 = round(mean(Reddito_Reale_Procapite[Anno == 2016]), 0),
    Reddito_Reale_2024 = round(mean(Reddito_Reale_Procapite[Anno == 2024]), 0),
    Variazione_perc = round((Reddito_Reale_2024 - Reddito_Reale_2016) / Reddito_Reale_2016 * 100, 1)
  )
print("=== TABELLA 3: EVOLUZIONE POTERE D'ACQUISTO 2016-2024 ===")
print(potere_acquisto)
# Esporta tutte le tabelle in CSV
write.csv2(tabella_reddito, "output/tabella_reddito_territoriale.csv", row.names = FALSE)
write.csv2(tabella_disoccupazione, "output/tabella_disoccupazione_territoriale.csv", row.names = FALSE)
write.csv2(potere_acquisto, "output/tabella_potere_acquisto.csv", row.names = FALSE)

#Serie storica Gini nazionale
ggplot(gini %>% filter(Anno >= 2016), aes(x = Anno, y = Indice_Gini)) +
  geom_line(color = "darkblue", size = 1.5) +
  geom_point(color = "darkblue", size = 3) +
  labs(title = "Evoluzione dell'Indice di Gini in Italia (2016-2024)",
       subtitle = "Valori più alti = maggiore disuguaglianza",
       x = "Anno",
       y = "Indice di Gini") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  geom_hline(yintercept = mean(gini$Indice_Gini[gini$Anno >= 2016]), 
             linetype = "dotted", color = "gray50") +
  annotate("text", x = 2016.5, y = mean(gini$Indice_Gini[gini$Anno >= 2016]) + 0.2, 
           label = "Media periodo", color = "gray50", size = 3)

# INDICATORE SINTETICO DI BENESSERE 
# Usiamo il dataset_panel o creiamo un dataset annuale per macroarea
# Seleziona le variabili rilevanti e gli anni
dati_benessere <- dataset_completo %>%
  filter(Anno >= 2016) %>%
  select(Anno, Area, 
         Reddito = Reddito_Reale_Procapite,
         Disoccupazione = Tasso_Disoccupazione,
         Poverta = Poverta_assoluta_familiare,
         Gini = Indice_Gini)  # Gini è nazionale, si ripete
# Funzione di normalizzazione
normalizza <- function(x) {
  (x - min(x, na.rm = TRUE)) / (max(x, na.rm = TRUE) - min(x, na.rm = TRUE)) * 100
}
# normalizzazione per anno 
dati_benessere_norm <- dati_benessere %>%
  group_by(Area) %>%
  mutate(
    Reddito_norm = normalizza(Reddito),     # Per il reddito (più alto = meglio) - normale
    Disoccupazione_inv = max(Disoccupazione, na.rm = TRUE) - Disoccupazione,     # Per disoccupazione (più bassa = meglio) - invertiamo
    Disoccupazione_norm = normalizza(Disoccupazione_inv),
    Poverta_inv = max(Poverta, na.rm = TRUE) - Poverta,
    Poverta_norm = normalizza(Poverta_inv),
  ) %>%
  ungroup()
dati_benessere_norm <- dati_benessere_norm %>%
  mutate( Benessere_3 = (Reddito_norm + Disoccupazione_norm + Poverta_norm) / 3) 
head(dati_benessere_norm %>% select(Anno, Area, Benessere_3))
dati_benessere_norm
write.csv2(dati_benessere_norm, "output/dati_benessere_norm.csv", row.names = FALSE)

# Grafico dell'indicatore sintetico 
ggplot(dati_benessere_norm, aes(x = Anno, y = Benessere_3, color = Area)) +
  geom_line(size = 1.2) +
  geom_point(size = 2) +
  labs(title = "Indicatore Sintetico di Benessere Territoriale",
       subtitle = "Reddito reale, occupazione, povertà (valori normalizzati 0-100)",
       x = "Anno",
       y = "Indice di Benessere (0-100)",
       color = "Area") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024) +
  theme(legend.position = "bottom")
# Classifica 2024
classifica_2024<- dati_benessere_norm %>%
  filter(Anno == 2024) %>%
  select(Area, Benessere_3) %>%
  arrange(desc(Benessere_3))
print("Classifica benessere territoriale 2024:")
print(classifica_2024)

# Calcola il gap nell'indicatore sintetico
gap_benessere <- dati_benessere_norm %>%
  filter(Area %in% c("Nord_Ovest", "Mezzogiorno")) %>%
  select(Anno, Area, Benessere_3) %>%
  pivot_wider(names_from = Area, values_from = Benessere_3) %>%
  mutate(gap_benessere = Nord_Ovest - Mezzogiorno)
gap_benessere
write.csv2(gap_benessere, "output/gap_benessere.csv", row.names = FALSE)

# Heatmap dell'indicatore nel tempo
ggplot(dati_benessere_norm, aes(x = Anno, y = Area, fill = Benessere_3)) +
  geom_tile() +
  scale_fill_gradient(low = "red", high = "green", name = "Benessere") +
  labs(title = "Heatmap dell'indicatore sintetico di benessere",
       subtitle = "Verde = benessere alto, Rosso = benessere basso",
       x = "Anno",
       y = "Area") +
  theme_minimal() +
  scale_x_continuous(breaks = 2016:2024)

#CORRELAZIONE TRA I DATI 
# Dataset nazionale (già hai dati_nazionali)
dati_nazionali <- dataset_completo %>%
  group_by(Anno) %>%
  summarise(
    Reddito_Reale = mean(Reddito_Reale_Procapite, na.rm = TRUE),
    Reddito_Nominale = mean(Reddito_Procapite, na.rm = TRUE),
    Inflazione = mean(Inflazione, na.rm = TRUE),
    Disoccupazione = mean(Tasso_Disoccupazione, na.rm = TRUE),
    Gini = first(Indice_Gini),
    Poverta_assoluta = mean(Poverta_assoluta_familiare, na.rm = TRUE),  # Nome corretto
    Poverta_relativa = mean(Poverta_relativa_familiare, na.rm = TRUE)   # Nome corretto
  ) %>%
  filter(Anno >= 2016)

# Dataset per macroarea (panel)
dati_panel <- dataset_completo %>%
  filter(Anno >= 2016) %>%
  select(
    Anno, 
    Area, 
    Reddito_Reale = Reddito_Reale_Procapite,
    Reddito_Nominale = Reddito_Procapite,
    Inflazione,
    Disoccupazione = Tasso_Disoccupazione,
    Poverta_assoluta = Poverta_assoluta_familiare,  # Nome corretto
    Poverta_relativa = Poverta_relativa_familiare   # Nome corretto
  )

# Reddito reale e disoccupazione (nazionale)
cor.test(dati_nazionali$Reddito_Reale, dati_nazionali$Disoccupazione)
# Reddito reale e povertà assoluta
cor.test(dati_nazionali$Reddito_Reale, dati_nazionali$Poverta_assoluta)
# Inflazione e reddito reale
cor.test(dati_nazionali$Inflazione, dati_nazionali$Reddito_Reale)
# Inflazione e povertà assoluta
cor.test(dati_nazionali$Inflazione, dati_nazionali$Poverta_assoluta)
# Disoccupazione e povertà assoluta
cor.test(dati_nazionali$Disoccupazione, dati_nazionali$Poverta_assoluta)
# Reddito nominale e reddito reale
cor.test(dati_nazionali$Reddito_Nominale, dati_nazionali$Reddito_Reale)
# matrice correlazione completa 
# Seleziona variabili numeriche
matrice_cor <- dati_nazionali %>%
  select(Reddito_Reale, Reddito_Nominale, Inflazione, Disoccupazione, Gini, Poverta_assoluta)
# Calcola matrice di correlazione
cor_matrix <- cor(matrice_cor, use = "complete.obs")
print(round(cor_matrix, 2))
# install.packages("corrplot")
library(corrplot)
corrplot(cor_matrix, 
         method = "color", 
         type = "upper", 
         tl.col = "black", 
         tl.srt = 45,
         addCoef.col = "black",  # Aggiunge i coefficienti
         number.cex = 0.8,
         title = "Matrice di correlazione tra indicatori economici (2016-2024)",
         mar = c(0,0,2,0))
# Test di significatività con p-value
# install.packages("Hmisc")
library(Hmisc)
rcorr(as.matrix(matrice_cor))
# Correlazione reddito-disoccupazione per macroarea
dati_panel %>%
  group_by(Area) %>%
  summarise(
    r = cor(Reddito_Reale, Disoccupazione, use = "complete.obs"),
    p_value = cor.test(Reddito_Reale, Disoccupazione)$p.value
  )

#### ANALISI CLUSTER SULLE REGIONI 
library(cluster)      # per analisi cluster
# install.packages("NbClust")
# install.packages("factoextra")
# install.packages("reshape2")
#install.packages("gridExtra")
library(factoextra)   
library(NbClust)    
library(reshape2)
library(gridExtra)
ultimo_anno <- max(dataset_territoriale$Anno)
#dataset macroaree
dati_base <- data.frame(
  Area = c("Nord_Ovest", "Nord_Est", "Centro", "Mezzogiorno"),
  Reddito = c(
    mean(dataset_territoriale$Reddito_Procapite[dataset_territoriale$Area == "Nord_Ovest" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE),
    mean(dataset_territoriale$Reddito_Procapite[dataset_territoriale$Area == "Nord_Est" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE),
    mean(dataset_territoriale$Reddito_Procapite[dataset_territoriale$Area == "Centro" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE),
    mean(dataset_territoriale$Reddito_Procapite[dataset_territoriale$Area == "Mezzogiorno" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE)
  ),
  Disoccupazione = c(
    mean(disoccupazione$Tasso_Disoccupazione[disoccupazione$Area == "Nord_Ovest" & disoccupazione$Anno == ultimo_anno], na.rm = TRUE),
    mean(disoccupazione$Tasso_Disoccupazione[disoccupazione$Area == "Nord_Est" & disoccupazione$Anno == ultimo_anno], na.rm = TRUE),
    mean(disoccupazione$Tasso_Disoccupazione[disoccupazione$Area == "Centro" & disoccupazione$Anno == ultimo_anno], na.rm = TRUE),
    mean(disoccupazione$Tasso_Disoccupazione[disoccupazione$Area == "Mezzogiorno" & disoccupazione$Anno == ultimo_anno], na.rm = TRUE)
  ) )
# Aggiungiamo anche il reddito reale 
dati_base$Reddito_Reale <- c(
  mean(dataset_territoriale$Reddito_Reale_Procapite[dataset_territoriale$Area == "Nord_Ovest" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE),
  mean(dataset_territoriale$Reddito_Reale_Procapite[dataset_territoriale$Area == "Nord_Est" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE),
  mean(dataset_territoriale$Reddito_Reale_Procapite[dataset_territoriale$Area == "Centro" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE),
  mean(dataset_territoriale$Reddito_Reale_Procapite[dataset_territoriale$Area == "Mezzogiorno" & dataset_territoriale$Anno == ultimo_anno], na.rm = TRUE)
)
dati_base <- na.omit(dati_base)
print("=== DATI PER CLUSTER ANALYSIS ===")
print(dati_base)
# Matrice per clustering
rownames(dati_base) <- dati_base$Area
matrice_cluster <- dati_base[, c("Reddito", "Disoccupazione", "Reddito_Reale")]
matrice_scaled <- scale(matrice_cluster)
print("Matrice standardizzata:")
print(matrice_scaled)
# Metodo Elbow (determinazione numero cluster)
set.seed(123)
wss_values <- numeric(3)
for(k in 1:3) {
  if(k == 1) {
    # Per k=1, withinss = varianza totale
    wss_values[k] <- sum(scale(matrice_scaled, scale = FALSE)^2)
  } else {
    km_result <- kmeans(matrice_scaled, centers = k, nstart = 25, iter.max = 100)
    wss_values[k] <- sum(km_result$withinss)
  } }
df_elbow <- data.frame(k = 1:3, wss = wss_values)
# Grafico elbow
ggplot(df_elbow, aes(x = k, y = wss)) +
  geom_line(color = "steelblue", size = 1.2) +
  geom_point(color = "steelblue", size = 3) +
  labs(title = "Metodo Elbow - Determinazione numero ottimale di cluster",
       subtitle = paste("Anno di riferimento:", ultimo_anno),
       x = "Numero di cluster (k)",
       y = "Within-cluster sum of squares") +
  theme_minimal() +
  scale_x_continuous(breaks = 1:3)

# 3. K-means clustering
set.seed(123)
kmeans_2 <- kmeans(matrice_scaled, centers = 2, nstart = 25)
kmeans_3 <- kmeans(matrice_scaled, centers = 3, nstart = 25)

# Risultati
print("=== RISULTATI K-MEANS (k=2) ===")
print(cbind(Area = rownames(matrice_scaled), Cluster = kmeans_2$cluster))

print("=== RISULTATI K-MEANS (k=3) ===")
print(cbind(Area = rownames(matrice_scaled), Cluster = kmeans_3$cluster))

# Aggiungiamo i cluster al dataset
dati_base$Cluster_2 <- kmeans_2$cluster
dati_base$Cluster_3 <- kmeans_3$cluster

# 2. Caratterizzazione dei cluster (usando dati_base)
caratteristiche_cluster_2 <- dati_base %>%
  group_by(Cluster_2) %>%
  summarise(
    N_aree = n(),
    Reddito_medio = mean(Reddito),
    Reddito_reale_medio = mean(Reddito_Reale),
    Disoccupazione_media = mean(Disoccupazione),
    Aree = paste(Area, collapse = ", ")
  )

print("=== CARATTERISTICHE CLUSTER (k=2) ===")
print(caratteristiche_cluster_2)

caratteristiche_cluster_3 <- dati_base %>%
  group_by(Cluster_3) %>%
  summarise(
    N_aree = n(),
    Reddito_medio = mean(Reddito),
    Reddito_reale_medio = mean(Reddito_Reale),
    Disoccupazione_media = mean(Disoccupazione),
    Aree = paste(Area, collapse = ", ")
  ) %>%
  arrange(desc(Reddito_medio))

print("=== CARATTERISTICHE CLUSTER (k=3) ===")
print(caratteristiche_cluster_3)

# 3. Visualizzazione PCA
pca_result <- prcomp(matrice_scaled, scale. = TRUE)
pca_data <- as.data.frame(pca_result$x[, 1:2])
pca_data$Area <- rownames(matrice_scaled)
pca_data$Cluster_2 <- as.factor(kmeans_2$cluster)
pca_data$Cluster_3 <- as.factor(kmeans_3$cluster)

# Grafico PCA con k=3
ggplot(pca_data, aes(x = PC1, y = PC2, color = Cluster_3, label = Area)) +
  geom_point(size = 4) +
  geom_text(vjust = -1, size = 3) +
  labs(title = "K-means Clustering (k=3) - Spazio PCA",
       subtitle = paste("Anno:", ultimo_anno),
       x = paste0("PC1 (", round(summary(pca_result)$importance[2,1]*100, 1), "%)"),
       y = paste0("PC2 (", round(summary(pca_result)$importance[2,2]*100, 1), "%)")) +
  theme_minimal() +
  scale_color_manual(values = c("1" = "steelblue", "2" = "darkgreen", "3" = "red"))

# 4. Hierarchical clustering
dist_matrix <- dist(matrice_scaled, method = "euclidean")
hc_ward <- hclust(dist_matrix, method = "ward.D2")

# Dendrogramma
library(ggdendro)
dendro_data <- dendro_data(hc_ward)
ggplot(segment(dendro_data)) +
  geom_segment(aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_text(data = label(dendro_data), 
            aes(x = x, y = y, label = label), hjust = 0, size = 4) +
  labs(title = "Dendrogramma - Hierarchical Clustering (Ward's Method)",
       subtitle = paste("Anno:", ultimo_anno),
       x = "Aree", y = "Distanza") +
  theme_minimal() +
  coord_flip() +
  scale_y_reverse()

# 5. Interpretazione
interpretazione <- caratteristiche_cluster_3 %>%
  mutate(
    Etichetta = case_when(
      Reddito_medio > 35000 ~ "Cluster Ricco/Sviluppato",
      Reddito_medio > 30000 ~ "Cluster Intermedio",
      TRUE ~ "Cluster in Ritardo Strutturale"
    ),
    Note = case_when(
      Reddito_medio > 35000 ~ "Alto reddito, bassa disoccupazione",
      Reddito_medio > 30000 ~ "Reddito medio, disoccupazione moderata",
      TRUE ~ "Basso reddito, alta disoccupazione"
    )
  )

print("=== INTERPRETAZIONE DEI CLUSTER ===")
print(interpretazione %>% select(Cluster_3, Etichetta, Reddito_medio, Disoccupazione_media, Aree, Note))

# 6. Salvataggio risultati
write.csv2(dati_base, "output/dati_cluster.csv", row.names = FALSE)
write.csv2(interpretazione, "output/interpretazione_cluster.csv", row.names = FALSE)

print("Analisi cluster completata con successo!")

# IL POTERE D'ACQUISTO DELLE REGIONI ITALIANE 
library(sf)
library(tmap)
library(dplyr)
library(ggplot2)
library(tidyr)
nic_regioni<- read.csv2("data/NICREG.csv",  sep = ";" ,
                        header = TRUE,
                        stringsAsFactors = FALSE,
                        dec = "." )
head (nic_regioni)

dataset_regionale <- read.csv2(
  "data/REDDITOREG.csv",
  sep = ";",
  header = TRUE,
  stringsAsFactors = FALSE,
  dec = "."
)

nic_regioni <- nic_regioni %>%
  rename(
    regione = Area,
    nic_2016 = nic.2016,
    nic_2024 = nic.2024
  ) %>%
  mutate(
    nic_2016 = as.numeric(gsub(",", ".", nic_2016)),
    nic_2024 = as.numeric(gsub(",", ".", nic_2024))
  )

reddito_regioni <- dataset_regionale %>%
  rename(
    regione = Area,
    reddito_2016 = X2016,
    reddito_2024 = X2024
  ) %>%
  mutate(
    reddito_2016 = as.numeric(gsub(",", ".", reddito_2016)),
    reddito_2024 = as.numeric(gsub(",", ".", reddito_2024))
  )

reddito_regioni <- reddito_regioni %>%
  filter(!is.na(regione) & regione != "" & !is.na(reddito_2016))

nic_regioni <- nic_regioni %>%
  filter(!is.na(regione) & regione != "" & !is.na(nic_2016))

reddito_regioni <- reddito_regioni %>%
  mutate(regione = case_when(
    regione == "Valle D'Aosta" ~ "Valle d'Aosta",
    TRUE ~ regione
  ))

nic_regioni <- nic_regioni %>%
  mutate(regione = case_when(
    regione == "Valle d'Aosta" ~ "Valle d'Aosta",
    TRUE ~ regione
  ))
reddito_regioni
nic_regioni

dati_completi <- reddito_regioni %>%
  left_join(nic_regioni, by = "regione") %>%
  mutate(
    potere_2016 = reddito_2016 / nic_2016 * 100,
    potere_2024 = reddito_2024 / nic_2024 * 100,
    var_assoluta = potere_2024 - potere_2016,
    var_perc = (potere_2024 / potere_2016 - 1) * 100
  ) %>%
  mutate(across(where(is.numeric), ~ round(.x, 2))) 

write.csv2(dati_completi, "output/datiregionali.csv", row.names = FALSE)

# Grafico: crescita percentuale
classifica_perc <- dati_completi %>%
  arrange(desc(var_perc))
print(classifica_perc)
ggplot(classifica_perc, aes(x = reorder(regione, var_perc), y = var_perc, fill = var_perc > 0)) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Variazione percentuale del Potere d'Acquisto",
    subtitle = "2016-2024",
    x = "",
    y = "Variazione %"
  ) +
  scale_fill_manual(values = c("TRUE" = "darkgreen", "FALSE" = "darkred"), guide = "none") +
  theme_minimal()

confini_regioni <- st_read("data/Reg01012025_g/Reg01012025_g_WGS84.shp")  # ISTAT boundaries, see README
unique(dati_completi$regione)
italy_data <- confini_regioni %>%
  mutate(
    regione_join = case_when(
      DEN_REG == "Piemonte" ~ "Piemonte",
      DEN_REG == "Valle d'Aosta" ~ "Valle d'Aosta",
      DEN_REG == "Lombardia" ~ "Lombardia",
      DEN_REG == "Trentino-Alto Adige" ~ "Trentino Alto Adige",  
      DEN_REG == "Veneto" ~ "Veneto",
      DEN_REG == "Friuli-Venezia Giulia" ~ "Friuli Venezia Giulia", 
      DEN_REG == "Liguria" ~ "Liguria",
      DEN_REG == "Emilia-Romagna" ~ "Emilia Romagna",  
      DEN_REG == "Toscana" ~ "Toscana",
      DEN_REG == "Umbria" ~ "Umbria",
      DEN_REG == "Marche" ~ "Marche",
      DEN_REG == "Lazio" ~ "Lazio",
      DEN_REG == "Abruzzo" ~ "Abruzzo",
      DEN_REG == "Molise" ~ "Molise",
      DEN_REG == "Campania" ~ "Campania",
      DEN_REG == "Puglia" ~ "Puglia",
      DEN_REG == "Basilicata" ~ "Basilicata",
      DEN_REG == "Calabria" ~ "Calabria",
      DEN_REG == "Sicilia" ~ "Sicilia",
      DEN_REG == "Sardegna" ~ "Sardegna",
      TRUE ~ DEN_REG
    )
  ) %>%
  left_join(dati_completi, by = c("regione_join" = "regione"))

# Mappa 2016
map_2016 <- tm_shape(italy_data) +
  tm_polygons(
    fill = "potere_2016",  # minuscolo! come nella colonna
    fill.scale = tm_scale_intervals(
      values = "brewer.reds",
      n = 6,
      style = "quantile"
    ),
    fill.legend = tm_legend(title = "Potere d'acquisto 2016"),
    col = "white",
    lwd = 0.5
  ) +
  tm_layout(frame = FALSE)

# Mappa 2024
map_2024 <- tm_shape(italy_data) +
  tm_polygons(
    fill = "potere_2024",  # minuscolo!
    fill.scale = tm_scale_intervals(
      values = "brewer.reds",
      n = 6,
      style = "quantile"
    ),
    fill.legend = tm_legend(title = "Potere d'acquisto 2024"),
    col = "white",
    lwd = 0.5
  ) +
  tm_layout(frame = FALSE)

# Mappa variazione percentuale
map_variazione <- tm_shape(italy_data) +
  tm_polygons(
    fill = "var_perc",  # minuscolo!
    fill.scale = tm_scale_intervals(
      values = "brewer.reds",
      n = 5,
      style = "quantile"
    ),
    fill.legend = tm_legend(title = "Variazione % (2016-2024)"),
    col = "white",
    lwd = 0.5
  ) +
  tm_layout(frame = FALSE)

# VISUALIZZA MAPPE
print(map_2016)
print(map_2024)
print(map_variazione)

mappe_tre <- tmap_arrange(map_2016, map_2024, map_variazione, ncol = 3)
print(mappe_tre)


# CLUSTER ANALYSIS PER REGIONE - SOLO REDDITO E CRESCITA

library(dplyr)
library(ggplot2)
library(cluster)
library(factoextra)
library(ggdendro)

dati_regioni_cluster <- dati_completi %>%
  select(regione, potere_2024, var_perc) %>%
  # Normalizza le variabili (importante per il clustering)
  mutate(
    potere_norm = scale(potere_2024)[,1],
    crescita_norm = scale(var_perc)[,1]
  ) %>%
  na.omit()

rownames(dati_regioni_cluster) <- dati_regioni_cluster$regione

matrice_cluster <- dati_regioni_cluster %>%
  select(potere_norm, crescita_norm)

# 2. METODO ELBOW - TROVA NUMERO OTTIMALE DI CLUSTER

set.seed(123)
wss <- numeric(10)
for(k in 1:10) {
  km <- kmeans(matrice_cluster, centers = k, nstart = 25)
  wss[k] <- km$tot.withinss
}

df_elbow <- data.frame(k = 1:10, wss = wss)

ggplot(df_elbow, aes(x = k, y = wss)) +
  geom_line(color = "steelblue", size = 1.2) +
  geom_point(color = "steelblue", size = 3) +
  labs(title = "Metodo Elbow - Cluster Regioni",
       subtitle = "Basato su potere d'acquisto 2024 e crescita %",
       x = "Numero di cluster (k)",
       y = "Within-cluster sum of squares") +
  theme_minimal() +
  scale_x_continuous(breaks = 1:10)

# 3. K-MEANS CON k OTTIMALE
k_ottimale <- 4

set.seed(123)
km_regioni <- kmeans(matrice_cluster, centers = k_ottimale, nstart = 25)
dati_regioni_cluster$cluster <- as.factor(km_regioni$cluster)

dati_regioni_cluster %>%
  select(regione, potere_2024, var_perc, cluster) %>%
  arrange(cluster, desc(potere_2024)) %>%
  print()

# CARATTERISTICHE DEI CLUSTER
caratteristiche <- dati_regioni_cluster %>%
  group_by(cluster) %>%
  summarise(
    n_regioni = n(),
    potere_medio = round(mean(potere_2024), 2),
    crescita_media = round(mean(var_perc), 2),
    min_potere = round(min(potere_2024), 2),
    max_potere = round(max(potere_2024), 2),
    regioni = paste(regione, collapse = ", ")
  )

print(caratteristiche)

# 5. GRAFICO A DISPERSIONE
library(ggrepel)
ggplot(dati_regioni_cluster, aes(x = potere_2024, y = var_perc, 
                                 color = cluster, label = regione)) +
  geom_point(size = 3) +
  geom_text_repel(size = 3,
                  box.padding = 0.5,
                  point.padding = 0.3,
                  segment.color = "gray50")
labs(title = "Cluster Analysis Regioni",
     subtitle = "Basata su potere d'acquisto 2024 e variazione % 2016-2024",
     x = "Potere d'acquisto 2024",
     y = "Variazione percentuale 2016-2024",
     color = "Cluster") +
  theme_minimal() +
  scale_color_brewer(palette = "Set1") +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  geom_vline(xintercept = mean(dati_regioni_cluster$potere_2024), 
             linetype = "dashed", color = "gray50") 


# 6. DENDRAGRAMMA (CLUSTERING GERARCHICO)
dist_matrix <- dist(matrice_cluster, method = "euclidean")
hc <- hclust(dist_matrix, method = "ward.D2")

library(ggdendro)
ddata <- dendro_data(hc)

ggplot(segment(ddata)) +
  geom_segment(aes(x = x, y = y, xend = xend, yend = yend)) +
  geom_text(data = label(ddata), 
            aes(x = x, y = y - 1, label = label), 
            hjust = 1, size =3.2) +
  labs(title = "Dendrogramma - Cluster Regioni",
       x = "", y = "Distanza") +
  theme_minimal() +
  coord_flip() +
  scale_y_reverse()

# Distanze di agglomerazione
distanze_agglomerazione <- hc_cluster$height
data.frame(
  step = 1:length(hc_cluster$height),
  distanza = hc_cluster$height
)
agglomerazione <- data.frame(
  fusione = c("4 + 3", "(4,3) + 1", "(4,3,1) + 2"),
  distanza = round(hc_cluster$height, 3)
)
print(agglomerazione)

#7. MAPPA DEI CLUSTER (se hai lo shapefile)

confini_regioni <- st_read("data/Reg01012025_g/Reg01012025_g_WGS84.shp")  # ISTAT boundaries, see README
unique(dati_completi$regione)
italy_data <- confini_regioni %>%
  mutate(
    regione_join = case_when(
      DEN_REG == "Piemonte" ~ "Piemonte",
      DEN_REG == "Valle d'Aosta" ~ "Valle d'Aosta",
      DEN_REG == "Lombardia" ~ "Lombardia",
      DEN_REG == "Trentino-Alto Adige" ~ "Trentino Alto Adige",  
      DEN_REG == "Veneto" ~ "Veneto",
      DEN_REG == "Friuli-Venezia Giulia" ~ "Friuli Venezia Giulia", 
      DEN_REG == "Liguria" ~ "Liguria",
      DEN_REG == "Emilia-Romagna" ~ "Emilia Romagna",  
      DEN_REG == "Toscana" ~ "Toscana",
      DEN_REG == "Umbria" ~ "Umbria",
      DEN_REG == "Marche" ~ "Marche",
      DEN_REG == "Lazio" ~ "Lazio",
      DEN_REG == "Abruzzo" ~ "Abruzzo",
      DEN_REG == "Molise" ~ "Molise",
      DEN_REG == "Campania" ~ "Campania",
      DEN_REG == "Puglia" ~ "Puglia",
      DEN_REG == "Basilicata" ~ "Basilicata",
      DEN_REG == "Calabria" ~ "Calabria",
      DEN_REG == "Sicilia" ~ "Sicilia",
      DEN_REG == "Sardegna" ~ "Sardegna",
      TRUE ~ DEN_REG
    )
  ) %>%
  left_join(dati_completi, by = c("regione_join" = "regione"))
cluster_map <- italy_data %>% 
  left_join(dati_regioni_cluster %>% select(regione, cluster), 
            by = c("regione_join" = "regione"))

library(tmap) 
map_cluster <- tm_shape(cluster_map) + 
  tm_polygons( col = "cluster", palette = "Set1", title = "Cluster regionali", border.col = "white", lwd = 0.3 ) +
  tm_layout(frame = FALSE) 

print(map_cluster)
