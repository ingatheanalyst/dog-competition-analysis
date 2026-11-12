-- Запрос 1: Топ 5 за 2026г
SELECT p.Dog, p.Breed, r.Year, r.Total 
FROM dogbase p
JOIN champ r ON p.Dog_id = r.Dog_id
WHERE r.Year = 2026 
  AND r.Total NOT IN ('dis', 'ng', 'vh', 'hur') -- исключаем дисквалификации
ORDER BY CAST(r.Total AS INTEGER) DESC -- принудительно сортируем как числа
LIMIT 5;


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
SELECT Year, Dog_name, Total_Score, Score_C, Score_A, Score_B, rank_in_year
FROM (
    SELECT 
        c.Year, 
        d.Dog AS Dog_name, 
        c.Total AS Total_Score,
        c.C AS Score_C,
        c.A AS Score_A,
        c.B AS Score_B,
        ROW_NUMBER() OVER(
            PARTITION BY c.Year 
            ORDER BY 
                CAST(c.Total AS INTEGER) DESC, -- 1. Общий балл
                CAST(c.C AS INTEGER) DESC,     -- 2. Если равно - по Защите (C)
                CAST(c.A AS INTEGER) DESC,     -- 3. Если и тут равно - по Следу (A)
                CAST(c.B AS INTEGER) DESC      -- 4. Если всё равно - по Послушанию (B)
        ) as rank_in_year
    FROM Champ c
    JOIN dogbase d ON c.Dog_id = d.Dog_id
    WHERE c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh')
) sub
WHERE rank_in_year <= 3;


-- Запрос 4: Динамика результатов собак (разница с предыдущим годом)
SELECT 
    d.Dog AS Dog_name,
    MAX(CASE WHEN c.Year = 2024 THEN c.Total END) AS "2024",
    MAX(CASE WHEN c.Year = 2025 THEN c.Total END) AS "2025",
    MAX(CASE WHEN c.Year = 2026 THEN c.Total END) AS "2026",
    -- Оборачиваем AVG в ROUND, чтобы оставить 1 знак после запятой
    ROUND(
        AVG(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS REAL) END), 
        1
    ) AS avg_score
FROM dogbase d
JOIN Champ c ON d.Dog_id = c.Dog_id
GROUP BY d.Dog
ORDER BY avg_score DESC;


-- Запрос 5: Собаки, с сильным следом (А) и защитой (С), но слабым послушанием (В)
SELECT 
    d.Dog AS Dog_name,
    d.Breed,
    c.Year,
    c.A AS Score_A_Tracking,
    c.B AS Score_B_Obidience, -- Баллы за послушание, чтобы видеть провал
    c.C AS Score_C_Protection
FROM Champ c
JOIN dogbase d ON c.Dog_id = d.Dog_id
WHERE c.A > 90 
  AND c.C > 90 
  AND c.B < 90 
  AND c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh') -- Исключаем дисквал, чтобы не выводить пустые строки
ORDER BY c.B ASC; -- Сортируем: сначала те, у кого послушание хуже всего

-- Запрос 6: Статистика по породам (средний балл, лучший балл, худший балл)
SELECT 
    d.Breed,
    COUNT(c.Dog_id) AS starts_count, -- колличество стартов с собаками этой породы за 3 года
    -- Считаем среднее только по числам
    ROUND(AVG(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS REAL) END), 1) AS avg_score,
    -- Ищем максимум только среди чисел
    MAX(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS INTEGER) END) AS best_score,
    -- Ищем минимум только среди чисел
    MIN(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS INTEGER) END) AS worst_score
FROM Champ c
JOIN dogbase d ON c.Dog_id = d.Dog_id
GROUP BY d.Breed
HAVING starts_count > 3
ORDER BY avg_score DESC;

-- Запрос 7: Самая перспективная порода в IGP
SELECT 
    d.Breed,
    COUNT(c.Dog_id) AS starts_count,
    ROUND(AVG(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS REAL) END), 1) AS avg_score,
    MAX(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS INTEGER) END) AS best_score,
    -- Считаем стабильность (чем меньше разница, тем стабильнее)
    MAX(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS INTEGER) END) - 
    MIN(CASE WHEN c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '') THEN CAST(c.Total AS INTEGER) END) AS score_range
FROM Champ c
JOIN dogbase d ON c.Dog_id = d.Dog_id
GROUP BY d.Breed
HAVING starts_count >= 10 -- Берем только породы, где было хотя бы 10 выступлений
ORDER BY avg_score DESC, score_range ASC; -- Сначала по среднему баллу, потом по стабильности

-- Запрос 8: Кореляция следа и остальных разделов
SELECT 
    CASE 
        WHEN CAST(A AS INTEGER) >= 90 THEN 'Очхор (90+)'
        WHEN CAST(A AS INTEGER) BETWEEN 70 AND 89 THEN 'Удв-хор (70-89)'
        ELSE 'Некв (<70)'
    END AS group_A_score,
    
    COUNT(*) AS dogs_count,
    ROUND(AVG(CAST(A AS REAL)), 1) AS avg_A,
    ROUND(AVG(CAST(B AS REAL)), 1) AS avg_B,
    ROUND(AVG(CAST(C AS REAL)), 1) AS avg_C,
    ROUND(AVG(CAST(Total AS REAL)), 1) AS avg_Total
    
FROM Champ
WHERE Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '')
GROUP BY group_A_score
ORDER BY avg_A DESC;

-- Запрос 9: Вывести всех собак чей результат от года к году упал на 10% и более
WITH DogHistory AS (
    SELECT 
        d.Dog AS Dog_name,
        c.Year,
        CAST(c.Total AS INTEGER) AS Total,
        LAG(CAST(c.Total AS INTEGER)) OVER(PARTITION BY c.Dog_id ORDER BY c.Year) AS prev_total
    FROM Champ c
    JOIN dogbase d ON c.Dog_id = d.Dog_id
    WHERE c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '')
)
SELECT 
    Dog_name,
    Year AS current_year,
    Total AS current_total,
    prev_total,
    ROUND((Total - prev_total) * 100.0 / prev_total, 1) AS drop_percentage
FROM DogHistory
WHERE prev_total IS NOT NULL 
  AND (Total - prev_total) * 1.0 / prev_total <= -0.10 -- Ищем падение на 10% и более
ORDER BY drop_percentage ASC; -- Сначала те, кто упал сильнее всего

-- Запрос 10: Вывести список от самых стабильных к менее стабильным по общему баллу
SELECT 
    d.Dog AS Dog_name,
    c.Year,
    CAST(c.Total AS INTEGER) AS Total,
    -- Считаем среднее по собаке прямо в каждой строке (без GROUP BY)
    ROUND(AVG(CAST(c.Total AS REAL)) OVER(PARTITION BY c.Dog_id), 1) AS dog_avg,
    -- Считаем максимальный балл собаки за все время
    MAX(CAST(c.Total AS INTEGER)) OVER(PARTITION BY c.Dog_id) AS dog_max
FROM Champ c
JOIN dogbase d ON c.Dog_id = d.Dog_id
WHERE c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '')
ORDER BY dog_avg DESC;

-- Запрос 11: Собаки, которые набрали больше 280 баллов, имеют минимум 2 выступления на ЧР, при этом их средний балл в этом году выше среднего по их породе в этом же году.
WITH DogStats AS (
    -- Считаем баллы собаки и общее количество её стартов
    SELECT 
        c.Dog_id,
        c.Year,
        CAST(c.Total AS INTEGER) AS Total_Score,
        -- Считаем, сколько всего раз собака выступала (за все годы)
        COUNT(*) OVER(PARTITION BY c.Dog_id) AS total_starts
    FROM Champ c
    WHERE c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '')
),
BreedStats AS (
    -- Считаем средний балл по породе в каждом году
    SELECT 
        c.Year,
        d.Breed,
        AVG(CAST(c.Total AS REAL)) AS Avg_Breed_Score
    FROM Champ c
    JOIN dogbase d ON c.Dog_id = d.Dog_id
    WHERE c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '')
    GROUP BY c.Year, d.Breed
)
-- Соединяем всё вместе
SELECT 
    d.Dog AS Dog_name,
    d.Breed,
    ds.Year,
    ds.Total_Score,
    ds.total_starts, -- Выводим количество стартов, чтобы было видно
    ROUND(bs.Avg_Breed_Score, 1) AS Avg_Breed_Score,
    ROUND(ds.Total_Score - bs.Avg_Breed_Score, 1) AS above_breed_avg
FROM DogStats ds
JOIN dogbase d ON ds.Dog_id = d.Dog_id
JOIN BreedStats bs ON ds.Year = bs.Year AND d.Breed = bs.Breed
WHERE ds.total_starts >= 2 -- Условие: минимум 2 выступления за все время
  AND ds.Total_Score > 280  -- Отсекаем слабые результаты, чтобы список был осмысленным
  AND ds.Total_Score > bs.Avg_Breed_Score -- И результат должен быть выше среднего по породе
ORDER BY ds.Year DESC, above_breed_avg DESC;

-- Запрос 12: Собаки, выступившие во все 3х годах
SELECT d.Dog AS Dog_name, d.Breed
FROM dogbase d
JOIN Champ c ON d.Dog_id = c.Dog_id
WHERE c.Total NOT IN ('dis', 'ng', 'inj', 'hur', 'vh', '')
GROUP BY d.Dog, d.Breed
HAVING COUNT(DISTINCT c.Year) = 3; -- Собака есть во всех трех годах
