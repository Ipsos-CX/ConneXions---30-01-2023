
CREATE PROCEDURE SelectionOutput.uspGetSelectionOutputByLanguage_SMS
    @Brand NVARCHAR(510) ,
    @Questionnaire VARCHAR(100) ,
    @Region VARCHAR(100),
	@Language VARCHAR(100)
AS /*
Version	Created		Author		Purpose					Called by
1.0		5-Feb-2015	P.Doyle		Gets SMS selections		Selection Output.dtsx (SMS - Data Flow Task)	
								by language
*/

DECLARE @NOW DATETIME
SET @NOW = GETDATE()


    SELECT  C.InternationalDiallingCode
            + CONVERT(NVARCHAR(100), CONVERT(BIGINT, dbo.udfReturnNumericsOnly(SUBSTRING(LTRIM(O.MobilePhone),
                                                              1, 19)))) AS MobilePhone ,
            O.PartyID ,
            O.sType ,
            O.ID ,
            O.Password ,
            O.ccode ,
            O.lang ,
            O.etype ,
            O.[week] ,
            O.modelcode ,
            CONVERT(NVARCHAR(20), O.FullModel) AS FullModel,			
			CONVERT(VARCHAR(10),@Now,121) AS SelectionDate
			
    FROM    SelectionOutput.SMSOutputByLanguage AS O
            INNER JOIN ContactMechanism.Countries C ON C.CountryID = O.ccode
            INNER JOIN dbo.Languages l ON l.LanguageID = O.lang
            INNER JOIN dbo.Brands b ON b.ManufacturerPartyID = O.manuf
    WHERE   b.Brand = @Brand
            AND O.Questionnaire = @Questionnaire
            AND O.Region = @Region
			AND O.Region = @Region
			AND L.Language = @Language