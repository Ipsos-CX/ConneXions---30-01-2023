CREATE VIEW [SampleReport].[vwCRCAgentList_CDSIDChanged]

AS
/*
	Purpose:	Return CHANGED (CDSID) entries in CRC Agent Lookup 
	Release		Version		Date		Deveoloper			Comment
	UAT			1.0			2022-05-02	Eddie Thomas   		TASK 841 / Bugtracker 19452 

*/

SELECT		stg.CDSID AS CDSID_New,
			glb.CDSID AS CDSID_Original,
			
			stg.FirstName AS FirstName_New, 
			glb.FirstName AS FirstName_Original,

			stg.Surname AS Surname_New, 
			glb.Surname AS Surname_Original,

			stg.DisplayOnQuestionnaire AS DisplayOnQuestionnaire_New, 
			glb.DisplayOnQuestionnaire AS DisplayOnQuestionnaire_Original,

			stg.DisplayOnWebsite AS DisplayOnWebsite_New, 
			glb.DisplayOnWebsite AS DisplayOnWebsite_Original,

			stg.FullName,
			stg.Market 
FROM		[$(ETLDB)].Stage.CRCAgents_GlobalList	stg  
INNER JOIN	[$(ETLDB)].Lookup.CRCAgents_GlobalList	glb ON	stg.FullName	= glb.FullName AND
															stg.Market		= glb.Market 

WHERE		stg.CDSID <> glb.CDSID