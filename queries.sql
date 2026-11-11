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
