# agouti-tools

Personal utilities for working with the Agouti API.

[get-ages.sh](get-ages.sh) - a script to get the all ages using the API.\
[export-project.sh](export-project.sh) - create an export of a project (optionally filtered), wait for it and download it, with curl.\
[export-project.py](export-project.py) - the same in Python, which can also write the observations per deployment.

The scripts read the API address from `.api_url` and the API key from `.api_key` (both git-ignored; any file
matching `.api_key*` is ignored, so keys like `.api_key_frank_prod` can sit next to it). Both can be overridden
with the `API_URL` and `API_KEY_FILE` environment variables.

## Exports

An export is a zip in the [Camtrap DP](https://camtrap-dp.tdwg.org/) format with `datapackage.json`,
`deployments.csv`, `media.csv` and `observations.csv`. It is created asynchronously, in three calls:

1. `POST /v1/projects/{projectId}/exports` creates it and answers 202 with its `id`. It answers 409 while another
   export of the project is still running.
2. `GET /v1/projects/{projectId}/exports/{exportId}` returns its `status`: `Scheduled`, `Started`, `Completed`,
   `Error` (see `error`) or `Expired`. This takes a few minutes.
3. `GET /v1/projects/{projectId}/exports/{exportId}/archive` downloads the zip.

All calls authenticate with the `X-API-KEY` header, and the key's user must be admin, maintainer or coordinator of
the project.

```bash
./export-project.sh <projectId>                  # the complete project, unpacked into output/export-<projectId>
API_KEY_FILE=.api_key_frank_prod ./export-project.sh <projectId> my-output-dir
python export-project.py <projectId>             # needs `pip install requests`
```

### Options

| | bash | python |
|---|---|---|
| How long the server keeps the zip: `1d` (default), `7d`, `30d` or `infinite` | `RETENTION=7d` | `--retention 7d` |
| Only part of the project, as JSON | `FILTERS='{...}'` | `--filters '{...}'` |
| Also write `observations-events.csv` without the media-level rows | | `--events-only` |
| Also write `observations-<deploymentID>.csv` per deployment | | `--split-by-deployment` |

Without a retention an export made with the API is removed from the server 7 days after it completed; these scripts
ask for 1 day, as they download it right away. An export that is kept forever (`infinite`) can be published to GBIF
and used for reports, one with a retention period cannot.

### Filters

Different filters must all match, the values of one filter are alternatives. Deployments, locations, tags, groups
and the date range select the deployments, and media and observations always follow them.

```json
{
  "deploymentIds": ["..."],
  "locationIds": ["..."],
  "tagIds": ["..."],
  "groupIds": ["..."],
  "dateRange": { "start": "2025-03-01", "end": "2025-09-30" },
  "species": { "mode": "exclude", "scientificNames": ["Homo sapiens"] },
  "observationTypes": { "mode": "exclude", "values": ["blank", "vehicle"] },
  "validatedOnly": true
}
```

- `dateRange`: deployments that overlap the range are kept, with their start and end clipped to it (the recorded
  dates are in `deploymentComments`); media and observations outside it are left out.
- `species` and `observationTypes` (`animal`, `human`, `vehicle`, `blank`, `unknown`, `unclassified`) with mode
  `exclude` leave those observations out and also drop the media of every sequence they occur in. With mode
  `include` only those observations, and the media of their sequences, remain.
- `validatedOnly` keeps only observations of validated sequences; all media stay.

`POST /v1/projects/{projectId}/exports/preview` takes the same filters and answers with approximate counts, without
creating an export. Unknown ids give 400, and filters that select no deployments give 422.

### Replacing the CSV downloads

| Old call | New |
|---|---|
| `GET /project/{id}/deployments.csv` | `deployments.csv` in the zip |
| `GET /project/{id}/observations.csv` | `observations.csv` in the zip. It also has media-level rows (positions, bounding boxes) with `observationLevel = media`; `--events-only` gives the rows the old call had. |
| `...observations.csv?deploymentID=a,b` | filters `{"deploymentIds": ["a", "b"]}`, or one export of the project split with `--split-by-deployment` |
| `...deployments.csv?deploymentStart=...`, `...observations.csv?eventStart=...` | filters `{"dateRange": {"start": "2025-05-23"}}`. Not the same: overlapping deployments are kept and clipped. |
| `...deployments.csv?locationName=...` (part of a name) | filters `{"locationIds": ["..."]}`, which takes ids and not names |

Compared with the CSV downloads:

- It takes minutes instead of seconds, and only one export per project can run at a time. For several deployments
  one export of the project, split locally, is faster than one export per deployment.
- It is one consistent snapshot of the project, with `media.csv` and `datapackage.json` next to the CSVs.
- The observations include positioning data.

## Deprecated

[create-export.sh](create-export.sh), and its variants `create-export-acc.sh`, `create-export-prd.sh` and
`create-export-local.sh`, are **deprecated**. They download CSV files directly, and Agouti is replacing those routes
with the exports above:

- The `/project/{id}/*.csv` and `/projects/{id}/*.csv` paths these scripts call are already removed, they answer
  501 (not implemented).
- The `/v1/projects/{id}/camtrap-dp/1.0.2/*.csv` routes, their replacement, are deprecated since 19 November 2026 and
  answer 410 (gone) after 30 June 2027. Until then every response has `Deprecation` and `Sunset` headers.

Use [export-project.sh](export-project.sh) or [export-project.py](export-project.py) instead. The old scripts stay
for reference only.
