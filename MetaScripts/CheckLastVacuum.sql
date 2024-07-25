-- Запрос на просмотр данных последнего vacuum

select
  pn.nspname,
  pc.relname,
  pslo.staactionname,
  pslo.stasubtype,
  pslo.statime as action_date,
  pp.partitionrangestart
from
  pg_stat_last_operation pslo
  right outer join pg_class pc on pc.oid = pslo.objid
  and pslo.staactionname in ('VACUUM')
  join pg_namespace pn on pn.oid = pc.relnamespace
  left join pg_catalog.pg_partitions pp on (
    pp.partitiontablename = pc.relname
    and pp.schemaname = pn.nspname
  )
where
  pc.relkind IN ('r', 's')
  and pc.relstorage IN ('h', 'a', 'c')
  and relname like 'table_name'   -- название таблицы
  and pn.nspname = 'schema_name'  -- название схемы
order by
  partitionrangestart desc;


/*
"Bloat" (раздувание) - таблиц происходит, когда таблицы занимают больше пространства, чем фактически
    в ней находится данных. Причиной этого могут служить растущее количество мертвых строк.
Для предотвращения раздуваний необходимо своевременно запускать "vacuum". Если всё же таблица "распухла",
    то необходимо произвести "vacuum full".
Статистику, собранную "ANALYZE", можно использовать для расчета ожидаемого количества дисковых страниц,
    необходимых для хранения таблицы. Меру раздувания, путем сравнения соотношения ожидаемых и
    фактических страниц, можно увидеть, выполнив запрос:

                        "SELECT * FROM gp_toolkit.gp_bloat_diag;"

В результаты включены только таблицы с умеренным или значительным раздуванием. Умеренным раздувание
    считается, если соотношение фактических и ожидаемых страниц принимает значение от четырех до десяти.
    Значительным же считается раздувание, превышающее десять.
*/