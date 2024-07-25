-- Посмотреть на перекос данных, можно с помощью запроса

with all_seg as (
  select count(1) as seg_cnt
  from gp_segment_configuration c
  where c.content >= 0 and role = 'p'
),

tab_data as (
  select
    count(*) cnt,
    gp_segment_id,
    count(1) over () as total
  from
    <schema_name>.<table_name>  -- указываем название схемы и таблицы
  group by
    gp_segment_id
),

agg_data as (
  select
    total,
    max(cnt) as max_seg_rows,
    case when all_seg.seg_cnt > tab_data.total then 0 else min(cnt) end as min_seg_rows
  from
    all_seg,
    tab_data
  group by
    seg_cnt,
    total
)

select
  max_seg_rows, -- максимальное кол-во строк на сегменте (должно +- совпадать с минимальным кол-ом строк)
  min_seg_rows, -- минимальное кол-во строк на сегменте
  round(
    (max_seg_rows - min_seg_rows)* 100.0 / max_seg_rows  -- % перекоса данных
  ) as skew_prc,
  seg_cnt - total as empty_seg_cnt
from
  agg_data,
  all_seg