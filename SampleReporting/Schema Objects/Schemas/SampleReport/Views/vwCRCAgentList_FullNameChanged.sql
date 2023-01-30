CREATE VIEW [SampleReport].[vwCRCAgentList_FullNameChanged]

AS
/*
	Purpose:	Return CHANGED (FullName) entries in CRC Agent Lookup 
	Release		Version		Date		Developer			Comment
	UAT			1.0			2022-05-02	Eddie Thomas   		TASK 841 / Bugtracker 19452 

*/

SELECT		stg.CDSID,
			stg.FirstName AS FirstName_New, 
			glb.FirstName AS FirstName_Original,

			stg.Surname AS Surname_New, 
			glb.Surname AS Surname_Original,

			stg.DisplayOnQuestionnaire AS DisplayOnQuestionnaire_New, 
			glb.DisplayOnQuestionnaire AS DisplayOnQuestionnaire_Original,

			stg.DisplayOnWebsite AS DisplayOnWebsite_New, 
			glb.DisplayOnWebsite AS DisplayOnWebsite_Original,

			stg.FullName AS FullName_New,
			glb.FullName AS FullName_Original,
			stg.Market 
FROM		[$(ETLDB)].Stage.CRCAgents_GlobalList	stg  
INNER JOIN	[$(ETLDB)].Lookup.CRCAgents_GlobalList	glb ON	stg.CDSID		= glb.CDSID AND
															stg.Market		= glb.Market AND 
															stg.FirstName	= glb.FirstName AND
															stg.Surname		= glb.Surname

WHERE		stg.FullName <> glb.FullName
