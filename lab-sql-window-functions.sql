-- 1
SELECT
    title,
    length,
    RANK() OVER (ORDER BY length DESC) AS rank_by_length
FROM film
WHERE length IS NOT NULL
  AND length > 0
ORDER BY length DESC;

SELECT
    title,
    length,
    rating,
    RANK() OVER (
        PARTITION BY rating
        ORDER BY length DESC
    ) AS rank_by_length_in_rating
FROM film
WHERE length IS NOT NULL
  AND length > 0
ORDER BY rating, rank_by_length_in_rating;

WITH actor_film_counts AS (
    SELECT
        fa.actor_id,
        COUNT(*) AS film_count
    FROM film_actor AS fa
    GROUP BY fa.actor_id
),

film_actor_ranked AS (
    SELECT
        f.film_id,
        f.title,
        a.actor_id,
        CONCAT(a.first_name, ' ', a.last_name) AS actor_name,
        afc.film_count,
        RANK() OVER (
            PARTITION BY f.film_id
            ORDER BY afc.film_count DESC
        ) AS actor_rank_in_film
    FROM film AS f
    JOIN film_actor AS fa
        ON f.film_id = fa.film_id
    JOIN actor AS a
        ON a.actor_id = fa.actor_id
    JOIN actor_film_counts AS afc
        ON afc.actor_id = a.actor_id
)

SELECT
    title,
    actor_name,
    film_count AS total_films_actor_has_acted_in
FROM film_actor_ranked
WHERE actor_rank_in_film = 1
ORDER BY title, actor_name;

WITH monthly_active_customers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m-01') AS month_start,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m-01')
)
SELECT
    month_start,
    active_customers
FROM monthly_active_customers
ORDER BY month_start;

WITH monthly_active_customers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m-01') AS month_start,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m-01')
),
monthly_with_previous AS (
    SELECT
        month_start,
        active_customers,
        LAG(active_customers) OVER (
            ORDER BY month_start
        ) AS prev_active_customers
    FROM monthly_active_customers
)
SELECT
    month_start,
    active_customers,
    prev_active_customers
FROM monthly_with_previous
ORDER BY month_start;

WITH monthly_active_customers AS (
    SELECT
        DATE_FORMAT(rental_date, '%Y-%m-01') AS month_start,
        COUNT(DISTINCT customer_id) AS active_customers
    FROM rental
    GROUP BY DATE_FORMAT(rental_date, '%Y-%m-01')
),
monthly_with_previous AS (
    SELECT
        month_start,
        active_customers,
        LAG(active_customers) OVER (
            ORDER BY month_start
        ) AS prev_active_customers
    FROM monthly_active_customers
)
SELECT
    month_start,
    active_customers,
    prev_active_customers,
    CASE
        WHEN prev_active_customers IS NULL OR prev_active_customers = 0 THEN NULL
        ELSE ROUND(
            (active_customers - prev_active_customers) / prev_active_customers * 100,
            2
        )
    END AS pct_change_active_customers
FROM monthly_with_previous
ORDER BY month_start;

WITH customer_month AS (
    SELECT DISTINCT
        customer_id,
        DATE_FORMAT(rental_date, '%Y-%m-01') AS month_start
    FROM rental
),

customer_month_with_prev AS (
    SELECT
        customer_id,
        month_start,
        LAG(month_start) OVER (
            PARTITION BY customer_id
            ORDER BY month_start
        ) AS prev_month_start
    FROM customer_month
),

retained_customers_per_month AS (
    SELECT
        month_start,
        COUNT(*) AS retained_customers
    FROM customer_month_with_prev
    WHERE prev_month_start IS NOT NULL
      AND DATE_ADD(prev_month_start, INTERVAL 1 MONTH) = month_start
    GROUP BY month_start
)

SELECT
    month_start,
    retained_customers
FROM retained_customers_per_month
ORDER BY month_start;
