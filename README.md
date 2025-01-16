# Netflix Movies and TV Shows Data Analysis using SQL

![](https://github.com/Jagan-nath-das/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
create database netflix_p3;
create table netflix
(
    show_id varchar(10) primary key,
    type	varchar (20),
    title	varchar (150),
    director	varchar (250),
    cast	varchar (1000),
    country	varchar(150),
    date_added	varchar(50),
    release_year	int,
    rating	varchar(20),
    duration	varchar (20),
    listed_in	varchar (100),
    description varchar(300)
);

set global local_infile = on;
LOAD DATA local INFILE "C:/ProgramData/MySQL/MySQL Server 8.4/Data/netflix_p3/netflix_titles.csv"
INTO TABLE netflix
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
ignore 1 lines;

```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT 
    type,
    COUNT(*)
FROM netflix
GROUP BY 1;
```

**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
select type, rating 
from
	(
	select 
		type, 
		rating,
		count(*),
		rank() over(partition by type order by count(*) desc) as ranking
	from netflix
	group by 1,2
	) as t1
where ranking = 1;
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT title
FROM netflix
WHERE
    release_year = 2020 & type = 'movie';
```

**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql

select country, count(*) as total_content
from
	(select 
		trim(substring_index(substring_index(country,',', n.n), ',','-1')) as country
	from netflix
	join (
		select 1 as n union all
		select 2 union all
		select 3 union all
		select 4 union all
		select 5
		) 
		as n on
		n.n <= 1+ length(country) - length (replace(country, ',', ''))
	 )  as split_countries
where country is not null and country != ''
group by 1
order by total_content desc
limit 5;

```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
select title, duration 
from netflix 
where type = 'movie'
order by cast(substring_index(duration, ',', 1) as signed) desc
limit 1;
```

**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
select distinct(release_year) from netflix
order by 1 desc;

select 
	*
 from netflix
where str_to_date (date_added, '%M %d, %Y') >= curdate() - interval 5 year;

```

**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
select * from netflix
where director like "%rajiv Chilaka%";
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
select * from
	(select 
		*,
		cast(substring_index(duration, ' ', 1) as unsigned) as season_count
	from netflix
	where type = "TV show"
	) as TV_shows
where season_count > 5;

```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
select 
	genres,
    count(*) as genre_count 
from (
    select 
		listed_in,
		trim(substring_index(substring_index(listed_in, ',', n.n), ',', -1)) as genres
	from netflix
		join(
			select 1 as n union all
			select 2 union all
			select 3
			)
			as n
			on n.n <= 1+ length(listed_in) - length(replace(listed_in, ',', ''))
			where listed_in is not null
			) as genres_count
        group by 1
        order by 2 desc;
        

```

**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix. 
return top 5 year with highest avg content release!

```sql
select 
    year(str_to_date(date_added, '%M %d, %Y')) as added_year,
    count(show_id),
    round((count(show_id)/(select count(*) from netflix where country like '%India%') * 100),2) as avg_content_release 
from netflix
where country like "%india%"
group by 1
order by 2 desc
limit 5; 
```

**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
select * from netflix
where listed_in like '%documentaries%'
and type= 'Movie';
```

**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
select * from netflix
where director = '';
```

**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
select * from netflix
where cast like '%salman khan%' 
and
release_year > year(curdate()) - 15;

```

**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
with recursive numbers as (
	select 1 as n union all
    select n+1
    from numbers 
    where n<60
    )
select actors, count(*) as movie_count
from(
	select
		trim(substring_index(substring_index(`cast`, ',', n), ',', -1)) as actors
	from netflix
		join numbers
		on n <= 1+ length(`cast`) - length(replace(`cast`, ',', ''))
		where `cast` != '' and country ='India'
    ) as actor_list
group by 1
order by 2 desc
limit 10;
```

**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
select 
	case
    when description like '%kill%' or
		 description like '%violence%' then 'Bad content'
         else 'Good content'
	end as category,
    count(*)
from netflix
group by 1
order by 2 desc;
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.
