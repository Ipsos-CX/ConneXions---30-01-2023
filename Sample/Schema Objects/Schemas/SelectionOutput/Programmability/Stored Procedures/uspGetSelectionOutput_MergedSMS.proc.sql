CREATE PROCEDURE [SelectionOutput].[uspGetSelectionOutput_MergedSMS]

	@Brand [dbo].[OrganisationName], @Market [dbo].[Country], @Questionnaire [dbo].[Requirement]

AS

/*
	
	Version			Date			Developer			Comment
	1.1				10-10-2019		Ben King			BUG 15581 change URL
*/

DECLARE @NOW DATETIME
SET @NOW = GETDATE()

SELECT  DISTINCT
		C.InternationalDiallingCode
        + CONVERT(NVARCHAR(100), CONVERT(BIGINT, dbo.udfReturnNumericsOnly(O.MobilePhone))) AS MobilePhone ,
        O.PartyID ,
        O.sType ,
        O.ID ,
        O.Password ,
        O.ccode ,
        O.lang ,
        O.etype ,
        O.[week] ,
        O.modelcode ,
        CONVERT(NVARCHAR(20),O.FullModel) AS FullModel,
		CONVERT(VARCHAR(10),@Now,121) AS SelectionDate,
		'https://feedback.tell-jlr.com/S/' +  O.Password AS URL,
		CONVERT(VARCHAR,DATEADD(week, DATEDIFF(day, 0, getdate())/7, 3),103) AS FileDate
		
FROM    SelectionOutput.Merged_SMS AS O
        INNER JOIN ContactMechanism.Countries C ON C.CountryID = O.ccode

		INNER JOIN dbo.Markets M on o.ccode = M.countryID	

WHERE	O.DateOutput IS NULL AND
		O.Stype = @Brand AND 
		O.Questionnaire = @Questionnaire AND 
		M.Market = @Market