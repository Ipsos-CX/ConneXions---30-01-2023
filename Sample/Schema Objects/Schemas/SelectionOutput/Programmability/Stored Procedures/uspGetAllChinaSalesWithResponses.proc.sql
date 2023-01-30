CREATE PROCEDURE SelectionOutput.uspGetAllChinaSalesWithResponses

AS /*

Description:  Gets all China Sales with Responses for output to DP. 
------------  Called by: Selection Output.dtsx (Output All Sales - Data Flow Task)	

Version		Created			Author			History		
-------		-------			------			-------			
1.0			27-07-2015		Chris Ross		Original version 
1.1			30-05-2016		Chris Ledger	Add extra verbatim comments
1.2			22-03-2017		Chris Ledger	Bug 13657 - Output Surname, Fullname, DearName & CoName as blank
1.3			21-06-2017		Ben King		BUG 14020 - Ouput Factory of Build, SVODealer and SVOVehicle
1.4			19-07-2017		Eddie Thomas	BUG 14099 - New data map July 2017
1.5			15-11-2017		Eddie Thomas	BUG 14371 - Integrating SMS data into China data Response Files
1.6			12-09-2018		Chris Ledger	BUG 14977 - Add Q21Response
1.7			11-10-2018		Chris Ledger	BUG 15053 - Add Q22Response, Q23Response & Q24Response fields
1.8			29-05-2019		Eddie Thomas	BUG 15412 - Add Q25 response, Q26 response, Q26 verbatim, Q27 response, Q27 verbatim, Q28 response & Q28 verbatim
1.9			14-01-2020		Chris Ledger	BUG 16865 - Add Q7a_1Response & Q7b_1Response fields

*/

    DECLARE @NOW DATETIME
    SET @NOW = GETDATE()

    SELECT  O.Password ,
            O.ID ,
            O.FullModel ,
            O.Model ,
            O.sType ,
            REPLACE(O.CarReg, CHAR(9), '') AS CarReg,
            REPLACE(O.Title , CHAR(9), '') AS Title,
            REPLACE(O.Initial , CHAR(9), '') AS Initial,
            N'' AS Surname,		-- V1.2
            N'' AS Fullname,	-- V1.2
            N'' AS DearName,	-- V1.2
            N'' AS CoName,		-- V1.2
            REPLACE(O.Add1 , CHAR(9), '') AS Add1,
            REPLACE(O.Add2 , CHAR(9), '') AS Add2,
            REPLACE(O.Add3 , CHAR(9), '') AS Add3,
            REPLACE(O.Add4 , CHAR(9), '') AS Add4,
            REPLACE(O.Add5 , CHAR(9), '') AS Add5,
            REPLACE(O.Add6 , CHAR(9), '') AS Add6,
            REPLACE(O.Add7 , CHAR(9), '') AS Add7,
            REPLACE(O.Add8 , CHAR(9), '') AS Add8,
            REPLACE(O.Add9 , CHAR(9), '') AS Add9,
            O.CTRY ,
            REPLACE(O.EmailAddress , CHAR(9), '') AS EmailAddress,
            O.Dealer ,
            O.sno ,
            O.ccode ,
            O.modelcode ,
            O.lang ,
            O.manuf ,
            O.gender ,
            O.qver ,
            O.blank ,
            O.etype ,
            O.reminder ,
            O.week ,
            O.test ,
            O.SampleFlag ,
            O.SalesServiceFile ,
            O.ITYPE ,
            O.Expired ,
            REPLACE(O.VIN , CHAR(9), '') AS VIN,
            REPLACE(CONVERT(VARCHAR(10), O.EventDate, 102), '.', '-') AS EventDate ,
            O.DealerCode ,
            REPLACE(O.Telephone , CHAR(9), '') AS Telephone,
            REPLACE(O.WorkTel , CHAR(9), '') AS WorkTel,
            REPLACE(O.MobilePhone , CHAR(9), '') AS MobilePhone,
            O.ManufacturerDealerCode ,
            O.ModelYear ,
            REPLACE(O.CustomerIdentifier , CHAR(9), '') AS CustomerIdentifier,
            O.OwnershipCycle ,
            O.OutletPartyID ,
            O.PartyID ,
            O.GDDDealerCode ,
            O.ReportingDealerPartyID ,
            O.VariantID ,
            O.ModelVariant ,
            CONVERT(NVARCHAR(10), @NOW, 121) AS SelectionDate ,
			CONVERT(NVARCHAR(100),
            CONVERT(VARCHAR(10), ISNULL(O.etype, '')) + '_'
            + CASE WHEN ISNULL(O.ITYPE, '') = '' THEN 'blank'
                   ELSE O.ITYPE
              END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.ccode, '')) + '_'
            + CASE WHEN O.manuf = 2 THEN 'J'
                   WHEN O.manuf = 3 THEN 'L'
                   ELSE 'UknownManufacturer'
              END + '_' 
			+ CONVERT(VARCHAR(10), ISNULL(O.lang, ''))) AS CampaignId,
			CSA.ResponseID, 
			CSA.InterviewerNumber,
			CSA.ResponseDate, 
			CSA.Q1Response, 
			CSA.Q1Verbatim, 
			CSA.Q2Response,  
			CSA.Q3Response, 
			CSA.Q4Response, 
			CSA.Q5Response, 
			CSA.Q6Response, 
			CSA.Q7Response,  
			CSA.Q8Response, 
			CSA.Q9Response,  
			CSA.Q9aResponse, 
			CSA.Q9aOptionResponse, 
			CSA.Q9aOption6verbatim, 
			CSA.Q10Response, 
			CSA.Q11Response,
			CSA.Q12Response, 
			CSA.Q13Response, 
			CSA.Q14Response,  
			CSA.Q15Response, 
			CSA.Q16Response,
			CSA.Q17Response,
			CSA.Q18Response, 
			CSA.Q21Response,						-- V1.6
			CSA.Q22Response,						-- V1.7
			CSA.Q23Response,						-- V1.7
			CSA.Q24Response,						-- V1.7
			CSA.AnonymousToRetailer, 
			CSA.AnonymousToManufacturer,
			CSA.Q3Verbatim,
			CSA.Q4Verbatim,
			CSA.Q5Verbatim,	
			CSA.Q7Verbatim,	
			CSA.Q9aVerbatim,
			CSA.Q10Verbatim,	
			CSA.Q12Verbatim,
			CSA.Q14aVerbatim,
			CSA.Q15aVerbatim,
			CSA.Q16Verbatim,
			CSA.Q17Verbatim,
			CSA.Q6Verbatim,							-- V1.4	
			CSA.Q7a AS Q7aResponse,					-- V1.4
			CSA.Q7aVerbatim,						-- V1.4
			CSA.Q7b AS Q7bResponse,					-- V1.4
			CSA.Q7bVerbatim,						-- V1.4
			CSA.Q8a AS Q8aVerbatim,					-- V1.4
			CSA.Q11_NEW AS Q11Verbatim,				-- V1.4
			CSA.Q14 AS [Q14 Response],				-- V1.4
			CSA.Q16a AS Q16aResponse,				-- V1.4
			CSA.Q16b AS Q16bVerbatim,				-- V1.4
			CSA.Q16c AS Q16cVerbatim,				-- V1.4
			CSA.Q20 AS Q20Response,					-- V1.4
			CSA.Q20Verbatim,						-- V1.4
			O.FOBCode,								-- V1.3
			ISNULL(O.SVOvehicle,0) As SVOvehicle,	-- V1.3
			ISNULL(O.SVODealer,0) AS SVODealer,	    -- V1.3	
			ISNULL(CSA.SurveyMethod,'') AS SurveyMethod,	--V1.5
			CSA.[Q25Response],						-- V1.8
			CSA.[Q26Response],						-- V1.8
			CSA.[Q26Verbatim],						-- V1.8
			CSA.[Q27Response],						-- V1.8
			CSA.[Q27Verbatim],						-- V1.8
			CSA.[Q28Response],						-- V1.8
			CSA.[Q28Verbatim],						-- V1.8
			CSA.[Q7a_1Response],					-- V1.9
			CSA.[Q7b_1Response]						-- V1.9
			
    FROM    SelectionOutput.OnlineOutput AS O
    INNER JOIN [$(ETLDB)].China.Sales_WithResponses CSA ON O.ID = CSA.CaseID 		
	