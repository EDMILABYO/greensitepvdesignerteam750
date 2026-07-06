alter table public.sites
  add column if not exists layout_length_m double precision not null default 0,
  add column if not exists layout_width_m double precision not null default 0;

alter table public.equipment
  add column if not exists position_x_m double precision not null default 0,
  add column if not exists position_y_m double precision not null default 0,
  add column if not exists footprint_length_m double precision not null default 0,
  add column if not exists footprint_width_m double precision not null default 0;
