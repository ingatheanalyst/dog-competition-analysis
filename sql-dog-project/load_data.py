import pandas as pd
import sqlite3

# 1. Подключаемся к базе данных
conn = sqlite3.connect('dogsdb.db')

print("Загружаю данные...")

# 2. Читаем dogbase.csv с разделителем ';'
df_dogs = pd.read_csv('dogbase.csv', sep=';')
# Записываем в базу (если таблица была, она заменится)
df_dogs.to_sql('dogbase', conn, if_exists='replace', index=False)

# 3. Читаем Champ.csv с разделителем ';'
df_champ = pd.read_csv('Champ.csv', sep=';')
# Записываем в базу
df_champ.to_sql('champ', conn, if_exists='replace', index=False)

# 4. Закрываем соединение
conn.close()

print("Готово! Обе таблицы перезаписаны с правильным разделителем.")
