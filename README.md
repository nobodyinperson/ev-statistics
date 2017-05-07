# einsatzverwaltung-statistics
Create statistical plots based on [abrain's wordpress-plugin "einsatzverwaltung"](https://github.com/abrain/einsatzverwaltung)

See, for example, [the statistics pages](http://www.feuerwehr-aumuehle.de/wopre/alle-einsaetze/statistiken/) of the voluntary fire brigade of Aumühle.

This is a quite heavy-handed approach. The database of [abrain's einsatzverwaltung](https://github.com/abrain/einsatzverwaltung) is not accessed directly, but the information is extracted from the web pages created by the plugin.
That obsoletes the need of access to the database and enables the plotting to take place on another machine than the webhost.

This repository is still in development state.

# Requirements

```bash
sudo apt-get install python3 python3-lxml
sudo apt-get install r-base
```
