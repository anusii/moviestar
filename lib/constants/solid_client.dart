/// Solid OIDC client identity for MovieStar.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Graham Williams

library;

/// The app's Solid-OIDC client profile document URL.

const String solidClientId =
    'https://anusii.github.io/moviestar/client-profile.jsonld';

/// Per-platform redirect URIs. solidpod's pickRedirectUri selects the right
/// entry at runtime (web redirect, custom scheme for mobile/desktop, and the
/// localhost entry for local development).

const List<String> solidRedirectUris = [
  'https://anusii.github.io/moviestar/redirect.html',
  'com.togaware.moviestar://redirect',
  'http://localhost:4400/redirect',
];
