/// Facade maintaining backward compatibility for TurtleSerializer.
///
/// This class delegates to specialized serializers while preserving.
/// the exact same API as the original monolithic TurtleSerializer.
///
/// Copyright (C) 2025, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://www.gnu.org/licenses/gpl-3.0.en.html.

library;

import 'package:moviestar/models/movie.dart';
import 'package:moviestar/shared/utils/turtle/api_key_turtle_serializer.dart';
import 'package:moviestar/shared/utils/turtle/movie_list_turtle_serializer.dart';
import 'package:moviestar/shared/utils/turtle/movie_turtle_serializer.dart';
import 'package:moviestar/shared/utils/turtle/rating_comment_turtle_serializer.dart';
import 'package:moviestar/shared/utils/turtle/turtle_base_serializer.dart';
import 'package:moviestar/shared/utils/turtle/turtle_namespace_manager.dart';
import 'package:moviestar/shared/utils/turtle/user_profile_turtle_serializer.dart';

/// Facade class maintaining complete backward compatibility with original TurtleSerializer.
///
/// All method signatures and behavior remain identical to ensure zero breaking changes.
/// This class delegates operations to specialized serializers for better maintainability.
class TurtleSerializer {
  // Expose namespace constants for backward compatibility
  static final moviestarOntoNS = TurtleNamespaceManager.moviestarOntoNS;
  static final moviestarDataNS = TurtleNamespaceManager.moviestarDataNS;
  static final movieNS = TurtleNamespaceManager.movieNS;
  static final xsdNS = TurtleNamespaceManager.xsdNS;
  static final rdfsNS = TurtleNamespaceManager.rdfsNS;
  static final owlNS = TurtleNamespaceManager.owlNS;
  static final localNS = TurtleNamespaceManager.localNS;

  // Expose common predicates for backward compatibility
  static final movieType = TurtleNamespaceManager.movieType;
  static final tvShowType = TurtleNamespaceManager.tvShowType;
  static final movieListType = TurtleNamespaceManager.movieListType;
  static final userType = TurtleNamespaceManager.userType;
  static final ratingType = TurtleNamespaceManager.ratingType;
  static final commentType = TurtleNamespaceManager.commentType;
  static final apiKeyType = TurtleNamespaceManager.apiKeyType;

  // User predicates
  static final hasMovieList = TurtleNamespaceManager.hasMovieList;
  static final hasApiKey = TurtleNamespaceManager.hasApiKey;
  static final dob = TurtleNamespaceManager.dob;
  static final gender = TurtleNamespaceManager.gender;
  static final webId = TurtleNamespaceManager.webId;

  // MovieList predicates
  static final hasMovie = TurtleNamespaceManager.hasMovie;
  static final filePath = TurtleNamespaceManager.filePath;

  // Movie predicates
  static final identifier = TurtleNamespaceManager.identifier;
  static final name = TurtleNamespaceManager.name;
  static final description = TurtleNamespaceManager.description;
  static final image = TurtleNamespaceManager.image;
  static final thumbnailUrl = TurtleNamespaceManager.thumbnailUrl;
  static final aggregateRating = TurtleNamespaceManager.aggregateRating;
  static final datePublished = TurtleNamespaceManager.datePublished;
  static final genre = TurtleNamespaceManager.genre;
  static final contentRating = TurtleNamespaceManager.contentRating;
  static final comment = TurtleNamespaceManager.comment;
  static final keyValue = TurtleNamespaceManager.keyValue;
  static final source = TurtleNamespaceManager.source;

  // List predicates
  static final nameProperty = TurtleNamespaceManager.nameProperty;
  static final moviesProperty = TurtleNamespaceManager.moviesProperty;

  // Rating predicates
  static final movieId = TurtleNamespaceManager.movieId;
  static final value = TurtleNamespaceManager.value;

  // Comment predicates
  static final text = TurtleNamespaceManager.text;

  // RDF predicates
  static final rdfType = TurtleNamespaceManager.rdfType;
  static final rdfsLabel = TurtleNamespaceManager.rdfsLabel;

  // ====== MOVIE SERIALIZATION METHODS ======

  /// Converts a list of movies to TTL format using proper RDF triples.
  static String moviesToTurtle(List<Movie> movies, String listName) {
    return MovieTurtleSerializer.moviesToTurtle(movies, listName);
  }

  /// Converts a single movie with user's personal rating and comment to TTL format.
  static String movieWithUserDataToTurtle(
    Movie movie,
    double? rating,
    String? comment,
  ) {
    return MovieTurtleSerializer.movieWithUserDataToTurtle(
      movie,
      rating,
      comment,
    );
  }

  /// Movie with user data using ontology structure.
  static String movieWithUserDataToTurtleOntology(
    Movie movie,
    double? rating,
    String? comment,
  ) {
    return MovieTurtleSerializer.movieWithUserDataToTurtleOntology(
      movie,
      rating,
      comment,
    );
  }

  /// Enhanced serialization with JSON backup for compatibility.
  static String moviesToTurtleWithJson(List<Movie> movies, String listName) {
    return MovieTurtleSerializer.moviesToTurtleWithJson(movies, listName);
  }

  /// Parses movies from TTL content using proper RDF parsing.
  static List<Movie> moviesFromTurtle(String ttlContent) {
    return MovieTurtleSerializer.moviesFromTurtle(ttlContent);
  }

  /// Parses a single movie with user data from TTL content.
  static Map<String, dynamic>? movieWithUserDataFromTurtle(String ttlContent) {
    return MovieTurtleSerializer.movieWithUserDataFromTurtle(ttlContent);
  }

  // ====== RATING/COMMENT SERIALIZATION METHODS ======

  /// Converts ratings map to TTL format using proper RDF triples.
  static String ratingsToTurtle(Map<String, double> ratings) {
    return RatingCommentTurtleSerializer.ratingsToTurtle(ratings);
  }

  /// Converts movie comments to TTL format using proper RDF triples.
  static String commentsToTurtle(Map<String, String> comments) {
    return RatingCommentTurtleSerializer.commentsToTurtle(comments);
  }

  /// Enhanced ratings serialization with JSON backup.
  static String ratingsToTurtleWithJson(Map<String, double> ratings) {
    return RatingCommentTurtleSerializer.ratingsToTurtleWithJson(ratings);
  }

  /// Enhanced comments serialization with JSON backup.
  static String commentsToTurtleWithJson(Map<String, String> comments) {
    return RatingCommentTurtleSerializer.commentsToTurtleWithJson(comments);
  }

  /// Parses ratings from TTL content using proper RDF parsing.
  static Map<String, double> ratingsFromTurtle(String ttlContent) {
    return RatingCommentTurtleSerializer.ratingsFromTurtle(ttlContent);
  }

  /// Parses comments from TTL content using proper RDF parsing.
  static Map<String, String> commentsFromTurtle(String ttlContent) {
    return RatingCommentTurtleSerializer.commentsFromTurtle(ttlContent);
  }

  // ====== USER PROFILE METHODS ======

  /// Creates a user profile in TTL format following the ontology structure.
  static String createUserProfile(
    String userWebId, {
    String? apiKey,
    String? dobString,
    String? genderString,
    required List<String> movieListIds,
  }) {
    return UserProfileTurtleSerializer.createUserProfile(
      userWebId,
      apiKey: apiKey,
      dobString: dobString,
      genderString: genderString,
      movieListIds: movieListIds,
    );
  }

  // ====== MOVIE LIST METHODS ======

  /// Creates a MovieList in TTL format following the ontology structure.
  static String createMovieList(
    String movieListId,
    String listName, {
    List<Movie> movies = const [],
    String? description,
    Map<String, String>? sharedWith,
    DateTime? sharedDate,
  }) {
    return MovieListTurtleSerializer.createMovieList(
      movieListId,
      listName,
      movies: movies,
      description: description,
      sharedWith: sharedWith,
      sharedDate: sharedDate,
    );
  }

  /// Parses a MovieList from TTL content and extracts movies.
  static Map<String, dynamic>? movieListFromTurtle(String ttlContent) {
    return MovieListTurtleSerializer.movieListFromTurtle(ttlContent);
  }

  // ====== API KEY METHODS ======

  /// Creates an API key file in TTL format following the ontology structure.
  static String createApiKey(
    String apiKeyId,
    String apiKeyValue, {
    String source = 'TMDB',
  }) {
    return ApiKeyTurtleSerializer.createApiKey(
      apiKeyId,
      apiKeyValue,
      source: source,
    );
  }

  // ====== UTILITY METHODS ======

  /// Generates a unique ID for resources.
  static String generateId() {
    return TurtleBaseSerializer.generateId();
  }
}
