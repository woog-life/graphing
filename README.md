# graphing

## Usage

Setup port-forwarding to access the postgres database:

```bash
kubectl -n wooglife port-forward $(kubectl -n wooglife get pods -l app=backend-postgres --no-headers | cut -f1 -d' ' | head -n 1) 5432:5432
```

- Install dependencies from [DESCRIPTION](DESCRIPTION) via renv:
```R
install.packages('renv')
```

restart session

```R
library(renv)
renv::install()
```

```bash
R -f main.R
```
