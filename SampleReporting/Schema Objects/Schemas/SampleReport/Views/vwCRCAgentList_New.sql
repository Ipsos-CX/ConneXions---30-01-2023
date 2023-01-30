CREATE VIEW [SampleReport].[vwCRCAgentList_New]

AS
/*
	Purpose:	Return NEW entries in CRC Agent Lookup 
	Release		Version		Date		Developer			Comment
	UAT			1.0			2022-05-02	Eddie Thomas   		TASK 841 / Bugtracker 19452 

*/
SELECT		stg.CDSID, stg.FirstName, stg.Surname, stg.DisplayOnQuestionnaire, stg.DisplayOnWebsite, stg.FullName, stg.Market 
FROM		[$(ETLDB)].Stage.CRCAgents_GlobalList	stg  
LEFT JOIN	[$(ETLDB)].Lookup.CRCAgents_GlobalList	glb ON	stg.CDSID		= glb.CDSID AND
															stg.FullName	= glb.FullName AND
															stg.Market		= glb.Market
WHERE		glb.CDSID IS NULL
