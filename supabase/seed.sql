-- Reference data for local/dev/staging. No real customer data.

-- Nigeria: 36 states + FCT
insert into public.regions (country_code, code, name) values
  ('NG','AB','Abia'),('NG','AD','Adamawa'),('NG','AK','Akwa Ibom'),('NG','AN','Anambra'),
  ('NG','BA','Bauchi'),('NG','BY','Bayelsa'),('NG','BE','Benue'),('NG','BO','Borno'),
  ('NG','CR','Cross River'),('NG','DE','Delta'),('NG','EB','Ebonyi'),('NG','ED','Edo'),
  ('NG','EK','Ekiti'),('NG','EN','Enugu'),('NG','FC','Federal Capital Territory'),
  ('NG','GO','Gombe'),('NG','IM','Imo'),('NG','JI','Jigawa'),('NG','KD','Kaduna'),
  ('NG','KN','Kano'),('NG','KT','Katsina'),('NG','KE','Kebbi'),('NG','KO','Kogi'),
  ('NG','KW','Kwara'),('NG','LA','Lagos'),('NG','NA','Nasarawa'),('NG','NI','Niger'),
  ('NG','OG','Ogun'),('NG','ON','Ondo'),('NG','OS','Osun'),('NG','OY','Oyo'),
  ('NG','PL','Plateau'),('NG','RI','Rivers'),('NG','SO','Sokoto'),('NG','TA','Taraba'),
  ('NG','YO','Yobe'),('NG','ZA','Zamfara');

-- Benin: 12 departments
insert into public.regions (country_code, code, name) values
  ('BJ','AL','Alibori'),('BJ','AK','Atacora'),('BJ','AQ','Atlantique'),('BJ','BO','Borgou'),
  ('BJ','CO','Collines'),('BJ','KO','Couffo'),('BJ','DO','Donga'),('BJ','LI','Littoral'),
  ('BJ','MO','Mono'),('BJ','OU','Ouémé'),('BJ','PL','Plateau'),('BJ','ZO','Zou');

-- Starter top-level categories (physical products only). PROPOSED list –
-- A/B/C to confirm; admins can edit after launch.
insert into public.categories (slug, name_en, name_fr, sort_order) values
  ('phones-tablets',   'Phones & Tablets',      'Téléphones et tablettes', 10),
  ('electronics',      'Electronics',           'Électronique',            20),
  ('computers',        'Computers',             'Ordinateurs',             30),
  ('fashion',          'Fashion',               'Mode',                    40),
  ('home-furniture',   'Home & Furniture',      'Maison et meubles',       50),
  ('appliances',       'Appliances',            'Électroménager',          60),
  ('vehicles-parts',   'Vehicle Parts',         'Pièces automobiles',      70),
  ('beauty-health',    'Beauty & Personal Care','Beauté et soins',         80),
  ('baby-kids',        'Baby & Kids',           'Bébé et enfants',         90),
  ('sports-outdoors',  'Sports & Outdoors',     'Sports et plein air',    100),
  ('books-media',      'Books & Media',         'Livres et médias',       110),
  ('other',            'Other',                 'Autres',                 999);
