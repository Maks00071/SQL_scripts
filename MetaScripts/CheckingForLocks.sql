
-- Все текущие блокировки можно посмотреть в pg_lock:
select
	locktype, --Тип блокируемого объекта: relation (отношение), extend (расширение отношения), page (страница), tuple (кортеж), transactionid (идентификатор транзакции), virtualxid (виртуальный идентификатор), object (объект), userlock (пользовательская блокировка) или advisory (рекомендательная)
	database, -- Идентификтатор содержания сегмента. Праймери и миррор будут иметь одинаковый content. Для матсетра он всегда равен -1.
	relation, -- OID отношения, являющегося целью блокировки (pg_class.oid)
	transactionid, -- Идентификатор транзакции, являющийся целью блокировки
	pid, -- Идентификатор серверного процесса (PID, Process ID), удерживающего или ожидающего эту блокировку
	mode, -- Название режима блокировки, которая удерживается или запрашивается этим процессом
	granted -- True, если блокировка получена, и false, если она ожидается
from pg_catalog.pg_lock;

-- Данный скрипт проверяет наличие блокировок в СУБД PostgreSQL and Greenplum

CREATE OR REPLACE VIEW dq.blocked_sessions AS
SELECT kl.pid AS blocking_pid
     , ka.usename AS blocking_user
     , ka.query AS blocking_query
     , bl.pid AS blocked_pid
     , a.usename AS blocked_user
     , a.query AS blocked_query
     , kl.mode AS blocking_mode
     , kl.relation::regclass AS relation
     , bl.mode AS blockedmode
     , to_char(age(now(), a.query_start), 'HH24h:MIm:SSs'::text) AS age
  FROM pg_locks bl
  JOIN pg_stat_activity a ON bl.pid = a.pid
  JOIN pg_locks kl ON 1=1
   AND bl.locktype = kl.locktype
   AND NOT bl.database IS DISTINCT FROM kl.database
   AND NOT bl.relation IS DISTINCT FROM kl.relation
   AND NOT bl.page IS DISTINCT FROM kl.page
   AND NOT bl.tuple IS DISTINCT FROM kl.tuple
   AND NOT bl.transactionid IS DISTINCT FROM kl.transactionid
   AND NOT bl.classid IS DISTINCT FROM kl.classid
   AND NOT bl.objid IS DISTINCT FROM kl.objid
   AND NOT bl.objsubid IS DISTINCT FROM kl.objsubid
   AND bl.pid <> kl.pid
  JOIN pg_stat_activity ka ON kl.pid = ka.pid
 WHERE kl.granted AND NOT bl.granted
 ORDER BY a.query_start;