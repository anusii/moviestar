# Movie Star &mdash; Encrypted Movie Preferences in your Data Vault

**An ANU Software Innovation Institute demonstrator for your Data Vault**.

*Authors: Kevin Wang, Ashley Tang, Zheyuan Xu, Graham Williams*

*[ANU Software Innovation Institute](https://sii.anu.edu.au)*

*License: GNU GPL V3*

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![Last Updated](https://img.shields.io/github/last-commit/anusii/moviestar?label=last%20updated)](https://github.com/anusii/moviestar/commits/dev/)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/moviestar/master/pubspec.yaml&query=$.version&label=version)](https://github.com/anusii/moviestar/blob/dev/CHANGELOG.md)
[![GitHub Issues](https://img.shields.io/github/issues/anusii/moviestar)](https://github.com/anusii/moviestar/issues)
[![GitHub License](https://img.shields.io/github/license/anusii/moviestar)](https://github.com/anusii/moviestar/blob/dev/LICENSE)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/anusii/moviestar/dev)](https://github.com/anusii/moviestar/commits/dev/)

Run the app online: [**web**](https://moviestar.solidcommunity.au).

Download the latest version:
**GNU/Linux**
[deb](https://solidcommunity.au/installers/moviestar_amd64.deb) or
[zip](https://solidcommunity.au/installers/moviestar-dev-linux.zip);
**Android**
[apk](https://solidcommunity.au/installers/moviestar.apk);
**macOS**
[zip](https://solidcommunity.au/installers/moviestar-dev-macos.zip);
**Windows**
[zip](https://solidcommunity.au/installers/moviestar-dev-windows.zip) or
[inno](https://solidcommunity.au/installers/moviestar-dev-windows-inno.exe).

Coding documentation is available from [solid community
au](https://solidcommunity.au/docs/moviestar)

## Introduction

A personal movies (and TV series) database and recommender.


Visit https://moviestar.solidcommunity.au/ to run the app online.

See [installers](installers/README.md) for instructions to install on
your device.

Visit the [Solid Community AU Portfolio](https://solidcommunity.au)
for our portfolio of Solid apps developed by the community.

The app is implemented in [Flutter](https://flutter.dev) using our own
[solidpod](https://pub.dev/packages/solidpod) package for Flutter to
manage the Solid Pod interactions, and
[markdown_tooltip](https://pub.dev/packages/markdown_tooltip) to
enhance the user experience, guiding the user through the app, within
app.

## User Stories

### Personal Movie Data Store

As a user I can

- [X] Retrieve movie details from imdb or movielens or **themoviedb**
  - [X] Artwork
  - [X] Release date
  - [X] Description
  - [X] Rating
- [X] View all movies in the GUI using movie art work
- [ ] Settings to store my API key
- [ ] New lists with names that I choose (e.g., Watched and To Watch)
- [ ] Have any number of lists
- [ ] Add movies to my Watched list or my To Watch list
- [ ] Have the lists stored in my POD encrypted including the meta data
- [ ] Retrieved the two lists from my POD on startup
- [ ] Add my own comments to a movie (text)
- [ ] Add a rating with a movie (0-5?)
- [ ] My Movie Lists can be sorted by
  - [ ] name
  - [ ] rating
  - [ ] release date

### Sharing my Movies

As a user I can

- [ ] Share all my movies data with another user
- [ ] See who has shared their movies with me
- [ ] Switch to a view of another user's movies - perhaps on HOME
- [ ] Summarise movies across users
  - [ ] Frequency count
  - [ ] Total ratings count

### Recommending Movies

As a user I can

- [ ] Add private (not shared) views of other users sharing movies
  - [ ] Includes a weighting for each user (0-5, default 2)
- [ ] Add to summarise movies across users
   - [ ] Weighted ratings of movies - user rating * their movie rating

Add support for recommendation engine - review
https://github.com/recommenders-team/recommenders.
