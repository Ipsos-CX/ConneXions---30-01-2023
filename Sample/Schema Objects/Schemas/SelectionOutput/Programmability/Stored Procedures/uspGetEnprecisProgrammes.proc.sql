CREATE PROCEDURE SelectionOutput.uspGetEnprecisProgrammes

AS 

/*
	Purpose:	Collates output data for all Enprecis selections yet to be outputted.  
		
	Version			Date			Developer			Comment
	1.0				20150309		Peter Doyle			Take embedded code out of package
														Called by Selection Output - Enprecis.dtsx
	2.0				20150709		Peter Doyle			add new requirements bug 11679

*/


	SELECT DISTINCT
		CASE ProgrammeRequirement
			WHEN 'Enprecis JAG 1MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_JaguarDataUK_1M'
			WHEN 'Enprecis JAG 12MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_JaguarDataUK_12M'
			WHEN 'Enprecis JAG 24MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_JaguarDataUK_24M'
			WHEN 'Enprecis JAG 3MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_JaguarDataUK_3M'
			WHEN 'Enprecis LR 1MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_LandRoverDataUK_1M'
			WHEN 'Enprecis LR 12MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_LandRoverDataUK_12M'
			WHEN 'Enprecis LR 24MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_LandRoverDataUK_24M'
			WHEN 'Enprecis LR 3MIS 2014+' THEN CONVERT(VARCHAR(8), GETDATE(), 112) + '_LandRoverDataUK_3M'
			ELSE ''
		END	FileName
		, ProgrammeRequirement 
			
	FROM SelectionOutput.Enprecis