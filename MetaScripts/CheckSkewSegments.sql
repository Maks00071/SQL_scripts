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
  all_seg;

/*
Схема "gp_toolkit" имеет две вьюшки, которые можно использовать для проверки перекосов:

 1. "gp_toolkit.gp_skew_coefficients" показывает перекос распределения данных путем расчета коэффициента
        вариации (CV) для данных, хранящихся в каждом сегменте. В столбце "skccoeff" показан
        коэффициент вариации, который рассчитывается как стандартное отклонение, разделенное на среднее значение.
        Он учитывает как среднее значение, так и изменчивость среднего значения ряда данных.
        Чем ниже значение, тем лучше. Более высокие значения указывают на большую асимметрию данных.

 2. "gp_toolkit.gp_skew_idle_fractions" показывает перекос в распределении данных путем расчета процента
        системы, которая простаивает во время сканирования таблицы, что является индикатором перекоса вычислений.
        Столбец "siffraction" показывает процент системы, которая простаивает во время сканирования таблицы.
        Это индикатор неравномерного распределения данных или неравномерности обработки запросов.
        Например, значение 0,1 указывает на асимметрию 10 %, значение 0,5 — на 50 % и т. д.
        Для таблиц с асимметрией более 10 % следует оценить политику распределения.
*/