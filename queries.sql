select p.dog, p.breed, r.year, r.total
from dogbase p
join camp r on p.dog_id = r.dog_id
where r.year = 2026
order by r.total desc
limit 5;
