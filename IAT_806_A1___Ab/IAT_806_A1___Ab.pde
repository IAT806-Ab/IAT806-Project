// ==============================
// Import Libraries
// ==============================

// ControlP5 is a GUI library for Processing that allows us to create dropdowns, sliders, buttons, etc.
import controlP5.*;

// Java utility classes for sorting and comparing objects (used for sorting movies by popularity)
import java.util.Collections;
import java.util.Comparator;


// ==============================
// API and Data Setup
// ==============================

// TMDB API key (required for authentication with TMDB API)
String apiKey = "541e4c0bd3dca1bd6a697b0707624a89";

// Base URL for TMDB API endpoints
String baseURL = "https://api.themoviedb.org/3";

// Base URL for movie poster images (w200 means width = 200 pixels)
String imageBaseURL = "https://image.tmdb.org/t/p/w200";

// ArrayList to store Movie objects fetched from TMDB
ArrayList<Movie> movies = new ArrayList<Movie>();

// Array to store poster images corresponding to movies
PImage[] posters;

// Flag to indicate if data has been successfully loaded (not heavily used here)
boolean dataLoaded = false;


// ==============================
// User Input and UI State
// ==============================

// Search query typed by user (not used much in this version since we rely on dropdown filters)
String searchQuery = "";

// Message displayed to guide the user (e.g., instructions or status updates)
String displayMessage = "Type to search, press ENTER to submit";

// Boolean flag to indicate if a search is currently in progress
boolean isSearching = false;


// ==============================
// Filter Variables
// ==============================

// Stores the selected genre ID (default -1 means "All genres")
int selectedGenreId = -1;

// Stores the selected release year (default "All" means no filter)
String selectedYear = "All";


// ==============================
// ControlP5 UI Components
// ==============================

// ControlP5 object to manage UI elements
ControlP5 cp5;

// Dropdown lists for selecting genre and year
ScrollableList genreSelector, yearSelector;

// Predefined genre IDs and names for quick selection (used to populate dropdown)
int[] genreIds = {-1, 28, 12, 16, 35, 18, 878};
String[] genreNames = {"All", "Action", "Adventure", "Animation", "Comedy", "Drama", "Sci-Fi"};

// Predefined years for filtering movies
String[] years = {"All", "2020", "2021", "2022", "2023", "2024", "2025"};


// ==============================
// Sorting Function
// ==============================

// Sorts the movies list by popularity in descending order (most popular first)
void sortMoviesByPopularity() {
  Collections.sort(movies, new Comparator<Movie>() {
    public int compare(Movie m1, Movie m2) {
      // Compare popularity values; higher popularity comes first
      return Float.compare(m2.popularity, m1.popularity);
    }
  });
}


// ==============================
// Setup Function
// ==============================

void setup() {
  size(800, 600); // Set the size of the window
  background(30); // Set background color to dark gray
  textAlign(CENTER); // Center-align text by default
  
  getMovieGenres(); // Attempt to load genres dynamically from TMDB API
  
  cp5 = new ControlP5(this); // Initialize ControlP5 for UI
  
  // Create Year Selector Dropdown
  yearSelector = cp5.addScrollableList("Release Date")
    .setId(1001) // Assign ID for event handling
    .setPosition(150,20) // Position on screen
    .setBackgroundColor(color(190)) // Background color
    .setColorActive(color(255, 128)) // Color when active
    .setColorForeground(color(255, 100)) // Foreground color
    .setBarHeight(50) // Height of the dropdown bar
    .setItemHeight(30); // Height of each item
  yearSelector.close(); // Keep dropdown closed initially
  
  // Populate year dropdown with predefined years
  for (int i = 0; i < years.length; i++) {
    yearSelector.addItem(years[i], i);
  }
  
  // Create Genre Selector Dropdown
  genreSelector = cp5.addScrollableList("genres")
    .setPosition(20,20)
    .setBackgroundColor(color(190))
    .setColorActive(color(255, 128))
    .setColorForeground(color(255, 100))
    .setBarHeight(50)
    .setItemHeight(30);
  genreSelector.close();
  
  // Populate genre dropdown with predefined genres
  for (int i = 0; i < genreNames.length; i++) {
    genreSelector.addItem(genreNames[i], i);
  }
  
  // Start with no movies loaded
  movies.clear();
}


// ==============================
// Event Handling for Dropdowns
// ==============================

// Triggered when user selects a year from the dropdown
void controlEvent(ControlEvent theEvent) {
  if (theEvent.getId() == 1001) { // Check if event is from yearSelector
    int value = (int) theEvent.getValue();
    println("Release Date selected: " + years[value]);
    selectedYear = years[value]; // Update selected year
    performSearch(); // Refresh search with new filter
  }
}

// Triggered when user selects a genre
void genres(int index) {
  if (index == -1) {
    selectedGenreId = -1; // All genres
  } else if (index >= 0 && index < genreIds.length) {
    selectedGenreId = genreIds[index]; // Update selected genre ID
    println("Genre ID: " + selectedGenreId);
    performSearch(); // Refresh search with new filter
  }
}


// ==============================
// Draw Loop
// ==============================

void draw() {
  background(30); // Clear screen
  
  // Display different states: searching, no results, or movie grid
  if (isSearching) {
    fill(255);
    text("Searching...", width/2, height/2);
  } else if (movies.size() == 0) {
    fill(150);
    text("No results to display", width/2, height/2);
    text("Try selecting a genre or year", width/2, height/2 + 30);
  } else {
    displayMovies(); // Show movie posters and info
  }
}


// ==============================
// Search Functions
// ==============================

// Initiates search based on selected filters
void performSearch() {  
  isSearching = true; // Show "Searching..." message
  movies.clear(); // Clear previous results
  searchMovies(); // Fetch new results
}

// Fetch movies from TMDB API using selected filters
void searchMovies() {
  try {
    // Base URL for discover endpoint
    String searchURL = "https://api.themoviedb.org/3/discover/movie?include_adult=false&include_video=false&language=en-US&page=1&sort_by=popularity.desc&api_key=" + apiKey;
    
    // Add genre filter if selected
    if (selectedGenreId >= 0) {
      searchURL = searchURL + "&with_genres=" + selectedGenreId;
    }
    
    // Add year filter if selected
    if (selectedYear != "All") {
      searchURL = searchURL + "&primary_release_year=" + selectedYear;
    }
    
    println("searchURL" + searchURL); // Debugging
    
    // Load JSON response from TMDB
    JSONObject response = loadJSONObject(searchURL);
    
    if (response != null) {
      JSONArray results = response.getJSONArray("results");
      
      movies.clear(); // Clear old results
      
      // Parse up to 9 movies for display
      for (int i = 0; i < min(9, results.size()); i++) {
        JSONObject movieData = results.getJSONObject(i);
                        
        Movie movie = new Movie();
        movie.title = movieData.getString("title");
        movie.overview = movieData.getString("overview");
        movie.popularity = movieData.getFloat("popularity");
        movie.releaseDate = movieData.getString("release_date");
        
        // Get poster path if available
        if (!movieData.isNull("poster_path")) {
          movie.posterPath = movieData.getString("poster_path");
        }
        
        movies.add(movie);
      }
      
      sortMoviesByPopularity(); // Sort results by popularity
      
      loadPosters(); // Load poster images
      displayMessage = "Found " + results.size() + " results. Press ESC to clear";
    } else {
      displayMessage = "Search failed. Check API key";
    }
  } catch (Exception e) {
    println("Error: " + e.getMessage());
    displayMessage = "Error occurred during search";
  }
  
  isSearching = false; // Done searching
}


// ==============================
// Poster Loading
// ==============================

// Load poster images for each movie
void loadPosters() {
  posters = new PImage[movies.size()];
  for (int i = 0; i < movies.size(); i++) {
    if (movies.get(i).posterPath != null) {
      String posterURL = imageBaseURL + movies.get(i).posterPath;
      posters[i] = loadImage(posterURL);
    }
  }
}


// ==============================
// Display Movies
// ==============================

// Display movies in a 3x3 grid
void displayMovies() {
  int cols = 3;
  int rows = 3;
  int movieWidth = width / cols;
  int movieHeight = (height - 70) / rows; // Leave space for dropdowns
  
  for (int i = 0; i < movies.size(); i++) {
    int x = (i % cols) * movieWidth;
    int y = (i / cols) * movieHeight + 70; // Offset for UI
    
    // Draw poster or placeholder
    if (i < posters.length && posters[i] != null) {
      image(posters[i], x + 10, y + 10, 80, 120);
    } else {
      fill(60);
      rect(x + 10, y + 10, 80, 120);
      fill(100);
      textAlign(CENTER);
      text("No\nPoster", x + 50, y + 65);
    }
    
    // Draw movie title
    fill(255);
    textAlign(LEFT);
    text(movies.get(i).title, x + 100, y + 30);
    
    // Draw popularity score and release year
    fill(255, 200, 0);
    text("Score: " + nf(movies.get(i).popularity, 0, 1), x + 100, y + 50);
    text(movies.get(i).releaseDate.substring(0,4), x + 100, y + 60);
    
    // Draw truncated overview
    fill(200);
    textSize(10);
    String overview = movies.get(i).overview;
    if (overview.length() > 150) {
      overview = overview.substring(0, 147) + "...";
    }
    text(overview, x + 100, y + 70, movieWidth - 110, 60);
    textSize(12);
  }
}


// ==============================
// Dynamic Genre Loading
// ==============================

// Fetch genre list from TMDB and populate dropdown
void getMovieGenres() {
   try {
      String genreListURL = "https://api.themoviedb.org/3/genre/movie/list?api_key=" + apiKey + "&language=en-US";
      JSONObject response = loadJSONObject(genreListURL);
    
      if (response != null) {
        JSONArray genres = response.getJSONArray("genres");
        
        genreSelector.clear(); // Clear old items
        
        for (int i = 0; i < genres.size(); i++) {
          JSONObject genre = genres.getJSONObject(i);
          int id = genre.getInt("id");
          String name = genre.getString("name");
          
          genreSelector.addItem(name, id); // Add to dropdown
          println("Genre: " + name + " (ID: " + id + ")");
        }
      } 
  } catch (Exception e) {
    println("Error loading genres");
  }
}


// ==============================
// Movie Class
// ==============================

// Represents a movie object with relevant details
class Movie {
  String title;        // Movie title
  String overview;     // Short description of the movie
  float rating;        // (Not used here, but could store vote_average)
  String posterPath;   // Path to poster image
  Float popularity;    // Popularity score from TMDB
  String releaseDate;  // Release date of the movie
}
