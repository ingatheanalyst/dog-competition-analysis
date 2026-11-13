-- Запрос 1: Воронка продаж

WITH StepCounts AS (
    SELECT 
        COUNT(DISTINCT CASE WHEN event_type = 'view' THEN user_id END) AS step_view,
        COUNT(DISTINCT CASE WHEN event_type = 'click' THEN user_id END) AS step_click,
        COUNT(DISTINCT CASE WHEN event_type = 'add_to_cart' THEN user_id END) AS step_cart,
        COUNT(DISTINCT CASE WHEN event_type = 'purchase' THEN user_id END) AS step_purchase
    FROM events
)
SELECT 
    step_view,
    step_click,
    ROUND(step_click * 100.0 / step_view, 2) AS cr_view_to_click,
    step_cart,
    ROUND(step_cart * 100.0 / step_click, 2) AS cr_click_to_cart,
    step_purchase,
    ROUND(step_purchase * 100.0 / step_cart, 2) AS cr_cart_to_purchase,
    ROUND(step_purchase * 100.0 / step_view, 2) AS total_conversion
FROM StepCounts;

-- Запрос 2: A/B тест

SELECT 
    u.ab_group,
    COUNT(DISTINCT u.user_id) AS total_users,
    SUM(a.total_revenue) AS total_revenue,
    ROUND(AVG(a.total_revenue), 2) AS arpu -- Средний доход на пользователя
FROM users u
JOIN ab_test_results a ON u.user_id = a.user_id
GROUP BY u.ab_group;

-- Запрос 3: Retention (Удержание)

WITH FirstVisit AS (
    -- Находим дату первого визита каждого пользователя
    SELECT 
        user_id, 
        MIN(event_date) AS reg_date
    FROM events
    GROUP BY user_id
),
NextDayVisits AS (
    -- Ищем тех, кто вернулся на следующий день
    SELECT DISTINCT e.user_id
    FROM events e
    JOIN FirstVisit f ON e.user_id = f.user_id
    WHERE DATE(e.event_date) = DATE(f.reg_date, '+1 day')
)
SELECT 
    (SELECT COUNT(*) FROM FirstVisit) AS total_users,
    (SELECT COUNT(*) FROM NextDayVisits) AS returned_next_day,
    ROUND((SELECT COUNT(*) FROM NextDayVisits) * 100.0 / (SELECT COUNT(*) FROM FirstVisit), 2) AS retention_day_1
;
