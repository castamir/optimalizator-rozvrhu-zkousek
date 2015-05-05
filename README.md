# Optimalizator rozvrhu zkousek


Tento nastroj slouzi k testovani generatoru rozvrhu zkousek na FIT. Skript `tester.sh` spousti generator ve vice paralelne provadenych procesech. Pocet procesu a rozsah penalizace se nastavuji pri spusteni.

Pozadavky:
------ 
- SWI Prolog v6.6.*

Nastaveni prav pro spousteni
------
```
chmod +x tester.sh
```

Spusteni:
------
```
./tester.sh
```

Skript vygeneruje slozku s aktualnim datumem a casem obsahujici data pro jednotlive spustene procesy. Skript `tester.sh` vypise, ktere procesy nalezly reseni.
Konkretni hodnoty reseni jsou v souborech: 
```
./test-DATUM/proces-N/output.txt
```

Parametry spusteni
------
Doporucuji spousten stejny pocet procesu jako maximalni rozsah - minimalni penalizace. Pri vypisu nastaveni jsou v hranatych zavorkach vychozi hodnoty.
```
Pocet procesu [1]: 100
Minimalni penalizace [0]: 20
Maximalni (rozsah) penalizace [100]: 120
```

