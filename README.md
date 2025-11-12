# Video Rating and Sharing

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/anusii/moviestar)
[![GitHub License](https://img.shields.io/github/license/anusii/moviestar)](https://github.com/anusii/moviestar?tab=GPL-3.0-1-ov-file)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/moviestar/master/pubspec.yaml&query=$.version&label=version)](https://github.com/anusii/moviestar/blob/dev/CHANGELOG.md)
[![Last Updated](https://img.shields.io/github/last-commit/anusii/moviestar?label=last%20updated)](https://github.com/anusii/moviestar/commits/dev/)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/anusii/moviestar/dev)](https://github.com/anusii/moviestar/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/anusii/moviestar)](https://github.com/anusii/moviestar/issues)

A [solidui](https://github.com/anusii/solidui) based app to support
the secure and private storage of your movie and tv show ratings as
well as your own commentary, to share that with others, selectively,
and to recommend what to watch, with all data stored on your own
encrypted personal online data store (Pod) hosted in your Data Vault
on a Solid Server. The app was developed by the [ANU Software
Innovation Institute](https://sii.anu.edu.au) and written by Kevin
Wang, Ashley Tang, Zheyuan Xu, and [Graham
Williams](https://togaware.com/Graham.Williams.html).

If you appreciate the app then please show some ❤️ and star the GitHub
Repository to support the project.

The latest version of the app can be run online at
[innerpod.solidcommunity.au](https://moviestar.solidcommunity.au)
&mdash; no installation required, or downloaded and installed for your
platform from the [Solid Community AU](https://solidcommunity.au):

+ **Web**
  [solidcommunity](https://healthpod.solidcommunity.au/);
+ **Android**
  [apk](https://solidcommunity.au/installers/moviestar.apk);
+ **GNU/Linux**
  [snap](https://solidcommunity.au/installers/moviestar_amd64.snap) or
  [deb](https://solidcommunity.au/installers/moviestar_amd64.deb) or
  [zip](https://solidcommunity.au/installers/moviestar-dev-linux.zip);
+ **macOS**
  [dmg](https://solidcommunity.au/installers/moviestar-dev-macos-unsigned.dmg)
  or
  [zip](https://solidcommunity.au/installers/moviestar-dev-macos.zip);
+ **Windows**
  [zip](https://solidcommunity.au/installers/moviestar-dev-windows.zip)
  or
  [inno](https://solidcommunity.au/installers/moviestar-dev-windows-inno.exe).

Contributions are welcome. Visit
[github](https://github.com/anusii/moviestar) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request. The app is implemented in
[Flutter](https://flutter.dev) using
[solidpod](https://pub.dev/packages/solidpod) for Flutter to manage
the Solid Pod interactions. Thank you.

## Introduction

The moviestar app is a personal movies (and TV series) database and
recommender using [Solid Pods](https://solidproject.org/about). You
can read, write, and share encrypted movie ratings stored on your
personal online data store (Pod) hosted on a [Solid
Server](https://github.com/CommunitySolidServer/CommunitySolidServer). Since
you control where your data are stored, other apps can also interact
with your ratings and commentary to add value to your data and data
shared with you. You maintain full control over **your** data, not the
app developer collecting and hoarding **your** data.

The app is implemented in [Flutter](https://flutter.dev) using our own
[solidpod](https://pub.dev/packages/solidpod) and
[solidui](https://pub.dev/packages/solidui) packages for Flutter to
manage the Solid Pod interactions. Using
[markdown_tooltip](https://pub.dev/packages/markdown_tooltip)s the
user is guided through the app.

## Testing

Run integration tests using:

```bash
# Run all integration tests
make qtest

# Run specific test
make workflows/pod_favorites_real_test.qtest
```

See [integration_test/docs/](integration_test/docs/) for complete testing
documentation including:

+ [Testing Guide](integration_test/docs/testing-guide.md) - How to run
  tests
+ [Understanding POD Authentication](integration_test/docs/authentication.md)
  - OAuth, DPoP concepts
+ [Setup Guide](integration_test/docs/setup-guide.md) - Initial setup

## User Stories

### Personal Movie Data Store

As a user I can

+ [X] Retrieve movie details from imdb or movielens or **themoviedb**
  + [X] Artwork
  + [X] Release date
  + [X] Description
  + [X] Rating
+ [X] View all movies in the GUI using movie art work
+ [X] Settings to store my API key
+ [x] New lists with names that I choose (e.g., Watched and To Watch)
+ [x] Have any number of lists
+ [x] Add movies to my Watched list or my To Watch list
+ [x] Have the lists stored in my POD encrypted including the meta data
+ [x] Retrieved the two lists from my POD on startup
+ [x] Add my own comments to a movie (text)
+ [x] Add a rating with a movie (0-5?)
+ [x] My Movie Lists can be sorted by
  + [x] name
  + [x] rating
  + [x] release date

### Sharing my Movies

As a user I can

+ [x] Share all my movies data with another user
+ [x] See who has shared their movies with me
+ [x] Switch to a view of another user's movies - perhaps on HOME
+ [ ] Summarise movies across users
  + [ ] Frequency count
  + [ ] Total ratings count

### Recommending Movies

As a user I can

+ [ ] Add private (not shared) views of other users sharing movies
  + [ ] Includes a weighting for each user (0-5, default 2)
+ [ ] Add to summarise movies across users
  + [ ] Weighted ratings of movies - user rating * their movie rating

Add support for recommendation engine - review
[recommenders](https://github.com/recommenders-team/recommenders).

<!-- markdownlint-disable MD036 -->
*Time-stamp: <Friday 2025-10-31 08:40:44 +1100 Graham Williams>*
<!-- markdownlint-enable MD036 -->

<!-- markdownlint-disable MD053 -->
[comment]: # (Local Variables:)
[comment]: # (time-stamp-line-limit: -8)
[comment]: # (End:)
<!-- markdownlint-enable MD053 -->
