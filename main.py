import csv
from dataclasses import dataclass
from datetime import datetime
from typing import Tuple, List

import psycopg


@dataclass
class Record:
    uuid: str
    time: datetime
    temperature: float

    def to_csv_entry(self) -> Tuple[str, str, float]:
        return self.time.strftime("%Y-%m-%d"), self.time.strftime("%B"), self.temperature


records: List[Record] = []
with psycopg.connect("host=127.0.0.1 dbname=woog user=woog") as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT * FROM lake_data WHERE lake_id='69c8438b-5aef-442f-a70d-e0d783ea2b38';")
        cur.fetchone()

        for record in cur:
            records.append(Record(*record))

records.sort(key=lambda r: r.time.month)
with open("result.csv", 'w') as f:
    writer = csv.writer(f)
    writer.writerow(["CST", "Month", "Temperature"])
    for record in records:
        writer.writerow(record.to_csv_entry())
