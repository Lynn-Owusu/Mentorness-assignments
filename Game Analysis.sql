--Q1.Extract P_ID, Dev_ID,PName and Difficulty_Level of all palyers at level 0

 SELECT 
	  A.[P_ID] 
	, A.[Dev_ID]
	, A.[Difficulty] 
	,B.[PName]
	
	
FROM [Game Analysis].[dbo].[level_details2$] A

JOIN [Game Analysis].[dbo].[player_details$] B
ON A.[P_ID] = B.[P_ID]

 WHERE  [Level]= 0

 --Q2.Find Level1_codewise Avg_kill_Count where lives_earned is 2 and at least 3 stages are crossed

 SELECT 
  A.[L1_Code] AS Level1
 ,AVG(B.[Kill_Count]) AS Avg_Kill_Count
 FROM [Game Analysis].[dbo].[player_details$] A
 JOIN [Game Analysis].[dbo].[level_details2$] B
 ON A.[P_ID] = B.[P_ID]
 WHERE [Lives_Earned] = 2 and [Stages_crossed] >=3
 GROUP BY [L1_Code]
 

 --Q3.Find the total number of stages crossed at each difficulty_level for level 2 with palyers using zm_series devices

 SELECT 
 [Difficulty] AS Difficulty_level
 ,[Total Number of Stages_crossed] = SUM([Stages_crossed])
 ,[Dev_ID] AS Device_ID
 ,[Players using zm_seires] =
 CASE 
    WHEN [Dev_ID] LIKE '%zm%' THEN 'zm_seires'
	ELSE 'Other'
END
 FROM [Game Analysis].[dbo].[level_details2$]
 WHERE [Level] = 2
 GROUP BY [Difficulty], [Dev_ID],[Level]
 ORDER BY 2 DESC


 --Q4.Extract P_ID and the total number of unique dates for those who have played games on multiple days

SELECT
[P_ID]
,COUNT(DISTINCT TimeStamp) AS Num_Unique_Dates
FROM [Game Analysis].[dbo].[level_details2$]
GROUP BY [P_ID]
HAVING COUNT(DISTINCT TimeStamp) > 1


--Q5.Find P_ID and Sum of Kill_Counts where Kill_counts is greater than average kill count for Medium Difficulty

SELECT 
[P_ID]
,SUM([Kill_Count]) AS level_wise_sum
FROM [Game Analysis].[dbo].[level_details2$]

WHERE Kill_Count > 
(
 SELECT
 AVG(Kill_Count)
 FROM [Game Analysis].[dbo].[level_details2$]
 WHERE [Difficulty] = 'Medium'
 )
 GROUP BY [P_ID]

 --Q6.Find level and corresponding level_code wise sum of lives earned,excluding level 0

 SELECT 
 A.[Level]
 ,B.[L1_Code]
 ,B.[L2_Code]
 ,SUM(A.[Lives_Earned]) AS level_code_wise_sum
 FROM [Game Analysis].[dbo].[level_details2$] A
 JOIN [Game Analysis].[dbo].[player_details$] B
 ON A.[P_ID] = B.[P_ID]
 WHERE A.[Level] > 0 
 GROUP BY [Level], [L1_Code], [L2_Code]
 ORDER BY 1 ASC
   
 --Q7. Find the top 3 scores based on Dev_ID and rank them in increasing order using row_number 

 WITH Score_Numbers AS 
 (
 SELECT 
 [Dev_ID]
 ,[Score]
 ,[Difficulty]
  ,ROW_NUMBER() OVER (PARTITION BY  [Dev_ID] ORDER BY [Score] ASC) AS row_num
 FROM [Game Analysis].[dbo].[level_details2$]
 )
 SELECT
 [Dev_ID]
 ,[Score]
 ,[Difficulty]
  FROM  Score_Numbers
  WHERE row_num <=3
  ORDER BY  [Dev_ID],row_num

--Q8. Find the first_login datetime for each device ID

SELECT 
 [Dev_ID]
,[First_Login] = MIN([TimeStamp]) 
FROM [Game Analysis].[dbo].[level_details2$]
GROUP BY [Dev_ID];

--Q9. Find top 5 scores based on each difficulty level and rank them using Rank(ASC) and show Dev_ID

WITH TopScores AS
(
SELECT 
[Difficulty]
,[Score]
,[Dev_ID]
,[Rank_Scores] = RANK() OVER (PARTITION BY [Difficulty] ORDER BY [Score] ASC)
FROM [Game Analysis].[dbo].[level_details2$]
)
SELECT 
[Difficulty]
,[Score]
,[Dev_ID]
FROM TopScores
WHERE [Rank_Scores]<=5
ORDER BY [Difficulty],[Rank_Scores]


--Q10. Find the Dev_ID logged in start datetime for each player P_ID. Output(P_ID,Dev_ID, First login datetime)

SELECT 
[Dev_ID]
,[P_ID]
,[startdatetime] = MIN([TimeStamp]) 
FROM [Game Analysis].[dbo].[level_details2$]
GROUP BY [Dev_ID],[P_ID]


--Q11. A. How many kill_counts were played by each player and date using a windows functions

SELECT 
[P_ID]
,[TimeStamp]
,[Sum_Kill_Count] = SUM([Kill_Count]) OVER(PARTITION BY [P_ID] ORDER BY [TimeStamp] ) 
FROM [Game Analysis].[dbo].[level_details2$]


--B. How many kill_counts were played by each player and date without using a windows functions

SELECT 
[P_ID]
,[TimeStamp]
,(SELECT SUM(kill_count) FROM [Game Analysis].[dbo].[level_details2$] 
WHERE [P_ID] = g.[P_ID] AND [TimeStamp] <=g.[TimeStamp]) AS Commulative_Kill_Count
FROM [Game Analysis].[dbo].[level_details2$]  g


--Q12 Find a commulative sum of stages crossed over start_datetime for each P_ID,excluding most recent start_datetime

WITH Commulative_sum AS(
SELECT 
[P_ID]
,[TimeStamp]
,[Stages_crossed]
,ROW_NUMBER() OVER (PARTITION BY [P_ID] ORDER BY [TimeStamp] DESC ) AS sum_stages_crossed
FROM [Game Analysis].[dbo].[level_details2$]
)
SELECT 
[P_ID]
,[TimeStamp]
,SUM([Stages_crossed]) OVER (PARTITION BY [P_ID] ORDER BY [TimeStamp]) AS commulative_sum_stages_crossed
FROM  Commulative_sum
WHERE sum_stages_crossed > 1

--Q13. Extract the top 3 highest sums of scores for each Dev_ID and the corresponding P_ID

WITH summed_scores AS (
SELECT 
 [Dev_ID]
,[P_ID]
,SUM([Score]) AS sum_scores
FROM [Game Analysis].[dbo].[level_details2$]
GROUP BY [Dev_ID],[P_ID]
),
highest_scores AS (
SELECT 
[Dev_ID]
,[P_ID]
,sum_scores
,ROW_NUMBER() OVER(PARTITION BY [Dev_ID] ORDER BY sum_scores DESC) AS highest_sum
FROM summed_scores
)
SELECT 
[Dev_ID]
,[P_ID]
,sum_scores
FROM highest_scores
WHERE highest_sum <=3


--Q14. Find players who scored more than 50% of the average score, scored by the sum of scores for each P_ID

WITH avg_scores AS(
SELECT 
[P_ID]
,AVG([Score]) AS avg_score
FROM [Game Analysis].[dbo].[level_details2$]
GROUP BY [P_ID]
)
SELECT 
[P_ID]
,[Score]
FROM [Game Analysis].[dbo].[level_details2$]
WHERE Score > (SELECT avg_score * 0.5 FROM avg_scores WHERE avg_scores.P_ID = [Game Analysis].[dbo].[level_details2$].P_ID)


--Q15. Create a stored procedure to find the top 'n' headshots_count based on Dev_ID and rank them(ASC) using Row_Number.Display Difficulty

CREATE PROCEDURE TopHeadshotsByDevID 
@n INT
AS 
BEGIN
WITH Headshots AS(
SELECT 
 [Dev_ID]
,[Difficulty]
,[Headshots_Count]
,[Top_Headshots]=ROW_NUMBER() OVER(PARTITION BY [Dev_ID] ORDER BY [Headshots_Count] ASC)
FROM [Game Analysis].[dbo].[level_details2$]
)
SELECT 
 [Dev_ID]
,[Difficulty]
,[Headshots_Count]
FROM Headshots
WHERE [Top_Headshots] <= @n
ORDER BY [Dev_ID],[Top_Headshots] 
END 
GO

EXEC TopHeadshotsByDevID 5;










