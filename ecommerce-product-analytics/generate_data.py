import pandas as pd
import numpy as np
import random
from datetime import datetime, timedelta

# Настройка для воспроизводимости (чтобы у всех были одинаковые данные)
np.random.seed(42)
random.seed(42)

# 1. ГЕНЕРАЦИЯ ПОЛЬЗОВАТЕЛЕЙ
num_users = 1000
channels = ['organic', 'paid_ads', 'referral', 'email']
groups = ['control', 'test']

users_data = []
for i in range(1, num_users + 1):
    # Дата первого визита (в течение января 2026)
    reg_date = datetime(2026, 1, 1) + timedelta(days=random.randint(0, 30))
    channel = random.choice(channels)
    group = random.choice(groups)
    users_data.append([i, reg_date.date(), channel, group])

df_users = pd.DataFrame(users_data, columns=['user_id', 'reg_date', 'acquisition_channel', 'ab_group'])
df_users.to_csv('users.csv', index=False, sep=';')

# 2. ГЕНЕРАЦИЯ СОБЫТИЙ (ВОРОНКА)
events = ['view', 'click', 'add_to_cart', 'purchase']
events_data = []
event_id = 1

for user in users_data:
    user_id = user[0]
    reg_date = user[1]
    group = user[3]
    
    # Вероятности прохождения шагов (для симуляции оттока)
    if group == 'control':
        prob_click = 0.6
        prob_cart = 0.4
        prob_purchase = 0.2
    else: # test (новая фича, конверсия чуть выше)
        prob_click = 0.7
        prob_cart = 0.5
        prob_purchase = 0.3

    # Шаг 1: Просмотр (делают все)
    events_data.append([event_id, user_id, reg_date, 'view', 0])
    event_id += 1
    
    # Шаг 2: Клик
    if random.random() < prob_click:
        click_date = reg_date + timedelta(days=random.randint(0, 1))
        events_data.append([event_id, user_id, click_date, 'click', 0])
        event_id += 1
        
        # Шаг 3: Корзина
        if random.random() < prob_cart:
            cart_date = click_date + timedelta(days=random.randint(0, 2))
            events_data.append([event_id, user_id, cart_date, 'add_to_cart', 0])
            event_id += 1
            
            # Шаг 4: Покупка
            if random.random() < prob_purchase:
                purchase_date = cart_date + timedelta(days=random.randint(0, 1))
                # Сумма покупки от 1000 до 10000 руб.
                amount = round(random.uniform(1000, 10000), 2)
                events_data.append([event_id, user_id, purchase_date, 'purchase', amount])
                event_id += 1

df_events = pd.DataFrame(events_data, columns=['event_id', 'user_id', 'event_date', 'event_type', 'amount'])
df_events.to_csv('events.csv', index=False, sep=';')

# 3. ГЕНЕРАЦИЯ РЕЗУЛЬТАТОВ A/B ТЕСТА
# Считаем сколько каждый пользователь потратил
revenue_per_user = df_events[df_events['event_type'] == 'purchase'].groupby('user_id')['amount'].sum().reset_index()
ab_data = pd.merge(df_users[['user_id', 'ab_group']], revenue_per_user, on='user_id', how='left').fillna({'amount': 0})
ab_data.columns = ['user_id', 'ab_group', 'total_revenue']

ab_data.to_csv('ab_test_results.csv', index=False, sep=';')

print("Данные успешно сгенерированы!")
print(f"Создано пользователей: {len(df_users)}")
print(f"Создано событий: {len(df_events)}")
print(f"Таблица A/B теста: {len(ab_data)} строк")