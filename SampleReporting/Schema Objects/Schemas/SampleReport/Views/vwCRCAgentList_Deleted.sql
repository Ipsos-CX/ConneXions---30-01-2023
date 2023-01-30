CREATE VIEW [SampleReport].[vwCRCAgentList_Deleted]

AS
/*
	Purpose:	Return DELETED entries in CRC Agent Lookup 
	Release		Version		Date		Developer			Comment
	UAT			1.0			2022-05-02	Eddie Thomas   		TASK 841 / Bugtracker 19452 

*/
SELECT		glb.CDSID, glb.FirstName, glb.Surname, glb.DisplayOnQuestionnaire, glb.DisplayOnWebsite, glb.FullName, glb.Market 
FROM		[$(ETLDB)].Lookup.CRCAgents_GlobalList	glb
LEFT JOIN	[$(ETLDB)].Stage.CRCAgents_GlobalList	stg  ON	glb.CDSID		= stg.CDSID AND
															glb.FullName	= stg.FullName AND
															glb.Market		= stg.Market
WHERE		glb.CDSID IS NULL
