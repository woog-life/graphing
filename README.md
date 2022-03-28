# graphing

## Usage

Setup port-forwarding to access the postgres database:

```bash
kubectl -n wooglife port-forward $(kubectl -n wooglife get pods -l app=backend-postgres --no-headers | cut -f1 -d' ') 5432:5432
```

Run python script for postgres -> CSV conversion

```bash
virtualenv venv
source venv/bin/activate
pip install -r requirements.txt
python main.py
```

Run R script on generated CSV

- Install dependencies from [DESCRIPTION](DESCRIPTION)

```bash
R -f main.R
```
