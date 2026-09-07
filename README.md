## Evolution of Purchasing Power in Italy (2016–2024)
This project analyses the evolution of purchasing power and economic well-being in Italy between 2016 and 2024. The analysis focuses on income, inflation, unemployment, poverty and inequality, with attention to the differences between Italian macro-areas and regions.
The aim is to describe and interpret these economic phenomena in a clear and accessible way, also for readers without a specific background in economics or statistics.

### Objectives
This analysis examines the evolution of per capita income—in both nominal and real terms—while assessing the impact of inflation on household purchasing power. It also investigates the relationships between income, unemployment, poverty, and inequality, highlighting regional disparities across Italy’s various macro-areas and regions.

Using cluster analysis and Principal Component Analysis (PCA), the study identifies groups of territories characterized by similar economic and social conditions. Finally, a composite indicator of territorial well-being is constructed to integrate various socioeconomic dimensions—such as income, employment, and poverty—into a single measure, thereby providing a comprehensive assessment of well-being across the country's different areas.

### Data & Analysis
The project combines official data from ISTAT and Eurostat covering the period from 2016 to 2024. The analysis focuses on several key economic and social indicators, including household disposable income, resident population, the Consumer Price Index (NIC), the unemployment rate, absolute and relative poverty indicators, and the Gini index of income inequality. The data were cleaned, organised and integrated to ensure comparability across both national and territorial levels.
The analysis considers the four main Italian macro-areas: North-West, North-East, Centre, and South and Islands. Since the Mezzogiorno is not directly available as a single aggregate in some datasets, its values were calculated by combining data for Southern Italy and the Islands, taking population size into account where necessary.

Both descriptive and statistical methods were used to investigate changes in purchasing power and territorial inequalities. Income data were used to calculate nominal and real income per capita. Real income was obtained by adjusting nominal income for inflation, making it possible to assess changes in actual purchasing power over time.

Several statistical techniques were applied to examine the relationships between the main economic indicators. These include correlation analysis, t-tests, and chi-square tests, which were used to identify associations and differences across geographical areas and economic variables.

The project also employs cluster analysis and Principal Component Analysis (PCA) to identify groups of Italian macro-areas and regions with similar economic and socio-economic characteristics. Finally, regional maps were produced to provide a geographical representation of purchasing power across Italy and to highlight territorial differences and inequalities.

### Main Areas of Analysis
A central part of the project concerns the distinction between **nominal and real income**.
Nominal income per capita increased significantly between 2016 and 2024, rising from approximately €17,800 to €22,500. However, after accounting for inflation, real income increased by only around 4%, from approximately €17,800 to €18,600.

This difference highlights the effect of inflation on **purchasing power**. The gap between nominal and real income became particularly pronounced in 2022–2023, when consumer prices increased substantially.

The analysis highlights persistent differences in purchasing power between Italian macro-areas.
The Mezzogiorno has a purchasing power approximately 35% lower than the North-West. The absolute income gap between these two areas increased slightly from around €7,337 in 2016 to €7,478 in 2024, suggesting that the territorial gap remained broadly stable over the period.
Unemployment also shows substantial **territorial differences**. In 2024, the unemployment rate was approximately 12.1% in the Mezzogiorno, compared with 3.6% in the North-East.
These differences underline the persistent economic divide between Northern and Southern Italy.

The analysis also examines changes in **poverty** over time.
The incidence of absolute household poverty increased from 5.4% in 2016 to 8.1% in 2024. The increase was particularly relevant in Northern areas, where poverty rates rose substantially during the period considered.
The intensity of poverty is also examined, providing information on how far below the poverty threshold poor households are located. In the North-West, for example, the poverty intensity reached approximately 19.1%.

Income **inequality** is measured using the Gini index obtained from Eurostat.
The Italian Gini index remained relatively stable during the period, at around 32.6. Despite the major economic shocks associated with the COVID-19 pandemic and the subsequent inflationary period, the analysis does not identify significant structural changes in overall income inequality at national level.

### Results
Overall, the analysis shows that the increase in nominal income between 2016 and 2024 was substantially larger than the increase in real income.
Inflation therefore played an important role in reducing the effective gains in purchasing power, particularly during the 2022–2023 inflationary shock.

The results also highlight the persistence of territorial inequalities. Northern regions generally show higher income levels and lower unemployment, while the Mezzogiorno continues to experience lower purchasing power, higher unemployment and higher poverty rates.

Correlation analysis confirms a strong negative relationship between income and unemployment. Nominal income and unemployment show a correlation of approximately -0.94, while unemployment and poverty are also strongly related.
The relationship between real income and unemployment is weaker, with a correlation of approximately -0.46, reflecting the influence of inflation on real purchasing power.

**Cluster analysis** was used to identify groups of Italian areas with similar economic characteristics.
At macro-area level, three main groups emerge:
- Northern Italy: North-West and North-East, characterised by higher income levels, low unemployment and relatively contained poverty.
- Centre: an intermediate economic profile, with income and unemployment levels between those of Northern and Southern Italy.
- Mezzogiorno: characterised by lower income, higher unemployment and higher poverty.
At regional level, four main groups can be identified.

Lombardy emerges as a separate cluster due to its particularly high income level and strong growth.
A second group includes regions characterised by relatively low purchasing power and negative or weak income growth, such as Liguria, Tuscany, Umbria, Marche, Abruzzo, Molise, Puglia and Friuli-Venezia Giulia.
A third group includes regions with relatively low purchasing power but stronger recent growth, including Calabria, Sardinia, Basilicata, Trentino-Alto Adige and Valle d'Aosta.
Finally, a group of more dynamic regions combines relatively high purchasing power with positive growth. This group includes Lazio, Veneto, Emilia-Romagna, Piedmont, Campania and Sicily.

### Tools
The project combines different software tools for data preparation, statistical analysis and visualisation.
Python was used for data cleaning and preprocessing, mainly through pandas and numpy.
R was used for data integration, statistical analysis, indicator construction, visualisation, cluster analysis and Principal Component Analysis.
QGIS, together with the R package qgisprocess, was used to create regional maps of purchasing power using official ISTAT administrative boundaries.

### Repository Contents
potere_d'acquisto.pdf — complete report of the analysis\\
dati.xlsx — Excel file containing the datasets used in the analysis
Reg01012025_g_WGS84.shp — ISTAT shapefile containing the Italian regional boundaries
README.md — project description

### Limitations
The analysis has several methodological limitations.
The general consumer price index (NIC) does not account for differences in consumption patterns between households with different income levels. As a result, the inflation actually experienced by lower-income households may differ from the general inflation rate.

The use of macro-area aggregates also limits the possibility of analysing differences within individual territories.
Cluster analysis at macro-area level should be interpreted mainly as a descriptive tool because the number of observations is very small.

Finally, the analysis does not investigate causal relationships. It describes the evolution of purchasing power and identifies associations between economic indicators, but it does not directly examine the structural causes of territorial inequalities, such as differences in productivity, employment structure, investment or institutional factors.

Despite these limitations, the project provides a quantitative overview of the evolution of purchasing power and economic inequalities in Italy between 2016 and 2024.

**Author:** Sofia Menegozzo
