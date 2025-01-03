--主キーはfirst_name, id
with original as (SELECT * FROM `preppindata-443311.PD2024week52.NiceNaghtyList`)

-- ListとList Orderを分割
,spliting as (SELECT 
  *,
  SPLIT(FilePaths, ' ')[offset(0)] as List,
  CAST(SPLIT(FilePaths, ' ')[offset(1)] as INT64) as ListOrder
FROM original)

--IndexとNiceScore, NaghtyScoreの作成
--Indexの作成
,makeIndex as (SELECT
 *,
 ((ListOrder * 100) + id)as Index
FROM spliting)

--Nice/Naghty Scoreの作成
,niceScore as (SELECT
  first_name,
  SUM(IF(List = 'Nice',1,0)) as NiceScore
FROM spliting
GROUP BY first_name)
,naghtyScore as 
(SELECT
  first_name,
  SUM(IF(List = 'Naughty',1,0)) as NaughtyScore
FROM spliting
GROUP BY first_name)

,scores as (SELECT 
  ni.NiceScore,
  na.NaughtyScore,
  m.Index,
  m.ListOrder,
  m.List,
  m.id,
  m.FilePaths,
  m.first_name
FROM makeIndex m
INNER JOIN niceScore ni
ON m.first_name = ni.first_name
INNER JOIN naghtyScore na
ON m.first_name = na.first_name)

--TieBreakでないNice/Naghtyを決定
,NiceOrNaughty as (SELECT
 *,
 CASE 
 WHEN NiceScore > NaughtyScore THEN "Nice"
 WHEN NaughtyScore > NiceScore THEN "Naughty"
 ELSE "unknown" 
 END as NiceOrNaughty
FROM scores)

--一人当たりの最大Index番号を決定
,LatestDecision as (SELECT
  first_name,
  MAX(Index) as LatestDecision
FROM NiceOrNaughty
GROUP BY first_name)

,joined as (
SELECT
  ld.LatestDecision,
  nn.NiceOrNaughty,
  nn.NaughtyScore,
  nn.NiceScore,
  nn.Index,
  nn.ListOrder,
  nn.List,
  nn.id,
  nn.first_name
FROM NiceOrNaughty nn
INNER JOIN LatestDecision ld
ON nn.first_name  = ld.first_name
)

-- TieBreakを決定

,tiebreak as (
  SELECT
  *,
  IF(NiceOrNaughty <> 'unknown',NiceOrNaughty,IF(LatestDecision=Index,List,NULL)) as NaughtyOrNiceTieBreak
FROM joined
)

,output as (SELECT
  MAX(NaughtyOrNiceTieBreak) as NaughtyOrNiceTiebreak,
  first_name
FROM tiebreak
GROUP BY first_name)

--検算

-- SELECT
--   *
-- FROM
--   (SELECT * FROM output EXCEPT DISTINCT SELECT * FROM `preppindata-443311.PD2024week52.2024week52answer`
-- )
-- UNION ALL
-- SELECT
--   *
-- FROM
--   (SELECT * FROM `preppindata-443311.PD2024week52.2024week52answer`
--  EXCEPT DISTINCT SELECT * FROM output)
