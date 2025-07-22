CREATE DATABASE IMDb_Movie_Analysis;

USE IMDb_Movie_Analysis;
 
DROP DATABASE imdb_movie_analysis;





-- Step 1: Create 'movies'

CREATE TABLE movies (
    id VARCHAR(20) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    year INT NOT NULL,
    date_published DATE,
    duration INT,
    country VARCHAR(100),
    worlwide_gross_income VARCHAR(50),
    languages VARCHAR(100),
    production_company VARCHAR(255)
);


-- Step 2: Create 'names'

CREATE TABLE names (
    id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(255),
    height DECIMAL(5,2) NULL,
    date_of_birth DATE NULL,
    known_for VARCHAR(255)
);



-- Step 3: Create 'genre'
CREATE TABLE genre (
    id INT AUTO_INCREMENT PRIMARY KEY,
    movie_id VARCHAR(20),
    genre VARCHAR(100),
    FOREIGN KEY (movie_id) REFERENCES movies(id)
);



-- Step 4: Create 'ratings'
CREATE TABLE ratings (
    movie_id VARCHAR(20),
    avg_rating DECIMAL(3,1),
    total_votes INT,
    median_rating DECIMAL(3,1),
    FOREIGN KEY (movie_id) REFERENCES movies(id)
);




-- Step 5: Create 'director_mapping'
CREATE TABLE director_mapping (
    movie_id VARCHAR(20),
    name_id VARCHAR(20),
    FOREIGN KEY (movie_id) REFERENCES movies(id),
    FOREIGN KEY (name_id) REFERENCES names(id)
);




-- Step 6: Create 'role_mapping'
CREATE TABLE role_mapping (
    movie_id VARCHAR(20) NOT NULL,
    name_id VARCHAR(20) NOT NULL,
    category VARCHAR(100) NOT NULL ,
    FOREIGN KEY (movie_id) REFERENCES movies(id),
    FOREIGN KEY (name_id) REFERENCES names(id)
);

SET GLOBAL local_infile = 1;

## Segment 1: Database - Tables, Columns, Relationships
## What are the different tables in the database and how are they connected to each other in the database?

## 6 tables in the dabase i.e. movie,genre,ratings,director_mapping,role_mapping,names,
## movies - Center table
## ratings — related to movies via movie_id

## genre — related to movies via movie_id

## names — list of people (actors, directors)

##role_mapping — maps movie_id and name_id with category (e.g. actor, director)

## director_mapping — maps movie_id with name_id of directors


## Find the total number of rows in each table of the schema.
SELECT 
'movies' AS movie_table ,COUNT(*) AS Total_Count FROM movies
UNION
SELECT 'ratings', COUNT(*) FROM ratings
UNION
SELECT 'genre', COUNT(*) FROM genre
UNION
SELECT 'names', COUNT(*) FROM names
UNION
SELECT 'role_mapping', COUNT(*) FROM role_mapping
UNION
SELECT 'director_mapping', COUNT(*) FROM director_mapping;


## Segment 2: Movie Release Trends
## Determine the total number of movies released each year and analyse the month-wise trend.
SELECT MONTH(date_published) AS month, count(id) AS toal_no_movies FROM movies
GROUP BY  month
ORDER BY month;

SELECT YEAR(date_published) AS year, COUNT(*) AS total_movies
FROM movies
GROUP BY YEAR(date_published)
ORDER BY year;

## Calculate the number of movies produced in the USA or India in the year 2019.
SELECT COUNT(*) AS movies_produced_USAIND FROM movies
where year = 2019
AND (country LIKE '%USA%' OR country LIKE '%India%');

-- Segment 3: Production Statistics and Genre Analysis
## Retrieve the unique list of genres present in the dataset.
SELECT DISTINCT(genre) FROM genre;

## Identify the genre with the highest number of movies produced overall.
SELECT genre, COUNT(movie_id) AS movie_count FROM genre
GROUP BY 1
ORDER BY 1 DESC
LIMIT 1;

## Determine the count of movies that belong to only one genre.
SELECT COUNT(*)
FROM (
    SELECT movie_id
    FROM genre
    GROUP BY movie_id
    HAVING COUNT(genre) = 1
) AS single_genre_movies;

## Calculate the average duration of movies in each genre.
SELECT g.genre , ROUND(AVG(m.duration),1 )AS average_duration_movie FROM movies m JOIN genre g 
ON m.id = g.movie_id
GROUP BY g.genre
ORDER BY average_duration_movie DESC;

## Find the rank of the 'thriller' genre among all genres in terms of the number of movies produced.
SELECT genre, COUNT(*) AS Total ,
RANK() OVER(ORDER BY COUNT(*)DESC) AS rank_genre
FROM genre
GROUP BY genre;

## Segment 4: Ratings Analysis and Crew Members
## $$ Retrieve the minimum and maximum values in each column of the ratings table (except movie_id).

SELECT MIN(avg_rating), MAX(avg_rating),MIN(total_votes),MAX(total_votes),MIN(median_rating),MAX(median_rating) FROM ratings;

## Identify the top 10 movies based on average rating.

SELECT m.title, r.avg_rating FROM movies m JOIN ratings r 
ON m.id = r.movie_id 
ORDER BY r.avg_rating DESC
LIMIT 10 ;

##  Summarise the ratings table based on movie counts by median ratings.
SELECT median_rating, COUNT(movie_id) AS Movie_Count FROM ratings
GROUP BY 1
ORDER BY 1 DeSC;

## Identify the production house that has produced the most number of hit movies (average rating > 8).
SELECT m.production_company, COUNT(*) AS hit_movies FROM movies m JOIN 
ratings r ON 
m.id = r.movie_id
WHERE r.avg_rating > 8
GROUP BY m.production_company
ORDER BY hit_movies DESC;


# Determine the number of movies released in each genre during March 2017 in the USA with more than 1,000 votes.
SELECT g.genre,COUNT(*) AS Total_Count FROM movies m JOIN genre g 
ON m.id = g.movie_id
JOIN ratings r ON r.movie_id= m.id 
WHERE r.total_Votes > 1000
AND MONTH(date_published) = 03 AND YEAR(date_published) = 2017
GROUP BY g.genre;

## Retrieve movies of each genre starting with the word 'The' and having an average rating > 8.
SELECT g.genre,m.title, r.avg_rating FROM movies m 
JOIN genre g ON m.id = g.movie_id
JOIN ratings r  ON m.id = r.movie_id
WHERE r.avg_rating > 8 
AND m.title LIKE "THE%";

## Segment 5: Crew Analysis
## Identify the columns in the names table that have null values.
SELECT * FROM names;

SELECT 
    SUM(CASE WHEN name IS NULL THEN 1 ELSE 0 END) AS null_name,
    SUM(CASE WHEN height IS NULL THEN 1 ELSE 0 END) AS null_height,
    SUM(CASE WHEN date_of_birth IS NULL THEN 1 ELSE 0 END) AS null_dob,
    SUM(CASE WHEN known_for IS NULL THEN 1 ELSE 0 END) AS null_known_for
FROM names;


## Determine the top three directors in the top three genres with movies having an average rating > 8.
WITH top_genre AS(SELECT genre FROM genre
GROUP BY genre
ORDEr BY COUNT(*) DESC
LIMIT 3)

SELECT n.name,g.genre,COUNT(*) AS total FROM director_mapping dm 
JOIN names n  ON dm.name_id = n.id
JOIN movies m  ON dm.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
JOIN genre g ON m.id = g.movie_id
WHERE r.avg_rating >8 AND g.genre IN (SELECT * FROM top_genre)
GROUP BY n.name,g.genre
ORDER BY total DESC
LIMIT 3;

## Find the top two actors whose movies have a median rating >= 8.
SELECT n.name,COUNT(*) AS movie_count FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN ratings r ON rm.movie_id = r.movie_id
WHERE median_rating >=8
AND rm.category = 'actor'
GROUP BY n.name
ORDER BY movie_count DESC
LIMIT 2;

## Identify the top three production houses based on the number of votes received by their movies.
SELECT m.production_company,SUM(r.total_votes) AS total_votes FROM movies m 
JOIN ratings r ON m.id = r.movie_id
GROUP BY m.production_company
ORDER BY total_votes DESC
LIMIT 3;

## Rank actors based on their average ratings in Indian movies released in India.

SELECT n.name,AVG(r.avg_rating ) AS avg_ratings FROM movies m 
JOIN ratings r 
ON m.id = r.movie_id
JOIN role_mapping rm 
ON rm.movie_id = m.id
JOIN names n 
ON n.id = rm.name_id 
WHERE m.country = "India"
GROUP BY n.name
ORDER BY avg_ratings DESC
LIMIT 5;

## Identify the top five actresses in Hindi movies released in India based on their average ratings.


SELECT n.name, AVG(r.avg_rating) AS avg_rating
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN movies m ON rm.movie_id = m.id
JOIN ratings r ON m.id = r.movie_id
WHERE m.country = 'India' AND m.languages LIKE '%Hindi%' AND rm.category = 'actress'
GROUP BY n.name
ORDER BY avg_rating DESC
LIMIT 5;

## Segment 6: Broader Understanding of Data
## Classify thriller movies based on average ratings into different categories.

SELECT title, avg_rating,
CASE 
	WHEN avg_rating >= 8 THEN "Excellent"
    WHEN avg_rating >= 6 THEN "Good"
    WHEN avg_rating >=4 THEN "Average"
    ELSE 'Poor'
    END AS rating_categort

 FROM movies m 
JOIN ratings r ON m.id = r.movie_id
JOIN genre g ON  m.id = g.movie_id
WHERE  g.genre  = "Thriller";



## analyse the genre-wise running total and moving average of the average movie duration.
SELECT genre, 
       SUM(duration) OVER (PARTITION BY genre ORDER BY genre ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total,
       AVG(duration) OVER (PARTITION BY genre) AS moving_avg
FROM movies m
JOIN genre g ON m.id = g.movie_id;

##  Identify the five highest-grossing movies of each year that belong to the top three genres.
WITH top_genre AS(SELECT genre FROM genre
GROUP BY genre
ORDEr BY COUNT(*) DESC
LIMIT 3)

SELECT m.title, m.date_published, r.total_votes, g.genre
FROM movies m
JOIN ratings r ON m.id = r.movie_id
JOIN genre g ON m.id = g.movie_id
WHERE g.genre IN (SELECT genre FROM top_genre)
ORDER BY YEAR(m.date_published), r.total_votes DESC
LIMIT 5;


## Determine the top two production houses that have produced the highest number of hits among multilingual movies.
SELECT production_company, COUNT(*) AS hit_count
FROM movies m
JOIN ratings r ON m.id = r.movie_id
WHERE r.avg_rating > 8 AND m.languages LIKE '%,%'
GROUP BY production_company
ORDER BY hit_count DESC
LIMIT 2;

## dentify the top three actresses based on the number of Super Hit movies (average rating > 8) in the drama genre.
SELECT n.name, COUNT(*) AS superhit_count
FROM role_mapping rm
JOIN names n ON rm.name_id = n.id
JOIN genre g ON rm.movie_id = g.movie_id
JOIN ratings r ON rm.movie_id = r.movie_id
WHERE rm.category = 'actress' AND g.genre = 'Drama' AND r.avg_rating > 8
GROUP BY n.name
ORDER BY superhit_count DESC
LIMIT 3;

## Retrieve details for the top nine directors based on the number of movies, including average inter-movie duration, ratings, and more.
WITH movie_gaps AS (
    SELECT m.id AS movie_id,
           n.name,
           m.date_published,
           LAG(m.date_published) OVER (PARTITION BY n.name ORDER BY m.date_published) AS previous_date
    FROM director_mapping dm
    JOIN names n ON dm.name_id = n.id
    JOIN movies m ON dm.movie_id = m.id
)

SELECT n.name, 
       COUNT(mg.movie_id) AS total_movies,
       AVG(r.avg_rating) AS avg_rating,
       AVG(DATEDIFF(mg.date_published, mg.previous_date)) AS avg_gap
FROM movie_gaps mg
JOIN ratings r ON mg.movie_id = r.movie_id
JOIN names n ON mg.name = n.name
GROUP BY n.name
ORDER BY total_movies DESC
LIMIT 9;





















 
