-- sample shops (same ones as the app's sample cards)
insert into shops (name, category, color_hex) values
  ('Oii Sushi',    'restaurant', '#5B7DB1'),
  ('YunTea',       'boba',       '#C96F4A'),
  ('85°C Bakery',  'bakery',     '#B8892F'),
  ('Lotus Boba',   'boba',       '#4E8F92'),
  ('Morning Pour', 'cafe',       '#8A6A9E'),
  ('Bean There',   'cafe',       '#6E9A7A'),
  ('Pho Corner',   'restaurant', '#B9667A');

-- each shop's stamp rules, matched by name
insert into stamp_programs (shop_id, stamps_needed, reward)
select shops.id, v.needed, v.reward
from shops
join (values
  ('Oii Sushi',    10, 'Free hand roll'),
  ('YunTea',       10, 'Free drink'),
  ('85°C Bakery',   8, 'Free pastry'),
  ('Lotus Boba',   10, 'Free drink'),
  ('Morning Pour',  8, 'Free latte'),
  ('Bean There',   10, 'Free coffee'),
  ('Pho Corner',   10, 'Free appetizer')
) as v(name, needed, reward) on v.name = shops.name;
