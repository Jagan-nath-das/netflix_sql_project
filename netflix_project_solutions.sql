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

-- SUPER IMPORTANT (BIG FILES EXTRACTION)
set global local_infile = on;

LOAD DATA local INFILE "C:/ProgramData/MySQL/MySQL Server 8.4/Data/netflix_p3/netflix_titles.csv"
INTO TABLE netflix
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
ignore 1 lines;

-- SHOW VARIABLES LIKE 'secure_file_priv';

 -- 15 Business Problems & Solutions

-- 1. Count the number of Movies vs TV Shows
select type, count(*)
from netflix 
group by 1;


-- 2. Find the most common rating for movies and TV shows
select * from netflix;

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


-- 3. List all movies released in a specific year (e.g., 2020)
select title from netflix
where release_year = 2020
& type = "movie" ;


-- 4. Find the top 5 countries with the most content on Netflix  (very easy in postgre by using arrays nesting and unnesting)

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


-- 5. Identify the longest movie

select title, duration 
from netflix 
where type = 'movie'
order by cast(substring_index(duration, ',', 1) as signed) desc
limit 1;

-- 6. Find content added in the last 5 years
select distinct(release_year) from netflix
order by 1 desc;

select 
	*
 from netflix
where str_to_date (date_added, '%M %d, %Y') >= curdate() - interval 5 year;

select curdate() - interval 5 year;


-- 7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
select * from netflix
where director like "%rajiv Chilaka%";

-- 8. List all TV shows with more than 5 seasons
select * from
	(select 
		*,
		cast(substring_index(duration, ' ', 1) as unsigned) as season_count
	from netflix
	where type = "TV show"
	) as TV_shows
where season_count > 5;

-- 9. Count the number of content items in each genre
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
        
	
-- 10.Find each year and the average numbers of content release in India on netflix. 
-- return top 5 year with highest avg content release!
select 
    year(str_to_date(date_added, '%M %d, %Y')) as added_year,
    count(show_id),
    round((count(show_id)/(select count(*) from netflix where country like '%India%') * 100),2) as avg_content_release 
from netflix
where country like "%india%"
group by 1
order by 2 desc
limit 5; 

-- 11. List all movies that are documentaries
select * from netflix
where listed_in like '%documentaries%'
and type= 'Movie';

-- 12. Find all content without a director
select * from netflix
where director = '';

-- 13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
select * from netflix
where cast like '%salman khan%' 
and
release_year > year(curdate()) - 15;

-- 14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
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

-- 15.
-- Categorize the content based on the presence of the keywords 'kill' and 'violence' in 
-- the description field. Label content containing these keywords as 'Bad' and all other 
-- content as 'Good'. Count how many items fall into each category.

select 
	case
    when description like '%kill%' or
		 description like '%violence%' then 'Bad content'
         else 'Good content'
	end as category,
    count(*)
from netflix
group by 1
order by 2 desc
;
