-- Запрос 1: Топ 5 за 2026г
select p.dog, p.breed, r.year, r.total
from dogbase p
join camp r on p.dog_id = r.dog_id
where r.year = 2026
order by r.total desc
limit 5;


-- Запрос 2: Как менялся средний итоговый балл и количество участников по годам?
SELECT 
    Year, 
    COUNT(Dog_id) AS total_participants, 
    ROUND(AVG(Total), 2) AS avg_total_score
FROM Champ
WHERE Total IS NOT NULL
GROUP BY Year
ORDER BY Year;

-- Запрос 3: Топ-3 собаки по итоговым баллам в каждом году
SELECT Year, Dog_name, Total_Score, rank_in_year
FROM (
    SELECT 
        c.Year, 
        d.Dog AS Dog_name, 
        c.Total AS Total_Score,
        RANK() OVER(PARTITION BY c.Year ORDER BY c.Total DESC) as rank_in_year
    FROM Champ c
    JOIN dogbase d ON c.Dog_id = d.Dog_id
    WHERE c.Total IS NOT NULL
) sub
WHERE rank_in_year <= 3;


-- Запрос 5: Динамика результатов собак (разница с предыдущим годом)
SELECT 
    Dog_name, 
    Year, 
    Total,
    LAG(Total) OVER(PARTITION BY Dog_name ORDER BY Year) as prev_year_total,
    (Total - LAG(Total) OVER(PARTITION BY Dog_name ORDER BY Year)) as score_difference
FROM (
    SELECT d.Dog AS Dog_name, c.Year, c.Total
    FROM Champ c
    JOIN dogbase d ON c.Dog_id = d.Dog_id
    WHERE c.Total IS NOT NULL
) sub
ORDER BY Dog_name, Year;


-- Запрос 5: Собаки, которые провалили раздел Защита (C), но взяли высокий балл за След (A)
-- (Помогает выявить перекос в подготовке)
SELECT 
    d.Dog AS Dog_name, 
    d.Breed, 
    c.Year, 
    c.A AS Score_A_Tracking, 
    c.C AS Score_C_Protection
FROM Champ c
JOIN dogbase d ON c.Dog_id = d.Dog_id
WHERE c.C = 0 AND c.A > 70; --70 баллов квалификация

-- Запрос 6: Статистика по породам (средний балл, лучший балл, худший балл)
SELECT 
    d.Breed, 
    COUNT(c.Dog_id) AS starts_count,
    ROUND(AVG(c.Total), 2) AS avg_score,
    MAX(c.Total) AS best_score,
    MIN(c.Total) AS worst_score
FROM Champ c
JOIN dogbase d ON c.Dog_id = d.Dog_id
WHERE c.Total IS NOT NULL
GROUP BY d.Breed
HAVING starts_count > 3 -- Берем только породы, у которых было больше 3 выступлений
ORDER BY avg_score DESC;

